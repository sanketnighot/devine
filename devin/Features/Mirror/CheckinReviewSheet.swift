import SwiftUI

struct CheckinReviewSheet: View {
    @ObservedObject var model: DevineAppModel
    let evaluation: CheckinEvaluation
    @Environment(\.dismiss) private var dismiss

    private var previousScore: Int? { model.glowScore }

    private var scoreDelta: Int? {
        guard let prev = previousScore else { return nil }
        return evaluation.updatedGlowScore - prev
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DevineTheme.Spacing.xl) {
                    scoreSection
                    feedbackSection
                    subscoreSection

                    if evaluation.suggestedPlanUpdate != nil {
                        planUpdateSection
                    }

                    actionButtons
                }
                .padding(.horizontal, DevineTheme.Spacing.lg)
                .padding(.top, DevineTheme.Spacing.lg)
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
            .navigationTitle("Check-in Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        model.dismissCheckinEvaluation()
                        dismiss()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Score Section

    private var scoreSection: some View {
        SurfaceCard {
            HStack(spacing: DevineTheme.Spacing.lg) {
                ProgressRing(
                    value: Double(evaluation.updatedGlowScore),
                    maxValue: 100,
                    size: 90,
                    lineWidth: 10
                )

                VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                    Text("Updated Glow Score")
                        .font(.system(.headline, design: .rounded, weight: .bold))

                    if let delta = scoreDelta {
                        HStack(spacing: DevineTheme.Spacing.xs) {
                            Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption.weight(.bold))
                            Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                        }
                        .foregroundStyle(delta >= 0 ? DevineTheme.Colors.successAccent : DevineTheme.Colors.warningAccent)
                    } else {
                        Text("First score!")
                            .font(.caption)
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                HStack(spacing: DevineTheme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                    Text("AI Feedback")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }

                Text(evaluation.feedback)
                    .font(.subheadline)
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                    .lineSpacing(3)
            }
        }
    }

    // MARK: - Subscore Section

    private var subscoreSection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                Text("Category Scores")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)

                ForEach(evaluation.updatedSubscores) { subscore in
                    HStack(spacing: DevineTheme.Spacing.md) {
                        Image(systemName: subscore.icon)
                            .font(.body)
                            .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(subscore.label)
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                Spacer()
                                Text("\(subscore.value)")
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                            }

                            Text(subscore.insight)
                                .font(.caption)
                                .foregroundStyle(DevineTheme.Colors.textSecondary)
                        }
                    }

                    if subscore.id != evaluation.updatedSubscores.last?.id {
                        Divider()
                            .foregroundStyle(DevineTheme.Colors.borderSubtle)
                    }
                }
            }
        }
    }

    // MARK: - Plan Update Section

    private var planUpdateSection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                HStack(spacing: DevineTheme.Spacing.sm) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(evaluation.adjustmentSeverity.color)

                    Text("Plan Adjustment")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Spacer()

                    Text(evaluation.adjustmentSeverity.label)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule(style: .continuous)
                                .fill(evaluation.adjustmentSeverity.color)
                        )
                }

                if let update = evaluation.suggestedPlanUpdate {
                    Text(update.reason)
                        .font(.subheadline)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                        .lineSpacing(2)
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: DevineTheme.Spacing.md) {
            // Primary: Accept all
            Button {
                DevineHaptic.actionComplete.fire()
                model.acceptCheckinEvaluation()
                dismiss()
            } label: {
                HStack(spacing: DevineTheme.Spacing.sm) {
                    Image(systemName: evaluation.suggestedPlanUpdate != nil ? "checkmark.circle.fill" : "checkmark")
                        .font(.subheadline.weight(.bold))
                    Text(evaluation.suggestedPlanUpdate != nil ? "Accept score & plan update" : "Accept score update")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.white)
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
            }
            .buttonStyle(.plain)

            // Secondary: Score only (only when plan update exists)
            if evaluation.suggestedPlanUpdate != nil {
                Button {
                    DevineHaptic.tap.fire()
                    model.dismissCheckinEvaluation()
                    dismiss()
                } label: {
                    Text("Accept score only, keep plan")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DevineTheme.Spacing.md)
                        .background(
                            Capsule(style: .continuous)
                                .fill(DevineTheme.Colors.ctaPrimary.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
