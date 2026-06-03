import Foundation
import SwiftData

@Model
final class PausePeriod {
    @Attribute(.unique) var id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var reasonRaw: String
    var isActive: Bool
    var notificationRebuildNeeded: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        reason: PauseReason,
        isActive: Bool = true,
        notificationRebuildNeeded: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.reasonRaw = reason.rawValue
        self.isActive = isActive
        self.notificationRebuildNeeded = notificationRebuildNeeded
        self.createdAt = createdAt
    }

    var reason: PauseReason {
        get { PauseReason(rawValue: reasonRaw) ?? .other }
        set { reasonRaw = newValue.rawValue }
    }
}
