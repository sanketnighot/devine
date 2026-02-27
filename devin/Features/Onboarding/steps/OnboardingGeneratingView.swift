import SwiftUI

struct OnboardingGeneratingView: View {
    let name: String
    let profile: UserProfile
    let goal: GlowGoal
    let photo: UIImage?
    let onComplete: (GeneratedPlan) -> Void
    let onFallback: () -> Void   // called if Gemini fails, uses default plan

    @State private var phase: Phase = .thinking
    @State private var orbScale: CGFloat = 1.0
    @State private var orbOpacity: Double = 0.7
    @State private var particles: [FloatParticle] = FloatParticle.generate()
    @State private var summaryText = ""
    @State private var showCTA = false
    @State private var generatedPlan: GeneratedPlan?

    private enum Phase {
        case thinking   // typewriter + orb + particle animation
        case revealing  // typewriter summary from Gemini
        case ready      // CTA visible
    }

    var body: some View {
        ZStack {
            DevineTheme.Colors.bgPrimary.ignoresSafeArea()

            // Floating particles
            ForEach(particles) { p in
                Text(p.symbol)
                    .font(.system(size: p.size))
                    .offset(x: p.x, y: p.y)
                    .opacity(p.opacity)
                    .animation(
                        .easeInOut(duration: p.duration)
                        .repeatForever(autoreverses: true)
                        .delay(p.delay),
                        value: orbScale
                    )
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    // Pulsing gradient orb
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [DevineTheme.Colors.ctaPrimary.opacity(0.4), DevineTheme.Colors.ctaSecondary.opacity(0.1), .clear],
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
                                    startPoint: .topLeading, endPoint: .bottomTrailing
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
                                    startPoint: .leading, endPoint: .trailing
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
            startPlanGeneration()
        }
    }

    private func startOrbAnimation() {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            orbScale = 1.12
            orbOpacity = 1.0
        }
    }

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
                print("[Onboarding] Error details: \(error.localizedDescription)")
                // Show error message but still let user continue with defaults
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

// MARK: - Float Particle

private struct FloatParticle: Identifiable {
    let id = UUID()
    let symbol: String
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    let opacity: Double
    let duration: Double
    let delay: Double

    static func generate() -> [FloatParticle] {
        let symbols = ["✨", "🌟", "💪", "⭐️", "✦", "◇"]
        return (0..<12).map { _ in
            FloatParticle(
                symbol: symbols.randomElement()!,
                size: CGFloat.random(in: 14...28),
                x: CGFloat.random(in: -160...160),
                y: CGFloat.random(in: -300...300),
                opacity: Double.random(in: 0.1...0.4),
                duration: Double.random(in: 2.0...4.5),
                delay: Double.random(in: 0...2.0)
            )
        }
    }
}
