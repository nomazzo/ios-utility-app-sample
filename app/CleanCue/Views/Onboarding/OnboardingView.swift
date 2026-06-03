import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    private let provider: PresetProvider
    private let settingsStore: AppSettingsStore
    private let creationService: PresetCreationService
    private let featureGate = FeatureGate()
    private let suggestionPolicy = OnboardingSuggestionPolicy()
    private let onComplete: () -> Void

    @State private var state = OnboardingState()
    @State private var step = 0
    @State private var errorMessage: String?
    @State private var showingNotificationPrimer = false

    init(
        provider: PresetProvider = .defaultProvider,
        settingsStore: AppSettingsStore = AppSettingsStore(),
        creationService: PresetCreationService = PresetCreationService(),
        onComplete: @escaping () -> Void
    ) {
        self.provider = provider
        self.settingsStore = settingsStore
        self.creationService = creationService
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(step + 1), total: 6)
                    .padding(.horizontal)
                    .padding(.top)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                footer
            }
            .navigationTitle("HomeRoutine Demo")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingNotificationPrimer) {
                NotificationPermissionPrimerView {
                    showingNotificationPrimer = false
                    finishOnboarding(shouldRequestNotificationPermission: true)
                } secondaryAction: {
                    showingNotificationPrimer = false
                    finishOnboarding(shouldRequestNotificationPermission: false)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            conceptStep
        case 1:
            homeTypeStep
        case 2:
            placeStep
        case 3:
            taskStep
        case 4:
            reminderStep
        default:
            firstTaskStep
        }
    }

    private var conceptStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 28)
            OnboardingHeroVisual()
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text("onboarding.concept.title", "掃除、何から\nやるか迷わない"))
                    .font(.system(size: 36, weight: .black))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.text("onboarding.concept.subtitle", "今日やる掃除だけ表示します"))
                    .font(.system(size: 22, weight: .bold))
                    .padding(.top, 10)
                Text(L10n.text("onboarding.concept.privacy", "ログイン不要。データは端末内。"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(CleanCueTheme.secondaryText)
                    .padding(.top, 6)
            }
            Spacer()
        }
        .padding(24)
    }

    private var homeTypeStep: some View {
        Form {
            Section {
                ForEach(HomeType.allCases, id: \.self) { homeType in
                    SelectionRow(
                        title: homeType.displayName,
                        isSelected: state.homeType == homeType
                    ) {
                        selectHomeType(homeType)
                    }
                }
            } header: {
                Text(L10n.text("onboarding.homeType.title", "住まいタイプ"))
            } footer: {
                Text(L10n.text("onboarding.homeType.footer", "おすすめの掃除の初期候補に使います。あとから変更できます。"))
            }
        }
    }

    private var placeStep: some View {
        Form {
            Section {
                ForEach(suggestedOnboardingPlaces) { place in
                    SelectionRow(
                        title: place.localizedDisplayName,
                        systemImage: place.iconName,
                        iconTint: CleanCueTheme.placeColor(hex: place.colorHex),
                        isSelected: state.selectedPlaceIDs.contains(place.id),
                        isDisabled: placeSelectionDisabled(place.id)
                    ) {
                        togglePlace(place.id)
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("onboarding.places.title", "場所を選ぶ"))
                    Text(L10n.text("onboarding.places.helper", "まずはよく掃除する場所だけでOKです"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            } footer: {
                Text(onboardingPlaceFooterText)
            }
        }
        .contentMargins(.bottom, 240, for: .scrollContent)
    }

    private var taskStep: some View {
        Form {
            Section {
            } header: {
                Text(L10n.format("onboarding.tasks.headerWithCount", "おすすめの掃除・%d件選択中", state.selectedTaskIDs.count))
            } footer: {
                Text(onboardingTaskFooterText)
            }

            ForEach(selectedTaskSections) { section in
                Section {
                    ForEach(section.tasks) { task in
                        SelectionRow(
                            title: task.localizedDisplayName,
                            subtitle: L10n.format("onboarding.taskSubtitle", "%d分・%@", task.estimatedMinutes, task.intervalRuleText),
                            isSelected: state.selectedTaskIDs.contains(task.id),
                            isDisabled: taskSelectionDisabled(task.id)
                        ) {
                            toggleTask(task.id)
                        }
                    }
                } header: {
                    OnboardingTaskSectionHeader(
                        place: section.place,
                        selectedCount: section.selectedCount,
                        totalCount: section.tasks.count
                    )
                }
            }
        }
        .contentMargins(.bottom, 240, for: .scrollContent)
    }

    private var reminderStep: some View {
        Form {
            Section {
                ForEach(ReminderTimeChoice.allCases, id: \.self) { choice in
                    SelectionRow(
                        title: choice.displayName,
                        isSelected: state.reminderChoice == choice
                    ) {
                        state.reminderChoice = choice
                    }
                }
            } header: {
                Text(L10n.text("onboarding.reminder.title", "通知時刻"))
            } footer: {
                Text(L10n.text("onboarding.reminder.footer", "通知はあとから設定で変更できます。通知しない場合、許可ダイアログは表示しません。"))
            }

            if state.reminderChoice == .custom {
                Section(L10n.text("reminder.custom", "カスタム")) {
                    DatePicker(
                        L10n.text("reminder.time", "時刻"),
                        selection: customReminderDate,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                }
            }
        }
        .contentMargins(.bottom, 240, for: .scrollContent)
    }

    private var firstTaskStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n.text("onboarding.firstTask.title", "今日の1件"))
                .font(.title.bold())

            if let task = firstSelectedTask, let place = provider.place(for: task.placeID) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(place.localizedDisplayName, systemImage: place.iconName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(task.localizedDisplayName)
                        .font(.title2.bold())
                    Text(L10n.format("common.minutes", "%d分", task.estimatedMinutes))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text(L10n.text("onboarding.firstTask.empty", "選んだ掃除からTodayを始めます。"))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(24)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack {
                if step > 0 {
                    Button(L10n.text("common.back", "戻る")) {
                        errorMessage = nil
                        step -= 1
                    }
                }

                Spacer()

                Button {
                    advance()
                } label: {
                    Text(step == 5 ? L10n.text("onboarding.startToday", "はじめる") : L10n.text("common.next", "次へ"))
                        .font(.system(size: 21, weight: .bold))
                        .frame(width: step == 5 ? 146 : 140, height: 58)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .disabled(!canAdvance)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
        .padding(.bottom, 14)
        .background(.bar)
    }

    private var canAdvance: Bool {
        switch step {
        case 2:
            !state.selectedPlaceIDs.isEmpty
        case 3:
            !state.selectedTaskIDs.isEmpty
        default:
            true
        }
    }

    private var firstSelectedTask: PresetTask? {
        provider.tasks(for: state.selectedPlaceIDs)
            .first { state.selectedTaskIDs.contains($0.id) }
    }

    private var selectedTaskSections: [OnboardingTaskSection] {
        suggestionPolicy.orderedPlaces(provider.places, for: state.homeType)
            .filter { state.selectedPlaceIDs.contains($0.id) }
            .map { place in
                let tasks = provider.tasks(for: place.id)
                let selectedCount = tasks.filter { state.selectedTaskIDs.contains($0.id) }.count
                return OnboardingTaskSection(place: place, tasks: tasks, selectedCount: selectedCount)
            }
    }

    private var customReminderDate: Binding<Date> {
        Binding {
            date(fromMinutes: state.customReminderMinutes)
        } set: { date in
            state.customReminderMinutes = minutes(from: date)
        }
    }

    private var onboardingPlaceFooterText: String {
        if settingsStore.load().proUnlocked {
            return L10n.text("onboarding.places.footer", "まずは1〜3か所で十分です。選んだ場所に合う掃除を次に提案します。")
        }

        return L10n.text("onboarding.places.freeLimitFooter", "まずは1〜3か所で十分です。無料版では3か所まで選べます。")
    }

    private var onboardingTaskFooterText: String {
        if settingsStore.load().proUnlocked {
            return L10n.text("onboarding.tasks.footer", "最初は各場所2〜3件がおすすめです。不要なものは外せます。")
        }

        return L10n.text("onboarding.tasks.freeLimitFooter", "最初は各場所2〜3件がおすすめです。無料版では20件まで選べます。")
    }

    private var suggestedOnboardingPlaces: [PresetPlace] {
        suggestionPolicy.orderedPlaces(provider.onboardingPlaces, for: state.homeType)
    }

    private func advance() {
        errorMessage = nil

        if step == 1 {
            applyHomeTypePlaceSuggestionsIfNeeded()
        }

        if step == 2 {
            prepareDefaultTasks()
        }

        if step < 5 {
            step += 1
            return
        }

        if state.reminderEnabled {
            Task {
                let permissionState = await NotificationScheduler().permissionState()
                if permissionState == .notDetermined {
                    showingNotificationPrimer = true
                } else {
                    finishOnboarding(shouldRequestNotificationPermission: false)
                }
            }
        } else {
            finishOnboarding(shouldRequestNotificationPermission: false)
        }
    }

    private func finishOnboarding(shouldRequestNotificationPermission: Bool) {
        do {
            let createdTasks = try creationService.completeOnboarding(
                state: state,
                in: modelContext,
                settingsStore: settingsStore
            )
            if state.reminderEnabled {
                Task {
                    await requestPermissionAndSchedule(
                        createdTasks: createdTasks,
                        shouldRequestAuthorization: shouldRequestNotificationPermission
                    )
                }
            }
            WidgetUpdateService.refresh(tasks: createdTasks, pausePeriods: [])
            onComplete()
        } catch {
            errorMessage = L10n.text("onboarding.saveFailed", "初期設定を保存できませんでした。")
        }
    }

    private func requestPermissionAndSchedule(createdTasks: [CleaningTask], shouldRequestAuthorization: Bool) async {
        let scheduler = NotificationScheduler()
        do {
            let state = await scheduler.permissionState()
            if state == .notDetermined && shouldRequestAuthorization {
                _ = try await scheduler.requestAuthorization()
            }
            try await scheduler.rebuildNotifications(
                tasks: createdTasks,
                pausePeriods: [],
                settings: settingsStore.load()
            )
        } catch {
            // 通知権限の取得に失敗しても、オンボーディング完了は妨げない。
        }
    }

    private func selectHomeType(_ homeType: HomeType) {
        let previousSuggestedPlaceIDs = Set(suggestionPolicy.suggestedPlaceIDs(for: state.homeType))
        let shouldRefreshSuggestions = state.selectedPlaceIDs.isEmpty || state.selectedPlaceIDs == previousSuggestedPlaceIDs

        state.homeType = homeType

        if shouldRefreshSuggestions {
            applyHomeTypePlaceSuggestions()
        }
    }

    private func applyHomeTypePlaceSuggestionsIfNeeded() {
        guard state.selectedPlaceIDs.isEmpty else { return }
        applyHomeTypePlaceSuggestions()
    }

    private func applyHomeTypePlaceSuggestions() {
        let availableIDs = Set(provider.onboardingPlaces.map(\.id))
        state.selectedPlaceIDs = Set(
            suggestionPolicy.suggestedPlaceIDs(for: state.homeType)
                .filter { availableIDs.contains($0) }
        )
        let remainingTaskIDs = Set(provider.tasks(for: state.selectedPlaceIDs).map(\.id))
        state.selectedTaskIDs = state.selectedTaskIDs.intersection(remainingTaskIDs)
    }

    private func togglePlace(_ placeID: String) {
        if state.selectedPlaceIDs.contains(placeID) {
            state.selectedPlaceIDs.remove(placeID)
            let remainingTaskIDs = Set(provider.tasks(for: state.selectedPlaceIDs).map(\.id))
            state.selectedTaskIDs = state.selectedTaskIDs.intersection(remainingTaskIDs)
        } else {
            guard !placeSelectionDisabled(placeID) else { return }
            state.selectedPlaceIDs.insert(placeID)
        }
    }

    private func toggleTask(_ taskID: String) {
        if state.selectedTaskIDs.contains(taskID) {
            state.selectedTaskIDs.remove(taskID)
        } else {
            guard !taskSelectionDisabled(taskID) else { return }
            state.selectedTaskIDs.insert(taskID)
        }
    }

    private func placeSelectionDisabled(_ placeID: String) -> Bool {
        guard !state.selectedPlaceIDs.contains(placeID) else { return false }
        return featureGate.placeLimit(
            currentActivePlaceCount: state.selectedPlaceIDs.count,
            settings: settingsStore.load()
        ).isBlocked
    }

    private func taskSelectionDisabled(_ taskID: String) -> Bool {
        guard !state.selectedTaskIDs.contains(taskID) else { return false }
        return featureGate.taskLimit(
            currentActiveTaskCount: state.selectedTaskIDs.count,
            settings: settingsStore.load()
        ).isBlocked
    }

    private func prepareDefaultTasks() {
        let availableIDs = Set(provider.tasks(for: state.selectedPlaceIDs).map(\.id))
        state.selectedTaskIDs = state.selectedTaskIDs.intersection(availableIDs)

        guard state.selectedTaskIDs.isEmpty else { return }

        state.selectedTaskIDs = suggestionPolicy.defaultTaskIDs(
            provider: provider,
            selectedPlaceIDs: state.selectedPlaceIDs,
            homeType: state.homeType
        )
    }

    private func date(fromMinutes minutes: Int) -> Date {
        Calendar.current.date(
            from: DateComponents(hour: minutes / 60, minute: minutes % 60)
        ) ?? Date()
    }

    private func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 9) * 60 + (components.minute ?? 0)
    }
}

private struct OnboardingTaskSection: Identifiable {
    let place: PresetPlace
    let tasks: [PresetTask]
    let selectedCount: Int

    var id: String {
        place.id
    }
}

private struct OnboardingTaskSectionHeader: View {
    let place: PresetPlace
    let selectedCount: Int
    let totalCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: place.iconName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(placeColor)
                .frame(width: 22, height: 22)
                .background(placeColor.opacity(0.14), in: Circle())

            Text(place.localizedDisplayName)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Text(L10n.format("onboarding.tasks.placeSelectionCount", "%d/%d件選択", selectedCount, totalCount))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .textCase(nil)
    }

    private var placeColor: Color {
        CleanCueTheme.placeColor(hex: place.colorHex)
    }
}

private struct OnboardingHeroVisual: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("onboarding.hero.title", "Today at a glance"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(L10n.text("onboarding.hero.summary", "3 tasks · 17 min"))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.primary.opacity(0.88))
                }

                Spacer()

                CleanCueProgressRing(
                    progress: 0.34,
                    label: "1/3",
                    size: 60,
                    lineWidth: 6,
                    tint: CleanCueTheme.cleanMint.opacity(0.68)
                )
            }

            VStack(alignment: .leading, spacing: 7) {
                OnboardingHeroRow(
                    title: L10n.text("preset.task.kitchen.sinkClean", "Clean sink"),
                    minutes: L10n.format("common.minutes", "%d分", 5),
                    color: CleanCueTheme.cleanMint
                )
                OnboardingHeroRow(
                    title: L10n.text("preset.task.bathroom.drainClean", "Clean drain"),
                    minutes: L10n.format("common.minutes", "%d分", 8),
                    color: CleanCueTheme.primaryBlue
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: 366)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(CleanCueTheme.separator.opacity(0.7), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
    }
}

