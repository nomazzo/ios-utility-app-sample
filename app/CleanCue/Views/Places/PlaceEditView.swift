import SwiftData
import SwiftUI

struct PlaceEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Place.orderIndex), SortDescriptor(\Place.createdAt)])
    private var places: [Place]

    private let place: Place?
    private let nextOrderIndex: Int

    @State private var name: String
    @State private var iconName: String
    @State private var colorHex: String
    @State private var validationMessage: String?

    init(place: Place? = nil, nextOrderIndex: Int = 0) {
        self.place = place
        self.nextOrderIndex = nextOrderIndex
        _name = State(initialValue: place?.name ?? "")
        _iconName = State(initialValue: place?.iconName ?? "house")
        _colorHex = State(initialValue: place?.colorHex ?? "#4A90E2")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.text("place.edit.name", "名前"), text: $name)
                    TextField(L10n.text("place.edit.icon", "アイコン"), text: $iconName)
                        .textInputAutocapitalization(.never)
                    TextField(L10n.text("place.edit.colorHex", "カラーコード"), text: $colorHex)
                        .textInputAutocapitalization(.never)
                }

                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(place == nil ? L10n.text("place.edit.newTitle", "場所を追加") : L10n.text("place.edit.editTitle", "場所を編集"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("common.cancel", "キャンセル")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("common.save", "保存")) {
                        save()
                    }
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = L10n.text("place.edit.error.nameRequired", "名前を入力してください。")
            return
        }

        guard !isDuplicateName(trimmedName) else {
            validationMessage = L10n.text("place.edit.error.duplicateName", "同じ名前の場所がすでにあります。")
            return
        }

        if let place {
            place.name = trimmedName
            place.iconName = iconName.isEmpty ? "house" : iconName
            place.colorHex = colorHex.isEmpty ? "#4A90E2" : colorHex
            place.updatedAt = Date()
        } else {
            let newPlace = Place(
                name: trimmedName,
                iconName: iconName.isEmpty ? "house" : iconName,
                colorHex: colorHex.isEmpty ? "#4A90E2" : colorHex,
                orderIndex: nextOrderIndex
            )
            modelContext.insert(newPlace)
        }

        try? modelContext.save()
        dismiss()
    }

    private func isDuplicateName(_ candidate: String) -> Bool {
        let normalizedCandidate = normalized(candidate)
        return places.contains { existingPlace in
            guard !existingPlace.isArchived else { return false }
            if let place, existingPlace.id == place.id {
                return false
            }
            return normalized(existingPlace.name) == normalizedCandidate
        }
    }

    private func normalized(_ string: String) -> String {
        string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
