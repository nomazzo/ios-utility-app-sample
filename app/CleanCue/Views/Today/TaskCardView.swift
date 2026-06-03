import SwiftUI

struct TaskCardView: View {
    let task: CleaningTask
    let urgency: UrgencyResult
    let completeAction: () -> Void
    let snoozeAction: () -> Void
    let skipAction: () -> Void
    var showsCompleteHint: Bool = false
    var dismissCompleteHint: () -> Void = {}
    var isSettlingAway: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink {
                TaskDetailView(task: task)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: task.place?.iconName ?? "sparkles")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(placeColor)
                            .frame(width: 30, height: 30)
                            .background(CleanCueTheme.softPlaceFill(hex: task.place?.colorHex), in: Circle())
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(task.place?.name ?? L10n.text("common.noPlace", "場所なし"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(urgency.state.compactDisplayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(urgencyForeground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(urgencyBackground, in: Capsule())
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }

                    HStack(spacing: 12) {
                        InlineMetaLabel(
                            text: L10n.format("common.minutes", "%d分", task.estimatedMinutes),
                            systemImage: "clock"
                        )
                        InlineMetaLabel(
                            text: task.nextDueDate.cleanCueDayText,
                            systemImage: "calendar"
                        )
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                TaskCardActionButton(
                    title: L10n.text("action.markComplete", "完了にする"),
                    systemImage: "checkmark.circle",
                    isProminent: true,
                    accessibilityLabel: L10n.format("accessibility.completeTask", "%@を完了", task.name),
                    action: completeAction
                )

                TaskCardActionButton(
                    title: L10n.text("action.tomorrow", "明日"),
                    systemImage: "sunrise",
                    isProminent: false,
                    accessibilityLabel: L10n.format("accessibility.snoozeTask", "%@を明日にする", task.name),
                    action: snoozeAction
                )

                TaskCardActionButton(
                    title: L10n.text("action.skipThisWeek", "今週スキップ"),
                    systemImage: "forward",
                    isProminent: false,
                    accessibilityLabel: L10n.format("accessibility.skipTask", "%@を今週スキップ", task.name),
                    action: skipAction
                )
            }

            if showsCompleteHint {
                CompleteActionHintBubble(dismissAction: dismissCompleteHint)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 8)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: showsCompleteHint)
        .opacity(isSettlingAway ? 0.45 : 1)
        .scaleEffect(isSettlingAway ? 0.98 : 1, anchor: .center)
        .offset(x: isSettlingAway ? 18 : 0)
        .allowsHitTesting(!isSettlingAway)
        .animation(.easeOut(duration: 0.16), value: isSettlingAway)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(placeColor.opacity(0.24))
                .frame(width: 2)
                .padding(.vertical, 12)
        }
    }

    private var placeColor: Color {
        CleanCueTheme.placeColor(hex: task.place?.colorHex)
    }

    private var urgencyForeground: Color {
        switch urgency.state {
        case .today:
            CleanCueTheme.primaryBlue
        case .overdue:
            CleanCueTheme.warmAttention
        case .soon:
            placeColor
        case .safe:
            CleanCueTheme.secondaryText
        }
    }

    private var urgencyBackground: Color {
        switch urgency.state {
        case .today:
            CleanCueTheme.softBlue
        case .overdue:
            CleanCueTheme.warmAttention.opacity(0.15)
        case .soon:
            CleanCueTheme.softPlaceFill(hex: task.place?.colorHex)
        case .safe:
            Color(.systemGray6)
        }
    }
}

private struct CompleteActionHintBubble: View {
    let dismissAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Triangle()
                .fill(CleanCueTheme.softMint)
                .frame(width: 18, height: 10)
                .padding(.leading, 50)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "hand.tap")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CleanCueTheme.cleanMint)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.text("today.completeHint.title", "掃除が終わったら「完了にする」"))
                        .font(.caption.weight(.bold))
                    Text(L10n.text("today.completeHint.message", "履歴に残り、次の予定日も自動で更新されます。"))
                        .font(.caption2)
                        .foregroundStyle(CleanCueTheme.secondaryText)
                }

                Spacer(minLength: 8)

                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CleanCueTheme.secondaryText)
                        .frame(width: 26, height: 26)
                        .background(Color(.systemBackground).opacity(0.72), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text("common.close", "閉じる"))
            }
            .padding(12)
            .background(CleanCueTheme.softMint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(CleanCueTheme.cleanMint.opacity(0.24), lineWidth: 1)
            }
        }
        .padding(.top, -2)
        .accessibilityElement(children: .combine)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct TaskCardActionButton: View {
    let title: String
    let systemImage: String
    let isProminent: Bool
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .imageScale(.medium)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .allowsTightening(true)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isProminent ? .white : CleanCueTheme.secondaryText)
            .frame(maxWidth: .infinity, minHeight: isProminent ? 36 : 34)
            .padding(.horizontal, 6)
            .background(buttonBackground, in: Capsule())
            .contentShape(Rectangle())
        }
        .buttonStyle(TaskCardPressButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }

    private var buttonBackground: Color {
        isProminent ? CleanCueTheme.cleanMint : Color(.systemGray6).opacity(0.78)
    }
}

private struct TaskCardPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension UrgencyState {
    var gentleDisplayName: String {
        switch self {
        case .safe:
            L10n.text("urgency.safe", "まだ大丈夫")
        case .soon:
            L10n.text("urgency.soon", "そろそろ")
        case .today:
            L10n.text("urgency.today", "今日")
        case .overdue:
            L10n.text("urgency.overdue", "後回し中")
        }
    }

    var compactDisplayName: String {
        switch self {
        case .safe:
            L10n.text("urgency.safe.short", "Later")
        case .soon:
            L10n.text("urgency.soon.short", "Soon")
        case .today:
            L10n.text("urgency.today.short", "Today")
        case .overdue:
            L10n.text("urgency.overdue.short", "Waiting")
        }
    }
}

extension ScheduleKind {
    var shortDisplayName: String {
        switch self {
        case .fixed:
            L10n.text("schedule.fixed.short", "固定")
        case .interval:
            L10n.text("schedule.interval.short", "経過")
        }
    }

    var displayName: String {
        switch self {
        case .fixed:
            L10n.text("schedule.fixed", "固定日")
        case .interval:
            L10n.text("schedule.interval", "経過日")
        }
    }

    var iconName: String {
        switch self {
        case .fixed:
            "calendar.badge.clock"
        case .interval:
            "arrow.triangle.2.circlepath"
        }
    }
}
