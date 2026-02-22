import SwiftUI

struct PlanView: View {
    @ObservedObject var model: DevineAppModel

    @State private var stabilityExpanded = false
    @State private var evidenceExpanded = false
    @State private var selectedAction: PerfectAction?
    @State private var showSubscores = false
    @State private var showPlanHistory = false

    private var completedCount: Int {
        model.todayActions.filter { model.isActionDone($0) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DevineTheme.Spacing.xl) {
                    planHeader
                    scoreTrajectoryHero
                    subscoreLink
                    weekSection
                    todayActionsSection
                    stabilitySection
                    evidenceSection
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
            .foregroundStyle(DevineTheme.Colors.textPrimary)
            .navigationTitle("Your Plan")
            .sheet(item: $selectedAction) { action in
                ActionPlayerSheet(action: action) {
                    model.markActionDone(action)
                    DevineHaptic.actionComplete.fire()
                }
                .presentationBackground(DevineTheme.Colors.bgPrimary)
            }
            .navigationDestination(isPresented: $showSubscores) {
                SubscoreBreakdownView(model: model)
            }
            .navigationDestination(isPresented: $showPlanHistory) {
                PlanHistoryView(model: model)
            }
        }
        .tint(DevineTheme.Colors.ctaPrimary)
    }

    // MARK: - Plan Header

    private var planHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                GoalBadge(goal: model.primaryGoal, style: .compact)

                Text("Updated \(model.lastUpdatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(DevineTheme.Colors.textMuted)
            }

            Spacer()

