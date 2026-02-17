import SwiftUI

struct PlanView: View {
    @ObservedObject var model: DevineAppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    planSummaryCard
                    currentStateCard
                    trajectoryCard
                    nextBestActionsCard
                    stabilityCard
                    evidenceLedgerCard
                }
                .padding(16)
            }
            .background(DevineTheme.Colors.bgPrimary)
            .foregroundStyle(DevineTheme.Colors.textPrimary)
            .navigationTitle("Plan")
        }
        .tint(DevineTheme.Colors.ctaPrimary)
    }

    private var planSummaryCard: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your adaptive plan")
                    .font(.title3.bold())
                Text("CurrentStateEstimate + GoalTrajectory + NextBestActions")
                    .font(.subheadline)
                    .foregroundStyle(DevineTheme.Colors.textSecondary)

                HStack(spacing: 12) {
                    Label("Updated \(model.lastUpdatedAt.formatted(date: .abbreviated, time: .shortened))", systemImage: "clock")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                    Spacer()
                    confidencePill(value: model.confidence)
                }
            }
        }
    }

    private var currentStateCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("CurrentStateEstimate")

                if let score = model.glowScore {
                    HStack(spacing: 14) {
                        ScoreRing(value: score)
                            .frame(width: 78, height: 78)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Glow Score \(score)/100")
                                .font(.headline)
                            Text(scoreInterpretation(score))
                                .font(.subheadline)
                                .foregroundStyle(DevineTheme.Colors.textSecondary)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No numeric score yet")
                            .font(.headline)
                        Text("Add a mirror check-in to unlock evidence-backed scoring.")
                            .font(.subheadline)
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private var trajectoryCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("GoalTrajectory")

                if let trajectory = model.goalTrajectory {
                    HStack(spacing: 10) {
                        trajectoryPill(label: "Min", value: "\(trajectory.minWeeks)w")
                        trajectoryPill(label: "Likely", value: "\(trajectory.likelyWeeks)w")
                        trajectoryPill(label: "Max", value: "\(trajectory.maxWeeks)w")
                    }

                    Text("Range estimate adapts as new evidence arrives.")
                        .font(.footnote)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                } else {
                    Text("Needs more evidence to estimate timeline confidence.")
                        .font(.subheadline)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                }
            }
        }
    }

    private var nextBestActionsCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("NextBestActions")

                ForEach(model.todayActions.prefix(3)) { action in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: model.isActionDone(action) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(model.isActionDone(action) ? DevineTheme.Colors.successAccent : DevineTheme.Colors.textMuted)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(action.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(action.instructions)
                                    .font(.footnote)
                                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                            }

                            Spacer(minLength: 8)

                            Text("\(action.estimatedMinutes)m")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(DevineTheme.Colors.bgSecondary)
                                )
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DevineTheme.Colors.bgSecondary)
                    )
                }
            }
        }
    }

    private var stabilityCard: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Stability")
                Text("Theme lock: 7 days unless a safety trigger.")
                    .font(.subheadline)
                    .foregroundStyle(DevineTheme.Colors.textSecondary)

                HStack(spacing: 8) {
                    Text("Latest:")
                        .font(.subheadline.weight(.semibold))
                    severityPill(model.latestAdjustmentSeverity)
                    Spacer()
                }
            }
        }
    }

    private var evidenceLedgerCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("EvidenceLedger")

                if model.evidenceLedger.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No evidence events yet.")
                            .font(.subheadline.weight(.semibold))
                        Text("Mirror check-ins will populate used and missing evidence here.")
                            .font(.footnote)
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }
                } else {
                    ForEach(model.evidenceLedger.prefix(5)) { event in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(event.summary)
                                .font(.subheadline.weight(.semibold))
                            Text("Used: \(event.evidenceUsed.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(DevineTheme.Colors.textSecondary)
                            if !event.evidenceMissing.isEmpty {
                                Text("Missing: \(event.evidenceMissing.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                            }
                            Text(event.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(DevineTheme.Colors.textMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(DevineTheme.Colors.surfaceCard)
            )
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
    }

    private func confidencePill(value: Double) -> some View {
        Text("Confidence \(Int(value * 100))%")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(DevineTheme.Colors.bgSecondary)
            )
    }

    private func trajectoryPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(DevineTheme.Colors.bgSecondary)
        )
    }

    private func severityPill(_ severity: PlanAdjustmentSeverity) -> some View {
        Text(severity.rawValue)
            .font(.caption.weight(.semibold))
            .foregroundStyle(severityColor(for: severity))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(severityColor(for: severity).opacity(0.12))
            )
    }

    private func severityColor(for severity: PlanAdjustmentSeverity) -> Color {
        switch severity {
        case .minorTweak:
            DevineTheme.Colors.successAccent
        case .resequence:
            DevineTheme.Colors.warningAccent
        case .pivot:
            DevineTheme.Colors.errorAccent
        }
    }

    private func scoreInterpretation(_ score: Int) -> String {
        switch score {
        case 0..<60:
            return "Early momentum stage. Focus on consistency over intensity."
        case 60..<80:
            return "Solid baseline. Small daily execution will move this up."
        default:
            return "Strong position. Keep stability and avoid over-correcting."
        }
    }
}
