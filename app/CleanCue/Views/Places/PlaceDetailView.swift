import SwiftData
import SwiftUI

struct PlaceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let place: Place

    @State private var showingEditPlace = false
    @State private var showingTaskTemplates = false
    @State private var showingDeleteConfirmation = false

    private var activeTasks: [CleaningTask] {
        place.tasks
            .filter { !$0.isArchived }
            .sorted { lhs, rhs in
                if lhs.nextDueDate == rhs.nextDueDate {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.nextDueDate < rhs.nextDueDate
            }
    }

    private var archivedTasks: [CleaningTask] {
        place.tasks
            .filter(\.isArchived)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: place.iconName)
                        .font(.title2)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading) {
                        Text(place.name)
                            .font(.headline)
                        InlineMetaLabel(
                            text: L10n.format("places.activeTaskCount.short", "%d", activeTasks.count),
                            systemImage: "checklist"
                        )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(L10n.text("tasks.section.active", "掃除")) {
                if activeTasks.isEmpty {
                    EmptyStateView(
                        title: L10n.text("empty.placeTasks.title", "掃除はまだありません"),
                        message: L10n.text("empty.placeTasks.message", "よくある掃除から追加できます。"),
                        systemImage: "checklist"
                    )
                } else {
                    ForEach(activeTasks) { task in
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            TaskRowView(task: task)
                        }
                    }
                }
            }

            if !archivedTasks.isEmpty {
                Section(L10n.text("tasks.section.archived", "アーカイブ")) {
                    ForEach(archivedTasks) { task in
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            TaskRowView(task: task)
                                .opacity(0.6)
                        }
                    }
                }
            }
        }
        .cleanCueScrollableBottomInset()
        .navigationTitle(place.name)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingTaskTemplates = true
                } label: {
                    Label(L10n.text("addTask.title", "掃除を追加"), systemImage: "plus")
                }

                Menu {
                    Button(L10n.text("places.edit", "場所を編集"), systemImage: "pencil") {
                        showingEditPlace = true
                    }
                    Button(L10n.text("places.delete", "場所を削除"), systemImage: "trash", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditPlace) {
            PlaceEditView(place: place)
        }
        .sheet(isPresented: $showingTaskTemplates) {
            TaskTemplatePickerView(place: place)
        }
        .confirmationDialog(
            L10n.text("places.delete.confirmTitle", "この場所を削除しますか？"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.text("places.delete.confirmAction", "場所と掃除を削除"), role: .destructive) {
                modelContext.delete(place)
                try? modelContext.save()
                dismiss()
            }
            Button(L10n.text("common.cancel", "キャンセル"), role: .cancel) {}
        } message: {
            Text(L10n.text("places.delete.confirmMessage", "この場所の掃除も一緒に削除されます。"))
        }
    }
}
