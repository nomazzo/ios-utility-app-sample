import SwiftUI

struct TaskRowView: View {
    let task: CleaningTask
    private let urgencyCalculator = UrgencyCalculator()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    InlineMetaLabel(
                        text: task.nextDueDate.cleanCueDayText,
                        systemImage: "calendar"
                    )
                    InlineMetaLabel(
                        text: L10n.format("common.minutes", "%d分", task.estimatedMinutes),
                        systemImage: "clock"
                    )
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            Text(urgencyCalculator.urgency(for: task.nextDueDate).state.compactDisplayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(urgencyCalculator.urgency(for: task.nextDueDate).state == .overdue ? .orange : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: Capsule())
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .contentShape(Rectangle())
    }
}

struct TaskScheduleSummaryView: View {
    let task: CleaningTask

    var body: some View {
        HStack(spacing: 10) {
            InlineMetaLabel(
                text: task.nextDueDate.cleanCueDayText,
                systemImage: "calendar"
            )
            InlineMetaLabel(
                text: L10n.format("common.minutes", "%d分", task.estimatedMinutes),
                systemImage: "clock"
            )
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}
