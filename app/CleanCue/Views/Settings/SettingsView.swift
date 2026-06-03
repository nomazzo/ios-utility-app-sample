import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    private let settingsStore: AppSettingsStore
    @State private var settings: AppSettings

    init(settingsStore: AppSettingsStore = AppSettingsStore()) {
        self.settingsStore = settingsStore
        _settings = State(initialValue: settingsStore.load())
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        NotificationSettingsView(settingsStore: settingsStore)
                    } label: {
                        SettingsNavigationRow(
                            title: L10n.text("settings.notifications", "通知設定"),
                            systemImage: "bell",
                            tint: CleanCueTheme.primaryBlue
                        )
                    }

                    NavigationLink {
                        DisplaySettingsView(settingsStore: settingsStore)
                    } label: {
                        SettingsNavigationRow(
                            title: L10n.text("settings.display", "表示設定"),
                            systemImage: "paintbrush",
                            tint: CleanCueTheme.cleanMint
                        )
                    }

                    NavigationLink {
                        ProView(settingsStore: settingsStore)
                    } label: {
                        SettingsNavigationRow(
                            title: "Pro",
                            systemImage: "sparkles",
                            tint: CleanCueTheme.color(hex: "#8B6BB1")
                        )
                    }
                }

                Section(L10n.text("settings.section.appInfo", "アプリ情報")) {
                    LabeledContent(L10n.text("settings.version", "バージョン"), value: appVersion)
                    Link(L10n.text("settings.terms", "利用規約"), destination: URL(string: "https://example.com/home-routine-demo/terms")!)
                    Link(L10n.text("settings.privacyPolicy", "プライバシーポリシー"), destination: URL(string: "https://example.com/home-routine-demo/privacy")!)
                }
            }
            .cleanCueScrollableBottomInset()
            .navigationTitle(L10n.text("settings.title", "設定"))
            .onReceive(NotificationCenter.default.publisher(for: .cleanCueSettingsDidChange)) { _ in
                settings = settingsStore.load()
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

private struct SettingsNavigationRow: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: Circle())
        }
    }
}

struct NotificationSettingsView: View {
    @Query(sort: [SortDescriptor(\CleaningTask.nextDueDate), SortDescriptor(\CleaningTask.createdAt)])
    private var tasks: [CleaningTask]
    @Query(sort: [SortDescriptor(\PausePeriod.startDate, order: .reverse)])
    private var pausePeriods: [PausePeriod]

    private let settingsStore: AppSettingsStore
    private let scheduler = NotificationScheduler()

    @State private var settings: AppSettings
    @State private var permissionState: NotificationPermissionState = .notDetermined
    @State private var pendingNotifications: [PendingNotificationSummary] = []
    @State private var message: String?
    @State private var showingNotificationPrimer = false
    @State private var permissionIntent: NotificationPermissionIntent = .enableNotifications

    init(settingsStore: AppSettingsStore = AppSettingsStore()) {
        self.settingsStore = settingsStore
        _settings = State(initialValue: settingsStore.load())
    }

