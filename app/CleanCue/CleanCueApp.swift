import SwiftUI
import SwiftData
import UserNotifications

@main
struct CleanCueApp: App {
    init() {
        // 通知アクションはアプリ起動時に登録し、Widgetや画面遷移に依存しないようにする。
        NotificationScheduler().registerCategories()
        UNUserNotificationCenter.current().delegate = NotificationActionHandler.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // SwiftDataのモデル定義を1か所に集約し、画面側はModelContextだけを扱う。
        .modelContainer(for: CleanCueSchema.models)
    }
}
