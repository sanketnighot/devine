import SwiftUI

struct OnboardingGoalView: View {
    let name: String
    @Binding var selectedGoal: GlowGoal?
    let onContinue: () -> Void

    private let goals = GlowGoal.allCases

    var body: some View {
        ZStack {
            DevineTheme.Colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Headline
                VStack(alignment: .leading, spacing: 6) {
                    TypewriterText(
                        text: "alright \(name), what's your",
                        speed: 45,
                        font: .system(size: 15, weight: .medium),
                        color: DevineTheme.Colors.textSecondary
                    )
                    TypewriterText(
                        text: "main vibe right now? ✨",
                        speed: 40,
                        font: .system(size: 26, weight: .bold),
                        color: DevineTheme.Colors.textPrimary
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 8)
                .padding(.bottom, 20)

                // Goal grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(goals) { goal in
                            GoalCard(
                                goal: goal,
                                isSelected: selectedGoal == goal
                            ) {
                                handleGoalSelect(goal)
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 16)
                }

                Spacer(minLength: 0)

                // CTA
                Button(action: {
                    DevineHaptic.tap.fire()
                    onContinue()
                }) {
                    HStack(spacing: 8) {
                        if let goal = selectedGoal {
                            Image(systemName: goal.iconName)
                                .font(.system(size: 16))
                        }
                        Text(selectedGoal == nil ? "pick one to continue" : "this is my goal →")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(selectedGoal == nil ? DevineTheme.Colors.textMuted : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        selectedGoal == nil
                        ? LinearGradient(colors: [DevineTheme.Colors.surfaceCard], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: DevineTheme.Gradients.primaryCTA, startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                }
                .disabled(selectedGoal == nil)
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }

        }
    }

    private func handleGoalSelect(_ goal: GlowGoal) {
        withAnimation(DevineTheme.Motion.expressive) {
            selectedGoal = goal
        }
        DevineHaptic.tap.fire()
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: GlowGoal
    let isSelected: Bool
    let onTap: () -> Void

    private var goalDescription: String {
        switch goal {
        case .faceDefinition: return "jawline, gua sha, lymph drainage"
        case .skinGlow: return "hydration, barrier health, texture"
        case .bodySilhouette: return "movement, posture, silhouette"
        case .hairStyle: return "growth, texture, signature style"
        case .energyFitness: return "sleep, cardio, daily energy"
        case .confidenceConsistency: return "mindset, habits, self-belief"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: goal.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? .white : goal.accentColor)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(goal.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isSelected ? .white : DevineTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)

                Text(goalDescription)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : DevineTheme.Colors.textMuted)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 120)
            .background(
                isSelected
                ? LinearGradient(colors: [goal.accentColor, goal.accentColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [DevineTheme.Colors.surfaceCard], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: DevineTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DevineTheme.Radius.lg)
                    .stroke(isSelected ? Color.clear : DevineTheme.Colors.borderSubtle, lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(DevineTheme.Motion.expressive, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
