import Foundation
import SwiftData

enum PreviewSampleData {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    static var referenceDate: Date {
        calendar.date(from: DateComponents(year: 2026, month: 5, day: 21)) ?? Date()
    }

    @MainActor
    static func makeContainer() -> ModelContainer {
        let schema = Schema(CleanCueSchema.models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])

        let kitchen = Place(name: "Kitchen", iconName: "fork.knife", colorHex: "#4A90E2", orderIndex: 0)
        let bathroom = Place(name: "Bathroom", iconName: "shower", colorHex: "#6BCB77", orderIndex: 1)

        let sinkTask = CleaningTask(
            name: "Sink reset",
            place: kitchen,
            nextDueDate: referenceDate,
            scheduleKind: .interval,
            intervalRule: IntervalRule(value: 3, unit: .day),
            estimatedMinutes: 5
        )

        let drainTask = CleaningTask(
            name: "Drain clean",
            place: bathroom,
            nextDueDate: calendar.date(byAdding: .day, value: 2, to: referenceDate) ?? referenceDate,
            scheduleKind: .fixed,
            fixedRule: FixedRule(type: .weekly, weekdays: [5]),
            estimatedMinutes: 10
        )

        container.mainContext.insert(kitchen)
        container.mainContext.insert(bathroom)
        container.mainContext.insert(sinkTask)
        container.mainContext.insert(drainTask)

        return container
    }
}