private struct OnboardingHeroRow: View {
    let title: String
    let minutes: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color.opacity(0.42))
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary.opacity(0.82))
                .lineLimit(1)
            Spacer()
            Text(minutes)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct OnboardingSampleTaskCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.text("onboarding.sample.title", "今日のおすすめ"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(L10n.text("urgency.today.short", "Today"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor, in: Capsule())
            }

            Text(L10n.text("onboarding.sample.task", "Clean sink"))
                .font(.headline)
            HStack(spacing: 12) {
                InlineMetaLabel(text: L10n.text("preset.place.kitchen", "Kitchen"), systemImage: "house")
                InlineMetaLabel(text: L10n.format("common.minutes", "%d分", 5), systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

private struct SelectionRow: View {
    let title: String
    var systemImage: String? = nil
    var subtitle: String? = nil
    var iconTint: Color = Color.accentColor
    var selectionTint: Color = CleanCueTheme.primaryBlue
    let isSelected: Bool
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .frame(width: 24)
                        .foregroundStyle(iconTint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? selectionTint : Color.secondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.42 : 1)
    }
}

private extension PresetTask {
    var intervalRuleText: String {
        guard let intervalRule else { return L10n.text("schedule.fixed", "固定日") }
        switch intervalRule.unit {
        case .day:
            return L10n.format("interval.everyDays", "%d日ごと", intervalRule.value)
        case .week:
            return L10n.format("interval.everyWeeks", "%d週ごと", intervalRule.value)
        case .month:
            return L10n.format("interval.everyMonths", "%dか月ごと", intervalRule.value)
        case .year:
            return L10n.format("interval.everyYears", "%d年ごと", intervalRule.value)
        }
    }
}

#Preview {
    OnboardingView {}
        .modelContainer(PreviewSampleData.makeContainer())
}
