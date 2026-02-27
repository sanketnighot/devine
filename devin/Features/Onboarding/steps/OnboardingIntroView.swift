import SwiftUI

struct OnboardingIntroView: View {
    let onContinue: () -> Void

    @State private var showCTA = false
    @State private var particles: [SparkleParticle] = SparkleParticle.generate(count: 18)
    @State private var animateParticles = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    DevineTheme.Colors.ctaPrimary,
                    DevineTheme.Colors.ctaSecondary,
                    DevineTheme.Colors.ctaPrimaryPressed
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Floating sparkle particles
            ForEach(particles) { p in
                Text(p.symbol)
                    .font(.system(size: p.size))
                    .opacity(animateParticles ? p.targetOpacity : 0)
                    .offset(
                        x: animateParticles ? p.targetX : p.startX,
                        y: animateParticles ? p.targetY : p.startY
                    )
                    .animation(
                        .easeInOut(duration: p.duration)
                        .repeatForever(autoreverses: true)
                        .delay(p.delay),
                        value: animateParticles
                    )
            }

            // Main content
            VStack(spacing: 0) {
                Spacer()

                // Logo mark
                Text("✦")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, 32)

                // Typewriter messages
                VStack(alignment: .leading, spacing: 16) {
                    TypewriterSequence(
                        messages: [
                            TypewriterSequence.Message(
                                text: "hi 👋",
                                speed: 30,
                                font: .system(size: 36, weight: .bold),
                                pauseAfter: 0.5
                            ),
                            TypewriterSequence.Message(
                                text: "i'm devine.",
                                speed: 28,
                                font: .system(size: 36, weight: .bold),
                                pauseAfter: 0.6
                            ),
                            TypewriterSequence.Message(
                                text: "think of me as your personal\nglow-up coach ✨",
                                speed: 45,
                                font: .system(size: 20, weight: .medium),
                                pauseAfter: 0.4
                            ),
                            TypewriterSequence.Message(
                                text: "i'll build you a plan that actually fits\nyour life, not some generic routine.",
                                speed: 50,
                                font: .system(size: 16, weight: .regular),
                                pauseAfter: 0.3
                            ),
                        ],
                        color: .white
                    ) {
                        withAnimation(DevineTheme.Motion.expressive) {
                            showCTA = true
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // CTA
                if showCTA {
                    VStack(spacing: 16) {
                        Button(action: onContinue) {
                            Text("let's do this 🌟")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(DevineTheme.Colors.ctaPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(.white)
                                .clipShape(Capsule())
                        }

                        Button(action: {}) {
                            Text("already have an account? sign in")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            animateParticles = true
        }
    }
}

// MARK: - Particle Model

private struct SparkleParticle: Identifiable {
    let id = UUID()
    let symbol: String
    let size: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    let targetOpacity: Double
    let duration: Double
    let delay: Double

    static func generate(count: Int) -> [SparkleParticle] {
        let symbols = ["✦", "✧", "⋆", "·", "✨", "⭑", "◇", "◆"]
        return (0..<count).map { _ in
            let x = CGFloat.random(in: -180...180)
            let y = CGFloat.random(in: -380...380)
            return SparkleParticle(
                symbol: symbols.randomElement()!,
                size: CGFloat.random(in: 8...22),
                startX: x + CGFloat.random(in: -20...20),
                startY: y + CGFloat.random(in: -20...20),
                targetX: x,
                targetY: y,
                targetOpacity: Double.random(in: 0.15...0.55),
                duration: Double.random(in: 2.5...5.0),
                delay: Double.random(in: 0...2.5)
            )
        }
    }
}
