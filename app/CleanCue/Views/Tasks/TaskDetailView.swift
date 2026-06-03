import SwiftData
import SwiftUI

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CleaningTask.nextDueDate), SortDescriptor(\CleaningTask.createdAt)])
    private var allTasks: [CleaningTask]
    @Query(sort: [SortDescriptor(\PausePeriod.startDate, order: .reverse)])
    private var pausePeriods: [PausePeriod]

    let task: CleaningTask

    @State private var showingEditTask = false
    @State private var showingArchiveConfirmation = false
    @State private var errorMessage: String?

    private let urgencyCalculator = UrgencyCalculator()

    private var sortedLogs: [CompletionLog] {
        task.logs.sorted { $0.completedAt > $1.completedAt }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.name)
                        .font(.title2.weight(.semibold))
                    InlineMetaLabel(
                        text: task.place?.name ?? L10n.text("common.noPlace", "場所なし"),
                        systemImage: "house"
                    )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                detailRow(L10n.text("task.detail.status", "状態"), urgencyCalculator.urgency(for: task.nextDueDate).state.gentleDisplayName)
                detailRow(L10n.text("task.detail.nextDue", "次回"), task.nextDueDate.cleanCueDayText)
                detailRow(L10n.text("task.detail.schedule", "予定"), task.scheduleSummary)
                detailRow(L10n.text("task.detail.estimate", "目安"), L10n.format("common.minutes", "%d分", task.estimatedMinutes))
                detailRow(L10n.text("task.detail.priority", "優先度"), task.priority.displayName)
                detailRow(L10n.text("task.detail.notification", "通知"), notificationSummary)

                if let lastCompletedAt = task.lastCompletedAt {
                    detailRow(L10n.text("task.detail.lastCompleted", "前回"), lastCompletedAt.cleanCueDayText)
                }
            }

            if !task.tools.isEmpty || !task.note.isEmpty {
                Section(L10n.text("task.detail.notes", "メモ")) {
                    if !task.tools.isEmpty {
                        detailRow(L10n.text("task.detail.tools", "道具"), task.tools)
                    }
                    if !task.note.isEmpty {
                        Text(task.note)
                    }
                }
            }

            Section(L10n.text("task.detail.actions", "操作")) {
                Button {
                    completeTask()
                } label: {
                    Label(L10n.text("action.complete", "完了"), systemImage: "checkmark.circle")
                }

                Button(
                    task.isArchived
                        ? L10n.text("task.restore", "掃除を戻す")
                        : L10n.text("task.archive", "掃除をアーカイブ"),
                    systemImage: task.isArchived ? "arrow.uturn.backward" : "archivebox"
                ) {
                    task.isArchived.toggle()
                    task.updatedAt = Date()
                    try? modelContext.save()
                    rebuildNotifications()
                    if task.isArchived {
                        dismiss()
                    }
                }

                Button(L10n.text("task.delete", "掃除を削除"), systemImage: "trash", role: .destructive) {
                    showingArchiveConfirmation = true
                }
            }

            Section(L10n.text("task.detail.logs", "履歴")) {
                if sortedLogs.isEmpty {
                    Text(L10n.text("empty.taskLogs.message", "完了履歴はまだありません。"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedLogs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.completedAt.cleanCueDayText)
                            if let originalDueDate = log.originalDueDate {
                                InlineMetaLabel(
                                    text: originalDueDate.cleanCueDayText,
                                    systemImage: "calendar"
                                )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .contentMargins(.bottom, 24, for: .scrollContent)
        .navigationTitle(L10n.text("task.detail.title", "掃除"))
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditTask = true
                } label: {
                    Label(L10n.text("common.edit", "編集"), systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEditTask) {
            TaskEditView(task: task, place: task.place)
        }
        .confirmationDialog(
            L10n.text("task.delete.confirmTitle", "この掃除を削除しますか？"),
            isPresented: $showingArchiveConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.text("task.delete", "掃除を削除"), role: .destructive) {
                modelContext.delete(task)
                try? modelContext.save()
                rebuildNotifications()
                dismiss()
            }
            Button(L10n.text("common.cancel", "キャンセル"), role: .cancel) {}
        }
    }

    private func completeTask() {
        do {
            try TaskActionService().complete(task: task, in: modelContext)
            errorMessage = nil
            rebuildNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func rebuildNotifications() {
        WidgetUpdateService.refresh(tasks: allTasks, pausePeriods: pausePeriods)

        Task {
            do {
                try await NotificationScheduler().rebuildNotifications(
                    tasks: allTasks,
                    pausePeriods: pausePeriods,
                    settings: AppSettingsStore().load()
                )
            } catch {
                // 通知再構築に失敗しても、タスク詳細の操作結果は保持する。
            }
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }

    private var notificationSummary: String {
        guard task.reminderEnabled else {
            return L10n.text("task.detail.notificationOff", "オフ")
        }

        let time = Calendar.current.date(
            from: DateComponents(
                hour: task.reminderTimeMinutes / 60,
                minute: task.reminderTimeMinutes % 60
            )
        )?.cleanCueTimeText ?? "\(task.reminderTimeMinutes / 60):\(String(format: "%02d", task.reminderTimeMinutes % 60))"

        return "\(task.reminderStyle.displayName) \(time)"
    }
}
