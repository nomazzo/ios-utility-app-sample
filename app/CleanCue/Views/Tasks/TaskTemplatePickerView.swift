import SwiftData
import SwiftUI

struct TaskTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\CleaningTask.nextDueDate), SortDescriptor(\CleaningTask.createdAt)])
    private var allTasks: [CleaningTask]
    @Query(sort: [SortDescriptor(\PausePeriod.startDate, order: .reverse)])
    private var pausePeriods: [PausePeriod]

    let place: Place

    @State private var message: String?
    @State private var toastMessage: String?
    @State private var processingTaskIDs: Set<String> = []
    @State private var addedTaskIDs: Set<String> = []
    @State private var justAddedTaskIDs: Set<String> = []
    @State private var successFeedback = 0
    @State private var warningFeedback = 0
    @State private var showingManualTask = false
    @State private var showingProLimit = false
    @State private var showingProView = false
    @State private var searchText = ""
    @State private var selectedInitialDueChoice: InitialDueDateChoice = .today

    private let provider = PresetProvider.defaultProvider
    private let creationService = PresetCreationService()
    private let settingsStore = AppSettingsStore()
    private let featureGate = FeatureGate()
    private let dueDatePolicy = InitialDueDatePolicy()

    private var sections: [TaskTemplateSection] {
        let baseSections: [TaskTemplateSection]
        if let matchedPlace = creationService.presetPlace(matching: place) {
            baseSections = [
                TaskTemplateSection(
                    place: matchedPlace,
                    tasks: provider.tasks(for: matchedPlace.id)
                )
            ]
        } else {
            baseSections = (provider.places + [provider.homeMaintenancePlace]).map { presetPlace in
                TaskTemplateSection(
                    place: presetPlace,
                    tasks: provider.tasks(for: presetPlace.id)
                )
            }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return baseSections }

        return baseSections.compactMap { section in
            let filteredTasks = section.tasks.filter {
                $0.localizedDisplayName.localizedCaseInsensitiveContains(query) ||
                    section.place.localizedDisplayName.localizedCaseInsensitiveContains(query)
            }
            guard !filteredTasks.isEmpty else { return nil }
            return TaskTemplateSection(place: section.place, tasks: filteredTasks)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let message {
                    Section {
                        Text(message)
                            .foregroundStyle(.secondary)
                    }
                }

                InitialDueDateChoiceInlineSection(
                    title: L10n.text("task.edit.initialDue", "初回予定日"),
                    selection: $selectedInitialDueChoice,
                    allowsSpreadOut: true
                )

                ForEach(sections) { section in
                    Section(section.place.localizedDisplayName) {
                        ForEach(section.tasks) { task in
                            Button {
                                add(task)
                            } label: {
                                TaskTemplateRow(
                                    task: task,
                                    placeColorHex: section.place.colorHex,
                                    isAlreadyAdded: isAlreadyAdded(task),
                                    isProcessing: processingTaskIDs.contains(task.id),
                                    isJustAdded: justAddedTaskIDs.contains(task.id)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(processingTaskIDs.contains(task.id) || isAlreadyAdded(task))
                        }
                    }
                }

                Section {
                    Button {
                        openManualTask()
                    } label: {
                        Label(L10n.text("common.manualAdd", "手入力で追加"), systemImage: "square.and.pencil")
                    }
                }
            }
            .navigationTitle(L10n.text("template.task.title", "掃除を追加"))
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: L10n.text("template.search.prompt", "名前で検索")
            )
            .overlay(alignment: .bottom) {
                if let toastMessage {
                    FeedbackToastView(message: toastMessage)
                        .padding(.bottom, 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.86), value: toastMessage)
            .sensoryFeedback(.success, trigger: successFeedback)
            .sensoryFeedback(.warning, trigger: warningFeedback)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("common.close", "閉じる")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingManualTask) {
                TaskEditView(place: place, allowsPlaceSelection: false)
            }
            .sheet(isPresented: $showingProView) {
                NavigationStack {
                    ProView(
                        settingsStore: settingsStore,
                        dismissAfterUnlockAcknowledgement: true
                    )
                }
            }
            .confirmationDialog(
                L10n.text("pro.limit.tasks", "無料版では20件まで掃除を登録できます。"),
                isPresented: $showingProLimit,
                titleVisibility: .visible
            ) {
                Button(L10n.text("pro.view", "Proを見る")) {
                    showingProView = true
                }
                Button(L10n.text("common.cancel", "キャンセル"), role: .cancel) {}
            } message: {
                Text(L10n.text("pro.limit.tasksMessage", "Proにすると、掃除の数を気にせず使えます。"))
            }
        }
    }

    private func openManualTask() {
        let activeTaskCount = allTasks.filter { !$0.isArchived }.count
        if featureGate.taskLimit(
            currentActiveTaskCount: activeTaskCount,
            settings: settingsStore.load()
        ).isAllowed {
            showingManualTask = true
        } else {
            showingProLimit = true
        }
    }

    private func add(_ presetTask: PresetTask) {
        guard !processingTaskIDs.contains(presetTask.id) else {
            return
        }

        guard !isAlreadyAdded(presetTask) else {
            message = L10n.format(
                "template.task.duplicate",
                "%@はこの場所にすでにあります。",
                presetTask.localizedDisplayName
            )
            warningFeedback += 1
            return
        }

        let activeTaskCount = allTasks.filter { !$0.isArchived }.count
        guard featureGate.taskLimit(
            currentActiveTaskCount: activeTaskCount,
            settings: settingsStore.load()
        ).isAllowed else {
            showingProLimit = true
            warningFeedback += 1
            return
        }

        processingTaskIDs.insert(presetTask.id)
        do {
            let initialDueDate = initialDueDate(forAddedTaskIndex: addedTaskIDs.count)
            let created = try creationService.createPresetTask(
                taskID: presetTask.id,
                place: place,
                initialDueDate: initialDueDate,
                in: modelContext,
                settings: settingsStore.load()
            )
            addedTaskIDs.insert(presetTask.id)
            markJustAdded(presetTask.id)
            processingTaskIDs.remove(presetTask.id)
            let successMessage = L10n.format(
                "template.task.added",
                "%@を追加しました。",
                created.name
            )
            message = successMessage
            showToast(successMessage)
            successFeedback += 1
            rebuildNotifications(tasks: allTasks + [created])
        } catch {
            processingTaskIDs.remove(presetTask.id)
            message = L10n.text("template.task.addFailed", "掃除を追加できませんでした。")
            warningFeedback += 1
        }
    }

    private func initialDueDate(forAddedTaskIndex index: Int) -> Date {
        if selectedInitialDueChoice == .spreadOut {
            return dueDatePolicy.distributedDate(index: index)
        }
        return dueDatePolicy.startDate(for: selectedInitialDueChoice)
    }

    private func isAlreadyAdded(_ presetTask: PresetTask) -> Bool {
        if addedTaskIDs.contains(presetTask.id) {
            return true
        }

        return place.tasks.contains { task in
            !task.isArchived && task.sourcePresetId == presetTask.id
        }
    }

    private func rebuildNotifications(tasks: [CleaningTask]) {
        WidgetUpdateService.refresh(tasks: tasks, pausePeriods: pausePeriods)

        Task {
            do {
                try await NotificationScheduler().rebuildNotifications(
                    tasks: tasks,
                    pausePeriods: pausePeriods,
                    settings: settingsStore.load()
                )
            } catch {
                // 通知権限がなくても、テンプレートからのタスク作成は使えるようにする。
            }
        }
    }

    private func showToast(_ text: String) {
        toastMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if toastMessage == text {
                toastMessage = nil
            }
        }
    }

    private func markJustAdded(_ taskID: String) {
        withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
            _ = justAddedTaskIDs.insert(taskID)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.28)) {
                _ = justAddedTaskIDs.remove(taskID)
            }
        }
    }
}

