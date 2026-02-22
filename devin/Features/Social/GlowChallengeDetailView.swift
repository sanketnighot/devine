import SwiftUI

struct GlowChallengeDetailView: View {
    let circle: GlowCircle

    @Environment(\.dismiss) private var dismiss
    @State private var heroVisible = false
    @State private var gridVisible = false

    private var challenge: GlowChallenge {
        circle.activeChallenge ?? GlowChallenge(
            title: "7-Day Glow Challenge",
            description: "Complete your daily actions for 7 days straight — as a team.",
            durationDays: 7,
            memberProgress: Dictionary(uniqueKeysWithValues: circle.members.map { ($0.id, 0) })
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DevineTheme.Spacing.xl) {
                    heroCard
                    memberProgressGrid
                    howItWorks
                    safetyNote
                }
                .padding(.horizontal, DevineTheme.Spacing.lg)
                .padding(.top, DevineTheme.Spacing.md)
                .padding(.bottom, DevineTheme.Spacing.xxxl)
            }
            .background(
                LinearGradient(
                    colors: DevineTheme.Gradients.screenBackground,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .foregroundStyle(DevineTheme.Colors.textPrimary)
            .navigationTitle(challenge.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            DevineHaptic.sheetPresent.fire()
            withAnimation(DevineTheme.Motion.expressive.delay(0.1)) {
                heroVisible = true
            }
            withAnimation(DevineTheme.Motion.expressive.delay(0.3)) {
                gridVisible = true
            }
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        GradientCard(colors: DevineTheme.Gradients.heroCard, showGlow: true) {
            VStack(spacing: DevineTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 64, height: 64)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(DevineTheme.Colors.textOnGradient)
                }

                VStack(spacing: DevineTheme.Spacing.xs) {
                    Text(challenge.title)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(DevineTheme.Colors.textOnGradient)

                    Text("Win as a team — no rankings, no comparison")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.8))
                }

                // Co-op progress bar
                VStack(spacing: DevineTheme.Spacing.sm) {
                    Text("Team progress")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(0.5)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 8)

                            Capsule(style: .continuous)
                                .fill(Color.white)
                                .frame(width: max(0, geo.size.width * challenge.overallProgress), height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(challenge.overallProgress * 100))% complete")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(DevineTheme.Colors.textOnGradient)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(heroVisible ? 1 : 0)
        .offset(y: heroVisible ? 0 : 16)
    }

    // MARK: - Member Progress

    private var memberProgressGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: DevineTheme.Spacing.md),
                GridItem(.flexible(), spacing: DevineTheme.Spacing.md),
            ],
            spacing: DevineTheme.Spacing.md
        ) {
            ForEach(circle.members) { member in
                memberProgressCard(member)
            }
        }
        .opacity(gridVisible ? 1 : 0)
        .offset(y: gridVisible ? 0 : 20)
    }

    private func memberProgressCard(_ member: CircleMember) -> some View {
        let daysCompleted = challenge.memberProgress[member.id] ?? 0
        let progress = Double(daysCompleted) / Double(max(1, challenge.durationDays))

        return SurfaceCard {
            VStack(spacing: DevineTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(DevineTheme.Colors.ctaPrimary.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Text(member.avatarInitials)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                }

                VStack(spacing: DevineTheme.Spacing.xs) {
                    Text(member.displayName)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .lineLimit(1)

                    Text("\(daysCompleted)/\(challenge.durationDays) days")
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(DevineTheme.Colors.bgSecondary)
                            .frame(height: 5)

                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: DevineTheme.Gradients.primaryCTA,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * progress), height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
    }

    // MARK: - How It Works

    private var howItWorks: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                Text("How it works")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))

                howItWorksRow(icon: "checkmark.circle.fill", text: "Complete your 3 daily actions")
                howItWorksRow(icon: "person.3.fill", text: "Check in with your circle")
                howItWorksRow(icon: "party.popper.fill", text: "Celebrate together on day 7")
            }
        }
    }

    private func howItWorksRow(icon: String, text: String) -> some View {
        HStack(spacing: DevineTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                .frame(width: 24)

            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.textSecondary)
        }
    }

    // MARK: - Safety Note

    private var safetyNote: some View {
        HStack(spacing: DevineTheme.Spacing.sm) {
            Image(systemName: "heart.fill")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)

            Text("No rankings. No scores. Just your circle, glowing together.")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)
                .lineSpacing(2)
        }
        .padding(.horizontal, DevineTheme.Spacing.xs)
    }
}
