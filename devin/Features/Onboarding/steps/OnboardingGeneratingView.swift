import SwiftUI

struct OnboardingGeneratingView: View {
    let name: String
    let profile: UserProfile
    let goal: GlowGoal
    let photo: UIImage?
    let onComplete: (GeneratedPlan) -> Void
    let onFallback: () -> Void

    @State private var phase: Phase = .thinking
    @State private var orbScale: CGFloat = 1.0
    @State private var orbOpacity: Double = 0.7
    @State private var ringsVisible = false
    @State private var rotation: Double = 0
    @State private var summaryText = ""
    @State private var showCTA = false
    @State private var generatedPlan: GeneratedPlan?

    private enum Phase {
        case thinking
        case revealing
        case ready
    }

    var body: some View {
        ZStack {
            DevineTheme.Colors.bgPrimary.ignoresSafeArea()

            // ── Ambient center glow ──────────────────────────────────────
            // Large radial bloom behind the orb — atmospheric depth
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DevineTheme.Colors.ctaPrimary.opacity(0.12),
                            DevineTheme.Colors.ctaSecondary.opacity(0.06),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                )
                .frame(width: 440)
                .blur(radius: 20)
                .scaleEffect(orbScale)
                .opacity(ringsVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.6), value: ringsVisible)

            // ── Orbital rings ─────────────────────────────────────────────
            // 3 concentric stroke rings, staggered pulse — signals active thinking
            ForEach([0, 1, 2], id: \.self) { i in
                let diameter = CGFloat(200 + i * 90)
                let baseOpacity = 0.18 - Double(i) * 0.05
                Circle()
                    .stroke(
                        DevineTheme.Colors.ctaPrimary.opacity(baseOpacity),
                        lineWidth: i == 0 ? 1.5 : 1.0
                    )
                    .frame(width: diameter)
                    .scaleEffect(orbScale > 1 ? 1 + CGFloat(i) * 0.025 : 1)
                    .opacity(ringsVisible ? 1 : 0)
                    .animation(
                        .easeInOut(duration: 1.6 + Double(i) * 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.35),
                        value: orbScale
                    )
                    .animation(.easeIn(duration: 0.5).delay(Double(i) * 0.15), value: ringsVisible)
            }

            // ── Rotating orbital marks ────────────────────────────────────
            // 4 ✦ marks at compass points on a fixed radius,
            // rotating as a unit — deliberate motion, not random scatter
            ForEach([0.0, 90.0, 180.0, 270.0], id: \.self) { angle in
                Text("✦")
                    .font(.system(size: 7, weight: .light))
                    .foregroundColor(DevineTheme.Colors.ctaPrimary.opacity(0.5))
                    .offset(y: -116)
                    .rotationEffect(.degrees(angle + rotation))
                    .opacity(ringsVisible ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.4), value: ringsVisible)
            }

            // ── Main content ──────────────────────────────────────────────
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    // Pulsing gradient orb
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        DevineTheme.Colors.ctaPrimary.opacity(0.4),
                                        DevineTheme.Colors.ctaSecondary.opacity(0.1),
                                        .clear,
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .scaleEffect(orbScale)
                            .opacity(orbOpacity)

                        Image(systemName: "sparkles")
                            .font(.system(size: 36))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: DevineTheme.Gradients.primaryCTA,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(orbScale * 0.95)
                    }

                    // Phase-specific text
                    VStack(spacing: 16) {
                        switch phase {
                        case .thinking:
                            TypewriterSequence(
                                messages: [
                                    TypewriterSequence.Message(
                                        text: "okay \(name), let me cook... 🔥",
                                        speed: 40,
                                        font: .system(size: 20, weight: .semibold),
                                        pauseAfter: 1.2
                                    ),
                                    TypewriterSequence.Message(
                                        text: "looking at your goal and\neverything you told me...",
                                        speed: 45,
                                        font: .system(size: 15),
                                        pauseAfter: 1.0
                                    ),
                                    TypewriterSequence.Message(
                                        text: "building your personalized plan ✨",
                                        speed: 45,
                                        font: .system(size: 15),
                                        pauseAfter: 0.3
                                    ),
                                ],
                                color: DevineTheme.Colors.textPrimary
                            )

                        case .revealing:
                            VStack(spacing: 8) {
                                Text("your plan is ready 🎉")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(DevineTheme.Colors.textPrimary)

                                TypewriterText(
                                    text: summaryText,
                                    speed: 55,
                                    font: .system(size: 15),
                                    color: DevineTheme.Colors.textSecondary
                                ) {
                                    withAnimation(DevineTheme.Motion.expressive) {
                                        phase = .ready
                                        showCTA = true
                                    }
                                }
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                            }

                        case .ready:
                            VStack(spacing: 8) {
                                Text("your plan is ready 🎉")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(DevineTheme.Colors.textPrimary)
                                Text(summaryText)
                                    .font(.system(size: 15))
                                    .foregroundColor(DevineTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)

                Spacer()

                if showCTA {
                    Button(action: {
                        DevineHaptic.actionComplete.fire()
                        if let plan = generatedPlan {
                            onComplete(plan)
                        } else {
                            onFallback()
                        }
                    }) {
                        Text("see my plan →")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: DevineTheme.Gradients.primaryCTA,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startOrbAnimation()
            startRotation()
            startPlanGeneration()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                ringsVisible = true
            }
        }
    }

    // MARK: - Animations

    private func startOrbAnimation() {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            orbScale = 1.12
            orbOpacity = 1.0
        }
    }

    private func startRotation() {
        // Continuous slow rotation — 18s per revolution feels deliberate, not frantic
        withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }

    // MARK: - Plan Generation

    private func startPlanGeneration() {
        Task {
            do {
                let plan = try await PlanGenerationService().generatePlan(
                    profile: profile,
                    goal: goal,
                    photo: photo
                )
                await MainActor.run {
                    generatedPlan = plan
                    summaryText = plan.summary
                    withAnimation(DevineTheme.Motion.standard) {
                        phase = .revealing
                    }
                }
            } catch {
                print("[Onboarding] ❌ Plan generation failed: \(error)")
                await MainActor.run {
                    summaryText = "hmm, i couldn't reach the AI right now 😅 but don't worry — i've got a solid starter plan for your \(goal.displayName.lowercased()) goal. you can regenerate later!"
                    withAnimation(DevineTheme.Motion.standard) {
                        phase = .revealing
                    }
                }
            }
        }
    }
}
