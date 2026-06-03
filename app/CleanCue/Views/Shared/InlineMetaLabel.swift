import SwiftUI

struct InlineMetaLabel: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label {
            Text(text)
                .lineLimit(1)
        } icon: {
            Image(systemName: systemImage)
                .imageScale(.small)
        }
        .labelStyle(.titleAndIcon)
        .accessibilityElement(children: .combine)
    }
}
