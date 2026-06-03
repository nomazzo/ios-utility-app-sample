import Foundation
import SwiftData

enum PauseModeError: Error, LocalizedError, Equatable {
    case invalidDateRange
    case missingFixedRule

    var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            L10n.text("pause.error.invalidDateRange", "終了日は開始日以降にしてください。")
        case .missingFixedRule:
            L10n.text("pause.error.missingFixedRule", "固定日のルールが見つかりません。")
        }
    }
}

@MainActor
struct PauseModeService {
    var calendar: Calendar
    var scheduleCalculator: ScheduleCalculator

    init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.scheduleCalculator = ScheduleCalculator(calendar: calendar)
    }

    func activePausePeriod(
        from periods: [PausePeriod],
        referenceDate: Date = Date()
    ) -> PausePeriod? {
        let day = calendar.startOfDay(for: referenceDate)
        return periods
            .filter { $0.isActive }
            .filter {
                calendar.startOfDay(for: $0.startDate) <= day &&
                    day <= calendar.startOfDay(for: $0.endDate)
            }
            .sorted { $0.endDate < $1.endDate }
            .first
    }

    func isPaused(
        periods: [PausePeriod],
        referenceDate: Date = Date()
    ) -> Bool {
        activePausePeriod(from: periods, referenceDate: referenceDate) != nil
    }

    @discardableResult
    func startPause(
        title: String,
        startDate: Date,
        endDate: Date,
        reason: PauseReason,
        tasks: [CleaningTask],
        in modelContext: ModelContext
    ) throws -> PausePeriod {
        let normalizedStart = calendar.startOfDay(for: startDate)
        let normalizedEnd = calendar.startOfDay(for: endDate)
        guard normalizedStart <= normalizedEnd else {
            throw PauseModeError.invalidDateRange
        }

        let period = PausePeriod(
            title: title.isEmpty ? reason.displayName : title,
            startDate: normalizedStart,
            endDate: normalizedEnd,
            reason: reason,
            isActive: true,
            notificationRebuildNeeded: true
        )
        modelContext.insert(period)

        try adjustSchedules(
            for: tasks.filter { !$0.isArchived },
            startDate: normalizedStart,
            endDate: normalizedEnd,
            in: modelContext
        )

        try modelContext.save()
        return period
    }

    func updatePausePeriod(
        _ period: PausePeriod,
        title: String,
        startDate: Date,
        endDate: Date,
        reason: PauseReason,
        in modelContext: ModelContext
    ) throws {
        let normalizedStart = calendar.startOfDay(for: startDate)
        let normalizedEnd = calendar.startOfDay(for: endDate)
        guard normalizedStart <= normalizedEnd else {
            throw PauseModeError.invalidDateRange
        }

        period.title = title.isEmpty ? reason.displayName : title
        period.startDate = normalizedStart
        period.endDate = normalizedEnd
        period.reason = reason
        period.notificationRebuildNeeded = true
        try modelContext.save()
    }

    func endPause(
        _ period: PausePeriod,
        endedAt: Date = Date(),
        in modelContext: ModelContext
    ) throws {
        period.isActive = false
        period.endDate = calendar.startOfDay(for: endedAt)
        period.notificationRebuildNeeded = true
        try modelContext.save()
    }

    private func adjustSchedules(
        for tasks: [CleaningTask],
        startDate: Date,
        endDate: Date,
        in modelContext: ModelContext
    ) throws {
        let pauseDays = inclusiveDayCount(from: startDate, to: endDate)

        for task in tasks {
            switch task.scheduleKind {
            case .interval:
                shiftIntervalTask(task, pauseDays: pauseDays, startDate: startDate)
            case .fixed:
                try skipFixedOccurrencesIfNeeded(
                    task,
                    startDate: startDate,
                    endDate: endDate,
                    in: modelContext
                )
            }
        }
    }

    private func shiftIntervalTask(
        _ task: CleaningTask,
        pauseDays: Int,
        startDate: Date
    ) {
        let dueDay = calendar.startOfDay(for: task.nextDueDate)
        guard dueDay >= startDate,
              let shiftedDate = calendar.date(byAdding: .day, value: pauseDays, to: dueDay) else {
            return
        }

        task.nextDueDate = calendar.startOfDay(for: shiftedDate)
        task.updatedAt = Date()
    }

    private func skipFixedOccurrencesIfNeeded(
        _ task: CleaningTask,
        startDate: Date,
        endDate: Date,
        in modelContext: ModelContext
    ) throws {
        guard let fixedRule = task.fixedRule else {
            throw PauseModeError.missingFixedRule
        }

        let originalDueDate = calendar.startOfDay(for: task.nextDueDate)
        var candidate = originalDueDate
        var skippedDuringPause = false

        while candidate <= endDate {
            if candidate >= startDate {
                skippedDuringPause = true
            }

            candidate = try scheduleCalculator.nextDueDate(
                scheduleKind: .fixed,
                fixedRule: fixedRule,
                completedAt: candidate,
                previousDueDate: candidate
            )
        }

        guard skippedDuringPause else { return }

        task.nextDueDate = candidate
        task.snoozedUntil = nil
        task.updatedAt = Date()

        let log = CompletionLog(
            task: task,
            completedAt: startDate,
            originalDueDate: originalDueDate,
            actionType: .autoSkippedByPause
        )
        log.note = L10n.text("pause.log.autoSkipped", "休みモードで自動スキップ")
        task.logs.append(log)
        modelContext.insert(log)
    }

    private func inclusiveDayCount(from startDate: Date, to endDate: Date) -> Int {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(days + 1, 1)
    }
}
