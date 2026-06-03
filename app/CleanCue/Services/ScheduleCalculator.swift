import Foundation

nonisolated enum ScheduleCalculationError: Error, Equatable, Sendable {
    case missingFixedRule
    case missingIntervalRule
    case invalidIntervalValue
    case invalidFixedRule
    case unableToCalculateDate
}

nonisolated struct ScheduleCalculator {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func nextDueDate(
        scheduleKind: ScheduleKind,
        fixedRule: FixedRule? = nil,
        intervalRule: IntervalRule? = nil,
        completedAt: Date,
        previousDueDate: Date?
    ) throws -> Date {
        // 固定日程は「前回予定日」を基準にし、間隔日程は「完了日」を基準にする。
        switch scheduleKind {
        case .fixed:
            guard let fixedRule else { throw ScheduleCalculationError.missingFixedRule }
            let baseDate = previousDueDate ?? completedAt
            return try nextFixedDate(for: fixedRule, after: baseDate, includingBaseDate: false)

        case .interval:
            guard let intervalRule else { throw ScheduleCalculationError.missingIntervalRule }
            return try nextIntervalDate(for: intervalRule, from: completedAt)
        }
    }

    func firstDueDate(for fixedRule: FixedRule, onOrAfter date: Date) throws -> Date {
        try nextFixedDate(for: fixedRule, after: date, includingBaseDate: true)
    }

    func nextIntervalDate(for rule: IntervalRule, from date: Date) throws -> Date {
        guard rule.value > 0 else { throw ScheduleCalculationError.invalidIntervalValue }

        let baseDate = calendar.startOfDay(for: date)
        var components = DateComponents()

        switch rule.unit {
        case .day:
            components.day = rule.value
        case .week:
            components.day = rule.value * 7
        case .month:
            components.month = rule.value
        case .year:
            components.year = rule.value
        }

        guard let nextDate = calendar.date(byAdding: components, to: baseDate) else {
            throw ScheduleCalculationError.unableToCalculateDate
        }

        return calendar.startOfDay(for: nextDate)
    }

    private func nextFixedDate(
        for rule: FixedRule,
        after baseDate: Date,
        includingBaseDate: Bool
    ) throws -> Date {
        switch rule.type {
        case .weekly:
            return try nextWeeklyDate(
                weekdays: rule.weekdays,
                after: baseDate,
                includingBaseDate: includingBaseDate
            )
        case .biweekly:
            return try nextBiweeklyDate(
                rule: rule,
                after: baseDate,
                includingBaseDate: includingBaseDate
            )
        case .monthlyDay:
            guard let dayOfMonth = rule.dayOfMonth, (1...31).contains(dayOfMonth) else {
                throw ScheduleCalculationError.invalidFixedRule
            }
            return try nextMonthlyDate(
                dayOfMonth: dayOfMonth,
                useLastDay: false,
                after: baseDate,
                includingBaseDate: includingBaseDate
            )
        case .monthlyLastDay:
            return try nextMonthlyDate(
                dayOfMonth: nil,
                useLastDay: true,
                after: baseDate,
                includingBaseDate: includingBaseDate
            )
        case .yearlyDate:
            guard let month = rule.month, let day = rule.day else {
                throw ScheduleCalculationError.invalidFixedRule
            }
            return try nextYearlyDate(
                month: month,
                day: day,
                after: baseDate,
                includingBaseDate: includingBaseDate
            )
        }
    }

    private func nextWeeklyDate(
        weekdays: [Int],
        after baseDate: Date,
        includingBaseDate: Bool
    ) throws -> Date {
        let validWeekdays = normalizedWeekdays(weekdays)
        guard !validWeekdays.isEmpty else { throw ScheduleCalculationError.invalidFixedRule }

        let baseStart = calendar.startOfDay(for: baseDate)
        let startOffset = includingBaseDate ? 0 : 1

        // 週次は最大2週間先まで見れば、曜日指定の次回候補を必ず拾える。
        for offset in startOffset...14 {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: baseStart) else {
                continue
            }

            let weekday = calendar.component(.weekday, from: candidate)
            if validWeekdays.contains(weekday) {
                return calendar.startOfDay(for: candidate)
            }
        }

        throw ScheduleCalculationError.unableToCalculateDate
    }

    private func nextBiweeklyDate(
        rule: FixedRule,
        after baseDate: Date,
        includingBaseDate: Bool
    ) throws -> Date {
        let validWeekdays = normalizedWeekdays(rule.weekdays)
        guard !validWeekdays.isEmpty, let anchorDate = rule.anchorDate else {
            throw ScheduleCalculationError.invalidFixedRule
        }

        let baseStart = calendar.startOfDay(for: baseDate)
        let startOffset = includingBaseDate ? 0 : 1
        let anchorWeekStart = try weekStart(for: anchorDate)

        // 隔週は基準週との差分が偶数の週だけを候補にする。
        for offset in startOffset...370 {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: baseStart) else {
                continue
            }

            let weekday = calendar.component(.weekday, from: candidate)
            guard validWeekdays.contains(weekday) else { continue }

            let candidateWeekStart = try weekStart(for: candidate)
            let weeks = calendar.dateComponents([.weekOfYear], from: anchorWeekStart, to: candidateWeekStart).weekOfYear

            if let weeks, weeks >= 0, weeks.isMultiple(of: 2) {
                return calendar.startOfDay(for: candidate)
            }
        }

        throw ScheduleCalculationError.unableToCalculateDate
    }

    private func nextMonthlyDate(
        dayOfMonth: Int?,
        useLastDay: Bool,
        after baseDate: Date,
        includingBaseDate: Bool
    ) throws -> Date {
        let baseStart = calendar.startOfDay(for: baseDate)
        let baseComponents = calendar.dateComponents([.year, .month], from: baseStart)

        guard let baseYear = baseComponents.year, let baseMonth = baseComponents.month else {
            throw ScheduleCalculationError.unableToCalculateDate
        }

        for monthOffset in 0...240 {
            guard let monthDate = calendar.date(from: DateComponents(year: baseYear, month: baseMonth + monthOffset, day: 1)),
                  let monthRange = calendar.range(of: .day, in: .month, for: monthDate) else {
                continue
            }

            // 31日指定など月末を超える日は、その月の最終日に丸める。
            let targetDay = useLastDay ? monthRange.count : min(dayOfMonth ?? 1, monthRange.count)
            let components = calendar.dateComponents([.year, .month], from: monthDate)

            guard let candidate = calendar.date(from: DateComponents(year: components.year, month: components.month, day: targetDay)) else {
                continue
            }

            if isCandidate(candidate, validAgainst: baseStart, includingBaseDate: includingBaseDate) {
                return calendar.startOfDay(for: candidate)
            }
        }

        throw ScheduleCalculationError.unableToCalculateDate
    }

    private func nextYearlyDate(
        month: Int,
        day: Int,
        after baseDate: Date,
        includingBaseDate: Bool
    ) throws -> Date {
        guard (1...12).contains(month), (1...31).contains(day) else {
            throw ScheduleCalculationError.invalidFixedRule
        }

        let baseStart = calendar.startOfDay(for: baseDate)
        guard let baseYear = calendar.dateComponents([.year], from: baseStart).year else {
            throw ScheduleCalculationError.unableToCalculateDate
        }

        for yearOffset in 0...80 {
            let year = baseYear + yearOffset
            guard let candidate = validDate(year: year, month: month, day: day) else {
                continue
            }

            if isCandidate(candidate, validAgainst: baseStart, includingBaseDate: includingBaseDate) {
                return calendar.startOfDay(for: candidate)
            }
        }

        throw ScheduleCalculationError.unableToCalculateDate
    }

    private func normalizedWeekdays(_ weekdays: [Int]) -> Set<Int> {
        Set(weekdays.filter { (1...7).contains($0) })
    }

    private func weekStart(for date: Date) throws -> Date {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            throw ScheduleCalculationError.unableToCalculateDate
        }
        return calendar.startOfDay(for: interval.start)
    }

    private func validDate(year: Int, month: Int, day: Int) -> Date? {
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components) else { return nil }
        let resolved = calendar.dateComponents([.year, .month, .day], from: date)
        guard resolved.year == year, resolved.month == month, resolved.day == day else { return nil }
        return calendar.startOfDay(for: date)
    }

    private func isCandidate(
        _ candidate: Date,
        validAgainst baseDate: Date,
        includingBaseDate: Bool
    ) -> Bool {
        let comparison = calendar.compare(
            calendar.startOfDay(for: candidate),
            to: calendar.startOfDay(for: baseDate),
            toGranularity: .day
        )

        return includingBaseDate ? comparison != .orderedAscending : comparison == .orderedDescending
    }
}
