import SwiftUI

struct FeedbackToastView: View {
    let message: String
    var systemImage: String = "checkmark.circle.fill"

    var body: some View {
        Label(message, systemImage: systemImage)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.primary.opacity(0.86), in: Capsule())
            .shadow(color: .black.opacity(0.16), radius: 10, y: 4)
            .accessibilityLabel(message)
    }
}
