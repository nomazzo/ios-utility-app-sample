import SwiftUI

struct CleanCueProgressRing: View {
    let progress: Double
    let label: String
    var size: CGFloat = 68
    var lineWidth: CGFloat = 7
    var tint: Color = CleanCueTheme.cleanMint
    var track: Color = CleanCueTheme.separator

    var body: some View {
        ZStack {
            Circle()
                .stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(.horizontal, 6)
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: progress)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: label)
        .accessibilityLabel(label)
    }
}
