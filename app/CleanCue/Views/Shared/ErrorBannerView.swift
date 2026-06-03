import SwiftUI

struct ErrorBannerView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.footnote)
            .foregroundStyle(.red)
            .padding(.vertical, 4)
            .accessibilityLabel(message)
    }
}
