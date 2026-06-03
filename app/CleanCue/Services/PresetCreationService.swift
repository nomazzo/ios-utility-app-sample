import Foundation
import SwiftData

enum PresetCreationError: Error, Equatable {
    case noPlacesSelected
    case noTasksSelected
    case freePlaceLimitExceeded
    case freeTaskLimitExceeded
    case missingPresetPlace(String)
    case missingPresetTask(String)
    case duplicatePresetPlace(String)
}

struct PresetCreationService {
    var provider: PresetProvider
    var calendar: Calendar
    var dueDatePolicy: InitialDueDatePolicy

    init(
        provider: PresetProvider = .defaultProvider,
        calendar: Calendar = .current
    ) {
        self.provider = provider
        self.calendar = calendar
        self.dueDatePolicy = InitialDueDatePolicy(calendar: calendar)
    }

    @discardableResult
    @MainActor
    func completeOnboarding(
        state: OnboardingState,
        referenceDate: Date = Date(),
        in modelContext: ModelContext,
        settingsStore: AppSettingsStore
    ) throws -> [CleaningTask] {
        guard !state.selectedPlaceIDs.isEmpty else {
            throw PresetCreationError.noPlacesSelected
        }
        guard !state.selectedTaskIDs.isEmpty else {
            throw PresetCreationError.noTasksSelected
        }

        let storedSettings = settingsStore.load()
        if !storedSettings.proUnlocked && state.selectedPlaceIDs.count > FeatureGate.freePlaceLimit {
            throw PresetCreationError.freePlaceLimitExceeded
        }

        let selectedTasks = provider.tasks(for: state.selectedPlaceIDs)
            .filter { state.selectedTaskIDs.contains($0.id) }
        guard !selectedTasks.isEmpty else {
            throw PresetCreationError.noTasksSelected
        }
        if !storedSettings.proUnlocked && selectedTasks.count > FeatureGate.freeTaskLimit {
            throw PresetCreationError.freeTaskLimitExceeded
        }

        var createdPlacesByID: [String: Place] = [:]

        for (index, placeID) in state.selectedPlaceIDs.sorted().enumerated() {
            guard let presetPlace = provider.place(for: placeID) else {
                throw PresetCreationError.missingPresetPlace(placeID)
            }
            let place = makePlace(from: presetPlace, orderIndex: index, referenceDate: referenceDate)
            modelContext.insert(place)
            createdPlacesByID[placeID] = place
        }

        let onboardingSettings = settings(from: state)
        let dueDates = dueDatePolicy.distributedDates(count: selectedTasks.count, referenceDate: referenceDate)
        let createdTasks = try selectedTasks.enumerated().map { index, presetTask in
            guard let place = createdPlacesByID[presetTask.placeID] else {
                throw PresetCreationError.missingPresetPlace(presetTask.placeID)
            }
            let task = makeTask(
                from: presetTask,
                place: place,
                dueDate: dueDates[index],
                referenceDate: referenceDate,
                settings: onboardingSettings
            )
            modelContext.insert(task)
            place.tasks.append(task)
            return task
        }

        var updatedSettings = storedSettings
        updatedSettings.hasCompletedOnboarding = true
        updatedSettings.homeType = state.homeType
        updatedSettings.defaultReminderEnabled = state.reminderEnabled
        updatedSettings.defaultReminderTimeMinutes = state.reminderTimeMinutes
        settingsStore.save(updatedSettings)

        try modelContext.save()
        return createdTasks
    }

    @discardableResult
    @MainActor
    func createPresetPlace(
        placeID: String,
        referenceDate: Date = Date(),
        existingPlaceCount: Int,
        existingPlaces: [Place] = [],
        in modelContext: ModelContext
    ) throws -> Place {
        guard let presetPlace = provider.place(for: placeID) else {
            throw PresetCreationError.missingPresetPlace(placeID)
        }
        if existingPresetPlace(placeID: placeID, existingPlaces: existingPlaces) != nil {
            throw PresetCreationError.duplicatePresetPlace(placeID)
        }

        let place = makePlace(from: presetPlace, orderIndex: existingPlaceCount, referenceDate: referenceDate)
        modelContext.insert(place)
        try modelContext.save()
        return place
    }

