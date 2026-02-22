import SwiftUI

struct GoalBadge: View {
    let goal: GlowGoal
    var style: BadgeStyle = .standard

    enum BadgeStyle {
        case standard
        case compact
    }

    var body: some View {
        HStack(spacing: DevineTheme.Spacing.xs) {
            Image(systemName: goal.iconName)
                .font(style == .compact ? .caption2 : .caption)

            Text(goal.displayName)
                .font(style == .compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
        }
        .foregroundStyle(goal.accentColor)
        .padding(.horizontal, style == .compact ? 8 : 10)
        .padding(.vertical, style == .compact ? 4 : 6)
        .background(
            Capsule(style: .continuous)
                .fill(goal.accentColor.opacity(0.12))
        )
    }
}
