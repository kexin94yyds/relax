import SwiftUI

struct MethodCardView: View {
    let method: BreathingMethod

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(method.color)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(method.name)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)

                    Spacer(minLength: 12)

                    Circle()
                        .fill(method.color)
                        .frame(width: 14, height: 14)
                }

                Text(method.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                FlowLayout(spacing: 8) {
                    DetailPill(text: "吸气: \(method.inhale)秒")
                    if method.hold > 0 {
                        DetailPill(text: "保持: \(method.hold)秒")
                    }
                    DetailPill(text: "呼气: \(method.exhale)秒")
                    DetailPill(text: "循环: \(method.cycles)次")
                }
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct DetailPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color(red: 51 / 255, green: 51 / 255, blue: 51 / 255))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(red: 248 / 255, green: 249 / 255, blue: 250 / 255), in: Capsule())
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if lineWidth > 0 && lineWidth + spacing + size.width > maxWidth {
                totalHeight += lineHeight + spacing
                totalWidth = max(totalWidth, lineWidth)
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += lineWidth == 0 ? size.width : spacing + size.width
                lineHeight = max(lineHeight, size.height)
            }
        }

        totalHeight += lineHeight
        totalWidth = max(totalWidth, lineWidth)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview {
    ZStack {
        Color.indigo
        MethodCardView(method: BreathingMethod.all[0])
            .padding()
    }
}
