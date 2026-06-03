import SwiftUI

struct InitialDueDateChoicePicker: View {
    @Binding var selection: InitialDueDateChoice
    var allowsSpreadOut = false

    private var choices: [InitialDueDateChoice] {
        InitialDueDateChoice.allCases.filter { allowsSpreadOut || $0 != .spreadOut }
    }

    var body: some View {
        WrappingHStack(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(choices) { choice in
                Button {
                    selection = choice
                } label: {
                    Text(choice.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 9)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selection == choice ? CleanCueTheme.primaryBlue.opacity(0.16) : Color(.secondarySystemGroupedBackground))
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(selection == choice ? CleanCueTheme.primaryBlue : .primary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct InitialDueDateChoiceInlineSection: View {
    let title: String
    @Binding var selection: InitialDueDateChoice
    var allowsSpreadOut = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            InitialDueDateChoicePicker(selection: $selection, allowsSpreadOut: allowsSpreadOut)
        }
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 8, leading: 38, bottom: 18, trailing: 38))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

private struct WrappingHStack: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        layout(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let rows = layout(in: bounds.width, subviews: subviews).rows
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    private func layout(in maxWidth: CGFloat, subviews: Subviews) -> (rows: [Row], size: CGSize) {
        let availableWidth = max(maxWidth, 1)
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let nextWidth = current.items.isEmpty
                ? size.width
                : current.width + horizontalSpacing + size.width

            if !current.items.isEmpty, nextWidth > availableWidth {
                rows.append(current)
                current = Row()
            }

            current.items.append(RowItem(index: index, size: size))
            current.width = current.items.count == 1 ? size.width : current.width + horizontalSpacing + size.width
            current.height = max(current.height, size.height)
        }

        if !current.items.isEmpty {
            rows.append(current)
        }

        let height = rows.enumerated().reduce(CGFloat.zero) { partial, element in
            partial + element.element.height + (element.offset == rows.count - 1 ? 0 : verticalSpacing)
        }
        let width = rows.map(\.width).max() ?? 0
        return (rows, CGSize(width: min(width, availableWidth), height: height))
    }

    private struct Row {
        var items: [RowItem] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private struct RowItem {
        let index: Int
        let size: CGSize
    }
}