    var body: some View {
        List {
            Section {
                Toggle(L10n.text("settings.notifications.toggle", "通知"), isOn: notificationEnabledBinding)

                DatePicker(
                    L10n.text("settings.notifications.defaultTime", "デフォルト通知時刻"),
                    selection: reminderDateBinding,
                    displayedComponents: .hourAndMinute
                )
                .disabled(!settings.defaultReminderEnabled)

                NavigationLink {
                    PauseModeView()
                } label: {
                    Label(L10n.text("pause.mode", "休みモード"), systemImage: "pause.circle")
                }
            }

            Section(L10n.text("settings.notifications.status", "通知の状態")) {
                LabeledContent(
                    L10n.text("settings.notifications.permission", "権限"),
                    value: permissionState.displayName
                )
                LabeledContent(
                    L10n.text("settings.notifications.nextScheduled", "次の通知予定"),
                    value: nextNotificationText
                )
                LabeledContent(
                    L10n.text("settings.notifications.pendingCount", "予定済み通知数"),
                    value: pendingNotificationCountText
                )

                if permissionState == .denied {
                    Text(L10n.text("settings.notifications.deniedHelp", "HomeRoutine Demoの通知はiPhoneの設定でオフになっています。通知を使うには設定アプリで許可してください。"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        openSystemSettings()
                    } label: {
                        Label(L10n.text("settings.notifications.openSettings", "設定アプリを開く"), systemImage: "gear")
                    }
                }
            }

            Section(L10n.text("settings.notifications.test", "通知テスト")) {
                Button {
                    Task {
                        await sendTestNotification()
                    }
                } label: {
                    Label(L10n.text("settings.notifications.testButton", "5秒後に通知テスト"), systemImage: "bell.badge")
                }

                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section(L10n.text("help.notifications.title", "通知が届かない場合")) {
                Text(L10n.text("help.notifications.body", "iOSの通知設定、集中モード、休みモード、掃除ごとの通知設定を確認してください。"))
                    .foregroundStyle(.secondary)
            }
        }
        .cleanCueScrollableBottomInset()
        .navigationTitle(L10n.text("settings.notifications", "通知設定"))
        .task {
            await refreshNotificationDiagnostics()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cleanCueSettingsDidChange)) { _ in
            settings = settingsStore.load()
            Task {
                await refreshNotificationDiagnostics()
            }
        }
        .sheet(isPresented: $showingNotificationPrimer) {
            NotificationPermissionPrimerView {
                showingNotificationPrimer = false
                let intent = permissionIntent
                Task {
                    await requestPermissionAndContinue(intent)
                }
            } secondaryAction: {
                showingNotificationPrimer = false
                if permissionIntent == .enableNotifications {
                    message = L10n.text("settings.notifications.notNowMessage", "通知はあとでオンにできます。")
                }
            }
        }
    }

    private var notificationEnabledBinding: Binding<Bool> {
        Binding {
            settings.defaultReminderEnabled
        } set: { newValue in
            Task {
                await handleNotificationToggle(newValue)
            }
        }
    }

    private var reminderDateBinding: Binding<Date> {
        Binding {
            date(fromMinutes: settings.defaultReminderTimeMinutes)
        } set: { date in
            settings.defaultReminderTimeMinutes = minutes(from: date)
            settingsStore.save(settings)
            Task {
                await rebuildNotifications()
            }
        }
    }

    private func handleNotificationToggle(_ enabled: Bool) async {
        guard enabled else {
            settings.defaultReminderEnabled = false
            settingsStore.save(settings)
            await scheduler.cancelAllTaskNotifications()
            await refreshNotificationDiagnostics()
            message = L10n.text("settings.notifications.offMessage", "通知をオフにしました。")
            return
        }

        await refreshPermissionState()

        switch permissionState {
        case .authorized:
            settings.defaultReminderEnabled = true
            settingsStore.save(settings)
            await rebuildNotifications()
        case .notDetermined:
            permissionIntent = .enableNotifications
            showingNotificationPrimer = true
        case .denied:
            message = L10n.text("settings.notifications.denied", "通知がオフになっています。設定アプリでオンにできます。")
        }
    }

    private func sendTestNotification() async {
        await refreshPermissionState()

        if permissionState == .notDetermined {
            permissionIntent = .sendTestNotification
            showingNotificationPrimer = true
            return
        }

        switch permissionState {
        case .authorized:
            do {
                try await scheduler.scheduleTestNotificationAfterFiveSeconds()
                message = L10n.text("settings.notifications.testScheduled", "5秒後にテスト通知を送ります。")
            } catch {
                message = L10n.text("settings.notifications.testFailed", "テスト通知を設定できませんでした。")
            }
        case .denied:
            message = L10n.text("settings.notifications.denied", "通知がオフになっています。設定アプリでオンにできます。")
        case .notDetermined:
            message = L10n.text("settings.notifications.checkPermission", "通知許可を確認してください。")
        }
    }

    private func requestPermissionAndContinue(_ intent: NotificationPermissionIntent) async {
        do {
            _ = try await scheduler.requestAuthorization()
        } catch {
            message = L10n.text("settings.notifications.permissionFailed", "通知許可を確認できませんでした。")
        }

        await refreshPermissionState()

        guard permissionState == .authorized else {
            message = L10n.text("settings.notifications.denied", "通知がオフになっています。設定アプリでオンにできます。")
            return
        }

        switch intent {
        case .enableNotifications:
            settings.defaultReminderEnabled = true
            settingsStore.save(settings)
            await rebuildNotifications()
        case .sendTestNotification:
            await sendTestNotification()
        }
    }

    private func refreshPermissionState() async {
        permissionState = await scheduler.permissionState()
    }

    private func refreshNotificationDiagnostics() async {
        await refreshPermissionState()
        pendingNotifications = await scheduler.pendingTaskNotificationSummaries()
    }

    private func rebuildNotifications() async {
        do {
            try await scheduler.rebuildNotifications(
                tasks: tasks,
                pausePeriods: pausePeriods,
                settings: settings
            )
            WidgetUpdateService.refresh(tasks: tasks, pausePeriods: pausePeriods)
            pendingNotifications = await scheduler.pendingTaskNotificationSummaries()
            if settings.defaultReminderEnabled, permissionState == .authorized {
                message = L10n.text("settings.notifications.updated", "通知設定を更新しました。")
            }
        } catch {
            message = L10n.text("settings.notifications.updateFailed", "通知を更新できませんでした。")
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func date(fromMinutes minutes: Int) -> Date {
        Calendar.current.date(from: DateComponents(hour: minutes / 60, minute: minutes % 60)) ?? Date()
    }

    private func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 9) * 60 + (components.minute ?? 0)
    }

    private var nextNotificationText: String {
        guard let nextFireDate = pendingNotifications.first?.nextFireDate else {
            return L10n.text("settings.notifications.noneScheduled", "予定なし")
        }

        return nextFireDate.formatted(
            .dateTime.month(.abbreviated).day().hour().minute().locale(Locale.current)
        )
    }

    private var pendingNotificationCountText: String {
        if L10n.isDanish {
            return pendingNotifications.count == 1 ? "1 planlagt" : "\(pendingNotifications.count) planlagte"
        }
        if L10n.isNorwegianBokmal {
            return pendingNotifications.count == 1 ? "1 planlagt" : "\(pendingNotifications.count) planlagte"
        }
        if L10n.isSpanish {
            guard pendingNotifications.count > 0 else { return "Ninguna" }
            return pendingNotifications.count == 1 ? "1 programada" : "\(pendingNotifications.count) programadas"
        }
        if L10n.isPortuguese {
            guard pendingNotifications.count > 0 else { return "Nenhuma" }
            return pendingNotifications.count == 1 ? "1 agendada" : "\(pendingNotifications.count) agendadas"
        }
        if L10n.isItalian {
            guard pendingNotifications.count > 0 else { return "Nessuna" }
            return pendingNotifications.count == 1 ? "1 programmata" : "\(pendingNotifications.count) programmate"
        }
        if L10n.isKorean {
            guard pendingNotifications.count > 0 else { return "없음" }
            return "\(pendingNotifications.count)개 예약됨"
        }
        if L10n.isTraditionalChinese {
            guard pendingNotifications.count > 0 else { return "無" }
            return "已排程 \(pendingNotifications.count) 個"
        }
        if L10n.isFinnish {
            guard pendingNotifications.count > 0 else { return "Ei yhtään" }
            return pendingNotifications.count == 1 ? "1 ajastettu" : "\(pendingNotifications.count) ajastettua"
        }
        return L10n.format("settings.notifications.pendingCount.value", "%d件", pendingNotifications.count)
    }
}

private enum NotificationPermissionIntent: Equatable {
    case enableNotifications
    case sendTestNotification
}

struct DisplaySettingsView: View {
    private let settingsStore: AppSettingsStore
    @State private var settings: AppSettings

