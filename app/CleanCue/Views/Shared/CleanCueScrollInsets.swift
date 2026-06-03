import SwiftUI

extension View {
    func cleanCueScrollableBottomInset() -> some View {
        contentMargins(.bottom, 96, for: .scrollContent)
    }
}
