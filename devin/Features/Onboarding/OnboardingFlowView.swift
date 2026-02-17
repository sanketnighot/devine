import SwiftUI

struct OnboardingResult {
    let goal: GlowGoal
    let didProvidePhotoEvidence: Bool
}

private enum OnboardingStep: Int, CaseIterable {
    case welcome
    case goal
    case photo
    case preview
}

struct OnboardingFlowView: View {
    let onComplete: (OnboardingResult) -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var selectedGoal: GlowGoal?
    @State private var didProvidePhotoEvidence = false

    var body: some View {
        VStack(spacing: 24) {
            header
            content
            controls
        }
        .padding(24)
        .frame(maxWidth: 580)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [DevineTheme.Colors.bgPrimary, DevineTheme.Colors.bgSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .foregroundStyle(DevineTheme.Colors.textPrimary)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            if step != .welcome {
                Button("Back") {
                    if let previous = OnboardingStep(rawValue: step.rawValue - 1) {
                        step = previous
                    }
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
            }

            Text("devine")
                .font(.title.bold())

            ProgressView(value: Double(step.rawValue + 1), total: Double(OnboardingStep.allCases.count))
                .tint(DevineTheme.Colors.ringProgress)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            VStack(alignment: .leading, spacing: 12) {
                Text("Glow up, but make it real.")
                    .font(.largeTitle.bold())
                Text("You will get a plan that evolves with you through small, sustainable daily actions.")
                    .font(.body)
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                labelRow(text: "Photo is optional.")
                labelRow(text: "Private by default.")
                labelRow(text: "No public rankings.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .goal:
            VStack(alignment: .leading, spacing: 14) {
                Text("What do you want to upgrade first?")
                    .font(.title2.bold())

                ForEach(GlowGoal.allCases) { goal in
                    Button {
                        selectedGoal = goal
                    } label: {
                        HStack {
                            Text(goal.displayName)
                                .font(.headline)
                            Spacer()
                            if selectedGoal == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DevineTheme.Colors.successAccent)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selectedGoal == goal ? DevineTheme.Colors.ctaPrimary.opacity(0.16) : DevineTheme.Colors.surfaceCard)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .photo:
            VStack(alignment: .leading, spacing: 12) {
                Text("Optional check-in photo")
                    .font(.title2.bold())
                Text("A private photo can unlock a verified Glow Score. You can skip and add this later.")
                    .font(.body)
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                Button("Add quick check-in now") {
                    didProvidePhotoEvidence = true
                    step = .preview
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(DevineTheme.Colors.ctaPrimary)

                Button("Skip for now") {
                    didProvidePhotoEvidence = false
                    step = .preview
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(DevineTheme.Colors.ctaSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .preview:
            VStack(alignment: .leading, spacing: 14) {
                Text("Your plan preview")
                    .font(.title2.bold())
                if didProvidePhotoEvidence {
                    scorePreviewCard
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No numeric score yet")
                            .font(.headline)
                        Text("Your first plan is ready. Add a mirror check-in to unlock a verified Glow Score.")
                            .font(.body)
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(DevineTheme.Colors.surfaceCard)
                    )
                }

                Text("Next step: choose your subscription to unlock your full plan and daily action loop.")
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var controls: some View {
        HStack {
            Spacer()
            switch step {
            case .welcome:
                Button("Start") {
                    step = .goal
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(DevineTheme.Colors.ctaPrimary)

            case .goal:
                Button("Continue") {
                    step = .photo
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedGoal == nil)
                .tint(DevineTheme.Colors.ctaPrimary)

            case .photo:
                EmptyView()

            case .preview:
                Button("Continue to subscription") {
                    onComplete(
                        OnboardingResult(
                            goal: selectedGoal ?? .faceDefinition,
                            didProvidePhotoEvidence: didProvidePhotoEvidence
                        )
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(DevineTheme.Colors.ctaPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var scorePreviewCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(DevineTheme.Colors.bgSecondary)
                    .frame(width: 56, height: 56)

                Image(systemName: "checkmark.shield.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DevineTheme.Colors.successAccent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Evidence received")
                    .font(.headline)
                Text("Your full score will appear after the first mirror analysis. No fake numbers.")
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                    .font(.subheadline)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DevineTheme.Colors.surfaceCard)
        )
    }

    private func labelRow(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DevineTheme.Colors.successAccent)
            Text(text)
                .font(.subheadline.weight(.medium))
        }
    }
}
