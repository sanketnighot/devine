import SwiftUI

struct OnboardingIntroView: View {
    let onContinue: () -> Void

    @State private var showCTA = false
    @State private var marksVisible = false

    // Fixed positions for the 5 decorative ✦ marks — deliberate, not random
    private let marks: [(x: CGFloat, y: CGFloat, size: CGFloat, delay: Double)] = [
        (-130,  -320, 10, 0.0),
        ( 140,  -270,  7, 0.2),
        (-150,    20, 12, 0.5),
        ( 155,   120,  8, 0.7),
        (  20,   310,  9, 0.4),
    ]

    var body: some View {
        ZStack {
            // ── Background gradient ──────────────────────────────────────
            LinearGradient(
                colors: [
                    DevineTheme.Colors.ctaPrimary,
                    DevineTheme.Colors.ctaSecondary,
                    DevineTheme.Colors.ctaPrimaryPressed,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // ── Ambient aurora blobs ─────────────────────────────────────
            // Three large blurred circles at intentional positions
            // create the soft light-bloom feel without clutter
            Group {
                // Top-right warm bloom
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 340)
                    .blur(radius: 70)
                    .offset(x: 130, y: -240)

                // Bottom-left cool bloom
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 280)
                    .blur(radius: 60)
                    .offset(x: -120, y: 290)

                // Center subtle halo behind the text area
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 420)
                    .blur(radius: 90)
                    .offset(x: 0, y: 60)
            }

            // ── Intentional geometric marks ──────────────────────────────
            // 5 ✦ marks at fixed, grid-aligned positions — not random
            ForEach(Array(marks.enumerated()), id: \.offset) { index, mark in
                Text("✦")
                    .font(.system(size: mark.size, weight: .light))
                    .foregroundColor(.white)
                    .opacity(marksVisible ? 0.35 : 0)
                    .offset(x: mark.x, y: mark.y)
                    .animation(
                        .easeInOut(duration: 0.8).delay(mark.delay),
                        value: marksVisible
                    )
            }

            // ── Main content ─────────────────────────────────────────────
            VStack(spacing: 0) {
                Spacer()

                // Logo mark — slightly larger for visual authority
                Text("✦")
                    .font(.system(size: 52, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.bottom, 36)

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
            // Staggered mark appearance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                marksVisible = true
            }
        }
    }
}
