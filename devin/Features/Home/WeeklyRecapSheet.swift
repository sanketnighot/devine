import SwiftUI

struct WeeklyRecapSheet: View {
    @ObservedObject var model: DevineAppModel
    @Environment(\.dismiss) private var dismiss

    @State private var headerVisible = false
    @State private var statsVisible = false
    @State private var highlightVisible = false
    @State private var moodVisible = false
    @State private var teaserVisible = false

    private var completedToday: Int {
        model.todayActions.filter { model.isActionDone($0) }.count
    }

    private var weekCheckins: Int {
        model.thisWeekCheckinCount
    }

    private var topMoods: [(tag: String, count: Int)] {
        model.thisWeekMoodTags
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { (tag: $0.key, count: $0.value) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DevineTheme.Spacing.xl) {
                    heroHeader
                    statsRow
                    highlightCard
                    moodSummary
                    nextWeekTeaser
                    footer
                }
                .padding(.horizontal, DevineTheme.Spacing.lg)
                .padding(.top, DevineTheme.Spacing.lg)
                .padding(.bottom, DevineTheme.Spacing.xxxl)
            }
            .scrollIndicators(.hidden)
            .background(
                LinearGradient(
                    colors: DevineTheme.Gradients.screenBackground,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Your week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            DevineHaptic.sheetPresent.fire()
            animateEntrance()
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        GradientCard(colors: DevineTheme.Gradients.heroCard, showGlow: true) {
            VStack(spacing: DevineTheme.Spacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundStyle(DevineTheme.Colors.textOnGradient)

                Text("Your week in review")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textOnGradient)

                Text(weekDateRange)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(headerVisible ? 1 : 0)
        .offset(y: headerVisible ? 0 : 16)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: DevineTheme.Spacing.md) {
            statCircle(
                value: "\(completedToday)/\(model.todayActions.count)",
                label: "Today",
                icon: "checkmark.circle",
                color: DevineTheme.Colors.successAccent
            )

            statCircle(
                value: "\(model.streakDays)",
                label: "Streak",
                icon: "flame.fill",
                color: DevineTheme.Colors.warningAccent
            )

            statCircle(
                value: "\(weekCheckins)",
                label: "Check-ins",
                icon: "camera.viewfinder",
                color: DevineTheme.Colors.ctaPrimary
            )
        }
        .opacity(statsVisible ? 1 : 0)
        .offset(y: statsVisible ? 0 : 12)
    }

    private func statCircle(value: String, label: String, icon: String, color: Color) -> some View {
        SurfaceCard {
            VStack(spacing: DevineTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(color)
                }

                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textPrimary)

                Text(label)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Highlight Card

    private var highlightCard: some View {
        GradientCard(
            colors: [model.primaryGoal.accentColor.opacity(0.9), model.primaryGoal.accentColor.opacity(0.6)]
        ) {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
                Text("Highlight")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(highlightCopy)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.textOnGradient)
            }
        }
        .opacity(highlightVisible ? 1 : 0)
        .offset(y: highlightVisible ? 0 : 12)
    }

    private var highlightCopy: String {
        if StreakMilestone.thresholds.contains(model.streakDays) && model.streakDays > 0 {
            return StreakMilestone.celebrationCopy(for: model.streakDays)
                ?? "You showed up. That's the hardest part."
        }
        if model.streakDays >= 7 {
            return "A \(model.streakDays)-day streak this week! You're on fire."
        }
        if weekCheckins > 0 {
            return "You checked in \(weekCheckins) time\(weekCheckins == 1 ? "" : "s") this week. Progress is progress."
        }
        return "You showed up. That's the hardest part."
    }

    // MARK: - Mood Summary

    @ViewBuilder
    private var moodSummary: some View {
        if !topMoods.isEmpty {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                Text("How you felt")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)

                FlowLayout(spacing: DevineTheme.Spacing.sm) {
                    ForEach(topMoods, id: \.tag) { mood in
                        HStack(spacing: DevineTheme.Spacing.xs) {
                            MoodChip(label: mood.tag, isSelected: true) {}
                                .disabled(true)

                            Text("\(mood.count)x")
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundStyle(DevineTheme.Colors.textMuted)
                        }
                    }
                }
            }
            .opacity(moodVisible ? 1 : 0)
            .offset(y: moodVisible ? 0 : 12)
        }
    }

    // MARK: - Next Week Teaser

    private var nextWeekTeaser: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                HStack(spacing: DevineTheme.Spacing.sm) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.body)
                        .foregroundStyle(DevineTheme.Colors.ctaPrimary)

                    Text("Next week's focus")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                }

                GoalBadge(goal: model.primaryGoal)

                Text("Keep the momentum. 3 actions a day, same glow energy.")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                    .lineSpacing(2)

                Button {
                    DevineHaptic.tap.fire()
                    dismiss()
                } label: {
                    HStack(spacing: DevineTheme.Spacing.sm) {
                        Text("Let's go")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(DevineTheme.Colors.textOnGradient)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DevineTheme.Spacing.md)
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
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(teaserVisible ? 1 : 0)
        .offset(y: teaserVisible ? 0 : 12)
    }

    // MARK: - Footer

    private var footer: some View {
        Text("See you next Monday")
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundStyle(DevineTheme.Colors.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.top, DevineTheme.Spacing.md)
    }

    // MARK: - Helpers

    private var weekDateRange: String {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return "" }
        let start = interval.start.formatted(.dateTime.month(.abbreviated).day())
        let end = interval.end.addingTimeInterval(-1).formatted(.dateTime.month(.abbreviated).day())
        return "\(start) – \(end)"
    }

    private func animateEntrance() {
        withAnimation(DevineTheme.Motion.expressive.delay(0.1)) {
            headerVisible = true
        }
        withAnimation(DevineTheme.Motion.expressive.delay(0.25)) {
            statsVisible = true
        }
        withAnimation(DevineTheme.Motion.expressive.delay(0.4)) {
            highlightVisible = true
        }
        withAnimation(DevineTheme.Motion.expressive.delay(0.55)) {
            moodVisible = true
        }
        withAnimation(DevineTheme.Motion.expressive.delay(0.65)) {
            teaserVisible = true
        }
    }
}
