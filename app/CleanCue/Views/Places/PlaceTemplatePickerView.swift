import SwiftData
import SwiftUI

struct PlaceTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Place.orderIndex), SortDescriptor(\Place.createdAt)])
    private var places: [Place]

    @State private var message: String?
    @State private var toastMessage: String?
    @State private var processingTemplateIDs: Set<String> = []
    @State private var addedTemplateIDs: Set<String> = []
    @State private var justAddedTemplateIDs: Set<String> = []
    @State private var successFeedback = 0
    @State private var warningFeedback = 0
    @State private var showingManualPlace = false
    @State private var showingProLimit = false
    @State private var showingProView = false
    @State private var searchText = ""

    private let provider = PresetProvider.defaultProvider
    private let creationService = PresetCreationService()
    private let settingsStore = AppSettingsStore()
    private let featureGate = FeatureGate()

    private var activePlaces: [Place] {
        places.filter { !$0.isArchived }
    }

    private var templates: [PresetPlace] {
        provider.places + [provider.homeMaintenancePlace]
    }

    private var filteredTemplates: [PresetPlace] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return templates }

        return templates.filter { template in
            template.localizedDisplayName.localizedCaseInsensitiveContains(query) ||
                provider.tasks(for: template.id).contains {
                    $0.localizedDisplayName.localizedCaseInsensitiveContains(query)
                }
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

                Section {
                    ForEach(filteredTemplates) { template in
                        Button {
                            add(template)
                        } label: {
                            PlaceTemplateRow(
                                template: template,
                                taskNames: provider.tasks(for: template.id).prefix(3).map(\.localizedDisplayName),
                                isAlreadyAdded: isAlreadyAdded(template),
                                isProcessing: processingTemplateIDs.contains(template.id),
                                isJustAdded: justAddedTemplateIDs.contains(template.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(processingTemplateIDs.contains(template.id) || isAlreadyAdded(template))
                    }
                } header: {
                    Text(L10n.text("template.place.section", "場所"))
                } footer: {
                    Text(L10n.text("template.place.footer", "ここでは場所だけを追加します。掃除は追加した場所の中から選べます。"))
                }

                Section {
                    Button {
                        openManualPlace()
                    } label: {
                        Label(L10n.text("common.manualAdd", "手入力で追加"), systemImage: "square.and.pencil")
                    }
                }
            }
            .navigationTitle(L10n.text("template.place.title", "場所を追加"))
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
            .sheet(isPresented: $showingManualPlace) {
                PlaceEditView(nextOrderIndex: places.count)
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
                L10n.text("pro.limit.places", "無料版では3個まで場所を登録できます。"),
                isPresented: $showingProLimit,
                titleVisibility: .visible
            ) {
                Button(L10n.text("pro.view", "Proを見る")) {
                    showingProView = true
                }
                Button(L10n.text("common.cancel", "キャンセル"), role: .cancel) {}
            } message: {
                Text(L10n.text("pro.limit.placesMessage", "Proにすると、場所の数を気にせず使えます。"))
            }
        }
    }

    private func isAlreadyAdded(_ template: PresetPlace) -> Bool {
        addedTemplateIDs.contains(template.id)
            || creationService.existingPresetPlace(
                placeID: template.id,
                existingPlaces: activePlaces
            ) != nil
    }

    private func openManualPlace() {
        if featureGate.placeLimit(
            currentActivePlaceCount: activePlaces.count,
            settings: settingsStore.load()
        ).isAllowed {
            showingManualPlace = true
        } else {
            showingProLimit = true
        }
    }

    private func add(_ template: PresetPlace) {
        guard !processingTemplateIDs.contains(template.id) else {
            return
        }

        if isAlreadyAdded(template) {
            message = L10n.format(
                "template.place.duplicate",
                "%@はすでにあります。場所を開いて掃除を追加してください。",
                template.localizedDisplayName
            )
            warningFeedback += 1
            return
        }

        guard featureGate.placeLimit(
            currentActivePlaceCount: activePlaces.count,
            settings: settingsStore.load()
        ).isAllowed else {
            showingProLimit = true
            warningFeedback += 1
            return
        }

        processingTemplateIDs.insert(template.id)
        do {
            let created = try creationService.createPresetPlace(
                placeID: template.id,
                existingPlaceCount: places.count,
                existingPlaces: activePlaces,
                in: modelContext
            )
            addedTemplateIDs.insert(template.id)
            markJustAdded(template.id)
            processingTemplateIDs.remove(template.id)
            let successMessage = L10n.format(
                "template.place.added",
                "%@を追加しました。",
                created.name
            )
            message = successMessage
            showToast(successMessage)
            successFeedback += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                dismiss()
            }
        } catch PresetCreationError.duplicatePresetPlace {
            processingTemplateIDs.remove(template.id)
            message = L10n.format(
                "template.place.duplicate",
                "%@はすでにあります。場所を開いて掃除を追加してください。",
                template.localizedDisplayName
            )
            warningFeedback += 1
        } catch {
            processingTemplateIDs.remove(template.id)
            message = L10n.text("template.place.addFailed", "場所を追加できませんでした。")
            warningFeedback += 1
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

    private func markJustAdded(_ templateID: String) {
        withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
            _ = justAddedTemplateIDs.insert(templateID)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.28)) {
                _ = justAddedTemplateIDs.remove(templateID)
            }
        }
    }
}

private struct PlaceTemplateRow: View {
    let template: PresetPlace
    let taskNames: [String]
    let isAlreadyAdded: Bool
    let isProcessing: Bool
    let isJustAdded: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: template.iconName)
                .font(.body.weight(.semibold))
                .frame(width: 34, height: 34)
                .foregroundStyle(templateColor)
                .background(templateColor.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(template.localizedDisplayName)
                    .font(.body)
                    .foregroundStyle(.primary)
                if taskNames.isEmpty {
                    Text(L10n.text("template.place.noTasks", "掃除テンプレートなし"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(taskNames.joined(separator: " / "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isProcessing {
                ProgressView()
            } else if isAlreadyAdded {
                TemplateStatusBadge(
                    title: L10n.text("template.place.alreadyAdded", "追加済み"),
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

    private var templateColor: Color {
        CleanCueTheme.placeColor(hex: template.colorHex)
    }
}

#Preview {
    PlaceTemplatePickerView()
        .modelContainer(PreviewSampleData.makeContainer())
}
