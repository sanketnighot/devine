import SwiftUI

struct StreakFlame: View {
    let streakDays: Int
    var size: CGFloat = 28

    @State private var isPulsing = false

    private var isActive: Bool { streakDays > 0 }

    private var flameScale: CGFloat {
        switch streakDays {
        case 0: 1.0
        case 1...3: 1.0
        case 4...7: 1.1
        case 8...14: 1.2
        case 15...30: 1.3
        default: 1.4
        }
    }

    var body: some View {
        Image(systemName: isActive ? "flame.fill" : "flame")
            .font(.system(size: size))
            .foregroundStyle(
                isActive
                    ? LinearGradient(
                        colors: [
                            DevineTheme.Colors.warningAccent,
                            DevineTheme.Colors.ctaSecondary,
                            DevineTheme.Colors.ctaPrimary,
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    : LinearGradient(
                        colors: [DevineTheme.Colors.textMuted],
                        startPoint: .bottom,
                        endPoint: .top
                    )
            )
            .scaleEffect(flameScale * (isPulsing ? 1.08 : 1.0))
            .shadow(
                color: isActive ? DevineTheme.Colors.warningAccent.opacity(0.4) : .clear,
                radius: isPulsing ? 8 : 0
            )
            .onAppear {
                guard isActive else { return }
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
            .accessibilityLabel("\(streakDays) day streak")
    }
}

// MARK: - Streak Milestones

enum StreakMilestone {
    static let thresholds = [3, 7, 14, 21, 30, 50, 100]

    static func next(after days: Int) -> Int? {
        thresholds.first { $0 > days }
    }

    static func previous(before days: Int) -> Int {
        thresholds.last { $0 <= days } ?? 0
    }

    static func isExactMilestone(_ days: Int) -> Bool {
        thresholds.contains(days)
    }

    static func celebrationCopy(for days: Int) -> String? {
        switch days {
        case 3: "3 days in! You're building momentum."
        case 7: "A full week! You're unstoppable."
        case 14: "Two weeks straight! This is becoming you."
        case 21: "21 days — they say that's a habit."
        case 30: "One month. You're literally glowing."
        case 50: "50 days! You're in rare company."
        case 100: "100 days. Iconic."
        default: nil
        }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let streakDays: Int

    @State private var milestoneHitVisible = false

    private var nextMilestone: Int? {
        StreakMilestone.next(after: streakDays)
    }

    private var previousMilestone: Int {
        StreakMilestone.previous(before: streakDays)
    }

    private var isExactMilestone: Bool {
        StreakMilestone.isExactMilestone(streakDays)
    }

    private var milestoneProgress: Double {
        guard let next = nextMilestone else { return 1.0 }
        let range = Double(next - previousMilestone)
        guard range > 0 else { return 1.0 }
        return Double(streakDays - previousMilestone) / range
    }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
                HStack(spacing: DevineTheme.Spacing.md) {
                    StreakFlame(streakDays: streakDays, size: 24)

                    VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                        Text("\(streakDays)-day streak")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(DevineTheme.Colors.textPrimary)

                        MiniProgressBar(
                            value: milestoneProgress * (nextMilestone.map(Double.init) ?? 1),
                            maxValue: Double(nextMilestone ?? 1),
                            height: 6,
                            gradientColors: [DevineTheme.Colors.warningAccent, DevineTheme.Colors.ctaSecondary]
                        )
                    }

                    Spacer()

                    if let next = nextMilestone {
                        Text("\(streakDays)/\(next)")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    }
                }

                // Milestone countdown or celebration
                if isExactMilestone && streakDays > 0 {
                    Text(StreakMilestone.celebrationCopy(for: streakDays) ?? "Milestone reached!")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(DevineTheme.Colors.successAccent)
                        .scaleEffect(milestoneHitVisible ? 1.0 : 0.8)
                        .opacity(milestoneHitVisible ? 1 : 0)
                        .onAppear {
                            withAnimation(DevineTheme.Motion.celebration) {
                                milestoneHitVisible = true
                            }
                        }
                } else if let next = nextMilestone {
                    let daysToGo = next - streakDays
                    Text("\(daysToGo) more day\(daysToGo == 1 ? "" : "s") to your \(next)-day streak")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                }
            }
        }
    }
}