    @discardableResult
    @MainActor
    func createPresetPlaceWithDefaultTasks(
        placeID: String,
        defaultTaskCount: Int = 3,
        referenceDate: Date = Date(),
        existingPlaceCount: Int,
        in modelContext: ModelContext,
        settings: AppSettings
    ) throws -> Place {
        let place = try createPresetPlace(
            placeID: placeID,
            referenceDate: referenceDate,
            existingPlaceCount: existingPlaceCount,
            existingPlaces: [],
            in: modelContext
        )

        let defaultTasks = Array(provider.tasks(for: placeID).prefix(defaultTaskCount))
        let dueDates = dueDatePolicy.distributedDates(count: defaultTasks.count, referenceDate: referenceDate)
        for (index, presetTask) in defaultTasks.enumerated() {
            let task = makeTask(
                from: presetTask,
                place: place,
                dueDate: dueDates[index],
                referenceDate: referenceDate,
                settings: settings
            )
            modelContext.insert(task)
            place.tasks.append(task)
        }

        try modelContext.save()
        return place
    }

    @discardableResult
    @MainActor
    func createPresetTask(
        taskID: String,
        place: Place,
        referenceDate: Date = Date(),
        initialDueDate: Date? = nil,
        in modelContext: ModelContext,
        settings: AppSettings
    ) throws -> CleaningTask {
        guard let presetTask = provider.tasks.first(where: { $0.id == taskID }) else {
            throw PresetCreationError.missingPresetTask(taskID)
        }

        let task = makeTask(
            from: presetTask,
            place: place,
            dueDate: initialDueDate ?? calendar.startOfDay(for: referenceDate),
            referenceDate: referenceDate,
            settings: settings
        )
        modelContext.insert(task)
        place.tasks.append(task)
        try modelContext.save()
        return task
    }

    @discardableResult
    @MainActor
    func createHomeMaintenancePlaceIfNeeded(
        existingPlaces: [Place],
        referenceDate: Date = Date(),
        in modelContext: ModelContext
    ) -> Place {
        if let place = existingPresetPlace(
            placeID: provider.homeMaintenancePlace.id,
            existingPlaces: existingPlaces
        ) {
            return place
        }

        let place = makePlace(
            from: provider.homeMaintenancePlace,
            orderIndex: existingPlaces.count,
            referenceDate: referenceDate
        )
        modelContext.insert(place)
        return place
    }

    @MainActor
    func existingPresetPlace(placeID: String, existingPlaces: [Place]) -> Place? {
        guard let presetPlace = provider.place(for: placeID) else {
            return nil
        }

        return existingPlaces.first { place in
            guard !place.isArchived else { return false }
            return matches(place, preset: presetPlace)
        }
    }

    @MainActor
    func presetPlace(matching place: Place) -> PresetPlace? {
        (provider.places + [provider.homeMaintenancePlace]).first { preset in
            matches(place, preset: preset)
        }
    }

    private func settings(from state: OnboardingState) -> AppSettings {
        AppSettings(
            hasCompletedOnboarding: true,
            defaultReminderEnabled: state.reminderEnabled,
            defaultReminderTimeMinutes: state.reminderTimeMinutes,
            homeType: state.homeType
        )
    }

    private func matches(_ place: Place, preset: PresetPlace) -> Bool {
        let presetNames = [
            preset.displayName,
            preset.localizedDisplayName,
            preset.id.replacingOccurrences(of: "_", with: " ")
        ].map(normalized)
        let nameMatches = presetNames.contains(normalized(place.name))
        let styleMatches = place.iconName == preset.iconName
            && normalized(place.colorHex) == normalized(preset.colorHex)
        return nameMatches || styleMatches
    }

    private func normalized(_ string: String) -> String {
        string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    @MainActor
    private func makePlace(
        from preset: PresetPlace,
        orderIndex: Int,
        referenceDate: Date
    ) -> Place {
        Place(
            name: preset.localizedDisplayName,
            iconName: preset.iconName,
            colorHex: preset.colorHex,
            orderIndex: orderIndex,
            createdAt: referenceDate,
            updatedAt: referenceDate
        )
    }

    @MainActor
    private func makeTask(
        from preset: PresetTask,
        place: Place,
        dueDate: Date,
        referenceDate: Date,
        settings: AppSettings
    ) -> CleaningTask {
        let task = CleaningTask(
            name: preset.localizedDisplayName,
            place: place,
            nextDueDate: dueDate,
            scheduleKind: preset.scheduleKind,
            fixedRule: preset.fixedRule,
            intervalRule: preset.intervalRule,
            estimatedMinutes: preset.estimatedMinutes,
            priority: preset.priority,
            createdAt: referenceDate,
            updatedAt: referenceDate
        )
        task.note = preset.localizedNote
        task.tools = preset.localizedTools
        task.sourcePresetId = preset.id
        task.reminderEnabled = settings.defaultReminderEnabled
        task.reminderTimeMinutes = settings.defaultReminderTimeMinutes
        return task
    }
}
