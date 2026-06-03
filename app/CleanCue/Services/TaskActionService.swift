import Foundation
import SwiftData

enum TaskActionError: Error, LocalizedError {
    case missingScheduleRule
    case scheduleCalculationFailed

    var errorDescription: String? {
        switch self {
        case .missingScheduleRule:
            "Schedule rule is missing."
        case .scheduleCalculationFailed:
            "Could not calculate the next due date."
        }
    }
}

@MainActor
struct TaskActionService {
    var scheduleCalculator: ScheduleCalculator

    init(scheduleCalculator: ScheduleCalculator = ScheduleCalculator()) {
        self.scheduleCalculator = scheduleCalculator
    }

    @discardableResult
    func complete(
        task: CleaningTask,
        at completedAt: Date = Date(),
        in modelContext: ModelContext
    ) throws -> CompletionLog {
        // 完了操作では、履歴作成と次回予定日の更新を1つの保存単位にまとめる。
        let originalDueDate = task.nextDueDate
        let nextDueDate: Date

        switch task.scheduleKind {
        case .fixed:
            guard let fixedRule = task.fixedRule else {
                throw TaskActionError.missingScheduleRule
            }
            nextDueDate = try nextActiveFixedDate(
                fixedRule: fixedRule,
                originalDueDate: originalDueDate,
                actionDate: completedAt
            )

        case .interval:
            guard let intervalRule = task.intervalRule else {
                throw TaskActionError.missingScheduleRule
            }
            nextDueDate = try scheduleCalculator.nextDueDate(
                scheduleKind: .interval,
                intervalRule: intervalRule,
                completedAt: completedAt,
                previousDueDate: originalDueDate
            )
        }

        let log = CompletionLog(
            task: task,
            completedAt: completedAt,
            originalDueDate: originalDueDate,
            actionType: .completed
        )

        task.lastCompletedAt = completedAt
        task.lastCompletedDueDate = originalDueDate
        task.nextDueDate = nextDueDate
        task.snoozedUntil = nil
        task.updatedAt = completedAt
        task.logs.append(log)
        modelContext.insert(log)

        try modelContext.save()
        return log
    }

    @discardableResult
    func snoozeTomorrow(
        task: CleaningTask,
        at actionDate: Date = Date(),
        in modelContext: ModelContext
    ) throws -> CompletionLog {
        // 明日へ延期した事実もログ化し、後から行動履歴として確認できるようにする。
        let originalDueDate = task.nextDueDate
        let snoozedUntil = tomorrowMorning(after: actionDate)
        let log = CompletionLog(
            task: task,
            completedAt: actionDate,
            originalDueDate: originalDueDate,
            actionType: .snoozed
        )

        task.snoozedUntil = snoozedUntil
        task.updatedAt = actionDate
        task.logs.append(log)
        modelContext.insert(log)

        try modelContext.save()
        return log
    }

    @discardableResult
    func skipThisWeek(
        task: CleaningTask,
        at actionDate: Date = Date(),
        in modelContext: ModelContext
    ) throws -> CompletionLog {
        // スキップは完了とは区別しつつ、次回予定だけを先へ進める。
        let originalDueDate = task.nextDueDate
        let nextDueDate: Date

        switch task.scheduleKind {
        case .fixed:
            guard let fixedRule = task.fixedRule else {
                throw TaskActionError.missingScheduleRule
            }
            nextDueDate = try nextActiveFixedDate(
                fixedRule: fixedRule,
                originalDueDate: originalDueDate,
                actionDate: actionDate
            )

        case .interval:
            guard let advancedDate = scheduleCalculator.calendar.date(
                byAdding: .day,
                value: 7,
                to: scheduleCalculator.calendar.startOfDay(for: originalDueDate)
            ) else {
                throw TaskActionError.scheduleCalculationFailed
            }
            nextDueDate = scheduleCalculator.calendar.startOfDay(for: advancedDate)
        }

        let log = CompletionLog(
            task: task,
            completedAt: actionDate,
            originalDueDate: originalDueDate,
            actionType: .skipped
        )

        task.nextDueDate = nextDueDate
        task.snoozedUntil = nil
        task.updatedAt = actionDate
        task.logs.append(log)
        modelContext.insert(log)

        try modelContext.save()
        return log
    }

    private func tomorrowMorning(after date: Date) -> Date {
        let calendar = scheduleCalculator.calendar
        let startOfToday = calendar.startOfDay(for: date)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? date
        return calendar.date(byAdding: .hour, value: 9, to: tomorrow) ?? tomorrow
    }

    private func nextActiveFixedDate(
        fixedRule: FixedRule,
        originalDueDate: Date,
        actionDate: Date
    ) throws -> Date {
        let calendar = scheduleCalculator.calendar
        let actionDay = calendar.startOfDay(for: actionDate)
        var candidate = try scheduleCalculator.nextDueDate(
            scheduleKind: .fixed,
            fixedRule: fixedRule,
            completedAt: actionDate,
            previousDueDate: originalDueDate
        )

        // 過去分をまとめて完了した場合でも、次回予定は必ず操作日より後に置く。
        while calendar.compare(candidate, to: actionDay, toGranularity: .day) != .orderedDescending {
            candidate = try scheduleCalculator.nextDueDate(
                scheduleKind: .fixed,
                fixedRule: fixedRule,
                completedAt: actionDate,
                previousDueDate: candidate
            )
        }

        return candidate
    }
}
