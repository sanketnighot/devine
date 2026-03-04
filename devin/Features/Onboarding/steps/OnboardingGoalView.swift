import SwiftUI

struct OnboardingGoalView: View {
    let name: String
    @Binding var selectedGoal: GlowGoal?
    @Binding var customGoalText: String
    let onContinue: () -> Void

    @FocusState private var customFieldFocused: Bool

    // All preset goals — custom card is rendered separately below the grid
    private let presetGoals = GlowGoal.allCases.filter { $0 != .custom }

    private var canContinue: Bool {
        guard let goal = selectedGoal else { return false }
        if goal == .custom { return !customGoalText.trimmingCharacters(in: .whitespaces).isEmpty }
        return true
    }

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

                // Goal grid + custom card
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        // Preset goals — 2-column grid
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(presetGoals) { goal in
                                GoalCard(
                                    goal: goal,
                                    isSelected: selectedGoal == goal
                                ) {
                                    handleGoalSelect(goal)
                                }
                            }
                        }

                        // Custom goal — full-width card with inline text field
                        CustomGoalCard(
                            isSelected: selectedGoal == .custom,
                            text: $customGoalText,
                            isFocused: $customFieldFocused
                        ) {
                            handleGoalSelect(.custom)
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
                        if let goal = selectedGoal, goal != .custom {
                            Image(systemName: goal.iconName)
                                .font(.system(size: 16))
                        }
                        Text(ctaLabel)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(canContinue ? .white : DevineTheme.Colors.textMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        canContinue
                        ? LinearGradient(colors: DevineTheme.Gradients.primaryCTA, startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [DevineTheme.Colors.surfaceCard], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                }
                .disabled(!canContinue)
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
    }

    private var ctaLabel: String {
        guard let goal = selectedGoal else { return "pick one to continue" }
        if goal == .custom {
            return customGoalText.trimmingCharacters(in: .whitespaces).isEmpty
                ? "describe your goal to continue"
                : "this is my goal →"
        }
        return "this is my goal →"
    }

    private func handleGoalSelect(_ goal: GlowGoal) {
        withAnimation(DevineTheme.Motion.expressive) {
            selectedGoal = goal
        }
        DevineHaptic.tap.fire()
        if goal == .custom {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                customFieldFocused = true
            }
        } else {
            customFieldFocused = false
        }
    }
}

// MARK: - Custom Goal Card

private struct CustomGoalCard: View {
    let isSelected: Bool
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : DevineTheme.Colors.ctaPrimary)

                    Text("Something else")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isSelected ? .white : DevineTheme.Colors.textPrimary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text("tell me what you're working on")
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : DevineTheme.Colors.textMuted)

                // Inline text field — only visible when selected
                if isSelected {
                    TextField("e.g. better posture, glow-up, stress relief...", text: $text, axis: .vertical)
                        .lineLimit(1...3)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .tint(.white)
                        .focused(isFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: DevineTheme.Radius.md, style: .continuous)
                                .fill(Color.white.opacity(0.2))
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture {} // absorb tap so button doesn't toggle off
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected
                ? LinearGradient(
                    colors: [DevineTheme.Colors.ctaPrimary, DevineTheme.Colors.ctaPrimary.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : LinearGradient(
                    colors: [DevineTheme.Colors.surfaceCard],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DevineTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DevineTheme.Radius.lg)
                    .stroke(
                        isSelected ? Color.clear : DevineTheme.Colors.ctaPrimary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1, dash: [5, 3])
                    )
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(DevineTheme.Motion.expressive, value: isSelected)
        }
        .buttonStyle(.plain)
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
        case .custom: return ""
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
