import SwiftData
import SwiftUI

struct PauseModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\PausePeriod.startDate, order: .reverse)])
    private var periods: [PausePeriod]
    @Query(sort: [SortDescriptor(\CleaningTask.nextDueDate), SortDescriptor(\CleaningTask.createdAt)])
    private var tasks: [CleaningTask]

    @State private var showingEditor = false
    @State private var editingPeriod: PausePeriod?
    @State private var errorMessage: String?

    private let service = PauseModeService()

    private var activePeriods: [PausePeriod] {
        periods.filter(\.isActive)
    }

    private var inactivePeriods: [PausePeriod] {
        periods.filter { !$0.isActive }
    }

    var body: some View {
        List {
            Section {
                Button {
                    editingPeriod = nil
                    showingEditor = true
                } label: {
                    Label(L10n.text("pause.start", "休みモードを開始"), systemImage: "pause.circle.fill")
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            pauseSection(
                title: L10n.text("pause.activeSection", "休みモード中"),
                emptyMessage: L10n.text("pause.active.empty", "今は通常どおりです。"),
                periods: activePeriods
            )
            pauseSection(
                title: L10n.text("pause.historySection", "履歴"),
                emptyMessage: L10n.text("pause.history.empty", "まだ履歴はありません。"),
                periods: inactivePeriods
            )
        }
        .cleanCueScrollableBottomInset()
        .navigationTitle(L10n.text("pause.mode", "休みモード"))
        .sheet(isPresented: $showingEditor) {
            PausePeriodEditView(period: editingPeriod) { title, startDate, endDate, reason in
                save(title: title, startDate: startDate, endDate: endDate, reason: reason)
            }
        }
    }

    private func pauseSection(title: String, emptyMessage: String, periods: [PausePeriod]) -> some View {
        Section(title) {
            if periods.isEmpty {
                Text(emptyMessage)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(periods) { period in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(period.title)
                                .font(.headline)
                            Spacer()
                            Text(period.reason.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text("\(period.startDate.cleanCueDayText) - \(period.endDate.cleanCueDayText)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if period.notificationRebuildNeeded {
                            Label(L10n.text("pause.notificationRebuildNeeded", "通知の再構築が必要"), systemImage: "bell.badge")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Button(L10n.text("common.edit", "編集")) {
                                editingPeriod = period
                                showingEditor = true
                            }
                            .buttonStyle(.bordered)

                            if period.isActive {
                                Button(L10n.text("pause.end", "終了")) {
                                    end(period)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func save(title: String, startDate: Date, endDate: Date, reason: PauseReason) {
        do {
            if let editingPeriod {
                try service.updatePausePeriod(
                    editingPeriod,
                    title: title,
                    startDate: startDate,
                    endDate: endDate,
                    reason: reason,
                    in: modelContext
                )
            } else {
                try service.startPause(
                    title: title,
                    startDate: startDate,
                    endDate: endDate,
                    reason: reason,
                    tasks: tasks,
                    in: modelContext
                )
            }
            errorMessage = nil
            showingEditor = false
            rebuildNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func end(_ period: PausePeriod) {
        do {
            try service.endPause(period, in: modelContext)
            errorMessage = nil
            rebuildNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func rebuildNotifications() {
        WidgetUpdateService.refresh(tasks: tasks, pausePeriods: periods)

        Task {
            do {
                try await NotificationScheduler().rebuildNotifications(
                    tasks: tasks,
                    pausePeriods: periods,
                    settings: AppSettingsStore().load()
                )
            } catch {
                // 一時停止中の通知再構築に失敗しても、保存済みの期間はそのまま使う。
            }
        }
    }
}

private struct PausePeriodEditView: View {
    @Environment(\.dismiss) private var dismiss

    let period: PausePeriod?
    let saveAction: (String, Date, Date, PauseReason) -> Void

    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var reason: PauseReason

    init(
        period: PausePeriod?,
        saveAction: @escaping (String, Date, Date, PauseReason) -> Void
    ) {
        self.period = period
        self.saveAction = saveAction
        _title = State(initialValue: period?.title ?? "")
        _startDate = State(initialValue: period?.startDate ?? Date())
        _endDate = State(initialValue: period?.endDate ?? Date())
        _reason = State(initialValue: period?.reason ?? .busy)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.text("pause.period", "期間")) {
                    DatePicker(L10n.text("pause.startDate", "開始日"), selection: $startDate, displayedComponents: .date)
                    DatePicker(L10n.text("pause.endDate", "終了日"), selection: $endDate, displayedComponents: .date)
                }

                Section(L10n.text("pause.reason", "理由")) {
                    Picker(L10n.text("pause.reason", "理由"), selection: $reason) {
                        ForEach(PauseReason.allCases, id: \.self) { reason in
                            Text(reason.displayName).tag(reason)
                        }
                    }
                }

                Section(L10n.text("pause.label", "ラベル")) {
                    TextField(L10n.text("pause.label.placeholder", "例: 旅行"), text: $title)
                }
            }
            .navigationTitle(
                period == nil
                    ? L10n.text("pause.startTitle", "休みモード開始")
                    : L10n.text("pause.editTitle", "休みモード編集")
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("common.cancel", "キャンセル")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("common.save", "保存")) {
                        saveAction(title, startDate, endDate, reason)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PauseModeView()
    }
    .modelContainer(PreviewSampleData.makeContainer())
}
