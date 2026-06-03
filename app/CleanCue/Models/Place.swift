import Foundation
import SwiftData

@Model
final class Place {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var orderIndex: Int
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CleaningTask.place)
    var tasks: [CleaningTask]

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "house",
        colorHex: String = "#4A90E2",
        orderIndex: Int = 0,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.orderIndex = orderIndex
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tasks = []
    }
}
