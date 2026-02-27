import SwiftUI

struct FullWeekPlanView: View {
    @ObservedObject var model: DevineAppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.xl) {
                if let plan = model.generatedPlan {
                    headerSection(plan: plan)

                    ForEach(plan.dailyPlans) { day in
                        dayCard(day)
                    }
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
        .foregroundStyle(DevineTheme.Colors.textPrimary)
        .navigationTitle("7-Day Plan")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private func headerSection(plan: GeneratedPlan) -> some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
            Text(plan.summary)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.textSecondary)
                .lineSpacing(2)

            Text("Generated \(plan.generatedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)
        }
    }

    // MARK: - Day Card

    private func dayCard(_ day: DailyPlan) -> some View {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(day.date)
        let isPast = day.date < cal.startOfDay(for: .now)
        let dayKey = DevineAppModel.dayKey(for: day.date)
        let dayCompletedIDs = Set(model.completedActionsByDayPublic[dayKey] ?? [])
        let dayActions = day.actions.map { $0.toPerfectAction() }
        let completedCount = dayActions.filter { dayCompletedIDs.contains($0.id) }.count
        let allComplete = completedCount >= dayActions.count && !dayActions.isEmpty

        return VStack(alignment: .leading, spacing: 0) {
            // Day header
            HStack(spacing: DevineTheme.Spacing.md) {
                // Day number badge
                ZStack {
                    Circle()
                        .fill(
                            isToday
                                ? model.primaryGoal.accentColor
                                : allComplete
                                    ? DevineTheme.Colors.successAccent
                                    : DevineTheme.Colors.bgSecondary
                        )
                        .frame(width: 36, height: 36)

                    if allComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(day.dayNumber)")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(isToday ? .white : DevineTheme.Colors.textPrimary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: DevineTheme.Spacing.sm) {
                        Text("Day \(day.dayNumber)")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))

                        if isToday {
                            Text("Today")
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundStyle(model.primaryGoal.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(model.primaryGoal.accentColor.opacity(0.12))
                                )
                        }
                    }

                    Text(day.theme)
                        .font(.caption)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                }

                Spacer()

                // Completion count
                if isPast || isToday {
                    Text("\(completedCount)/\(dayActions.count)")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(
                            allComplete
                                ? DevineTheme.Colors.successAccent
                                : DevineTheme.Colors.textMuted
                        )
                }
            }
            .padding(DevineTheme.Spacing.md)

            Divider()
                .foregroundStyle(DevineTheme.Colors.borderSubtle)
                .padding(.horizontal, DevineTheme.Spacing.md)

            // Actions list
            VStack(spacing: 0) {
                ForEach(Array(day.actions.enumerated()), id: \.element.id) { index, action in
                    let isDone = dayCompletedIDs.contains(action.id)

                    HStack(spacing: DevineTheme.Spacing.md) {
                        // Status icon
                        ZStack {
                            Circle()
                                .fill(
                                    isDone
                                        ? DevineTheme.Colors.successAccent.opacity(0.15)
                                        : DevineTheme.Colors.bgSecondary
                                )
                                .frame(width: 28, height: 28)

                            if isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(DevineTheme.Colors.successAccent)
                            } else {
                                Text("\(index + 1)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(DevineTheme.Colors.textMuted)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(action.title)
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(
                                    isDone
                                        ? DevineTheme.Colors.textMuted
                                        : DevineTheme.Colors.textPrimary
                                )
                                .strikethrough(isDone, color: DevineTheme.Colors.textMuted.opacity(0.5))

                            Text(action.instructions)
                                .font(.caption)
                                .foregroundStyle(DevineTheme.Colors.textSecondary)
                                .lineLimit(2)
                                .lineSpacing(1)
                        }

                        Spacer()

                        Text("\(action.estimatedMinutes)m")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(DevineTheme.Colors.bgSecondary)
                            )
                    }
                    .padding(.horizontal, DevineTheme.Spacing.md)
                    .padding(.vertical, DevineTheme.Spacing.sm + 2)

                    if index < day.actions.count - 1 {
                        Divider()
                            .foregroundStyle(DevineTheme.Colors.borderSubtle)
                            .padding(.leading, DevineTheme.Spacing.md + 28 + DevineTheme.Spacing.md)
                            .padding(.trailing, DevineTheme.Spacing.md)
                    }
                }
            }
            .padding(.bottom, DevineTheme.Spacing.sm)
        }
        .background(
            RoundedRectangle(cornerRadius: DevineTheme.Radius.xl, style: .continuous)
                .fill(DevineTheme.Colors.surfaceCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DevineTheme.Radius.xl, style: .continuous)
                .stroke(
                    isToday ? model.primaryGoal.accentColor.opacity(0.3) : Color.clear,
                    lineWidth: 1.5
                )
        )
    }
}