    init(settingsStore: AppSettingsStore = AppSettingsStore()) {
        self.settingsStore = settingsStore
        _settings = State(initialValue: settingsStore.load())
    }

    var body: some View {
        Form {
            Section(L10n.text("settings.display.appearance", "表示モード")) {
                Picker(L10n.text("settings.display.appearance", "表示モード"), selection: appearanceBinding) {
                    ForEach(AppAppearance.allCases, id: \.self) { appearance in
                        Text(appearance.displayName).tag(appearance)
                    }
                }
            }

            Section(L10n.text("today.title", "今日")) {
                Picker(L10n.text("settings.display.todayCount", "表示件数"), selection: todayDisplayLimitBinding) {
                    ForEach(TodayDisplayLimit.allCases, id: \.self) { limit in
                        Text(limit.displayName).tag(limit)
                    }
                }

                Picker(L10n.text("settings.display.urgencyStyle", "そろそろ表現"), selection: urgencyExpressionStyleBinding) {
                    ForEach(UrgencyExpressionStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
            }

            Section(L10n.text("calendar.title", "カレンダー")) {
                Picker(L10n.text("settings.display.weekStart", "週の開始曜日"), selection: weekStartPreferenceBinding) {
                    ForEach(WeekStartPreference.allCases, id: \.self) { preference in
                        Text(preference.displayName).tag(preference)
                    }
                }
            }
        }
        .cleanCueScrollableBottomInset()
        .navigationTitle(L10n.text("settings.display", "表示設定"))
    }

    private var appearanceBinding: Binding<AppAppearance> {
        Binding {
            settings.appearance
        } set: {
            settings.appearance = $0
            save()
        }
    }

    private var todayDisplayLimitBinding: Binding<TodayDisplayLimit> {
        Binding {
            settings.todayDisplayLimit
        } set: {
            settings.todayDisplayLimit = $0
            save()
        }
    }

    private var urgencyExpressionStyleBinding: Binding<UrgencyExpressionStyle> {
        Binding {
            settings.urgencyExpressionStyle
        } set: {
            settings.urgencyExpressionStyle = $0
            save()
        }
    }

    private var weekStartPreferenceBinding: Binding<WeekStartPreference> {
        Binding {
            settings.weekStartPreference
        } set: { newValue in
            settings.weekStartPreference = newValue
            settings.firstWeekday = newValue.firstWeekday
            save()
        }
    }

    private func save() {
        settingsStore.save(settings)
    }
}

private extension NotificationPermissionState {
    var displayName: String {
        switch self {
        case .notDetermined:
            L10n.text("notification.permission.notDetermined", "未確認")
        case .denied:
            L10n.text("notification.permission.denied", "オフ")
        case .authorized:
            L10n.text("notification.permission.authorized", "オン")
        }
    }
}

private extension AppAppearance {
    var displayName: String {
        switch self {
        case .system:
            L10n.text("appearance.system", "システム")
        case .light:
            L10n.text("appearance.light", "ライト")
        case .dark:
            L10n.text("appearance.dark", "ダーク")
        }
    }
}

private extension TodayDisplayLimit {
    var displayName: String {
        switch self {
        case .one:
            L10n.text("todayDisplayLimit.one", "1件")
        case .three:
            L10n.text("todayDisplayLimit.three", "3件")
        case .all:
            L10n.text("todayDisplayLimit.all", "すべて")
        }
    }
}

private extension UrgencyExpressionStyle {
    var displayName: String {
        switch self {
        case .gentle:
            L10n.text("urgencyExpression.gentle", "やさしい")
        case .standard:
            L10n.text("urgencyExpression.standard", "標準")
        }
    }
}

private extension WeekStartPreference {
    var displayName: String {
        switch self {
        case .automatic:
            L10n.text("weekStart.automatic", "自動")
        case .monday:
            L10n.text("weekStart.monday", "月曜")
        case .sunday:
            L10n.text("weekStart.sunday", "日曜")
        }
    }

    var firstWeekday: Int? {
        switch self {
        case .automatic:
            nil
        case .monday:
            2
        case .sunday:
            1
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewSampleData.makeContainer())
}
