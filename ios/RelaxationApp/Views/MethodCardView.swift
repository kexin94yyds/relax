import SwiftUI

struct MethodCardView: View {
    let method: BreathingMethod
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(String(format: "%02d", index))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(RelaxationTheme.mutedInk)
                .frame(width: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    Text(method.name)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(RelaxationTheme.ink)
                        .lineLimit(2)

                    Spacer(minLength: 12)

                    Text(rhythmText)
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(RelaxationTheme.ink)
                        .lineLimit(1)
                }

                Text(method.description)
                    .font(.system(size: 14))
                    .foregroundStyle(RelaxationTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Text("\(method.cycles) 轮")
                    Text("\(method.totalDuration / 60) 分 \(method.totalDuration % 60) 秒")
                }
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(RelaxationTheme.mutedInk)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RelaxationTheme.mutedInk)
                .padding(.top, 4)
        }
        .padding(.vertical, 20)
        .contentShape(Rectangle())
    }

    private var rhythmText: String {
        if method.hold > 0 {
            return "\(method.inhale) · \(method.hold) · \(method.exhale)"
        }
        return "\(method.inhale) · \(method.exhale)"
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
    VStack {
        MethodCardView(method: BreathingMethod.all[0], index: 1)
        Divider()
        MethodCardView(method: BreathingMethod.all[1], index: 2)
    }
    .padding()
    .background(RelaxationTheme.paper)
}
