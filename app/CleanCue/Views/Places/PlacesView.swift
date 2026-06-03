import SwiftData
import SwiftUI

struct PlacesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Place.orderIndex), SortDescriptor(\Place.createdAt)])
    private var places: [Place]

    let resetToken: Int

    @State private var navigationPath = NavigationPath()
    @State private var showingTemplatePlaces = false

    init(resetToken: Int = 0) {
        self.resetToken = resetToken
    }

    private var activePlaces: [Place] {
        places.filter { !$0.isArchived }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if activePlaces.isEmpty {
                    List {
                        Section {
                            EmptyStateView(
                                title: L10n.text("empty.places.title", "場所がまだありません"),
                                message: L10n.text("empty.places.message", "キッチンや浴室など、掃除したい場所を追加しましょう。"),
                                systemImage: "house"
                            )
                        }
                    }
                    .cleanCueScrollableBottomInset()
                } else {
                    List {
                        ForEach(activePlaces) { place in
                            NavigationLink(value: place) {
                                PlaceRow(place: place)
                            }
                        }
                        .onDelete(perform: deletePlaces)
                    }
                    .cleanCueScrollableBottomInset()
                }
            }
            .navigationTitle(L10n.text("places.title", "場所"))
            .navigationDestination(for: Place.self) { place in
                PlaceDetailView(place: place)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingTemplatePlaces = true
                    } label: {
                        Label(L10n.text("places.add", "場所を追加"), systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingTemplatePlaces) {
                PlaceTemplatePickerView()
            }
            .onChange(of: resetToken) {
                navigationPath = NavigationPath()
                showingTemplatePlaces = false
            }
        }
    }

    private func deletePlaces(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(activePlaces[index])
        }
        try? modelContext.save()
    }
}

private struct PlaceRow: View {
    let place: Place

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: place.iconName)
                .font(.body.weight(.semibold))
                .frame(width: 40, height: 40)
                .foregroundStyle(placeColor)
                .background(placeColor.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(place.name)
                    .font(.body)

                Text(summaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let statusBadge {
                Text(statusBadge.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusBadge.foreground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusBadge.background, in: Capsule())
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var activeTaskCount: Int {
        activeTasks.count
    }

    private var activeTasks: [CleaningTask] {
        place.tasks.filter { !$0.isArchived }
    }

    private var nextTask: CleaningTask? {
        activeTasks.min { $0.nextDueDate < $1.nextDueDate }
    }

    private var summaryText: String {
        let nextText = nextTask.map { nextLabel(for: $0.nextDueDate) }
            ?? L10n.text("places.next.none", "予定なし")
        if L10n.isDutch {
            let taskLabel = activeTaskCount == 1 ? "taak" : "taken"
            return "\(activeTaskCount) \(taskLabel) · Volgende: \(nextText)"
        }
        if L10n.isDanish {
            let taskLabel = activeTaskCount == 1 ? "opgave" : "opgaver"
            return "\(activeTaskCount) \(taskLabel) · Næste: \(nextText)"
        }
        if L10n.isNorwegianBokmal {
            let taskLabel = activeTaskCount == 1 ? "oppgave" : "oppgaver"
            return "\(activeTaskCount) \(taskLabel) · Neste: \(nextText)"
        }
        if L10n.isSpanish {
            let taskLabel = activeTaskCount == 1 ? "tarea" : "tareas"
            return "\(activeTaskCount) \(taskLabel) · Siguiente: \(nextText)"
        }
        if L10n.isPortuguese {
            let taskLabel = activeTaskCount == 1 ? "tarefa" : "tarefas"
            return "\(activeTaskCount) \(taskLabel) · Próxima: \(nextText)"
        }
        if L10n.isItalian {
            return "\(activeTaskCount) attività · Prossima: \(nextText)"
        }
        return L10n.format("places.summary", "%d件・次回 %@", activeTaskCount, nextText)
    }

    private var statusBadge: (title: String, foreground: Color, background: Color)? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let overdueCount = activeTasks.filter { calendar.startOfDay(for: $0.nextDueDate) < today }.count
        if overdueCount > 0 {
            return (
                L10n.format("places.badge.waiting", "後回し %d", overdueCount),
                .orange,
                Color.orange.opacity(0.14)
            )
        }

        let todayCount = activeTasks.filter {
            calendar.isDate($0.nextDueDate, inSameDayAs: Date())
        }.count
        if todayCount > 0 {
            return (
                L10n.format("places.badge.today", "今日 %d", todayCount),
                CleanCueTheme.primaryBlue,
                CleanCueTheme.softBlue
            )
        }

        return nil
    }

    private var placeColor: Color {
        CleanCueTheme.color(hex: place.colorHex)
    }

    private func nextLabel(for date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: date)

        if dueDay < today {
            return L10n.text("urgency.overdue.short", "Waiting")
        }

        if calendar.isDate(date, inSameDayAs: Date()) {
            return L10n.text("urgency.today.short", "Today")
        }

        return date.cleanCueDayText
    }
}
