import Foundation
import SwiftData

@MainActor
struct CompletionLogService {
    func delete(_ log: CompletionLog, in modelContext: ModelContext) throws {
        let task = log.task

        if let task, let index = task.logs.firstIndex(where: { $0.id == log.id }) {
            task.logs.remove(at: index)
        }

        modelContext.delete(log)

        if let task {
            recalculateLastCompletion(for: task)
            task.updatedAt = Date()
        }

        try modelContext.save()
    }

    func recalculateLastCompletion(for task: CleaningTask) {
        let latestCompletedLog = task.logs
            .filter { $0.actionType == .completed }
            .sorted { $0.completedAt > $1.completedAt }
            .first

        task.lastCompletedAt = latestCompletedLog?.completedAt
        task.lastCompletedDueDate = latestCompletedLog?.originalDueDate
    }
}
