import Foundation

nonisolated enum CalendarTaskMode: String, CaseIterable, Sendable {
    case today
    case tomorrow
    case thisWeek
    case thisMonth
    case overdue
}

nonisolated struct CalendarTaskProvider {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func tasks(
        for mode: CalendarTaskMode,
        from tasks: [CleaningTask],
        referenceDate: Date = Date()
    ) -> [CleaningTask] {
        let activeTasks = tasks.filter { !$0.isArchived }

        return activeTasks
            .filter { task in
                matches(task, mode: mode, referenceDate: referenceDate)
            }
            .sorted(by: taskSort)
    }

    private func matches(
        _ task: CleaningTask,
        mode: CalendarTaskMode,
        referenceDate: Date
    ) -> Bool {
        let today = calendar.startOfDay(for: referenceDate)
        let dueDay = calendar.startOfDay(for: task.nextDueDate)

        switch mode {
        case .today:
            return calendar.isDate(dueDay, inSameDayAs: today)
        case .tomorrow:
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return false }
            return calendar.isDate(dueDay, inSameDayAs: tomorrow)
        case .thisWeek:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: today) else { return false }
            return dueDay >= interval.start && dueDay < interval.end
        case .thisMonth:
            guard let interval = calendar.dateInterval(of: .month, for: today) else { return false }
            return dueDay >= interval.start && dueDay < interval.end
        case .overdue:
            return dueDay < today
        }
    }

    private func taskSort(_ lhs: CleaningTask, _ rhs: CleaningTask) -> Bool {
        if lhs.nextDueDate != rhs.nextDueDate {
            return lhs.nextDueDate < rhs.nextDueDate
        }
        return lhs.createdAt < rhs.createdAt
    }
}
