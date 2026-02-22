import SwiftUI

struct CelebrationOverlay: View {
    @Binding var isPresented: Bool
    var message: String = "Tiny win. Keep going."
    var particleCount: Int = 20

    @State private var particles: [Particle] = []
    @State private var showMessage = false

    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.01)
                    .ignoresSafeArea()

                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .offset(particle.offset)
                        .opacity(particle.opacity)
                }

                if showMessage {
                    Text(message)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DevineTheme.Colors.textPrimary)
                        .padding(.horizontal, DevineTheme.Spacing.xl)
                        .padding(.vertical, DevineTheme.Spacing.md)
                        .background(
                            Capsule(style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onChange(of: isPresented) {
            if isPresented {
                triggerCelebration()
            }
        }
        .allowsHitTesting(false)
    }

    private func triggerCelebration() {
        let colors: [Color] = DevineTheme.Gradients.celebration + [
            DevineTheme.Colors.ctaPrimary,
            DevineTheme.Colors.ctaSecondary,
            DevineTheme.Colors.successAccent
        ]

        particles = (0..<particleCount).map { _ in
            Particle(
                color: colors.randomElement() ?? .pink,
                size: CGFloat.random(in: 4...10),
                offset: .zero,
                opacity: 1
            )
        }

        withAnimation(.easeOut(duration: 0.8)) {
            particles = particles.map { particle in
                var p = particle
                p.offset = CGSize(
                    width: CGFloat.random(in: (-160)...160),
                    height: CGFloat.random(in: (-300)...(-40))
                )
                p.opacity = 0
                return p
            }
        }

        withAnimation(DevineTheme.Motion.celebration.delay(0.1)) {
            showMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(DevineTheme.Motion.quick) {
                showMessage = false
                isPresented = false
            }
        }
    }
}

private struct Particle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var offset: CGSize
    var opacity: Double
}
