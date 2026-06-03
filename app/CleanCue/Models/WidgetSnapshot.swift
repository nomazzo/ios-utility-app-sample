import Foundation

nonisolated enum WidgetSnapshotDefaults {
    static let appGroupIdentifier = "group.com.example.homeroutinedemo"
    static let snapshotKey = "CleanCueWidgetSnapshot"
}

nonisolated struct WidgetTaskSnapshot: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var taskName: String
    var placeName: String
    var dueLabel: String
    var estimatedMinutes: Int
    var urgency: Double
}

nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
    var generatedAt: Date
    var localeIdentifier: String?
    var todayTasks: [WidgetTaskSnapshot]

    static let empty = WidgetSnapshot(
        generatedAt: Date(timeIntervalSince1970: 0),
        localeIdentifier: nil,
        todayTasks: []
    )
}
