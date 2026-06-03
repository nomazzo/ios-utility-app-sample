import Foundation
import SwiftData
import UserNotifications

nonisolated enum CleanCueNotificationCategory {
    static let taskReminder = "TASK_REMINDER"
}

nonisolated enum CleanCueNotificationAction {
    static let complete = "ACTION_COMPLETE"
    static let snoozeTomorrow = "ACTION_SNOOZE_TOMORROW"
    static let skipThisWeek = "ACTION_SKIP_THIS_WEEK"
}

nonisolated enum CleanCueNotificationUserInfoKey {
    static let taskID = "taskId"
}

nonisolated enum NotificationActionKind: Equatable, Sendable {
    case complete
    case snoozeTomorrow
    case skipThisWeek

    init?(identifier: String) {
        switch identifier {
        case CleanCueNotificationAction.complete:
            self = .complete
        case CleanCueNotificationAction.snoozeTomorrow:
            self = .snoozeTomorrow
        case CleanCueNotificationAction.skipThisWeek:
            self = .skipThisWeek
        default:
            return nil
        }
    }
}

nonisolated struct NotificationActionPayload: Equatable, Sendable {
    var action: NotificationActionKind
    var taskID: UUID

    init?(actionIdentifier: String, userInfo: [AnyHashable: Any]) {
        guard let action = NotificationActionKind(identifier: actionIdentifier),
              let taskIDString = userInfo[CleanCueNotificationUserInfoKey.taskID] as? String,
              let taskID = UUID(uuidString: taskIDString) else {
            return nil
        }

        self.action = action
        self.taskID = taskID
    }
}

nonisolated struct NotificationScheduleRequest: Equatable, Sendable {
    var identifier: String
    var taskID: UUID
    var title: String
    var body: String
    var fireDate: Date
    var offsetDays: Int
    var userInfo: [String: String]
}

nonisolated struct PendingNotificationSummary: Equatable, Sendable {
    var identifier: String
    var title: String
    var body: String
    var nextFireDate: Date?
}

enum NotificationPermissionState: Equatable {
    case notDetermined
    case denied
    case authorized

    init(status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .authorized, .provisional, .ephemeral:
            self = .authorized
        @unknown default:
            self = .denied
        }
    }
}

struct NotificationScheduler {
    private let center: UNUserNotificationCenter
    private let calendar: Calendar
    private let urgencyCalculator: UrgencyCalculator
    private let featureGate: FeatureGate
    private let identifierPrefix = "cleancue.task."
    private let testIdentifier = "cleancue.test.notification"

    init(
        center: UNUserNotificationCenter = .current(),
        calendar: Calendar = .current,
        urgencyCalculator: UrgencyCalculator = UrgencyCalculator(),
        featureGate: FeatureGate = FeatureGate()
    ) {
        self.center = center
        self.calendar = calendar
        self.urgencyCalculator = urgencyCalculator
        self.featureGate = featureGate
    }