private struct TaskTemplateSection: Identifiable {
    var place: PresetPlace
    var tasks: [PresetTask]

    var id: String {
        place.id
    }
}

private struct TaskTemplateRow: View {
    let task: PresetTask
    let placeColorHex: String
    let isAlreadyAdded: Bool
    let isProcessing: Bool
    let isJustAdded: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(placeColor.opacity(isAlreadyAdded ? 0.08 : 0.18))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.localizedDisplayName)
                    .font(.body)
                    .foregroundStyle(.primary)
                InlineMetaLabel(
                    text: L10n.format("template.task.minutes", "%d分", task.estimatedMinutes),
                    systemImage: "clock"
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isProcessing {
                ProgressView()
            } else if isAlreadyAdded {
                TemplateStatusBadge(
                    title: L10n.text("template.task.alreadyAdded", "追加済み"),
                    systemImage: "checkmark.circle.fill",
                    isHighlighted: isJustAdded
                )
                .transition(.scale(scale: 0.86).combined(with: .opacity))
            } else {
                Image(systemName: "plus.circle")
                    .foregroundStyle(.tint)
                    .accessibilityLabel(L10n.text("template.add", "追加"))
                    .transition(.scale(scale: 0.86).combined(with: .opacity))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isJustAdded ? CleanCueTheme.softMint.opacity(0.82) : Color.clear)
        )
        .opacity(isAlreadyAdded ? 0.9 : 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isAlreadyAdded)
        .animation(.easeOut(duration: 0.22), value: isJustAdded)
    }

    private var placeColor: Color {
        CleanCueTheme.placeColor(hex: placeColorHex)
    }
}

#Preview {
    NavigationStack {
        TaskTemplatePickerView(place: Place(name: "Kitchen", iconName: "fork.knife", colorHex: "#3A7CA5"))
    }
    .modelContainer(PreviewSampleData.makeContainer())
}
