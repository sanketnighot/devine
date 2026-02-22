import SwiftUI

struct HealthConnectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var heroVisible = false

    var body: some View {
        NavigationStack {
            VStack(spacing: DevineTheme.Spacing.xl) {
                Spacer()

                heroIcon
                headline
                benefitsList
                ctaButtons
                privacyFooter

                Spacer()
            }
            .padding(.horizontal, DevineTheme.Spacing.lg)
            .background(
                LinearGradient(
                    colors: DevineTheme.Gradients.screenBackground,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            DevineHaptic.sheetPresent.fire()
            withAnimation(DevineTheme.Motion.expressive.delay(0.1)) {
                heroVisible = true
            }
        }
    }

    // MARK: - Hero

    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            DevineTheme.Colors.errorAccent.opacity(0.15),
                            DevineTheme.Colors.ctaPrimary.opacity(0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)

            Image(systemName: "heart.fill")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DevineTheme.Colors.errorAccent, DevineTheme.Colors.ctaPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .scaleEffect(heroVisible ? 1 : 0.6)
        .opacity(heroVisible ? 1 : 0)
    }

    private var headline: some View {
        VStack(spacing: DevineTheme.Spacing.sm) {
            Text("Precision upgrade")
                .font(.system(.title3, design: .rounded, weight: .bold))

            Text("Your plan gets smarter with every signal.")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Benefits

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
            benefitRow(icon: "scalemass", text: "Weight trends over time")
            benefitRow(icon: "bed.double", text: "Sleep insights and recovery")
            benefitRow(icon: "figure.walk", text: "Activity and energy levels")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DevineTheme.Spacing.xl)
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: DevineTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                .frame(width: 24)

            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
        }
    }

    // MARK: - CTAs

    private var ctaButtons: some View {
        VStack(spacing: DevineTheme.Spacing.md) {
            Button {
                DevineHaptic.actionComplete.fire()
                dismiss()
            } label: {
                Text("Connect Apple Health")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textOnGradient)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DevineTheme.Spacing.lg)
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

            Button {
                dismiss()
            } label: {
                Text("Maybe later")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Footer

    private var privacyFooter: some View {
        HStack(spacing: DevineTheme.Spacing.sm) {
            Image(systemName: "lock.shield")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)

            Text("Read-only. We never write to your Health data.")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)
        }
    }
}
