import SwiftUI

struct SocialView: View {
    @ObservedObject var model: DevineAppModel

    @State private var showCreateCircle = false
    @State private var showJoinCircle = false
    @State private var showChallenge = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DevineTheme.Spacing.xl) {
                    if model.glowCircle != nil {
                        ActiveCircleView(model: model, showChallenge: $showChallenge)
                        challengeTeaserActive
                    } else {
                        circleEmptyState
                        challengeTeaser
                    }
                    safetyFooter
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
            .navigationTitle("Glow Together")
        }
        .tint(DevineTheme.Colors.ctaPrimary)
        .sheet(isPresented: $showCreateCircle) {
            CreateCircleSheet { name in
                model.createCircle(name: name)
            }
            .presentationBackground(DevineTheme.Colors.bgPrimary)
        }
        .sheet(isPresented: $showJoinCircle) {
            JoinCircleSheet { code in
                model.joinCircle(inviteCode: code)
            }
            .presentationBackground(DevineTheme.Colors.bgPrimary)
        }
        .sheet(isPresented: $showChallenge) {
            if let circle = model.glowCircle {
                GlowChallengeDetailView(circle: circle)
                    .presentationBackground(DevineTheme.Colors.bgPrimary)
            }
        }
    }

    // MARK: - Circle Empty State

    private var circleEmptyState: some View {
        GradientCard(colors: DevineTheme.Gradients.heroCard, showGlow: true) {
            VStack(spacing: DevineTheme.Spacing.xl) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 88, height: 88)

                    Image(systemName: "person.3.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(DevineTheme.Colors.textOnGradient)
                }

                VStack(spacing: DevineTheme.Spacing.sm) {
                    Text("Better together")
                        .font(.title3.bold())
                        .foregroundStyle(DevineTheme.Colors.textOnGradient)

                    Text("Start a circle with your closest 3–8 friends.\nStay consistent together, celebrate wins,\nand keep each other glowing.")
                        .font(.subheadline)
                        .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                VStack(spacing: DevineTheme.Spacing.md) {
                    Button {
                        DevineHaptic.tap.fire()
                        showCreateCircle = true
                    } label: {
                        Text("Create your circle")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(DevineTheme.Gradients.heroCard.first ?? .pink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DevineTheme.Spacing.md)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.white)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        DevineHaptic.tap.fire()
                        showJoinCircle = true
                    } label: {
                        Text("Join with invite code")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - Challenge Teaser (no circle yet)

    private var challengeTeaser: some View {
        SurfaceCard {
            HStack(spacing: DevineTheme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DevineTheme.Colors.warningAccent.opacity(0.15),
                                    DevineTheme.Colors.ctaSecondary.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: "trophy.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DevineTheme.Colors.warningAccent, DevineTheme.Colors.ctaSecondary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                    Text("Glow Challenges")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))

                    Text("7-day consistency challenge.\nWin as a team, not against each other.")
                        .font(.caption)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                        .lineSpacing(2)

                    Text("Coming with your first circle")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                        .padding(.top, DevineTheme.Spacing.xs)
                }

                Spacer()
            }
        }
    }

    // MARK: - Challenge Teaser Active (has circle)

    private var challengeTeaserActive: some View {
        Button {
            DevineHaptic.tap.fire()
            showChallenge = true
        } label: {
            SurfaceCard {
                HStack(spacing: DevineTheme.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DevineTheme.Colors.warningAccent.opacity(0.15),
                                        DevineTheme.Colors.ctaSecondary.opacity(0.1),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: "trophy.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [DevineTheme.Colors.warningAccent, DevineTheme.Colors.ctaSecondary],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                        Text("Glow Challenges")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))

                        if let challenge = model.glowCircle?.activeChallenge {
                            Text("\(Int(challenge.overallProgress * 100))% team progress")
                                .font(.caption)
                                .foregroundStyle(DevineTheme.Colors.textSecondary)
                        }

                        Text("Tap to view details")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Safety Footer

    private var safetyFooter: some View {
        VStack(spacing: DevineTheme.Spacing.sm) {
            HStack(spacing: DevineTheme.Spacing.lg) {
                safetyPoint(icon: "eye.slash", text: "No rankings")
                safetyPoint(icon: "hand.raised", text: "No comparison")
                safetyPoint(icon: "lock.shield", text: "Private")
            }

            Text("Your glow journey is yours. Circles are about support, not competition.")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, DevineTheme.Spacing.sm)
    }

    private func safetyPoint(icon: String, text: String) -> some View {
        VStack(spacing: DevineTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(DevineTheme.Colors.textMuted)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundStyle(DevineTheme.Colors.textMuted)
        }
    }
}
