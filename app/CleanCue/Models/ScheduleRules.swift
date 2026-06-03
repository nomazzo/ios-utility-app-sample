import Foundation

nonisolated enum ScheduleKind: String, Codable, CaseIterable, Sendable {
    case fixed
    case interval
}

nonisolated enum TaskPriority: String, Codable, CaseIterable, Sendable {
    case low
    case normal
    case high
}

nonisolated enum CompletionActionType: String, Codable, CaseIterable, Sendable {
    case completed
    case skipped
    case snoozed
    case autoSkippedByPause
}

nonisolated enum IntervalUnit: String, Codable, CaseIterable, Sendable {
    case day
    case week
    case month
    case year
}

nonisolated enum FixedRuleType: String, Codable, CaseIterable, Sendable {
    case weekly
    case biweekly
    case monthlyDay
    case monthlyLastDay
    case yearlyDate
}

nonisolated enum PauseReason: String, Codable, CaseIterable, Sendable {
    case travel
    case sick
    case busy
    case other
}

nonisolated enum HomeType: String, Codable, CaseIterable, Sendable {
    case livingAlone
    case family
    case shared
    case other
}

nonisolated enum AppAppearance: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}

nonisolated enum TodayDisplayLimit: String, Codable, CaseIterable, Sendable {
    case one
    case three
    case all
}

nonisolated enum UrgencyExpressionStyle: String, Codable, CaseIterable, Sendable {
    case gentle
    case standard
}

nonisolated enum WeekStartPreference: String, Codable, CaseIterable, Sendable {
    case automatic
    case monday
    case sunday
}

nonisolated enum ReminderStyle: String, Codable, CaseIterable, Sendable {
    case standard
    case careful
    case important

    var offsetDays: [Int] {
        switch self {
        case .standard:
            [0]
        case .careful:
            [1, 0]
        case .important:
            [3, 1, 0]
        }
    }

    init(offsetDays: [Int]) {
        switch offsetDays.sorted(by: >) {
        case ReminderStyle.careful.offsetDays:
            self = .careful
        case ReminderStyle.important.offsetDays:
            self = .important
        default:
            self = .standard
        }
    }
}

nonisolated struct IntervalRule: Codable, Equatable, Sendable {
    var value: Int
    var unit: IntervalUnit

    init(value: Int, unit: IntervalUnit) {
        self.value = value
        self.unit = unit
    }
}

nonisolated struct FixedRule: Codable, Equatable, Sendable {
    var type: FixedRuleType
    var weekdays: [Int]
    var dayOfMonth: Int?
    var month: Int?
    var day: Int?
    var anchorDate: Date?

    init(
        type: FixedRuleType,
        weekdays: [Int] = [],
        dayOfMonth: Int? = nil,
        month: Int? = nil,
        day: Int? = nil,
        anchorDate: Date? = nil
    ) {
        self.type = type
        self.weekdays = weekdays
        self.dayOfMonth = dayOfMonth
        self.month = month
        self.day = day
        self.anchorDate = anchorDate
    }
}

nonisolated enum ModelCoding {
    static let encoder = JSONEncoder()
    static let decoder = JSONDecoder()

    static func encode<T: Encodable>(_ value: T) -> Data? {
        try? encoder.encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
