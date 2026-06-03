import Foundation

nonisolated struct PresetPlace: Identifiable, Codable, Equatable, Sendable {
    var id: String
    var displayName: String
    var localizedNameKey: String
    var iconName: String
    var colorHex: String

    init(
        id: String,
        displayName: String,
        localizedNameKey: String,
        iconName: String,
        colorHex: String
    ) {
        self.id = id
        self.displayName = displayName
        self.localizedNameKey = localizedNameKey
        self.iconName = iconName
        self.colorHex = colorHex
    }
}

nonisolated struct PresetTask: Identifiable, Codable, Equatable, Sendable {
    var id: String
    var placeID: String
    var displayName: String
    var localizedNameKey: String
    var localizedNoteKey: String?
    var note: String
    var tools: String
    var estimatedMinutes: Int
    var priority: TaskPriority
    var scheduleKind: ScheduleKind
    var fixedRule: FixedRule?
    var intervalRule: IntervalRule?

    init(
        id: String,
        placeID: String,
        displayName: String,
        localizedNameKey: String,
        localizedNoteKey: String? = nil,
        note: String = "",
        tools: String = "",
        estimatedMinutes: Int,
        priority: TaskPriority = .normal,
        scheduleKind: ScheduleKind = .interval,
        fixedRule: FixedRule? = nil,
        intervalRule: IntervalRule? = nil
    ) {
        self.id = id
        self.placeID = placeID
        self.displayName = displayName
        self.localizedNameKey = localizedNameKey
        self.localizedNoteKey = localizedNoteKey
        self.note = note
        self.tools = tools
        self.estimatedMinutes = estimatedMinutes
        self.priority = priority
        self.scheduleKind = scheduleKind
        self.fixedRule = fixedRule
        self.intervalRule = intervalRule
    }
}

nonisolated enum ReminderTimeChoice: String, CaseIterable, Codable, Equatable, Sendable {
    case morning
    case noon
    case evening
    case night
    case none
    case custom

    var defaultMinutes: Int {
        switch self {
        case .morning:
            8 * 60
        case .noon:
            12 * 60
        case .evening:
            18 * 60
        case .night:
            20 * 60
        case .none, .custom:
            9 * 60
        }
    }

    var isReminderEnabled: Bool {
        self != .none
    }
}

nonisolated struct OnboardingState: Equatable, Sendable {
    var homeType: HomeType
    var selectedPlaceIDs: Set<String>
    var selectedTaskIDs: Set<String>
    var reminderChoice: ReminderTimeChoice
    var customReminderMinutes: Int

    init(
        homeType: HomeType = .livingAlone,
        selectedPlaceIDs: Set<String> = [],
        selectedTaskIDs: Set<String> = [],
        reminderChoice: ReminderTimeChoice = .morning,
        customReminderMinutes: Int = 9 * 60
    ) {
        self.homeType = homeType
        self.selectedPlaceIDs = selectedPlaceIDs
        self.selectedTaskIDs = selectedTaskIDs
        self.reminderChoice = reminderChoice
        self.customReminderMinutes = customReminderMinutes
    }

    var reminderEnabled: Bool {
        reminderChoice.isReminderEnabled
    }

    var reminderTimeMinutes: Int {
        reminderChoice == .custom ? customReminderMinutes : reminderChoice.defaultMinutes
    }
}

nonisolated struct OnboardingSuggestionPolicy: Sendable {
    func suggestedPlaceIDs(for homeType: HomeType) -> [String] {
        switch homeType {
        case .livingAlone:
            ["kitchen", "bathroom"]
        case .family:
            ["kitchen", "living_room"]
        case .shared:
            ["kitchen", "toilet"]
        case .other:
            ["kitchen", "bathroom"]
        }
    }

    func orderedPlaces(_ places: [PresetPlace], for homeType: HomeType) -> [PresetPlace] {
        let preferredIDs = suggestedPlaceIDs(for: homeType)
        return places.sorted { lhs, rhs in
            let lhsRank = preferredIDs.firstIndex(of: lhs.id) ?? Int.max
            let rhsRank = preferredIDs.firstIndex(of: rhs.id) ?? Int.max
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }

            let lhsOriginalIndex = places.firstIndex { $0.id == lhs.id } ?? Int.max
            let rhsOriginalIndex = places.firstIndex { $0.id == rhs.id } ?? Int.max
            return lhsOriginalIndex < rhsOriginalIndex
        }
    }

    func defaultTaskIDs(
        provider: PresetProvider,
        selectedPlaceIDs: Set<String>,
        homeType: HomeType
    ) -> Set<String> {
        let orderedPlaceIDs = orderedSelectedPlaceIDs(
            provider: provider,
            selectedPlaceIDs: selectedPlaceIDs,
            homeType: homeType
        )
        let allOrderedTasks = orderedPlaceIDs.flatMap { placeID in
            tasksOrdered(
                provider.tasks(for: placeID),
                homeType: homeType,
                placeID: placeID
            )
        }

        if orderedPlaceIDs.count >= 5 {
            return Set(allOrderedTasks.prefix(8).map(\.id))
        }

        let perPlaceLimit = orderedPlaceIDs.count <= 2 ? 3 : 2
        let defaults = orderedPlaceIDs.flatMap { placeID in
            tasksOrdered(
                provider.tasks(for: placeID),
                homeType: homeType,
                placeID: placeID
            )
            .prefix(perPlaceLimit)
        }
        return Set(defaults.map(\.id))
    }

    private func orderedSelectedPlaceIDs(
        provider: PresetProvider,
        selectedPlaceIDs: Set<String>,
        homeType: HomeType
    ) -> [String] {
        orderedPlaces(provider.places, for: homeType)
            .map(\.id)
            .filter { selectedPlaceIDs.contains($0) }
    }

    private func tasksOrdered(
        _ tasks: [PresetTask],
        homeType: HomeType,
        placeID: String
    ) -> [PresetTask] {
        let preferredIDs = preferredTaskIDs(homeType: homeType, placeID: placeID)
        return tasks.sorted { lhs, rhs in
            let lhsRank = preferredIDs.firstIndex(of: lhs.id) ?? Int.max
            let rhsRank = preferredIDs.firstIndex(of: rhs.id) ?? Int.max
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }

            let lhsOriginalIndex = tasks.firstIndex { $0.id == lhs.id } ?? Int.max
            let rhsOriginalIndex = tasks.firstIndex { $0.id == rhs.id } ?? Int.max
            return lhsOriginalIndex < rhsOriginalIndex
        }
    }

    private func preferredTaskIDs(homeType: HomeType, placeID: String) -> [String] {
        switch (homeType, placeID) {
        case (.family, "living_room"):
            ["living_floor_dust", "living_table_wipe", "living_sofa_crumbs"]
        case (.family, "washroom"):
            ["washroom_sink_wipe", "washroom_towel_change", "washroom_mirror_wipe"]
        case (.shared, "kitchen"):
            ["kitchen_sink_clean", "kitchen_counter_wipe", "kitchen_cabinet_handle_wipe"]
        case (.shared, "toilet"):
            ["toilet_seat_lid_wipe", "toilet_bowl_clean", "toilet_floor_wipe"]
        case (.shared, "entryway"):
            ["entryway_sweep", "entryway_shoes_reset", "entryway_door_handle_wipe"]
        default:
            []
        }
    }
}