    func registerCategories() {
        // 通知から直接「完了・明日・スキップ」を実行できるようにする。
        let complete = UNNotificationAction(
            identifier: CleanCueNotificationAction.complete,
            title: L10n.text("action.complete", "完了"),
            options: []
        )
        let snooze = UNNotificationAction(
            identifier: CleanCueNotificationAction.snoozeTomorrow,
            title: L10n.text("action.tomorrow", "明日"),
            options: []
        )
        let skip = UNNotificationAction(
            identifier: CleanCueNotificationAction.skipThisWeek,
            title: L10n.text("action.skipThisWeek", "今週スキップ"),
            options: []
        )
        let category = UNNotificationCategory(
            identifier: CleanCueNotificationCategory.taskReminder,
            actions: [complete, snooze, skip],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    func permissionState() async -> NotificationPermissionState {
        let settings = await center.notificationSettings()
        return NotificationPermissionState(status: settings.authorizationStatus)
    }

    @discardableResult
    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleTestNotificationAfterFiveSeconds() async throws {
        let state = await permissionState()
        guard state == .authorized else { return }

        // 設定画面から通知権限と表示を確認するための短いテスト通知。
        let content = UNMutableNotificationContent()
        content.title = "HomeRoutine Demo"
        content.body = L10n.text("notification.test.body", "通知テストです。")
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: testIdentifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )
        try await center.add(request)
    }

    func cancelAllTaskNotifications() async {
        let pending = await center.pendingNotificationRequests()
        // 他アプリやOS標準の通知を消さないよう、CleanCueの識別子だけを対象にする。
        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) || $0 == testIdentifier }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func pendingTaskNotificationSummaries() async -> [PendingNotificationSummary] {
        let pending = await center.pendingNotificationRequests()
        return pending
            .filter { $0.identifier.hasPrefix(identifierPrefix) }
            .map { request in
                PendingNotificationSummary(
                    identifier: request.identifier,
                    title: request.content.title,
                    body: request.content.body,
                    nextFireDate: (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
                )
            }
            .sorted {
                switch ($0.nextFireDate, $1.nextFireDate) {
                case let (lhs?, rhs?):
                    lhs < rhs
                case (_?, nil):
                    true
                case (nil, _?):
                    false
                case (nil, nil):
                    $0.identifier < $1.identifier
                }
            }
    }

    func rebuildNotifications(
        tasks: [CleaningTask],
        pausePeriods: [PausePeriod],
        settings: AppSettings,
        referenceDate: Date = Date()
    ) async throws {
        // タスク変更後は古い通知を捨て、現在の予定から作り直す。
        registerCategories()
        await cancelAllTaskNotifications()

        guard settings.defaultReminderEnabled,
              await permissionState() == .authorized else {
            return
        }

        let requests = scheduleRequests(
            for: tasks,
            pausePeriods: pausePeriods,
            settings: settings,
            referenceDate: referenceDate
        )

        for request in requests {
            try await center.add(makeNotificationRequest(from: request))
        }
    }

    func scheduleRequests(
        for tasks: [CleaningTask],
        pausePeriods: [PausePeriod],
        settings: AppSettings,
        referenceDate: Date = Date(),
        horizonDays: Int = 30
    ) -> [NotificationScheduleRequest] {
        guard settings.defaultReminderEnabled,
              !isPaused(on: referenceDate, pausePeriods: pausePeriods),
              let horizonDate = calendar.date(byAdding: .day, value: horizonDays, to: referenceDate) else {
            return []
        }

        return tasks
            .filter { !$0.isArchived }
            .filter(\.reminderEnabled)
            .flatMap { task in
                notificationDates(
                    for: task,
                    offsets: featureGate.notificationOffsets(for: task.reminderStyle, settings: settings),
                    settings: settings,
                    referenceDate: referenceDate,
                    horizonDate: horizonDate,
                    pausePeriods: pausePeriods
                )
            }
            .sorted { $0.fireDate < $1.fireDate }
    }

    func notificationIdentifier(taskID: UUID, offsetDays: Int) -> String {
        "\(identifierPrefix)\(taskID.uuidString).\(offsetDays)"
    }

    func notificationTitle(for task: CleaningTask) -> String {
        "\(task.place?.name ?? L10n.text("common.noPlace", "場所なし")): \(task.name)"
    }

    func notificationBody(for task: CleaningTask, referenceDate: Date = Date()) -> String {
        let urgency = urgencyCalculator.urgency(for: task.nextDueDate, relativeTo: referenceDate)
        return L10n.format(
            "notification.body.urgencyMinutes",
            "%@・%d分",
            urgency.state.notificationDisplayName,
            task.estimatedMinutes
        )
    }

    private func notificationDates(
        for task: CleaningTask,
        offsets: [Int],
        settings: AppSettings,
        referenceDate: Date,
        horizonDate: Date,
        pausePeriods: [PausePeriod]
    ) -> [NotificationScheduleRequest] {
        if let snoozedUntil = task.snoozedUntil, snoozedUntil > referenceDate {
            return makeScheduleRequestIfNeeded(
                task: task,
                fireDate: snoozedUntil,
                offsetDays: 0,
                referenceDate: referenceDate,
                horizonDate: horizonDate,
                pausePeriods: pausePeriods
            ).map { [$0] } ?? []
        }

        return offsets.compactMap { offset in
            guard let dueOffsetDate = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: task.nextDueDate)) else {
                return nil
            }
            let fireDate = date(on: dueOffsetDate, minutes: task.reminderEnabled ? task.reminderTimeMinutes : settings.defaultReminderTimeMinutes)
            return makeScheduleRequestIfNeeded(
                task: task,
                fireDate: fireDate,
                offsetDays: offset,
                referenceDate: referenceDate,
                horizonDate: horizonDate,
                pausePeriods: pausePeriods
            )
        }
    }

    private func makeScheduleRequestIfNeeded(
        task: CleaningTask,
        fireDate: Date,
        offsetDays: Int,
        referenceDate: Date,
        horizonDate: Date,
        pausePeriods: [PausePeriod]
    ) -> NotificationScheduleRequest? {
        guard fireDate >= referenceDate,
              fireDate <= horizonDate,
              !isPaused(on: fireDate, pausePeriods: pausePeriods) else {
            return nil
        }

        return NotificationScheduleRequest(
            identifier: notificationIdentifier(taskID: task.id, offsetDays: offsetDays),
            taskID: task.id,
            title: notificationTitle(for: task),
            body: notificationBody(for: task, referenceDate: referenceDate),
            fireDate: fireDate,
            offsetDays: offsetDays,
            userInfo: [CleanCueNotificationUserInfoKey.taskID: task.id.uuidString]
        )
    }

    private func makeNotificationRequest(from request: NotificationScheduleRequest) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default
        content.categoryIdentifier = CleanCueNotificationCategory.taskReminder
        content.userInfo = request.userInfo

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: request.fireDate)
        return UNNotificationRequest(
            identifier: request.identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
    }

    private func date(on day: Date, minutes: Int) -> Date {
        let startOfDay = calendar.startOfDay(for: day)
        return calendar.date(byAdding: .minute, value: minutes, to: startOfDay) ?? startOfDay
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
}

extension UrgencyState {
    var notificationDisplayName: String {
        switch self {
        case .safe:
            L10n.text("notification.urgency.safe", "まだ大丈夫")
        case .soon:
            L10n.text("notification.urgency.soon", "そろそろです")
        case .today:
            L10n.text("notification.urgency.today", "今日です")
        case .overdue:
            L10n.text("notification.urgency.overdue", "後回し中です")
        }
    }
}
