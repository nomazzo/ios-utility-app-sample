import SwiftUI

struct TemplateStatusBadge: View {
    let title: String
    let systemImage: String
    var isHighlighted = false

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isHighlighted ? CleanCueTheme.cleanMint : CleanCueTheme.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isHighlighted ? CleanCueTheme.softMint : Color(.systemGray6), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        isHighlighted ? CleanCueTheme.cleanMint.opacity(0.22) : Color.clear,
                        lineWidth: 1
                    )
            }
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .scaleEffect(isHighlighted ? 1.02 : 1)
            .accessibilityLabel(title)
    }
}
