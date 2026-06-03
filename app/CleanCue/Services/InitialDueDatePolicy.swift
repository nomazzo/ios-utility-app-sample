import Foundation

struct InitialDueDatePolicy {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func startDate(for choice: InitialDueDateChoice, referenceDate: Date = Date()) -> Date {
        let today = calendar.startOfDay(for: referenceDate)
        switch choice {
        case .today:
            return today
        case .tomorrow:
            return addingDays(1, to: today)
        case .weekend:
            return weekendDate(relativeTo: today)
        case .nextWeek:
            return addingDays(7, to: today)
        case .spreadOut:
            return today
        }
    }

    func distributedDates(count: Int, referenceDate: Date = Date()) -> [Date] {
        guard count > 0 else { return [] }
        let today = calendar.startOfDay(for: referenceDate)
        return (0..<count).map { index in
            addingDays(offset(for: index), to: today)
        }
    }

    func distributedDate(index: Int, referenceDate: Date = Date()) -> Date {
        let today = calendar.startOfDay(for: referenceDate)
        return addingDays(offset(for: max(index, 0)), to: today)
    }

    private func offset(for index: Int) -> Int {
        let starterOffsets = [0, 1, 3, 5, 7, 10, 14, 18, 21, 25, 28, 32, 35, 39, 42, 46, 49, 53, 56, 60]
        if starterOffsets.indices.contains(index) {
            return starterOffsets[index]
        }
        return 60 + ((index - starterOffsets.count + 1) * 4)
    }

    private func weekendDate(relativeTo date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 || weekday == 7 {
            return date
        }
        return addingDays(7 - weekday, to: date)
    }

    private func addingDays(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
}

enum InitialDueDateChoice: CaseIterable, Identifiable {
    case today
    case tomorrow
    case weekend
    case nextWeek
    case spreadOut

    var id: Self { self }

    var displayName: String {
        switch self {
        case .today:
            L10n.text("task.initialDue.today", "今日")
        case .tomorrow:
            L10n.text("task.initialDue.tomorrow", "明日")
        case .weekend:
            L10n.text("task.initialDue.weekend", "週末")
        case .nextWeek:
            L10n.text("task.initialDue.nextWeek", "来週")
        case .spreadOut:
            L10n.text("task.initialDue.spreadOut", "分散")
        }
    }
}