            confidencePill(value: model.confidence)
        }
    }

    // MARK: - Score + Trajectory Hero

    private var scoreTrajectoryHero: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.lg) {
                if let score = model.glowScore {
                    HStack(spacing: DevineTheme.Spacing.lg) {
                        ProgressRing(
                            value: Double(score),
                            maxValue: 100,
                            size: 80,
                            lineWidth: 9
                        )

                        VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
                            Text("Glow Score")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(DevineTheme.Colors.textMuted)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Text("\(score)/100")
                                .font(.system(.title3, design: .rounded, weight: .bold))

                            Text(scoreInterpretation(score))
                                .font(.caption)
                                .foregroundStyle(DevineTheme.Colors.textSecondary)
                                .lineSpacing(2)
                        }

                        Spacer()
                    }

                    if let trajectory = model.goalTrajectory {
                        Divider()
                            .foregroundStyle(DevineTheme.Colors.borderSubtle)

                        trajectoryRow(trajectory)
                    }
                } else {
                    noScoreState
                }
            }
        }
    }

    private func trajectoryRow(_ trajectory: GoalTrajectory) -> some View {
        HStack(spacing: DevineTheme.Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.body.weight(.medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: DevineTheme.Gradients.primaryCTA,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                Text("Estimated timeline")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)

                HStack(spacing: DevineTheme.Spacing.sm) {
                    trajectoryChip(label: "Best", value: "\(trajectory.minWeeks)w")
                    trajectoryChip(label: "Likely", value: "\(trajectory.likelyWeeks)w")
                    trajectoryChip(label: "Max", value: "\(trajectory.maxWeeks)w")
                }
            }

            Spacer()
        }
    }

    private func trajectoryChip(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(DevineTheme.Colors.textMuted)
        }
        .padding(.horizontal, DevineTheme.Spacing.md)
        .padding(.vertical, DevineTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DevineTheme.Radius.sm, style: .continuous)
                .fill(DevineTheme.Colors.bgSecondary)
        )
    }

    private var noScoreState: some View {
        HStack(spacing: DevineTheme.Spacing.lg) {
            ProgressRing(
                value: 0,
                maxValue: 100,
                size: 64,
                lineWidth: 7,
                showLabel: false,
                showGlow: false
            )

            VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                Text("No score yet")
                    .font(.system(.headline, design: .rounded, weight: .bold))

                Text("Complete a mirror check-in to unlock your score and timeline estimate.")
                    .font(.caption)
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                    .lineSpacing(2)
            }

            Spacer()
        }
    }

    // MARK: - Subscore Link

    @ViewBuilder
    private var subscoreLink: some View {
        if model.glowScore != nil {
            Button {
                DevineHaptic.tap.fire()
                showSubscores = true
            } label: {
                SurfaceCard(padding: DevineTheme.Spacing.md) {
                    HStack(spacing: DevineTheme.Spacing.md) {
                        HStack(spacing: -6) {
                            ForEach(model.subscores.prefix(4)) { entry in
                                ZStack {
                                    Circle()
                                        .fill(entry.accentColor.opacity(0.15))
                                        .frame(width: 28, height: 28)

                                    Image(systemName: entry.icon)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(entry.accentColor)
                                }
                                .background(
                                    Circle()
                                        .fill(DevineTheme.Colors.surfaceCard)
                                        .frame(width: 30, height: 30)
                                )
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your Glow Map")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(DevineTheme.Colors.textPrimary)

                            Text("See what's driving your score")
                                .font(.system(.caption2, design: .rounded, weight: .medium))
                                .foregroundStyle(DevineTheme.Colors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - This Week

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
            Text("This week")
                .font(.system(.subheadline, design: .rounded, weight: .bold))

            SurfaceCard(padding: DevineTheme.Spacing.md) {
                WeekStrip(completedDays: completedWeekdays(), accentColor: model.primaryGoal.accentColor)
            }
        }
    }

    // MARK: - Today's Actions

    private var todayActionsSection: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
            HStack {
                Text("Today's actions")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))

                Spacer()

                Text("\(completedCount)/\(model.todayActions.count)")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
            }

            MiniProgressBar(
                value: Double(completedCount),
                maxValue: Double(model.todayActions.count),
                height: 5
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

    // MARK: - Stability (Collapsible)

    private var stabilitySection: some View {
        CollapsibleSection(
            title: "Plan stability",
            icon: "lock.shield",
            isExpanded: $stabilityExpanded
        ) {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                HStack(spacing: DevineTheme.Spacing.sm) {
                    Text("Current:")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DevineTheme.Colors.textMuted)

                    severityPill(model.latestAdjustmentSeverity)
                }

                Text("Your plan theme is locked for consistency. It adjusts only when evidence supports a change.")
                    .font(.caption)
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                    .lineSpacing(2)

                if !model.planAdjustmentHistory.isEmpty {
                    Button {
                        DevineHaptic.tap.fire()
                        withAnimation(DevineTheme.Motion.quick) { showPlanHistory = true }
                    } label: {
                        HStack {
                            Text("View plan history")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(DevineTheme.Colors.textMuted)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Evidence Log (Collapsible)

    private var evidenceSection: some View {
        CollapsibleSection(
            title: "Evidence log",
            icon: "doc.text.magnifyingglass",
            count: model.evidenceLedger.count,
            isExpanded: $evidenceExpanded
        ) {
            if model.evidenceLedger.isEmpty {
                Text("Mirror check-ins will populate your evidence log here.")
                    .font(.caption)
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
            } else {
                VStack(spacing: DevineTheme.Spacing.md) {
                    ForEach(model.evidenceLedger.prefix(5)) { event in
                        evidenceRow(event)
                    }
                }
            }
        }
    }

    private func evidenceRow(_ event: EvidenceEvent) -> some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
            Text(event.summary)
                .font(.caption.weight(.semibold))

            HStack(spacing: DevineTheme.Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(DevineTheme.Colors.successAccent)
                Text(event.evidenceUsed.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(DevineTheme.Colors.textMuted)
            }

            if !event.evidenceMissing.isEmpty {
                HStack(spacing: DevineTheme.Spacing.xs) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 9))
                        .foregroundStyle(DevineTheme.Colors.warningAccent)
                    Text(event.evidenceMissing.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                }
            }

            Text(event.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(DevineTheme.Colors.textMuted.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DevineTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DevineTheme.Radius.md, style: .continuous)
                .fill(DevineTheme.Colors.bgSecondary)
        )
    }

    // MARK: - Helpers

    private func confidencePill(value: Double) -> some View {
        HStack(spacing: DevineTheme.Spacing.xs) {
            Circle()
                .fill(confidenceColor(value))
                .frame(width: 6, height: 6)
            Text("\(Int(value * 100))%")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(DevineTheme.Colors.textMuted)
        }
        .padding(.horizontal, DevineTheme.Spacing.sm)
        .padding(.vertical, DevineTheme.Spacing.xs)
        .background(
            Capsule(style: .continuous)
                .fill(DevineTheme.Colors.bgSecondary)
        )
    }

    private func confidenceColor(_ value: Double) -> Color {
        if value >= 0.7 { return DevineTheme.Colors.successAccent }
        if value >= 0.4 { return DevineTheme.Colors.warningAccent }
        return DevineTheme.Colors.textMuted
    }

    private func severityPill(_ severity: PlanAdjustmentSeverity) -> some View {
        HStack(spacing: DevineTheme.Spacing.xs) {
            Circle()
                .fill(severityColor(for: severity))
                .frame(width: 6, height: 6)
            Text(severityLabel(severity))
                .font(.caption.weight(.semibold))
                .foregroundStyle(severityColor(for: severity))
        }
        .padding(.horizontal, DevineTheme.Spacing.sm)
        .padding(.vertical, DevineTheme.Spacing.xs)
        .background(
            Capsule(style: .continuous)
                .fill(severityColor(for: severity).opacity(0.1))
        )
    }

    private func severityLabel(_ severity: PlanAdjustmentSeverity) -> String {
        switch severity {
        case .minorTweak: "Minor tweak"
        case .resequence: "Resequence"
        case .pivot: "Pivot"
        }
    }

    private func severityColor(for severity: PlanAdjustmentSeverity) -> Color {
        switch severity {
        case .minorTweak: DevineTheme.Colors.successAccent
        case .resequence: DevineTheme.Colors.warningAccent
        case .pivot: DevineTheme.Colors.errorAccent
        }
    }

    private func scoreInterpretation(_ score: Int) -> String {
        switch score {
        case 0..<60:
            "Early momentum. Focus on consistency over intensity."
        case 60..<80:
            "Solid baseline. Small daily actions will move this up."
        default:
            "Strong position. Maintain stability and avoid over-correcting."
        }
    }

    private func completedWeekdays() -> Set<Int> {
        // For now, show today as completed if all actions are done
        var days: Set<Int> = []
        if completedCount == model.todayActions.count && completedCount > 0 {
            days.insert(WeekStrip.currentWeekdayIndex())
        }
        return days
    }
}

// MARK: - Collapsible Section Component

private struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    var count: Int? = nil
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                DevineHaptic.tap.fire()
                withAnimation(DevineTheme.Motion.standard) {
                    isExpanded.toggle()
                }
            } label: {
                SurfaceCard(padding: DevineTheme.Spacing.md) {
                    HStack(spacing: DevineTheme.Spacing.sm) {
                        Image(systemName: icon)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DevineTheme.Colors.ctaPrimary)

                        Text(title)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(DevineTheme.Colors.textPrimary)

                        if let count, count > 0 {
                            Text("\(count)")
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundStyle(DevineTheme.Colors.textMuted)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(DevineTheme.Colors.bgSecondary)
                                )
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .padding(.top, DevineTheme.Spacing.md)
                    .padding(.horizontal, DevineTheme.Spacing.xs)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
