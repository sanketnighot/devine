import SwiftUI

private enum PaywallLoadState {
    case loading
    case ready
    case failed
}

struct PaywallGateView: View {
    let onSubscribe: () -> Void
    let onContinueLimited: () -> Void

    @State private var loadState: PaywallLoadState = .loading
    @State private var isAnnual = true
    @State private var heroVisible = false
    @State private var cardsVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: DevineTheme.Spacing.xl) {
                heroSection
                benefitsList

                Group {
                    switch loadState {
                    case .loading:
                        loadingState
                    case .ready:
                        readyState
                    case .failed:
                        failedState
                    }
                }

                legalFooter
            }
            .padding(.horizontal, DevineTheme.Spacing.lg)
            .padding(.top, DevineTheme.Spacing.xxl)
            .padding(.bottom, DevineTheme.Spacing.xxxl)
        }
        .scrollIndicators(.hidden)
        .background(
            LinearGradient(
                colors: DevineTheme.Gradients.screenBackground,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .foregroundStyle(DevineTheme.Colors.textPrimary)
        .task {
            loadProducts()
        }
        .onAppear {
            DevineHaptic.sheetPresent.fire()
            withAnimation(DevineTheme.Motion.expressive.delay(0.1)) {
                heroVisible = true
            }
            withAnimation(DevineTheme.Motion.expressive.delay(0.3)) {
                cardsVisible = true
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: DevineTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DevineTheme.Colors.ctaPrimary.opacity(0.12),
                                DevineTheme.Colors.ctaSecondary.opacity(0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: DevineTheme.Gradients.primaryCTA,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(heroVisible ? 1 : 0.6)
            .opacity(heroVisible ? 1 : 0)

            VStack(spacing: DevineTheme.Spacing.sm) {
                Text("Unlock your full\nglow plan")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Personalized. Adaptive. Real results.")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
            }
            .opacity(heroVisible ? 1 : 0)
            .offset(y: heroVisible ? 0 : 12)
        }
    }

    // MARK: - Benefits

    private var benefitsList: some View {
        VStack(spacing: DevineTheme.Spacing.md) {
            benefitRow(icon: "brain.head.profile.fill", text: "AI-powered plan that adapts to you")
            benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track real progress with evidence")
            benefitRow(icon: "camera.viewfinder", text: "Mirror check-ins with mood tracking")
            benefitRow(icon: "flame.fill", text: "Streaks, celebrations & daily actions")
        }
        .padding(.vertical, DevineTheme.Spacing.sm)
        .opacity(cardsVisible ? 1 : 0)
        .offset(y: cardsVisible ? 0 : 8)
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: DevineTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                .frame(width: 28)

            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.textPrimary)

            Spacer()
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: DevineTheme.Spacing.md) {
            ShimmerPlaceholder(height: 80)
            ShimmerPlaceholder(height: 80)
            ShimmerPlaceholder(height: 52, cornerRadius: DevineTheme.Radius.pill)
        }
    }

    // MARK: - Ready State

    private var readyState: some View {
        VStack(spacing: DevineTheme.Spacing.md) {
            planCard(
                title: "$24 / month",
                subtitle: "Flexible month-to-month",
                badge: nil,
                selected: !isAnnual
            ) {
                DevineHaptic.tap.fire()
                withAnimation(DevineTheme.Motion.quick) {
                    isAnnual = false
                }
            }

            planCard(
                title: "$199 / year",
                subtitle: "$16.58/mo — billed annually",
                badge: "Save 31%",
                selected: isAnnual
            ) {
                DevineHaptic.tap.fire()
                withAnimation(DevineTheme.Motion.quick) {
                    isAnnual = true
                }
            }

            // Primary CTA
            Button {
                DevineHaptic.actionComplete.fire()
                onSubscribe()
            } label: {
                Text("Start My Glow Plan")
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
                    .shadow(color: DevineTheme.Colors.ctaPrimary.opacity(0.3), radius: 12, y: 6)
            }
            .buttonStyle(.plain)

            // Restore
            Button {
                DevineHaptic.tap.fire()
                onSubscribe()
            } label: {
                Text("Restore Purchases")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
            }
            .buttonStyle(.plain)

            // Continue limited
            Button {
                DevineHaptic.tap.fire()
                onContinueLimited()
            } label: {
                HStack(spacing: DevineTheme.Spacing.xs) {
                    Text("Continue with limited access")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                }
                .foregroundStyle(DevineTheme.Colors.textSecondary)
                .padding(.horizontal, DevineTheme.Spacing.lg)
                .padding(.vertical, DevineTheme.Spacing.sm)
                .background(
                    Capsule(style: .continuous)
                        .fill(DevineTheme.Colors.bgSecondary)
                )
            }
            .buttonStyle(.plain)
        }
        .opacity(cardsVisible ? 1 : 0)
        .offset(y: cardsVisible ? 0 : 8)
    }

    // MARK: - Failed State

    private var failedState: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                HStack(spacing: DevineTheme.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(DevineTheme.Colors.warningAccent)
                    Text("Subscriptions temporarily unavailable")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }

                Text("Check your connection and try again, or continue with limited access.")
                    .font(.caption)
                    .foregroundStyle(DevineTheme.Colors.textSecondary)

                HStack(spacing: DevineTheme.Spacing.md) {
                    Button {
                        DevineHaptic.tap.fire()
                        loadProducts()
                    } label: {
                        Text("Retry")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(DevineTheme.Colors.textOnGradient)
                            .padding(.horizontal, DevineTheme.Spacing.xl)
                            .padding(.vertical, DevineTheme.Spacing.sm)
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
                        DevineHaptic.tap.fire()
                        onContinueLimited()
                    } label: {
                        Text("Continue limited")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Legal Footer

    private var legalFooter: some View {
        HStack(spacing: DevineTheme.Spacing.sm) {
            Image(systemName: "lock.shield")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)

            Text("Cancel anytime. No commitment. Subscription terms apply.")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)
        }
    }

    // MARK: - Plan Card

    private func planCard(
        title: String,
        subtitle: String,
        badge: String?,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                    HStack(spacing: DevineTheme.Spacing.sm) {
                        Text(title)
                            .font(.system(.headline, design: .rounded, weight: .bold))

                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(DevineTheme.Colors.textOnGradient)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
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
                    }

                    Text(subtitle)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(
                        selected
                            ? DevineTheme.Colors.ctaPrimary
                            : DevineTheme.Colors.textMuted
                    )
                    .symbolEffect(.bounce, value: selected)
            }
            .padding(DevineTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DevineTheme.Radius.xl, style: .continuous)
                    .fill(DevineTheme.Colors.surfaceCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DevineTheme.Radius.xl, style: .continuous)
                    .stroke(
                        selected
                            ? LinearGradient(
                                colors: DevineTheme.Gradients.primaryCTA,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [DevineTheme.Colors.borderSubtle],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: selected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Load Products

    private func loadProducts() {
        withAnimation(DevineTheme.Motion.standard) {
            loadState = .loading
        }
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(DevineTheme.Motion.standard) {
                if ProcessInfo.processInfo.environment["SIMULATE_PAYWALL_FAILURE"] == "1" {
                    loadState = .failed
                } else {
                    loadState = .ready
                }
            }
        }
    }
}
