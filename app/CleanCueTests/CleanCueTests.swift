import Foundation
import SwiftData
import Testing
@testable import CleanCue

struct CleanCueTests {
    // 日付計算のテストはタイムゾーン差で揺れないよう、固定カレンダーを使う。
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    @Test func presetProviderContainsStableDemoPresets() {
        let provider = PresetProvider.defaultProvider

        #expect(provider.place(for: "kitchen")?.displayName == "キッチン")
        #expect(provider.tasks(for: "kitchen").map(\.id).contains("kitchen_sink_clean"))
        #expect(provider.homeMaintenanceTasks.map(\.id).contains("maintenance_ac_filter"))
    }

    @Test func featureGateAppliesFreeLimitsAndProUnlock() {
        // 無料版の制限とPro解放時の解除を、営業デモの重要仕様として確認する。
        let gate = FeatureGate()
        let freeSettings = AppSettings(proUnlocked: false)
        let proSettings = AppSettings(proUnlocked: true)

        let blockedPlaces = gate.placeLimit(currentActivePlaceCount: FeatureGate.freePlaceLimit, settings: freeSettings)
        let blockedTasks = gate.taskLimit(currentActiveTaskCount: FeatureGate.freeTaskLimit, settings: freeSettings)
        let unlockedTasks = gate.taskLimit(currentActiveTaskCount: 99, settings: proSettings)

        #expect(blockedPlaces.isBlocked)
        #expect(blockedTasks.isBlocked)
        #expect(unlockedTasks.isAllowed)
        #expect(gate.canUseReminderStyle(.careful, settings: proSettings))
        #expect(!gate.canUseReminderStyle(.careful, settings: freeSettings))
    }

    @MainActor
    @Test func purchaseManagerLoadsPurchasesAndRestoresDemoPro() async throws {
        // StoreKit本体には触れず、差し替えクライアントで購入フローの状態更新を検証する。
        let suiteName = "CleanCueTests.purchaseManagerLoadsPurchasesAndRestoresDemoPro"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)

        let product = PurchaseProductInfo(
            id: CleanCueProductID.pro,
            displayName: "HomeRoutine Demo Pro",
            description: "Demo unlock",
            displayPrice: "¥700"
        )
        let client = MockPurchaseClient(
            productsResponse: [product],
            purchaseResult: .success([CleanCueProductID.pro]),
            entitlementProductIDs: []
        )
        let settingsStore = AppSettingsStore(userDefaults: userDefaults, key: "settings", appliesRuntimeOverrides: false)
        let manager = PurchaseManager(
            client: client,
            entitlementStore: EntitlementStore(settingsStore: settingsStore)
        )

        let products = try await manager.loadProducts()
        let purchaseOutcome = try await manager.purchasePro()
        client.entitlementProductIDs = [CleanCueProductID.pro]
        let restoreOutcome = try await manager.restorePurchases()

        #expect(products == [product])
        #expect(purchaseOutcome == .purchased)
        #expect(restoreOutcome == .restored(true))
        #expect(client.didSync)
        #expect(settingsStore.load().proUnlocked)
    }

    @MainActor
    @Test func widgetSnapshotUsesTodayOverdueAndUpcomingTasks() async throws {
        // Widgetには「今日・期限切れ・近日の軽いタスク」が安定した順序で渡ることを確認する。
        let today = try date(year: 2026, month: 5, day: 21)
        let place = Place(name: "Kitchen")
        let tasks = [
            makeTask(name: "Overdue", place: place, due: try date(year: 2026, month: 5, day: 20)),
            makeTask(name: "Today", place: place, due: today),
            makeTask(name: "Upcoming", place: place, due: try date(year: 2026, month: 5, day: 23))
        ]
        let service = WidgetSnapshotService(
            provider: TodayTaskProvider(calendar: calendar, maximumRecommendedCount: 3),
            calendar: calendar,
            appGroupIdentifier: nil,
            userDefaults: UserDefaults(suiteName: "CleanCueTests.widgetSnapshot") ?? .standard
        )

        let snapshot = service.makeSnapshot(
            tasks: tasks,
            pausePeriods: [],
            referenceDate: today
        )

        #expect(snapshot.todayTasks.map { $0.taskName } == ["Today", "Overdue", "Upcoming"])
        #expect(snapshot.todayTasks.first?.dueLabel == L10n.text("urgency.today", "今日"))
    }

    @MainActor
    @Test func completingTaskCreatesLogAndAdvancesDueDate() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let today = try date(year: 2026, month: 5, day: 21)
        let completedAt = try dateTime(year: 2026, month: 5, day: 21, hour: 10)
        let place = Place(name: "Kitchen")
        let task = makeTask(name: "Wipe counter", place: place, due: today)

        context.insert(place)
        context.insert(task)

        let service = TaskActionService(scheduleCalculator: ScheduleCalculator(calendar: calendar))
        let log = try service.complete(task: task, at: completedAt, in: context)

        #expect(log.actionType == .completed)
        #expect(log.originalDueDate == today)
        #expect(task.lastCompletedAt == completedAt)
        #expect(task.nextDueDate == (try date(year: 2026, month: 5, day: 28)))
        #expect(task.logs.count == 1)
    }

    private func date(year: Int, month: Int, day: Int) throws -> Date {
        try dateTime(year: year, month: month, day: day, hour: 0)
    }

    private func dateTime(year: Int, month: Int, day: Int, hour: Int) throws -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour
        )

        return try #require(calendar.date(from: components))
    }

    private func makeTask(
        name: String,
        place: Place,
        due: Date,
        estimatedMinutes: Int = 5
    ) -> CleaningTask {
        CleaningTask(
            name: name,
            place: place,
            nextDueDate: due,
            scheduleKind: .interval,
            intervalRule: IntervalRule(value: 7, unit: .day),
            estimatedMinutes: estimatedMinutes
        )
    }

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(CleanCueSchema.models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

private final class MockPurchaseClient: PurchaseClient {
    // 購入結果を任意に差し替えるための、テスト専用StoreKit代替。
    var productsResponse: [PurchaseProductInfo]
    var purchaseResult: PurchaseClientResult
    var entitlementProductIDs: Set<String>
    var didSync = false

    init(
        productsResponse: [PurchaseProductInfo],
        purchaseResult: PurchaseClientResult,
        entitlementProductIDs: Set<String>
    ) {
        self.productsResponse = productsResponse
        self.purchaseResult = purchaseResult
        self.entitlementProductIDs = entitlementProductIDs
    }

    func products(for productIDs: [String]) async throws -> [PurchaseProductInfo] {
        productsResponse.filter { productIDs.contains($0.id) }
    }

    func purchase(productID: String) async throws -> PurchaseClientResult {
        purchaseResult
    }

    func currentEntitlementProductIDs() async -> Set<String> {
        entitlementProductIDs
    }

    func sync() async throws {
        didSync = true
    }
}
