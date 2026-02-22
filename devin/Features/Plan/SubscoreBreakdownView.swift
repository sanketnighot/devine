import SwiftUI

struct SubscoreBreakdownView: View {
    @ObservedObject var model: DevineAppModel

    @State private var headerVisible = false
    @State private var cardsVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: DevineTheme.Spacing.xl) {
                heroHeader
                subscoreGrid
                insightFooter
            }
            .padding(.horizontal, DevineTheme.Spacing.lg)
            .padding(.top, DevineTheme.Spacing.md)
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
        .navigationTitle("Your Glow Map")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            DevineHaptic.tap.fire()
            withAnimation(DevineTheme.Motion.expressive.delay(0.1)) {
                headerVisible = true
            }
            withAnimation(DevineTheme.Motion.expressive.delay(0.3)) {
                cardsVisible = true
            }
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        GradientCard(colors: DevineTheme.Gradients.heroCard, showGlow: true) {
            VStack(spacing: DevineTheme.Spacing.md) {
                if let score = model.glowScore {
                    ProgressRing(
                        value: Double(score),
                        maxValue: 100,
                        size: 72,
                        lineWidth: 8,
                        trackColor: Color.white.opacity(0.2)
                    )

                    VStack(spacing: DevineTheme.Spacing.xs) {
                        Text("Overall Glow Score")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.7))
                            .textCase(.uppercase)
                            .tracking(0.5)

                        Text("Here's what makes up your \(score)")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(DevineTheme.Colors.textOnGradient)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(headerVisible ? 1 : 0)
        .offset(y: headerVisible ? 0 : 16)
    }

    // MARK: - Subscore Grid

    private var subscoreGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: DevineTheme.Spacing.md),
                GridItem(.flexible(), spacing: DevineTheme.Spacing.md),
            ],
            spacing: DevineTheme.Spacing.md
        ) {
            ForEach(Array(model.subscores.enumerated()), id: \.element.id) { index, subscore in
                subscoreCard(subscore, index: index)
            }
        }
        .opacity(cardsVisible ? 1 : 0)
        .offset(y: cardsVisible ? 0 : 20)
    }

    private func subscoreCard(_ entry: SubscoreEntry, index: Int) -> some View {
        SurfaceCard {
            VStack(spacing: DevineTheme.Spacing.md) {
                // Icon + Score
                HStack {
                    ZStack {
                        Circle()
                            .fill(entry.accentColor.opacity(0.12))
                            .frame(width: 36, height: 36)

                        Image(systemName: entry.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(entry.accentColor)
                    }

                    Spacer()

                    Text("\(entry.value)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(entry.accentColor)
                }

                // Label
                Text(entry.label)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(DevineTheme.Colors.bgSecondary)
                            .frame(height: 5)

                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [entry.accentColor, entry.accentColor.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geo.size.width * CGFloat(entry.value) / CGFloat(entry.maxValue),
                                height: 5
                            )
                    }
                }
                .frame(height: 5)

                // Insight
                Text(entry.insight)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Footer

    private var insightFooter: some View {
        HStack(spacing: DevineTheme.Spacing.sm) {
            Image(systemName: "info.circle")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)

            Text("Subscores are estimated from your check-ins and daily actions. More data = better accuracy.")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)
                .lineSpacing(2)
        }
        .padding(.horizontal, DevineTheme.Spacing.xs)
    }
}
