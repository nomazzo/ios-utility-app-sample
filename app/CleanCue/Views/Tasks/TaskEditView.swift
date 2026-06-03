import SwiftData
import SwiftUI

struct TaskEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Place.orderIndex), SortDescriptor(\Place.createdAt)])
    private var places: [Place]
    @Query(sort: [SortDescriptor(\CleaningTask.nextDueDate), SortDescriptor(\CleaningTask.createdAt)])
    private var allTasks: [CleaningTask]
    @Query(sort: [SortDescriptor(\PausePeriod.startDate, order: .reverse)])
    private var pausePeriods: [PausePeriod]

    private let task: CleaningTask?
    private let initialPlace: Place?
    private let allowsPlaceSelection: Bool

    @State private var selectedPlaceID: UUID?
    @State private var name: String
    @State private var estimatedMinutes: Int
    @State private var priority: TaskPriority
    @State private var note: String
    @State private var tools: String
    @State private var reminderEnabled: Bool
    @State private var reminderTimeMinutes: Int
    @State private var reminderStyle: ReminderStyle
    @State private var scheduleKind: ScheduleKind
    @State private var nextDueDate: Date
    @State private var intervalValue: Int
    @State private var intervalUnit: IntervalUnit
    @State private var fixedRuleType: FixedRuleType
    @State private var selectedWeekday: Int
    @State private var dayOfMonth: Int
    @State private var month: Int
    @State private var day: Int
    @State private var anchorDate: Date
    @State private var validationMessage: String?
    @State private var showingReminderStyleProAlert = false
    @State private var showingProView = false

    private let featureGate = FeatureGate()
    private let settingsStore = AppSettingsStore()
    private let dueDatePolicy = InitialDueDatePolicy()
    @State private var initialDueChoice: InitialDueDateChoice = .today

    private var activePlaces: [Place] {
        places.filter { !$0.isArchived }
    }

    private var fixedPlace: Place? {
        activePlaces.first { $0.id == selectedPlaceID } ?? initialPlace
    }

    init(task: CleaningTask? = nil, place: Place? = nil, allowsPlaceSelection: Bool = true) {
        self.task = task
        self.initialPlace = place ?? task?.place
        self.allowsPlaceSelection = allowsPlaceSelection

        let intervalRule = task?.intervalRule ?? IntervalRule(value: 7, unit: .day)
        let fixedRule = task?.fixedRule ?? FixedRule(type: .weekly, weekdays: [2], anchorDate: Date())

        _selectedPlaceID = State(initialValue: (place ?? task?.place)?.id)
        _name = State(initialValue: task?.name ?? "")
        _estimatedMinutes = State(initialValue: task?.estimatedMinutes ?? 5)
        _priority = State(initialValue: task?.priority ?? .normal)
        _note = State(initialValue: task?.note ?? "")
        _tools = State(initialValue: task?.tools ?? "")
        _reminderEnabled = State(initialValue: task?.reminderEnabled ?? AppSettingsStore().load().defaultReminderEnabled)
        _reminderTimeMinutes = State(initialValue: task?.reminderTimeMinutes ?? AppSettingsStore().load().defaultReminderTimeMinutes)
        _reminderStyle = State(initialValue: task?.reminderStyle ?? .standard)
        _scheduleKind = State(initialValue: task?.scheduleKind ?? .interval)
        _nextDueDate = State(initialValue: task?.nextDueDate ?? Date())
        _intervalValue = State(initialValue: max(intervalRule.value, 1))
        _intervalUnit = State(initialValue: intervalRule.unit)
        _fixedRuleType = State(initialValue: fixedRule.type)
        _selectedWeekday = State(initialValue: fixedRule.weekdays.first ?? 2)
        _dayOfMonth = State(initialValue: fixedRule.dayOfMonth ?? 1)
        _month = State(initialValue: fixedRule.month ?? 1)
        _day = State(initialValue: fixedRule.day ?? 1)
        _anchorDate = State(initialValue: fixedRule.anchorDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.text("task.edit.sectionTask", "掃除")) {
                    TextField(L10n.text("task.edit.name", "名前"), text: $name)

                    if activePlaces.isEmpty {
                        Text(L10n.text("task.edit.createPlaceFirst", "掃除を追加する前に場所を作成してください。"))
                            .foregroundStyle(.secondary)
                    } else if !allowsPlaceSelection, let fixedPlace {
                        Label(fixedPlace.name, systemImage: fixedPlace.iconName)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker(L10n.text("task.edit.place", "場所"), selection: $selectedPlaceID) {
                            ForEach(activePlaces) { place in
                                Text(place.name).tag(Optional(place.id))
                            }
                        }
                    }

                    Stepper(
                        L10n.format("task.edit.estimateValue", "Estimate: %d min", estimatedMinutes),
                        value: $estimatedMinutes,
                        in: 1...240
                    )

                    Picker(L10n.text("task.edit.priority", "優先度"), selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                }

                Section(L10n.text("task.edit.sectionSchedule", "予定")) {
                    Picker(L10n.text("task.edit.scheduleType", "種類"), selection: $scheduleKind) {
                        Text(L10n.text("schedule.fixed", "固定日")).tag(ScheduleKind.fixed)
                        Text(L10n.text("schedule.interval", "経過日")).tag(ScheduleKind.interval)
                    }
                    .pickerStyle(.segmented)

                    if task == nil {
                        InitialDueDateChoicePicker(selection: $initialDueChoice)
                    }

                    DatePicker(
                        task == nil
                            ? L10n.text("task.edit.initialDue", "初回予定日")
                            : L10n.text("task.edit.nextDue", "次回"),
                        selection: $nextDueDate,
                        displayedComponents: .date
                    )

                    if scheduleKind == .interval {
                        Stepper(
                            intervalValueLabel,
                            value: $intervalValue,
                            in: 1...365
                        )
                        Picker(L10n.text("task.edit.intervalUnit", "単位"), selection: $intervalUnit) {
                            ForEach(IntervalUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                    } else {
                        Picker(L10n.text("task.edit.fixedRule", "固定ルール"), selection: $fixedRuleType) {
                            ForEach(FixedRuleType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }

                        fixedRuleFields
                    }
                }

                Section(L10n.text("task.edit.sectionNotes", "メモ")) {
                    TextField(L10n.text("task.edit.tools", "道具"), text: $tools, axis: .vertical)
                    TextField(L10n.text("task.edit.note", "メモ"), text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section(L10n.text("task.edit.sectionNotification", "通知")) {
                    Toggle(L10n.text("task.edit.notify", "この掃除を通知する"), isOn: $reminderEnabled)
                    DatePicker(L10n.text("task.edit.notificationTime", "時刻"), selection: reminderDateBinding, displayedComponents: .hourAndMinute)
                        .disabled(!reminderEnabled)
                    Picker(L10n.text("task.edit.notificationStyle", "通知スタイル"), selection: $reminderStyle) {
                        ForEach(ReminderStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .disabled(!reminderEnabled)
                    Text(reminderStyleHelpText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(L10n.text("task.edit.notificationScopeHelp", "この設定はこの掃除だけに適用されます。"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(task == nil ? L10n.text("task.edit.newTitle", "掃除を追加") : L10n.text("task.edit.editTitle", "掃除を編集"))
            .onAppear {
                if selectedPlaceID == nil {
                    selectedPlaceID = initialPlace?.id ?? activePlaces.first?.id
                }
                if !featureGate.canUseReminderStyle(reminderStyle, settings: settingsStore.load()) {
                    reminderStyle = .standard
                }
            }
            .onChange(of: reminderStyle) { _, newStyle in
                guard !featureGate.canUseReminderStyle(newStyle, settings: settingsStore.load()) else { return }
                reminderStyle = .standard
                showingReminderStyleProAlert = true
            }
            .onChange(of: initialDueChoice) { _, newChoice in
                nextDueDate = dueDatePolicy.startDate(for: newChoice)
            }
            .alert(L10n.text("pro.limit.reminderStyle.title", "当日以外の通知はPro機能です"), isPresented: $showingReminderStyleProAlert) {
                Button(L10n.text("common.cancel", "キャンセル"), role: .cancel) {}
                Button(L10n.text("pro.view", "Proを見る")) {
                    showingProView = true
                }
            } message: {
                Text(L10n.text("pro.limit.reminderStyle.message", "前日や3日前から通知するにはProが必要です。"))
            }
            .sheet(isPresented: $showingProView) {
                NavigationStack {
                    ProView(
                        settingsStore: settingsStore,
                        dismissAfterUnlockAcknowledgement: true
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("common.cancel", "キャンセル")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("common.save", "保存")) {
                        save()
                    }
                    .disabled(activePlaces.isEmpty)
                }
            }
        }
    }

    private var intervalValueLabel: String {
        if L10n.isDanish {
            switch intervalUnit {
            case .day:
                return "Hver \(intervalValue). dag"
            case .week:
                return "Hver \(intervalValue). uge"
            case .month:
                return "Hver \(intervalValue). måned"
            case .year:
                return "Hvert \(intervalValue). år"
            }
        }
        if L10n.isNorwegianBokmal {
            switch intervalUnit {
            case .day:
                return intervalValue == 1 ? "Hver dag" : "Hver \(intervalValue). dag"
            case .week:
                return intervalValue == 1 ? "Hver uke" : "Hver \(intervalValue). uke"
            case .month:
                return intervalValue == 1 ? "Hver måned" : "Hver \(intervalValue). måned"
            case .year:
                return intervalValue == 1 ? "Hvert år" : "Hvert \(intervalValue). år"
            }
        }
        if L10n.isSpanish {
            switch intervalUnit {
            case .day:
                return intervalValue == 1 ? "Cada día" : "Cada \(intervalValue) días"
            case .week:
                return intervalValue == 1 ? "Cada semana" : "Cada \(intervalValue) semanas"
            case .month:
                return intervalValue == 1 ? "Cada mes" : "Cada \(intervalValue) meses"
            case .year:
                return intervalValue == 1 ? "Cada año" : "Cada \(intervalValue) años"
            }
        }
        if L10n.isPortuguese {
            switch intervalUnit {
            case .day:
                return intervalValue == 1 ? "Todos os dias" : "De \(intervalValue) em \(intervalValue) dias"
            case .week:
                return intervalValue == 1 ? "Todas as semanas" : "De \(intervalValue) em \(intervalValue) semanas"
            case .month:
                return intervalValue == 1 ? "Todos os meses" : "De \(intervalValue) em \(intervalValue) meses"
            case .year:
                return intervalValue == 1 ? "Todos os anos" : "De \(intervalValue) em \(intervalValue) anos"
            }
        }
        if L10n.isItalian {
            switch intervalUnit {
            case .day:
                return intervalValue == 1 ? "Ogni giorno" : "Ogni \(intervalValue) giorni"
            case .week:
                return intervalValue == 1 ? "Ogni settimana" : "Ogni \(intervalValue) settimane"
            case .month:
                return intervalValue == 1 ? "Ogni mese" : "Ogni \(intervalValue) mesi"
            case .year:
                return intervalValue == 1 ? "Ogni anno" : "Ogni \(intervalValue) anni"
            }
        }
        if L10n.isKorean {
            switch intervalUnit {
            case .day:
                return "\(intervalValue)일마다"
            case .week:
                return "\(intervalValue)주마다"
            case .month:
                return "\(intervalValue)개월마다"
            case .year:
                return "\(intervalValue)년마다"
            }
        }
        if L10n.isTraditionalChinese {
            switch intervalUnit {
            case .day:
                return "每 \(intervalValue) 天"
            case .week:
                return "每 \(intervalValue) 週"
            case .month:
                return "每 \(intervalValue) 個月"
            case .year:
                return "每 \(intervalValue) 年"
            }
        }
        if L10n.isFinnish {
            switch intervalUnit {
            case .day:
                return intervalValue == 1 ? "Joka päivä" : "\(intervalValue) päivän välein"
            case .week:
                return intervalValue == 1 ? "Joka viikko" : "\(intervalValue) viikon välein"
            case .month:
                return intervalValue == 1 ? "Joka kuukausi" : "\(intervalValue) kuukauden välein"
            case .year:
                return intervalValue == 1 ? "Joka vuosi" : "\(intervalValue) vuoden välein"
            }
        }
        return L10n.format("task.edit.intervalValue", "Every %d", intervalValue)
    }

    @ViewBuilder
    private var fixedRuleFields: some View {
        switch fixedRuleType {
        case .weekly:
            weekdayPicker
        case .biweekly:
            weekdayPicker
            DatePicker(L10n.text("task.edit.anchorWeek", "基準週"), selection: $anchorDate, displayedComponents: .date)
        case .monthlyDay:
            Stepper(L10n.format("task.edit.dayOfMonthValue", "Day %d", dayOfMonth), value: $dayOfMonth, in: 1...31)
        case .monthlyLastDay:
            Text(L10n.text("task.edit.monthlyLastDayHelp", "毎月末日に予定します。"))
                .foregroundStyle(.secondary)
        case .yearlyDate:
            Stepper(L10n.format("task.edit.monthValue", "Month %d", month), value: $month, in: 1...12)
            Stepper(L10n.format("task.edit.dayValue", "Day %d", day), value: $day, in: 1...31)
        }
    }

    private var weekdayPicker: some View {
        Picker(L10n.text("task.edit.weekday", "曜日"), selection: $selectedWeekday) {
            ForEach(1...7, id: \.self) { weekday in
                Text(weekdayName(weekday)).tag(weekday)
            }
        }
    }

    private var reminderStyleHelpText: String {
        if !reminderEnabled {
            return L10n.text("reminderStyle.disabledHelp", "通知はオフです。")
        }
        if !settingsStore.load().proUnlocked, reminderStyle == .standard {
            return L10n.text("reminderStyle.proLockedHelp", "当日以外の通知はProで選べます。")
        }
        return reminderStyle.helpText
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = L10n.text("task.edit.error.nameRequired", "名前を入力してください。")
            return
        }

        guard let selectedPlace = activePlaces.first(where: { $0.id == selectedPlaceID }) else {
            validationMessage = L10n.text("task.edit.error.placeRequired", "場所を選択してください。")
            return
        }

        guard intervalValue > 0 else {
            validationMessage = L10n.text("task.edit.error.intervalRequired", "間隔は1以上にしてください。")
            return
        }

        let fixedRule = makeFixedRule()
        let intervalRule = IntervalRule(value: intervalValue, unit: intervalUnit)
        let settings = settingsStore.load()
        let savedReminderStyle = featureGate.canUseReminderStyle(reminderStyle, settings: settings) ? reminderStyle : .standard

        var tasksForNotificationRebuild = allTasks

        if let task {
            task.name = trimmedName
            task.place = selectedPlace
            task.estimatedMinutes = estimatedMinutes
            task.priority = priority
            task.note = note
            task.tools = tools
            task.reminderEnabled = reminderEnabled
            task.reminderTimeMinutes = reminderTimeMinutes
            task.reminderStyle = savedReminderStyle
            task.scheduleKind = scheduleKind
            task.nextDueDate = nextDueDate
            task.fixedRule = scheduleKind == .fixed ? fixedRule : nil
            task.intervalRule = scheduleKind == .interval ? intervalRule : nil
            task.updatedAt = Date()
        } else {
            let activeTaskCount = allTasks.filter { !$0.isArchived }.count
            let limit = featureGate.taskLimit(
                currentActiveTaskCount: activeTaskCount,
                settings: settings
            )
            guard limit.isAllowed else {
                validationMessage = L10n.text("pro.limit.tasksMessage", "Proにすると、掃除の数を気にせず使えます。")
                return
            }

            let newTask = CleaningTask(
                name: trimmedName,
                place: selectedPlace,
                nextDueDate: nextDueDate,
                scheduleKind: scheduleKind,
                fixedRule: scheduleKind == .fixed ? fixedRule : nil,
                intervalRule: scheduleKind == .interval ? intervalRule : nil,
                estimatedMinutes: estimatedMinutes,
                priority: priority
            )
            newTask.note = note
            newTask.tools = tools
            newTask.reminderEnabled = reminderEnabled
            newTask.reminderTimeMinutes = reminderTimeMinutes
            newTask.reminderStyle = savedReminderStyle
            modelContext.insert(newTask)
            selectedPlace.tasks.append(newTask)
            tasksForNotificationRebuild.append(newTask)
        }

        try? modelContext.save()
        rebuildNotifications(tasks: tasksForNotificationRebuild)
        dismiss()
    }

    private func rebuildNotifications(tasks: [CleaningTask]) {
        WidgetUpdateService.refresh(tasks: tasks, pausePeriods: pausePeriods)

        Task {
            do {
                try await NotificationScheduler().rebuildNotifications(
                    tasks: tasks,
                    pausePeriods: pausePeriods,
                    settings: settingsStore.load()
                )
            } catch {
                // 通知権限がなくても、タスク編集は使えるようにする。
            }
        }
    }

    private func makeFixedRule() -> FixedRule {
        switch fixedRuleType {
        case .weekly:
            FixedRule(type: .weekly, weekdays: [selectedWeekday])
        case .biweekly:
            FixedRule(type: .biweekly, weekdays: [selectedWeekday], anchorDate: anchorDate)
        case .monthlyDay:
            FixedRule(type: .monthlyDay, dayOfMonth: dayOfMonth)
        case .monthlyLastDay:
            FixedRule(type: .monthlyLastDay)
        case .yearlyDate:
            FixedRule(type: .yearlyDate, month: month, day: day)
        }
    }

    private var reminderDateBinding: Binding<Date> {
        Binding {
            Calendar.current.date(
                from: DateComponents(hour: reminderTimeMinutes / 60, minute: reminderTimeMinutes % 60)
            ) ?? Date()
        } set: { date in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            reminderTimeMinutes = (components.hour ?? 9) * 60 + (components.minute ?? 0)
        }
    }

    private func weekdayName(_ weekday: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        guard symbols.indices.contains(weekday - 1) else { return "\(weekday)" }
        return symbols[weekday - 1]
    }
}
