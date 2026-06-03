import SwiftData

enum CleanCueSchema {
    static let models: [any PersistentModel.Type] = [
        Place.self,
        CleaningTask.self,
        CompletionLog.self,
        PausePeriod.self
    ]
}
