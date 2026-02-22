import SwiftUI

struct ActionPlayerSheet: View {
    let action: PerfectAction
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var completed = false
    @State private var timerProgress: Double = 0
    @State private var showCheckmark = false
    @State private var showEncouragement = false

    private static let encouragements = [
        "Tiny win. Keep going.",
        "You showed up. That matters.",
        "One step closer to glowing.",
        "Consistency looks good on you.",
        "Done is better than perfect."
    ]

    @State private var encouragement = encouragements.randomElement() ?? "Tiny win. Keep going."

    var body: some View {
        ZStack {
            LinearGradient(
                colors: DevineTheme.Gradients.screenBackground,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator
                Capsule(style: .continuous)
                    .fill(DevineTheme.Colors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, DevineTheme.Spacing.sm)

                ScrollView {
                    VStack(spacing: DevineTheme.Spacing.xxl) {
                        gradientHeader
                        timerSection
                        instructionsSection
                        actionButton
                    }
                    .padding(.horizontal, DevineTheme.Spacing.xl)
                    .padding(.top, DevineTheme.Spacing.lg)
                    .padding(.bottom, DevineTheme.Spacing.xxxl)
                }
            }

            // Completion overlay
            if showEncouragement {
                completionOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .onAppear {
            DevineHaptic.sheetPresent.fire()
            startTimerAnimation()
        }
    }

    // MARK: - Gradient Header

    private var gradientHeader: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
            HStack {
                Text("Your next move")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(DevineTheme.Colors.bgSecondary)
                        )
                }
                .buttonStyle(.plain)
            }

            Text(action.title)
                .font(.title2.bold())
                .foregroundStyle(DevineTheme.Colors.textPrimary)
        }
    }

    // MARK: - Timer Ring Section

    private var timerSection: some View {
        VStack(spacing: DevineTheme.Spacing.md) {
            ZStack {
                Circle()
                    .stroke(DevineTheme.Colors.ringTrack, lineWidth: 8)

                Circle()
                    .trim(from: 0, to: completed ? 1.0 : timerProgress)
                    .stroke(
                        AngularGradient(
                            colors: completedGradient + [completedGradient.first ?? .pink],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                if timerProgress > 0 || completed {
                    Circle()
                        .trim(from: 0, to: completed ? 1.0 : timerProgress)
                        .stroke(
                            completedGradient.first ?? .pink,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 6)
                        .opacity(0.25)
                }

                VStack(spacing: DevineTheme.Spacing.xs) {
                    if completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(DevineTheme.Colors.successAccent)
                            .scaleEffect(showCheckmark ? 1 : 0.3)
                            .opacity(showCheckmark ? 1 : 0)
                    } else {
                        Text("\(action.estimatedMinutes)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(DevineTheme.Colors.textPrimary)
                            .contentTransition(.numericText())

                        Text("min")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    }
                }
            }
            .frame(width: 120, height: 120)

            Text(completed ? "Complete!" : "Self-paced")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(completed ? DevineTheme.Colors.successAccent : DevineTheme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var completedGradient: [Color] {
        completed
            ? [DevineTheme.Colors.successAccent, DevineTheme.Colors.successAccent]
            : DevineTheme.Gradients.primaryCTA
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        SurfaceCard(cornerRadius: DevineTheme.Radius.lg, padding: DevineTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                Label("Instructions", systemImage: "list.bullet")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(action.instructions)
                    .font(.body)
                    .foregroundStyle(DevineTheme.Colors.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        if !completed {
            Button {
                markDone()
            } label: {
                HStack(spacing: DevineTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body.weight(.semibold))
                    Text("Mark as done")
                        .font(.headline)
                }
                .foregroundStyle(DevineTheme.Colors.textOnGradient)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DevineTheme.Spacing.lg)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: DevineTheme.Gradients.primaryCTA,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: DevineTheme.Gradients.primaryCTA.first?.opacity(0.3) ?? .clear, radius: 12, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: DevineTheme.Spacing.xl) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: DevineTheme.Gradients.primaryCTA,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(showCheckmark ? 1 : 0.5)

                Text(encouragement)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(DevineTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(DevineTheme.Spacing.xxxl)
            .background(
                RoundedRectangle(cornerRadius: DevineTheme.Radius.xxl, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    // MARK: - Logic

    private func startTimerAnimation() {
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            timerProgress = 0.15
        }
    }

    private func markDone() {
        DevineHaptic.actionComplete.fire()

        withAnimation(DevineTheme.Motion.expressive) {
            completed = true
            timerProgress = 1.0
        }

        withAnimation(DevineTheme.Motion.celebration.delay(0.15)) {
            showCheckmark = true
        }

        withAnimation(DevineTheme.Motion.standard.delay(0.4)) {
            showEncouragement = true
        }

        onComplete()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(DevineTheme.Motion.quick) {
                showEncouragement = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }
    }
}
