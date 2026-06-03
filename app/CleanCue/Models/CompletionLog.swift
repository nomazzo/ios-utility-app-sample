import Foundation
import SwiftData

@Model
final class CompletionLog {
    @Attribute(.unique) var id: UUID
    var completedAt: Date
    var originalDueDate: Date?
    var actionTypeRaw: String
    var note: String

    var task: CleaningTask?

    init(
        id: UUID = UUID(),
        task: CleaningTask? = nil,
        completedAt: Date = Date(),
        originalDueDate: Date?,
        actionType: CompletionActionType
    ) {
        self.id = id
        self.task = task
        self.completedAt = completedAt
        self.originalDueDate = originalDueDate
        self.actionTypeRaw = actionType.rawValue
        self.note = ""
    }

    var actionType: CompletionActionType {
        get { CompletionActionType(rawValue: actionTypeRaw) ?? .completed }
        set { actionTypeRaw = newValue.rawValue }
    }
}
