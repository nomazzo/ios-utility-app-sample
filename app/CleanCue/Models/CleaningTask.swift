import Foundation
import SwiftData

@Model
final class CleaningTask {
    // SwiftDataで扱いやすいよう、永続化する値はプリミティブ寄りに保持する。
    @Attribute(.unique) var id: UUID

    var name: String
    var note: String
    var tools: String
    var estimatedMinutes: Int
    var priorityRaw: String

    var scheduleKindRaw: String
    var fixedRuleData: Data?
    var intervalRuleData: Data?

    var nextDueDate: Date
    var lastCompletedAt: Date?
    var lastCompletedDueDate: Date?

    var reminderEnabled: Bool
    var reminderTimeMinutes: Int
    var reminderOffsetsData: Data

    var snoozedUntil: Date?
    var isArchived: Bool

    var sourcePresetId: String?
    var createdAt: Date
    var updatedAt: Date

    var place: Place?

    // タスク削除時は履歴も削除し、孤立したログが残らないようにする。
    @Relationship(deleteRule: .cascade, inverse: \CompletionLog.task)
    var logs: [CompletionLog]

    init(
        id: UUID = UUID(),
        name: String,
        place: Place? = nil,
        nextDueDate: Date,
        scheduleKind: ScheduleKind,
        fixedRule: FixedRule? = nil,
        intervalRule: IntervalRule? = nil,
        estimatedMinutes: Int = 5,
        priority: TaskPriority = .normal,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.place = place
        self.note = ""
        self.tools = ""
        self.estimatedMinutes = estimatedMinutes
        self.priorityRaw = priority.rawValue
        self.scheduleKindRaw = scheduleKind.rawValue
        self.fixedRuleData = ModelCoding.encode(fixedRule)
        self.intervalRuleData = ModelCoding.encode(intervalRule)
        self.nextDueDate = nextDueDate
        self.lastCompletedAt = nil
        self.lastCompletedDueDate = nil
        self.reminderEnabled = false
        self.reminderTimeMinutes = 9 * 60
        self.reminderOffsetsData = Data()
        self.snoozedUntil = nil
        self.isArchived = false
        self.sourcePresetId = nil
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.logs = []
    }

    var scheduleKind: ScheduleKind {
        get { ScheduleKind(rawValue: scheduleKindRaw) ?? .interval }
        set { scheduleKindRaw = newValue.rawValue }
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .normal }
        set { priorityRaw = newValue.rawValue }
    }

    var fixedRule: FixedRule? {
        // 複合的なスケジュール条件はDataにエンコードして保存する。
        get { ModelCoding.decode(FixedRule.self, from: fixedRuleData) }
        set { fixedRuleData = ModelCoding.encode(newValue) }
    }

    var intervalRule: IntervalRule? {
        // 日数・週数などの繰り返し条件も同じ経路で読み書きする。
        get { ModelCoding.decode(IntervalRule.self, from: intervalRuleData) }
        set { intervalRuleData = ModelCoding.encode(newValue) }
    }

    var reminderStyle: ReminderStyle {
        get {
            guard let offsets = ModelCoding.decode([Int].self, from: reminderOffsetsData),
                  !offsets.isEmpty else {
                return .standard
            }
            return ReminderStyle(offsetDays: offsets)
        }
        set {
            reminderOffsetsData = ModelCoding.encode(newValue.offsetDays) ?? Data()
        }
    }
}
