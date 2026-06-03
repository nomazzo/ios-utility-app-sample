import Foundation

nonisolated enum UrgencyState: String, Codable, CaseIterable, Sendable {
    case safe
    case soon
    case today
    case overdue
}

nonisolated struct UrgencyResult: Equatable, Sendable {
    var state: UrgencyState
    var daysUntilDue: Int
}

nonisolated struct UrgencyCalculator {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func urgency(for dueDate: Date, relativeTo referenceDate: Date = Date()) -> UrgencyResult {
        let today = calendar.startOfDay(for: referenceDate)
        let dueDay = calendar.startOfDay(for: dueDate)
        let daysUntilDue = calendar.dateComponents([.day], from: today, to: dueDay).day ?? 0

        let state: UrgencyState
        switch daysUntilDue {
        case ..<0:
            state = .overdue
        case 0:
            state = .today
        case 1...3:
            state = .soon
        default:
            state = .safe
        }

        return UrgencyResult(state: state, daysUntilDue: daysUntilDue)
    }
}
