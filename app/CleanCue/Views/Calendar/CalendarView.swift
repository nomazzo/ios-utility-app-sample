import SwiftData
import SwiftUI

struct CalendarView: View {
    @Query(sort: [SortDescriptor(\CleaningTask.nextDueDate), SortDescriptor(\CleaningTask.createdAt)])
    private var tasks: [CleaningTask]

    @State private var mode: CalendarTaskMode = .today

    private let provider = CalendarTaskProvider()

    private var filteredTasks: [CleaningTask] {
        provider.tasks(for: mode, from: tasks, referenceDate: Date())
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    CalendarModeSelector(selection: $mode)
                }

                if !filteredTasks.isEmpty {
                    Section {
                        CalendarSummaryCard(
                            title: mode.displayName,
                            taskCount: filteredTasks.count,
                            totalMinutes: filteredTasks.reduce(0) { $0 + $1.estimatedMinutes }
                        )
                    }
                }

                Section(mode.displayName) {
                    if filteredTasks.isEmpty {
                        EmptyStateView(
                            title: L10n.text("empty.calendar.title", "表示する予定はありません"),
                            message: L10n.text("empty.calendar.message", "条件を変えると、別の日の予定を確認できます。"),
                            systemImage: "calendar"
                        )
                    } else {
                        ForEach(filteredTasks) { task in
                            NavigationLink {
                                TaskDetailView(task: task)
                            } label: {
                                calendarTaskRow(task)
                            }
                        }
                    }
                }
            }
            .cleanCueScrollableBottomInset()
            .navigationTitle(L10n.text("calendar.title", "カレンダー"))
        }
    }

    private func calendarTaskRow(_ task: CleaningTask) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(task.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(task.place?.name ?? L10n.text("common.noPlace", "場所なし"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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

            let badge = statusBadge(for: task)
            Text(badge.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(badge.foreground)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badge.background, in: Capsule())
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(for task: CleaningTask) -> (title: String, foreground: Color, background: Color) {
        if let lastCompletedAt = task.lastCompletedAt,
           Calendar.current.isDate(lastCompletedAt, inSameDayAs: task.nextDueDate) {
            return (
                L10n.text("calendar.status.completed", "完了済み"),
                CleanCueTheme.cleanMint,
                CleanCueTheme.softMint
            )
        }

        let calendar = Calendar.current
        let referenceDate = Date()
        let today = calendar.startOfDay(for: referenceDate)
        let dueDay = calendar.startOfDay(for: task.nextDueDate)

        if dueDay < today {
            return (
                L10n.text("urgency.overdue.short", "Waiting"),
                .orange,
                Color.orange.opacity(0.14)
            )
        }

        if calendar.isDate(task.nextDueDate, inSameDayAs: referenceDate) {
            return (
                L10n.text("urgency.today.short", "Today"),
                CleanCueTheme.primaryBlue,
                CleanCueTheme.softBlue
            )
        }

        return (
            L10n.text("calendar.status.scheduled", "予定"),
            .secondary,
            Color(.systemGray6)
        )
    }
}

private struct CalendarSummaryCard: View {
    let title: String
    let taskCount: Int
    let totalMinutes: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.title3.weight(.semibold))
                .foregroundStyle(CleanCueTheme.primaryBlue)
                .frame(width: 42, height: 42)
                .background(CleanCueTheme.softBlue, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(summaryTitle)
                    .font(.headline)
                Text(summaryDetail)
                    .font(.subheadline)
                    .foregroundStyle(CleanCueTheme.secondaryText)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var summaryTitle: String {
        let displayTitle = L10n.isDutch || L10n.isSwedish || L10n.isDanish || L10n.isNorwegianBokmal || L10n.isSpanish || L10n.isPortuguese || L10n.isItalian
            ? title.localizedLowercase
            : title
        return L10n.format("calendar.summary.title", "%@の予定", displayTitle)
    }

    private var summaryDetail: String {
        if L10n.isDutch {
            let taskLabel = taskCount == 1 ? "taak" : "taken"
            return "\(taskCount) \(taskLabel) · \(totalMinutes) min"
        }
        if L10n.isDanish {
            let taskLabel = taskCount == 1 ? "opgave" : "opgaver"
            return "\(taskCount) \(taskLabel) · \(totalMinutes) min"
        }
        if L10n.isNorwegianBokmal {
            let taskLabel = taskCount == 1 ? "oppgave" : "oppgaver"
            return "\(taskCount) \(taskLabel) · \(totalMinutes) min"
        }
        if L10n.isSpanish {
            let taskLabel = taskCount == 1 ? "tarea" : "tareas"
            return "\(taskCount) \(taskLabel) · \(totalMinutes) min"
        }
        if L10n.isPortuguese {
            let taskLabel = taskCount == 1 ? "tarefa" : "tarefas"
            return "\(taskCount) \(taskLabel) · \(totalMinutes) min"
        }
        if L10n.isItalian {
            return "\(taskCount) attività · \(totalMinutes) min"
        }
        return L10n.format("calendar.summary.detail", "%d件・%d分", taskCount, totalMinutes)
    }
}

private struct CalendarModeSelector: View {
    @Binding var selection: CalendarTaskMode

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CalendarTaskMode.allCases, id: \.self) { mode in
                    Button {
                        selection = mode
                    } label: {
                        Text(mode.compactDisplayName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(selection == mode ? .white : .primary)
                            .background(
                                selection == mode ? Color.accentColor : Color.secondary.opacity(0.13),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(selection == mode ? L10n.text("common.selected", "選択中") : "")
                }
            }
            .padding(.vertical, 2)
        }
        .accessibilityLabel(L10n.text("calendar.modePicker", "表示"))
    }
}

extension CalendarTaskMode {
    var displayName: String {
        switch self {
        case .today:
            L10n.text("calendar.mode.today", "今日")
        case .tomorrow:
            L10n.text("calendar.mode.tomorrow", "明日")
        case .thisWeek:
            L10n.text("calendar.mode.thisWeek", "今週")
        case .thisMonth:
            L10n.text("calendar.mode.thisMonth", "今月")
        case .overdue:
            L10n.text("urgency.overdue", "後回し中")
        }
    }

    var compactDisplayName: String {
        switch self {
        case .today:
            L10n.text("calendar.mode.today", "今日")
        case .tomorrow:
            L10n.text("calendar.mode.tomorrow", "明日")
        case .thisWeek:
            L10n.text("calendar.mode.week.short", "Week")
        case .thisMonth:
            L10n.text("calendar.mode.month.short", "Month")
        case .overdue:
            L10n.text("calendar.mode.waiting.short", "Waiting")
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(PreviewSampleData.makeContainer())
}
