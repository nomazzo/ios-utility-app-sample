import Foundation

@MainActor
struct TodayTaskSections {
    var allDueToday: [CleaningTask]
    var recommended: [CleaningTask]
    var overdue: [CleaningTask]
    var upcomingLight: [CleaningTask]

    var isEmpty: Bool {
        allDueToday.isEmpty && overdue.isEmpty && upcomingLight.isEmpty
    }
}

@MainActor
struct TodayTaskProvider {
    var calendar: Calendar
    var maximumRecommendedCount: Int
    var maximumUpcomingCount: Int
    var lightTaskMinuteLimit: Int

    init(
        calendar: Calendar = .current,
        maximumRecommendedCount: Int = 3,
        maximumUpcomingCount: Int = 3,
        lightTaskMinuteLimit: Int = 10
    ) {
        self.calendar = calendar
        self.maximumRecommendedCount = maximumRecommendedCount
        self.maximumUpcomingCount = maximumUpcomingCount
        self.lightTaskMinuteLimit = lightTaskMinuteLimit
    }

    func sections(for tasks: [CleaningTask], referenceDate: Date = Date()) -> TodayTaskSections {
        // 今日画面は「表示対象を絞る -> 並べる -> セクション化する」の順で構築する。
        let visibleTasks = tasks
            .filter { !$0.isArchived }
            .filter { !isHiddenBySnooze($0, referenceDate: referenceDate) }

        let sortedTasks = visibleTasks.sorted(by: taskSort)

        let allDueToday = sortedTasks
            .filter { calendar.isDate($0.nextDueDate, inSameDayAs: referenceDate) }

        let recommended = allDueToday
            .prefix(maximumRecommendedCount)

        let overdue = sortedTasks
            .filter { isOverdue($0, referenceDate: referenceDate) }

        let upcomingLight = sortedTasks
            .filter { isUpcomingLight($0, referenceDate: referenceDate) }
            .prefix(maximumUpcomingCount)

        return TodayTaskSections(
            allDueToday: allDueToday,
            recommended: Array(recommended),
            overdue: overdue,
            upcomingLight: Array(upcomingLight)
        )
    }

    func isHiddenBySnooze(_ task: CleaningTask, referenceDate: Date = Date()) -> Bool {
        guard let snoozedUntil = task.snoozedUntil else { return false }
        return snoozedUntil > referenceDate
    }

    private func isOverdue(_ task: CleaningTask, referenceDate: Date) -> Bool {
        calendar.compare(
            calendar.startOfDay(for: task.nextDueDate),
            to: calendar.startOfDay(for: referenceDate),
            toGranularity: .day
        ) == .orderedAscending
    }

    private func isUpcomingLight(_ task: CleaningTask, referenceDate: Date) -> Bool {
        let today = calendar.startOfDay(for: referenceDate)
        let dueDay = calendar.startOfDay(for: task.nextDueDate)
        guard let daysUntilDue = calendar.dateComponents([.day], from: today, to: dueDay).day else {
            return false
        }

        // 近いうちに終わる軽い作業を先取り候補として出す。
        return (1...7).contains(daysUntilDue) && task.estimatedMinutes <= lightTaskMinuteLimit
    }

    private func taskSort(_ lhs: CleaningTask, _ rhs: CleaningTask) -> Bool {
        // 期日、優先度、所要時間の順で、今日やるべき順序を安定させる。
        if lhs.nextDueDate != rhs.nextDueDate {
            return lhs.nextDueDate < rhs.nextDueDate
        }

        if priorityRank(lhs.priority) != priorityRank(rhs.priority) {
            return priorityRank(lhs.priority) > priorityRank(rhs.priority)
        }

        if lhs.estimatedMinutes != rhs.estimatedMinutes {
            return lhs.estimatedMinutes < rhs.estimatedMinutes
        }

        return lhs.createdAt < rhs.createdAt
    }

    private func priorityRank(_ priority: TaskPriority) -> Int {
        switch priority {
        case .low:
            0
        case .normal:
            1
        case .high:
            2
        }
    }
}
