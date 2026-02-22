import SwiftUI

struct DevineEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var ctaLabel: String? = nil
    var secondaryLabel: String? = nil
    var ctaAction: (() -> Void)? = nil
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: DevineTheme.Spacing.xl) {
            iconView
            textContent
            buttons
        }
        .padding(DevineTheme.Spacing.xxl)
        .frame(maxWidth: .infinity)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            DevineTheme.Colors.ctaPrimary.opacity(0.12),
                            DevineTheme.Colors.ctaSecondary.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)

            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: DevineTheme.Gradients.primaryCTA,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var textContent: some View {
        VStack(spacing: DevineTheme.Spacing.sm) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(DevineTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(DevineTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    @ViewBuilder
    private var buttons: some View {
        VStack(spacing: DevineTheme.Spacing.md) {
            if let ctaLabel, let ctaAction {
                Button(action: ctaAction) {
                    Text(ctaLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DevineTheme.Colors.textOnGradient)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DevineTheme.Spacing.md)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: DevineTheme.Gradients.primaryCTA,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            if let secondaryLabel, let secondaryAction {
                Button(action: secondaryAction) {
                    Text(secondaryLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
