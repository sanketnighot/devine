import SwiftUI

struct PlanHistoryView: View {
    @ObservedObject var model: DevineAppModel

    @State private var headerVisible = false
    @State private var rowsVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: DevineTheme.Spacing.xl) {
                heroSummary
                timelineList
                stabilityFooter
            }
            .padding(.horizontal, DevineTheme.Spacing.lg)
            .padding(.top, DevineTheme.Spacing.md)
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
        .foregroundStyle(DevineTheme.Colors.textPrimary)
        .navigationTitle("Plan History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            DevineHaptic.tap.fire()
            withAnimation(DevineTheme.Motion.expressive.delay(0.1)) {
                headerVisible = true
            }
            withAnimation(DevineTheme.Motion.expressive.delay(0.3)) {
                rowsVisible = true
            }
        }
    }

    // MARK: - Hero

    private var heroSummary: some View {
        GradientCard(colors: DevineTheme.Gradients.heroCard, showGlow: true) {
            VStack(spacing: DevineTheme.Spacing.md) {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(DevineTheme.Colors.textOnGradient)

                VStack(spacing: DevineTheme.Spacing.xs) {
                    Text("\(model.planAdjustmentHistory.count) adjustments")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(DevineTheme.Colors.textOnGradient)

                    Text(summaryMessage)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(headerVisible ? 1 : 0)
        .offset(y: headerVisible ? 0 : 16)
    }

    private var summaryMessage: String {
        let pivotCount = model.planAdjustmentHistory.filter { $0.severity == .pivot }.count
        if pivotCount == 0 {
            return "Your plan has stayed stable. Small tweaks, big results."
        } else if pivotCount == 1 {
            return "One pivot so far. Your plan adapts when evidence calls for it."
        } else {
            return "\(pivotCount) pivots. Your plan evolves with real data."
        }
    }

    // MARK: - Timeline

    private var timelineList: some View {
        VStack(spacing: 0) {
            ForEach(Array(model.planAdjustmentHistory.enumerated()), id: \.element.id) { index, record in
                timelineRow(record, isLast: index == model.planAdjustmentHistory.count - 1)
            }
        }
        .opacity(rowsVisible ? 1 : 0)
        .offset(y: rowsVisible ? 0 : 12)
    }

    private func timelineRow(_ record: PlanAdjustmentRecord, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: DevineTheme.Spacing.md) {
            // Left gutter: dot + line
            VStack(spacing: 0) {
                Circle()
                    .fill(record.severity.color)
                    .frame(width: 10, height: 10)
                    .padding(.top, DevineTheme.Spacing.lg)

                if !isLast {
                    Rectangle()
                        .fill(DevineTheme.Colors.borderSubtle)
                        .frame(width: 2)
                }
            }
            .frame(width: 10)

            // Right: card content
            SurfaceCard {
                VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
                    HStack {
                        severityPill(record.severity)

                        Spacer()

                        Text(record.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    }

                    Text(record.reason)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                        .lineSpacing(2)

                    if !record.associatedEvidence.isEmpty {
                        HStack(spacing: DevineTheme.Spacing.xs) {
                            ForEach(record.associatedEvidence, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                                    .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                                    .padding(.horizontal, DevineTheme.Spacing.sm)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(DevineTheme.Colors.ctaPrimary.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
            }
        }
        .padding(.bottom, isLast ? 0 : DevineTheme.Spacing.xs)
    }

    private func severityPill(_ severity: PlanAdjustmentSeverity) -> some View {
        HStack(spacing: DevineTheme.Spacing.xs) {
            Circle()
                .fill(severity.color)
                .frame(width: 6, height: 6)

            Text(severity.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(severity.color)
        }
        .padding(.horizontal, DevineTheme.Spacing.sm)
        .padding(.vertical, DevineTheme.Spacing.xs)
        .background(
            Capsule(style: .continuous)
                .fill(severity.color.opacity(0.1))
        )
    }

    // MARK: - Footer

    private var stabilityFooter: some View {
        HStack(spacing: DevineTheme.Spacing.sm) {
            Image(systemName: "lock.shield")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)

            Text("Your plan adjusts only when evidence supports it. No random changes, ever.")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)
                .lineSpacing(2)
        }
        .padding(.horizontal, DevineTheme.Spacing.xs)
    }
}
