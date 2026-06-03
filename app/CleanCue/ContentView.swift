import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    // 通知とWidgetの再構築に使うため、トップ階層でタスクと一時停止期間を監視する。
    @Query(sort: [SortDescriptor(\CleaningTask.nextDueDate), SortDescriptor(\CleaningTask.createdAt)])
    private var tasks: [CleaningTask]
    @Query(sort: [SortDescriptor(\PausePeriod.startDate, order: .reverse)])
    private var pausePeriods: [PausePeriod]

    private let settingsStore: AppSettingsStore
    @State private var settings: AppSettings
    @State private var selectedTab: AppTab
    @State private var placesResetToken = 0

    init(settingsStore: AppSettingsStore = AppSettingsStore()) {
        self.settingsStore = settingsStore
        Self.configureTabBarAppearance()
        _settings = State(initialValue: settingsStore.load())
        _selectedTab = State(initialValue: .today)
    }

    var body: some View {
        if shouldShowMainApp {
            // 主要機能はタブで分け、公開デモでも実際の利用導線が伝わる構成にしている。
            TabView(selection: tabSelection) {
                TodayView()
                    .tabItem {
                        Label(L10n.text("tab.today", "今日"), systemImage: "checklist")
                    }
                    .tag(AppTab.today)

                PlacesView(resetToken: placesResetToken)
                    .tabItem {
                        Label(L10n.text("tab.places", "場所"), systemImage: "house")
                    }
                    .tag(AppTab.places)

                CalendarView()
                    .tabItem {
                        Label(L10n.text("tab.calendar", "カレンダー"), systemImage: "calendar")
                    }
                    .tag(AppTab.calendar)

                LogsView()
                    .tabItem {
                        Label(L10n.text("tab.logs", "ログ"), systemImage: "clock.arrow.circlepath")
                    }
                    .tag(AppTab.logs)

                SettingsView(settingsStore: settingsStore)
                    .tabItem {
                        Label(L10n.text("tab.settings", "設定"), systemImage: "gearshape")
                    }
                    .tag(AppTab.settings)
            }
            .preferredColorScheme(settings.appearance.colorScheme)
            .task {
                await rebuildNotificationsIfPossible()
            }
            .onReceive(NotificationCenter.default.publisher(for: .cleanCueSettingsDidChange)) { _ in
                settings = settingsStore.load()
            }
        } else {
            OnboardingView(settingsStore: settingsStore) {
                settings = settingsStore.load()
            }
        }
    }

    private var shouldShowMainApp: Bool {
        settings.hasCompletedOnboarding
    }

    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                // 場所タブを再タップしたとき、一覧の選択状態を初期化できるようにする。
                if newTab == .places {
                    placesResetToken += 1
                }
                selectedTab = newTab
            }
        )
    }

    private func rebuildNotificationsIfPossible() async {
        // 起動時に購入状態、Widget、通知を軽く同期して、表示とバックグラウンド情報を揃える。
        _ = await PurchaseManager(
            entitlementStore: EntitlementStore(settingsStore: settingsStore)
        ).refreshEntitlements()
        settings = settingsStore.load()

        WidgetUpdateService.refresh(tasks: tasks, pausePeriods: pausePeriods)

        do {
            try await NotificationScheduler().rebuildNotifications(
                tasks: tasks,
                pausePeriods: pausePeriods,
                settings: settingsStore.load()
            )
        } catch {
            // 通知の再構築に失敗しても、アプリ起動は止めない。
        }
    }

    private static func configureTabBarAppearance() {
        // UIKit側のタブバー外観をここでまとめ、SwiftUI画面ごとの差分を減らす。
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        appearance.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 0.92)
                : UIColor.white.withAlphaComponent(0.92)
        }
        appearance.shadowColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.025)
        }
        appearance.selectionIndicatorImage = UIImage.cleanCueTabSelectionIndicator()

        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = UIColor.secondaryLabel
        normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel
        ]

        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = UIColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1.0)
        selected.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1.0)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1.0)
        UITabBar.appearance().unselectedItemTintColor = UIColor.label.withAlphaComponent(0.86)
    }
}

private extension UIImage {
    static func cleanCueTabSelectionIndicator() -> UIImage {
        let size = CGSize(width: 66, height: 38)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 0.16).setFill()
            UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: size),
                cornerRadius: 19
            ).fill()
        }
        return image.resizableImage(
            withCapInsets: UIEdgeInsets(top: 18, left: 32, bottom: 18, right: 32),
            resizingMode: .stretch
        )
    }
}

private enum AppTab: Hashable {
    case today
    case places
    case calendar
    case logs
    case settings
}

private extension AppAppearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.makeContainer())
}
