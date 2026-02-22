import SwiftUI

struct HomeView: View {
    @ObservedObject var model: DevineAppModel
    let isSubscribed: Bool
    let onShowPaywall: () -> Void

    @State private var selectedAction: PerfectAction?
    @State private var showingMirrorCheckin = false
    @State private var showingMirrorTimeline = false
    @State private var showCelebration = false
    @State private var celebrationMessage = "Tiny win. Keep going."
    @State private var celebratedMilestone: Int?
    @State private var showWeeklyRecap = false
    @AppStorage("last_recap_week") private var lastRecapWeek: Int = 0

    private var completedCount: Int {
        model.todayActions.filter { model.isActionDone($0) }.count
    }

    private var allDone: Bool {
        completedCount == model.todayActions.count
    }

    private var scoreTrendData: [Double] {
        model.evidenceLedger.suffix(10).reversed().map { _ in
            Double(model.glowScore ?? 0) + Double.random(in: -6 ... 6)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DevineTheme.Spacing.xl) {
                    greetingSection
                    scoreHero
                    primaryActionHero
                    todayProgressSection
                    streakSection
                    weekSummaryCard
                    timelineLink

                    if !isSubscribed {
                        upgradePill
                    }
                }
                .padding(.horizontal, DevineTheme.Spacing.lg)
                .padding(.top, DevineTheme.Spacing.md)
                .padding(.bottom, DevineTheme.Spacing.xxxl)
            }
            .background(
                LinearGradient(
                    colors: DevineTheme.Gradients.screenBackground,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("devine")
            .foregroundStyle(DevineTheme.Colors.textPrimary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        DevineHaptic.tap.fire()
                        showingMirrorCheckin = true
                    } label: {
                        Image(systemName: "camera.viewfinder")
                            .font(.body.weight(.medium))
                            .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                    }
                }
            }
            .sheet(item: $selectedAction) { action in
                ActionPlayerSheet(action: action) {
                    model.markActionDone(action)
                    DevineHaptic.actionComplete.fire()
                    triggerCelebrationIfNeeded()
                }
                .presentationBackground(DevineTheme.Colors.bgPrimary)
            }
            .sheet(isPresented: $showingMirrorCheckin) {
                MirrorCheckinSheet(
                    model: model,
                    onOpenTimeline: {
                        showingMirrorTimeline = true
                    }
                )
                .presentationBackground(DevineTheme.Colors.bgPrimary)
            }
            .navigationDestination(isPresented: $showingMirrorTimeline) {
                MirrorTimelineView(model: model)
            }
            .sheet(isPresented: $showWeeklyRecap) {
                WeeklyRecapSheet(model: model)
                    .presentationBackground(DevineTheme.Colors.bgPrimary)
            }
            .overlay {
                CelebrationOverlay(
                    isPresented: $showCelebration,
                    message: celebrationMessage
                )
            }
            .onAppear {
                model.rollOverIfNeeded()
                checkStreakMilestone()
                checkWeeklyRecap()
            }
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        TimeGreeting(goal: model.primaryGoal)
    }

    // MARK: - Score Hero

    private var scoreHero: some View {
        Group {
            if let score = model.glowScore {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                        HStack(spacing: DevineTheme.Spacing.lg) {
                            ProgressRing(
                                value: Double(score),
                                maxValue: 100,
                                size: 90,
                                lineWidth: 10
                            )

                            VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                                Text("Glow Score")
                                    .font(.system(.headline, design: .rounded, weight: .bold))

                                Text("Updated \(model.lastUpdatedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(DevineTheme.Colors.textSecondary)

                                Text("Evidence-backed & private")
                                    .font(.caption2)
                                    .foregroundStyle(DevineTheme.Colors.textMuted)
                            }

                            Spacer()
                        }

                        if scoreTrendData.count >= 2 {
                            TrendSparkline(
                                dataPoints: scoreTrendData,
                                accentColor: model.primaryGoal.accentColor,
                                height: 36
                            )
                        }
                    }
                }
            } else {
                GradientCard(colors: DevineTheme.Gradients.heroCard, showGlow: true) {
                    VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                        HStack(spacing: DevineTheme.Spacing.md) {
                            ProgressRing(
                                value: 0,
                                maxValue: 100,
                                size: 64,
                                lineWidth: 8,
                                trackColor: Color.white.opacity(0.2),
                                showLabel: false,
                                showGlow: false
                            )

                            VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                                Text("No score yet")
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                    .foregroundStyle(DevineTheme.Colors.textOnGradient)

                                Text("Your first mirror check-in unlocks it")
                                    .font(.caption)
                                    .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.8))
                            }
                        }

                        Button {
                            DevineHaptic.tap.fire()
                            showingMirrorCheckin = true
                        } label: {
                            Text("Start check-in")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DevineTheme.Gradients.heroCard.first ?? .pink)
                                .padding(.horizontal, DevineTheme.Spacing.xl)
                                .padding(.vertical, DevineTheme.Spacing.sm)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.white)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Primary Action Hero

    private var primaryActionHero: some View {
        Group {
            if let next = model.nextPendingAction {
                GradientCard(
                    colors: [model.primaryGoal.accentColor, model.primaryGoal.accentColor.opacity(0.7)],
                    showGlow: true
                ) {
                    VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                        HStack {
                            Text("Your next move")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.85))
                                .textCase(.uppercase)
                                .tracking(0.8)

                            Spacer()

                            Text("\(next.estimatedMinutes) min")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.7))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.white.opacity(0.2))
                                )
                        }

                        Text(next.title)
                            .font(.title3.bold())
                            .foregroundStyle(DevineTheme.Colors.textOnGradient)

                        Text(next.instructions)
                            .font(.subheadline)
                            .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.85))
                            .lineSpacing(2)

                        Button {
                            DevineHaptic.tap.fire()
                            selectedAction = next
                        } label: {
                            HStack(spacing: DevineTheme.Spacing.sm) {
                                Text("Start now")
                                    .font(.subheadline.weight(.bold))
                                Image(systemName: "arrow.right")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(model.primaryGoal.accentColor)
                            .padding(.horizontal, DevineTheme.Spacing.xl)
                            .padding(.vertical, DevineTheme.Spacing.md)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.white)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                allDoneCard
            }
        }
    }

    private var allDoneCard: some View {
        SurfaceCard {
            HStack(spacing: DevineTheme.Spacing.md) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(
                            colors: DevineTheme.Gradients.primaryCTA,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                    Text("All done for today!")
                        .font(.system(.headline, design: .rounded, weight: .bold))

                    Text("Consistency is your glow multiplier")
                        .font(.caption)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Today's Progress

    private var todayProgressSection: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
            HStack {
                Text("Today's progress")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textPrimary)

                Spacer()

                Text("\(completedCount)/\(model.todayActions.count)")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
            }

            MiniProgressBar(
                value: Double(completedCount),
                maxValue: Double(model.todayActions.count),
                height: 6
            )

            HStack(spacing: DevineTheme.Spacing.sm) {
                ForEach(model.todayActions) { action in
                    ActionPill(
                        title: action.title,
                        estimatedMinutes: action.estimatedMinutes,
                        isCompleted: model.isActionDone(action)
                    ) {
                        DevineHaptic.tap.fire()
                        selectedAction = action
                    }
                }
            }
        }
    }

    // MARK: - Streak

    private var streakSection: some View {
        StreakCard(streakDays: model.streakDays)
    }

    // MARK: - Week Summary Card

    private var weekSummaryCard: some View {
        Button {
            DevineHaptic.tap.fire()
            showWeeklyRecap = true
        } label: {
            SurfaceCard(padding: DevineTheme.Spacing.md) {
                HStack(spacing: DevineTheme.Spacing.md) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.body.weight(.medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: DevineTheme.Gradients.primaryCTA,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("This week")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(DevineTheme.Colors.textPrimary)

                        Text("\(completedCount)/\(model.todayActions.count) today · \(model.thisWeekCheckinCount) check-in\(model.thisWeekCheckinCount == 1 ? "" : "s")")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timeline Link

    private var timelineLink: some View {
        Button {
            DevineHaptic.tap.fire()
            showingMirrorTimeline = true
        } label: {
            SurfaceCard(padding: DevineTheme.Spacing.md) {
                HStack(spacing: DevineTheme.Spacing.md) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.body.weight(.medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: DevineTheme.Gradients.primaryCTA,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Progress timeline")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(DevineTheme.Colors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Upgrade Pill (bottom, subtle)

    private var upgradePill: some View {
        Button {
            DevineHaptic.tap.fire()
            onShowPaywall()
        } label: {
            HStack(spacing: DevineTheme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text("Unlock full plan")
                    .font(.caption.weight(.semibold))
                Image(systemName: "arrow.right")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(DevineTheme.Colors.ctaPrimary)
            .padding(.horizontal, DevineTheme.Spacing.lg)
            .padding(.vertical, DevineTheme.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                Capsule(style: .continuous)
                    .fill(DevineTheme.Colors.ctaPrimary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Celebration Logic

    private func checkWeeklyRecap() {
        let currentWeek = Calendar.current.component(.weekOfYear, from: .now)
        guard currentWeek != lastRecapWeek,
              model.streakDays > 0 || model.thisWeekCheckinCount > 0
        else { return }

        lastRecapWeek = currentWeek
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showWeeklyRecap = true
        }
    }

    private func checkStreakMilestone() {
        guard StreakMilestone.isExactMilestone(model.streakDays),
              celebratedMilestone != model.streakDays
        else { return }

        celebratedMilestone = model.streakDays
        celebrationMessage = StreakMilestone.celebrationCopy(for: model.streakDays)
            ?? "Milestone reached!"
        DevineHaptic.streakMilestone.fire()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCelebration = true
        }
    }

    private func triggerCelebrationIfNeeded() {
        let newCount = model.todayActions.filter { model.isActionDone($0) }.count
        if newCount == model.todayActions.count {
            celebrationMessage = "All done! You're glowing."
            DevineHaptic.allActionsComplete.fire()
        } else {
            celebrationMessage = "Tiny win. Keep going."
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showCelebration = true
        }
    }
}
