import Foundation

@MainActor
struct WidgetSnapshotService {
    var provider: TodayTaskProvider
    var urgencyCalculator: UrgencyCalculator
    var calendar: Calendar
    var appGroupIdentifier: String?
    var snapshotKey: String
    var userDefaults: UserDefaults?

    init(
        provider: TodayTaskProvider? = nil,
        urgencyCalculator: UrgencyCalculator = UrgencyCalculator(),
        calendar: Calendar = .current,
        appGroupIdentifier: String? = WidgetSnapshotDefaults.appGroupIdentifier,
        snapshotKey: String = WidgetSnapshotDefaults.snapshotKey,
        userDefaults: UserDefaults? = nil
    ) {
        self.provider = provider ?? TodayTaskProvider(calendar: calendar)
        self.urgencyCalculator = urgencyCalculator
        self.calendar = calendar
        self.appGroupIdentifier = appGroupIdentifier
        self.snapshotKey = snapshotKey
        self.userDefaults = userDefaults
    }

    func makeSnapshot(
        tasks: [CleaningTask],
        pausePeriods: [PausePeriod],
        referenceDate: Date = Date()
    ) -> WidgetSnapshot {
        // Widget側ではBundleにアクセスしづらい場面があるため、表示用ロケールもスナップショットへ含める。
        let localeIdentifier = Bundle.main.preferredLocalizations.first
            ?? Locale.current.identifier

        // 一時停止中はWidgetも空状態にし、本体アプリの状態と揃える。
        if isPaused(on: referenceDate, pausePeriods: pausePeriods) {
            return WidgetSnapshot(
                generatedAt: referenceDate,
                localeIdentifier: localeIdentifier,
                todayTasks: []
            )
        }

        let sections = provider.sections(for: tasks, referenceDate: referenceDate)
        // Widgetに載せる情報量を絞り、Small/Mediumサイズでも読みやすくする。
        let orderedTasks = Array((sections.recommended + sections.overdue + sections.upcomingLight).prefix(5))
        let snapshots = orderedTasks.map { task in
            makeTaskSnapshot(task, referenceDate: referenceDate)
        }

        return WidgetSnapshot(
            generatedAt: referenceDate,
            localeIdentifier: localeIdentifier,
            todayTasks: snapshots
        )
    }

    func saveSnapshot(
        tasks: [CleaningTask],
        pausePeriods: [PausePeriod],
        referenceDate: Date = Date()
    ) throws {
        // App GroupのUserDefaultsに保存し、Widget Extensionから同じデータを読む。
        let snapshot = makeSnapshot(
            tasks: tasks,
            pausePeriods: pausePeriods,
            referenceDate: referenceDate
        )
        let data = try JSONEncoder().encode(snapshot)
        defaults().set(data, forKey: snapshotKey)
    }

    func loadSnapshot() -> WidgetSnapshot {
        // 初回起動直後などデータがない場合は、Widget専用の空スナップショットを返す。
        guard let data = defaults().data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }

    private func makeTaskSnapshot(
        _ task: CleaningTask,
        referenceDate: Date
    ) -> WidgetTaskSnapshot {
        let urgency = urgencyCalculator.urgency(for: task.nextDueDate, relativeTo: referenceDate)
        return WidgetTaskSnapshot(
            id: task.id,
            taskName: task.name,
            placeName: task.place?.name ?? L10n.text("common.noPlace", "場所なし"),
            dueLabel: dueLabel(for: urgency),
            estimatedMinutes: task.estimatedMinutes,
            urgency: urgencyScore(for: urgency.state)
        )
    }

    private func dueLabel(for urgency: UrgencyResult) -> String {
        switch urgency.daysUntilDue {
        case ..<0:
            L10n.text("urgency.overdue", "後回し中")
        case 0:
            L10n.text("urgency.today", "今日")
        case 1:
            L10n.text("calendar.mode.tomorrow", "明日")
        case 2...7:
            L10n.format("widget.due.inDays", "%d日後", urgency.daysUntilDue)
        default:
            L10n.text("calendar.status.scheduled", "予定")
        }
    }

    private func urgencyScore(for state: UrgencyState) -> Double {
        switch state {
        case .overdue:
            1.0
        case .today:
            0.8
        case .soon:
            0.5
        case .safe:
            0.2
        }
    }

    private func isPaused(on date: Date, pausePeriods: [PausePeriod]) -> Bool {
        let day = calendar.startOfDay(for: date)
        return pausePeriods
            .filter(\.isActive)
            .contains {
                calendar.startOfDay(for: $0.startDate) <= day &&
                    day <= calendar.startOfDay(for: $0.endDate)
            }
    }

    private func defaults() -> UserDefaults {
        if let userDefaults {
            return userDefaults
        }

        if let appGroupIdentifier,
           let appGroupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            return appGroupDefaults
        }

        return .standard
    }
}
