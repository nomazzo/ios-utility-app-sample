import Foundation

nonisolated enum CleanCueProductID {
    // 公開デモ用のStoreKit Configurationで使う商品ID。
    static let pro = "com.example.homeroutinedemo.pro"
}

nonisolated enum PlanLimitKind: Equatable, Sendable {
    case places
    case tasks
}

nonisolated struct PlanLimitResult: Equatable, Sendable {
    var isAllowed: Bool
    var limit: Int?
    var currentCount: Int
    var kind: PlanLimitKind

    var isBlocked: Bool {
        !isAllowed
    }
}

nonisolated struct FeatureGate {
    // 無料版の制限値をここに集約し、画面側に課金判定を散らさない。
    static let freePlaceLimit = 3
    static let freeTaskLimit = 20

    func canUseReminderStyle(_ style: ReminderStyle, settings: AppSettings) -> Bool {
        style == .standard || settings.proUnlocked
    }

    func notificationOffsets(for style: ReminderStyle, settings: AppSettings) -> [Int] {
        canUseReminderStyle(style, settings: settings) ? style.offsetDays : ReminderStyle.standard.offsetDays
    }

    func placeLimit(currentActivePlaceCount: Int, settings: AppSettings) -> PlanLimitResult {
        limitResult(
            kind: .places,
            currentCount: currentActivePlaceCount,
            freeLimit: Self.freePlaceLimit,
            settings: settings
        )
    }

    func taskLimit(currentActiveTaskCount: Int, settings: AppSettings) -> PlanLimitResult {
        limitResult(
            kind: .tasks,
            currentCount: currentActiveTaskCount,
            freeLimit: Self.freeTaskLimit,
            settings: settings
        )
    }

    func canUseMultipleWidgets(settings: AppSettings) -> Bool {
        settings.proUnlocked
    }

    func canUseAdvancedBackup(settings: AppSettings) -> Bool {
        settings.proUnlocked
    }

    private func limitResult(
        kind: PlanLimitKind,
        currentCount: Int,
        freeLimit: Int,
        settings: AppSettings
    ) -> PlanLimitResult {
        if settings.proUnlocked {
            // Pro解放済みの場合、個数制限は画面側へ返さない。
            return PlanLimitResult(
                isAllowed: true,
                limit: nil,
                currentCount: currentCount,
                kind: kind
            )
        }

        return PlanLimitResult(
            isAllowed: currentCount < freeLimit,
            limit: freeLimit,
            currentCount: currentCount,
            kind: kind
        )
    }
}
