import SwiftUI

/// A polished falling-confetti celebration overlay.
/// Pieces cascade from the top of the screen downward with gentle sway and rotation.
struct CelebrationOverlay: View {
    @Binding var isPresented: Bool
    var message: String = ""
    var pieceCount: Int = 40

    @State private var pieces: [ConfettiPiece] = []
    @State private var showMessage = false

    var body: some View {
        ZStack {
            if isPresented {
                // Confetti layer
                GeometryReader { geo in
                    ForEach(pieces) { piece in
                        ConfettiView(piece: piece, containerWidth: geo.size.width, containerHeight: geo.size.height)
                    }
                }
                .ignoresSafeArea()

                // Optional message pill
                if showMessage, !message.isEmpty {
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
            } else {
                pieces = []
                showMessage = false
            }
        }
        .allowsHitTesting(false)
    }

    private func triggerCelebration() {
        let colors: [Color] = DevineTheme.Gradients.celebration + [
            DevineTheme.Colors.ctaPrimary,
            DevineTheme.Colors.ctaSecondary,
            DevineTheme.Colors.successAccent,
            .yellow,
            .mint
        ]

        pieces = (0..<pieceCount).map { i in
            ConfettiPiece(
                color: colors[i % colors.count],
                shape: ConfettiShape.allCases.randomElement() ?? .circle,
                size: CGFloat.random(in: 6...12),
                xPosition: CGFloat.random(in: 0...1),   // normalized 0-1
                delay: Double.random(in: 0...0.6),
                fallDuration: Double.random(in: 1.8...3.0),
                swayAmount: CGFloat.random(in: 20...60),
                rotation: Angle.degrees(Double.random(in: 0...360)),
                spinSpeed: Double.random(in: 180...720)
            )
        }

        if !message.isEmpty {
            withAnimation(DevineTheme.Motion.celebration.delay(0.2)) {
                showMessage = true
            }
        }

        // Auto-dismiss after the longest confetti fall + a brief pause
        let maxDuration = pieces.map { $0.delay + $0.fallDuration }.max() ?? 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + maxDuration + 0.3) {
            withAnimation(DevineTheme.Motion.standard) {
                isPresented = false
            }
        }
    }
}

// MARK: - Confetti Shape

private enum ConfettiShape: CaseIterable {
    case circle, roundedRect, star, diamond
}

// MARK: - Confetti Piece Data

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let shape: ConfettiShape
    let size: CGFloat
    let xPosition: CGFloat       // 0...1 normalized horizontal position
    let delay: Double
    let fallDuration: Double
    let swayAmount: CGFloat
    let rotation: Angle
    let spinSpeed: Double         // degrees per second
}

// MARK: - Single Confetti View (handles its own animation)

private struct ConfettiView: View {
    let piece: ConfettiPiece
    let containerWidth: CGFloat
    let containerHeight: CGFloat

    @State private var progress: CGFloat = 0   // 0 = top, 1 = past bottom
    @State private var swayPhase: CGFloat = 0
    @State private var spin: Angle = .zero
    @State private var opacity: Double = 0

    var body: some View {
        confettiShape
            .frame(width: piece.size, height: piece.shape == .roundedRect ? piece.size * 0.5 : piece.size)
            .foregroundColor(piece.color)
            .rotationEffect(piece.rotation + spin)
            .opacity(opacity)
            .position(
                x: containerWidth * piece.xPosition + piece.swayAmount * sin(swayPhase * .pi * 2),
                y: -20 + (containerHeight + 40) * progress
            )
            .onAppear {
                withAnimation(
                    .easeIn(duration: piece.fallDuration)
                    .delay(piece.delay)
                ) {
                    progress = 1
                }

                // Sway oscillation
                withAnimation(
                    .easeInOut(duration: piece.fallDuration * 0.4)
                    .repeatCount(5, autoreverses: true)
                    .delay(piece.delay)
                ) {
                    swayPhase = 1
                }

                // Spin
                withAnimation(
                    .linear(duration: piece.fallDuration)
                    .delay(piece.delay)
                ) {
                    spin = Angle.degrees(piece.spinSpeed)
                }

                // Fade in quickly, fade out near bottom
                withAnimation(.easeIn(duration: 0.15).delay(piece.delay)) {
                    opacity = 1
                }
                withAnimation(
                    .easeOut(duration: 0.4)
                    .delay(piece.delay + piece.fallDuration * 0.75)
                ) {
                    opacity = 0
                }
            }
    }

    @ViewBuilder
    private var confettiShape: some View {
        switch piece.shape {
        case .circle:
            Circle()
        case .roundedRect:
            RoundedRectangle(cornerRadius: 2, style: .continuous)
        case .star:
            Image(systemName: "star.fill")
                .font(.system(size: piece.size * 0.85))
        case .diamond:
            Rectangle()
                .rotationEffect(.degrees(45))
                .frame(width: piece.size * 0.7, height: piece.size * 0.7)
        }
    }
}
