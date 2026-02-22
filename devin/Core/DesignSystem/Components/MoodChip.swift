import SwiftUI

struct MoodChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    private var chipColor: Color {
        switch label.lowercased() {
        case "good sleep": DevineTheme.Colors.successAccent
        case "hydrated": Color(lightHex: 0x4DA6D9, darkHex: 0x6BBCE8)
        case "low energy": DevineTheme.Colors.warningAccent
        case "high stress": DevineTheme.Colors.errorAccent
        case "puffy eyes": DevineTheme.Colors.ctaSecondary
        default: DevineTheme.Colors.ctaPrimary
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DevineTheme.Spacing.xs) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }

                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? chipColor : DevineTheme.Colors.textSecondary)
            .padding(.horizontal, DevineTheme.Spacing.md)
            .padding(.vertical, DevineTheme.Spacing.sm)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? chipColor.opacity(0.15) : DevineTheme.Colors.bgSecondary)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isSelected ? chipColor.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(DevineTheme.Motion.quick, value: isSelected)
    }
}

struct MoodChipGrid: View {
    let tags: [String]
    @Binding var selectedTags: Set<String>

    var body: some View {
        FlowLayout(spacing: DevineTheme.Spacing.sm) {
            ForEach(tags, id: \.self) { tag in
                MoodChip(
                    label: tag,
                    isSelected: selectedTags.contains(tag)
                ) {
                    if selectedTags.contains(tag) {
                        selectedTags.remove(tag)
                    } else {
                        selectedTags.insert(tag)
                    }
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ArrangementResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return ArrangementResult(
            positions: positions,
            size: CGSize(width: maxWidth, height: currentY + lineHeight)
        )
    }

    private struct ArrangementResult {
        let positions: [CGPoint]
        let size: CGSize
    }
}

private extension Color {
    init(lightHex: UInt32, darkHex: UInt32) {
        self.init(
            UIColor { trait in
                let hex = trait.userInterfaceStyle == .dark ? darkHex : lightHex
                return UIColor(hex: hex)
            }
        )
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255
        let green = CGFloat((hex & 0x00FF00) >> 8) / 255
        let blue = CGFloat(hex & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
