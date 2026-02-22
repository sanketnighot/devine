import SwiftUI
import UIKit

struct SplashView: View {
    @Binding var isPresented: Bool

    // MARK: - Animation State

    // Act 1: The Drop
    @State private var dropOpacity: Double = 0
    @State private var dropScale: CGFloat = 0.5
    @State private var dropOffsetY: CGFloat = -200

    // Act 2: Impact + Ripples
    @State private var dropAbsorbed = false
    @State private var rippleExpanded: [Bool] = [false, false, false, false]

    // Act 3: Wordmark
    @State private var showWordmark = false

    // Act 4: Exit
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0

    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    // MARK: - Ripple Configuration

    private let rippleColors: [Color] = [
        DevineTheme.Colors.ctaPrimary,
        DevineTheme.Colors.ctaSecondary,
        DevineTheme.Colors.blush,
        DevineTheme.Colors.borderSubtle,
    ]

    private let rippleDelays: [Double] = [0.0, 0.15, 0.30, 0.45]

    // MARK: - Body

    var body: some View {
        ZStack {
            background

            if !reduceMotion {
                ripples
                droplet
            }

            wordmark
        }
        .scaleEffect(exitScale)
        .opacity(exitOpacity)
        .accessibilityHidden(true)
        .task {
            if reduceMotion {
                await runReducedMotionSequence()
            } else {
                await runFullSequence()
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        LinearGradient(
            colors: DevineTheme.Gradients.screenBackground,
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Droplet

    private var droplet: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: DevineTheme.Gradients.primaryCTA,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 14, height: 14)
            .shadow(color: DevineTheme.Colors.ctaPrimary.opacity(0.4), radius: 8, y: 2)
            .scaleEffect(dropAbsorbed ? 0.3 : dropScale)
            .opacity(dropAbsorbed ? 0 : dropOpacity)
            .offset(y: dropOffsetY)
    }

    // MARK: - Ripples

    private var ripples: some View {
        ZStack {
            ForEach(0 ..< 4, id: \.self) { index in
                Circle()
                    .stroke(rippleColors[index], lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .scaleEffect(rippleExpanded[index] ? 3.5 : 0.01)
                    .opacity(rippleExpanded[index] ? 0 : 0.7)
            }
        }
    }

    // MARK: - Wordmark

    private var wordmark: some View {
        Text("devine")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(DevineTheme.Colors.ctaPrimary)
            .scaleEffect(showWordmark ? 1.0 : 0.8)
            .opacity(showWordmark ? 1 : 0)
    }

    // MARK: - Full Animation Sequence

    @MainActor
    private func runFullSequence() async {
        // Act 1: Droplet appears
        withAnimation(.easeOut(duration: 0.15)) {
            dropOpacity = 1
            dropScale = 1.0
        }

        try? await Task.sleep(for: .milliseconds(50))

        // Droplet falls (gravity — easeIn = accelerating)
        withAnimation(.easeIn(duration: 0.50)) {
            dropOffsetY = 0
        }

        try? await Task.sleep(for: .milliseconds(500))

        // Act 2: Impact
        DevineHaptic.tap.fire()

        withAnimation(.easeOut(duration: 0.15)) {
            dropAbsorbed = true
        }

        // Ripples — staggered
        for i in 0 ..< 4 {
            let delay = rippleDelays[i]
            Task {
                try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
                withAnimation(.easeOut(duration: 0.8)) {
                    rippleExpanded[i] = true
                }
            }
        }

        // Act 3: Wordmark reveal (at ~0.45s after impact, while ripples are mid-flight)
        try? await Task.sleep(for: .milliseconds(450))

        withAnimation(DevineTheme.Motion.expressive) {
            showWordmark = true
        }

        // Hold for stillness
        try? await Task.sleep(for: .milliseconds(800))

        // Act 4: Exit
        withAnimation(.easeInOut(duration: 0.3)) {
            exitScale = 1.02
            exitOpacity = 0
        }

        try? await Task.sleep(for: .milliseconds(300))

        isPresented = false
    }

    // MARK: - Reduced Motion Sequence

    @MainActor
    private func runReducedMotionSequence() async {
        // Simple: show wordmark immediately, hold, fade out
        withAnimation(.easeInOut(duration: 0.3)) {
            showWordmark = true
        }

        try? await Task.sleep(for: .milliseconds(1000))

        withAnimation(.easeInOut(duration: 0.3)) {
            exitOpacity = 0
        }

        try? await Task.sleep(for: .milliseconds(300))

        isPresented = false
    }
}
