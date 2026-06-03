import Foundation
import WidgetKit

@MainActor
enum WidgetUpdateService {
    static func refresh(
        tasks: [CleaningTask],
        pausePeriods: [PausePeriod]
    ) {
        do {
            try WidgetSnapshotService().saveSnapshot(
                tasks: tasks,
                pausePeriods: pausePeriods
            )
        } catch {
            // Widget更新に失敗しても、メインのタスク操作は止めない。
        }
        requestReload()
    }

    static func requestReload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
