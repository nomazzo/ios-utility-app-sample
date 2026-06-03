import Foundation
import SwiftData
import UserNotifications

final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationActionHandler()

    private override init() {}

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await handle(response: response)
    }

    @MainActor
    private func handle(response: UNNotificationResponse) async {
        guard let payload = NotificationActionPayload(
            actionIdentifier: response.actionIdentifier,
            userInfo: response.notification.request.content.userInfo
        ) else {
            return
        }

        do {
            let schema = Schema(CleanCueSchema.models)
            let container = try ModelContainer(for: schema)
            let context = container.mainContext
            let taskID = payload.taskID
            let descriptor = FetchDescriptor<CleaningTask>(
                predicate: #Predicate { task in
                    task.id == taskID
                }
            )
            guard let task = try context.fetch(descriptor).first else { return }

            let actionService = TaskActionService()
            switch payload.action {
            case .complete:
                try actionService.complete(task: task, in: context)
            case .snoozeTomorrow:
                try actionService.snoozeTomorrow(task: task, in: context)
            case .skipThisWeek:
                try actionService.skipThisWeek(task: task, in: context)
            }

            try await rebuildNotifications(context: context)
        } catch {
            assertionFailure("Notification action failed: \(error)")
        }
    }

    @MainActor
    private func rebuildNotifications(context: ModelContext) async throws {
        let tasks = try context.fetch(FetchDescriptor<CleaningTask>())
        let pauses = try context.fetch(FetchDescriptor<PausePeriod>())
        WidgetUpdateService.refresh(tasks: tasks, pausePeriods: pauses)
        let settings = AppSettingsStore().load()
        try await NotificationScheduler().rebuildNotifications(
            tasks: tasks,
            pausePeriods: pauses,
            settings: settings
        )
    }
}
