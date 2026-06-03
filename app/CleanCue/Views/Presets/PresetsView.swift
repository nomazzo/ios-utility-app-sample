import SwiftData
import SwiftUI

struct PresetsView: View {
    var body: some View {
        PlaceTemplatePickerView()
    }
}

#Preview {
    PresetsView()
        .modelContainer(PreviewSampleData.makeContainer())
}
