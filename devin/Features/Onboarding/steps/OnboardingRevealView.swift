import SwiftUI

struct OnboardingRevealView: View {
    let name: String
    let goal: GlowGoal
    let plan: GeneratedPlan?
    let onComplete: () -> Void

    @State private var showHeader = false
    @State private var showScore = false
    @State private var showActions = false
    @State private var showCTA = false
    @State private var showCelebration = false
    @State private var selectedDayIndex = 0

    private var selectedPlan: DailyPlan? {
        guard let plans = plan?.dailyPlans, plans.indices.contains(selectedDayIndex) else {
            return plan?.todayPlan
        }
        return plans[selectedDayIndex]
    }

    private var selectedActions: [PerfectAction] {
        if let p = selectedPlan {
            return p.actions.map { $0.toPerfectAction() }
        }
        return PerfectAction.defaults(for: goal)
    }

    var body: some View {
        ZStack {
            DevineTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Hero card
                    if showHeader {
                        GradientCard(showGlow: true) {
                            VStack(spacing: 12) {
                                HStack {
                                    GoalBadge(goal: goal, style: .standard)
                                    Spacer()
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white.opacity(0.8))
                                }

                                Text("your 7-day plan is set ✨")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(DevineTheme.Colors.textOnGradient)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if let summary = plan?.summary {
                                    Text(summary)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.85))
                                        .fixedSize(horizontal: false, vertical: true)
                                } else {
                                    Text("3 daily actions, perfectly matched to your goal. Let's make it happen.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            }
                            .padding(DevineTheme.Spacing.lg)
                        }
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                    }

                    // Glow Score preview
                    if showScore, let score = plan?.initialGlowScore {
                        SurfaceCard {
                            HStack(spacing: DevineTheme.Spacing.lg) {
                                ProgressRing(
                                    value: Double(score),
                                    maxValue: 100,
                                    size: 64,
                                    lineWidth: 8
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("your starting glow score")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(DevineTheme.Colors.textMuted)
                                        .textCase(.uppercase)
                                        .tracking(0.5)

                                    Text("\(score)/100")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(DevineTheme.Colors.textPrimary)

                                    Text("AI-estimated based on your profile")
                                        .font(.system(size: 11))
                                        .foregroundColor(DevineTheme.Colors.textSecondary)
                                }

                                Spacer()
                            }
                        }
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                    }

                    // Selected day's actions
                    if showActions {
                        VStack(spacing: 12) {
                            HStack {
                                Text(selectedPlan.map { "day \($0.dayNumber) — \($0.theme.lowercased()) 🔥" } ?? "today's actions 🔥")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(DevineTheme.Colors.textSecondary)
                                    .animation(DevineTheme.Motion.quick, value: selectedDayIndex)

                                Spacer()
                            }

                            ForEach(Array(selectedActions.enumerated()), id: \.element.id) { i, action in
                                ActionRevealCard(action: action, index: i, goal: goal)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }

                            // Week preview
                            if let plan, plan.dailyPlans.count > 1 {
                                weekPreviewStrip(plan: plan)
                                    .transition(.opacity)
                            }
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }

            // Sticky CTA
            VStack {
                Spacer()
                if showCTA {
                    Button(action: handleComplete) {
                        Text("let's glow 🌟")
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
                    .background(
                        DevineTheme.Colors.bgPrimary
                            .opacity(0.95)
                            .ignoresSafeArea()
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            CelebrationOverlay(isPresented: $showCelebration, message: "")
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(DevineTheme.Motion.expressive) { showHeader = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(DevineTheme.Motion.expressive) { showScore = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(DevineTheme.Motion.expressive) { showActions = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                showCelebration = true
                DevineHaptic.allActionsComplete.fire()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(DevineTheme.Motion.expressive) { showCTA = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                showCelebration = false
            }
        }
    }

    private func handleComplete() {
        DevineHaptic.streakMilestone.fire()
        onComplete()
    }

    // MARK: - Week Preview Strip

    private func weekPreviewStrip(plan: GeneratedPlan) -> some View {
        SurfaceCard(padding: DevineTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 10) {
                Text("your 7-day roadmap")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DevineTheme.Colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(plan.dailyPlans.enumerated()), id: \.element.id) { idx, day in
                            let isSelected = idx == selectedDayIndex
                            Button {
                                withAnimation(DevineTheme.Motion.quick) {
                                    selectedDayIndex = idx
                                }
                                DevineHaptic.tap.fire()
                            } label: {
                                VStack(spacing: 6) {
                                    Text("D\(day.dayNumber)")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(isSelected ? .white : DevineTheme.Colors.textSecondary)
                                        .frame(width: 28, height: 28)
                                        .background(
                                            Circle()
                                                .fill(isSelected
                                                      ? goal.accentColor
                                                      : DevineTheme.Colors.bgSecondary)
                                        )

                                    Text(day.theme)
                                        .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                                        .foregroundColor(isSelected ? goal.accentColor : DevineTheme.Colors.textMuted)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 64)
                                }
                            }
                            .buttonStyle(.plain)
                            .animation(DevineTheme.Motion.quick, value: selectedDayIndex)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Action Reveal Card

private struct ActionRevealCard: View {
    let action: PerfectAction
    let index: Int
    let goal: GlowGoal

    @State private var appeared = false

    var body: some View {
        SurfaceCard(cornerRadius: DevineTheme.Radius.lg, padding: DevineTheme.Spacing.lg) {
            HStack(spacing: 14) {
                // Number badge
                Text("\(index + 1)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(goal.accentColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(action.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DevineTheme.Colors.textPrimary)

                    Text(action.instructions)
                        .font(.system(size: 13))
                        .foregroundColor(DevineTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Time estimate
                VStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("\(action.estimatedMinutes)m")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(DevineTheme.Colors.textMuted)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 20)
        .onAppear {
            withAnimation(DevineTheme.Motion.expressive) {
                appeared = true
            }
        }
    }
}
