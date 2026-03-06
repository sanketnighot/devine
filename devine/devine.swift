import WidgetKit
import SwiftUI

// MARK: - Shared Data Model

struct DevineWidgetData {
    let glowScore: Int?
    let streakDays: Int
    let todayCompleted: Int
    let todayTotal: Int
    let goalName: String

    static let placeholder = DevineWidgetData(
        glowScore: 72,
        streakDays: 5,
        todayCompleted: 1,
        todayTotal: 3,
        goalName: "Skin glow"
    )

    static let empty = DevineWidgetData(
        glowScore: nil,
        streakDays: 0,
        todayCompleted: 0,
        todayTotal: 3,
        goalName: "Getting started"
    )
}

// MARK: - Timeline Entry

struct DevineEntry: TimelineEntry {
    let date: Date
    let data: DevineWidgetData
}

// MARK: - Timeline Provider

struct DevineProvider: TimelineProvider {
    /// Suite name must match the App Group registered on both the main app target
    /// and this widget target in Xcode → Signing & Capabilities → App Groups.
    private let suiteName = "group.com.sanket.devin"

    func placeholder(in context: Context) -> DevineEntry {
        DevineEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (DevineEntry) -> Void) {
        completion(DevineEntry(date: .now, data: loadWidgetData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DevineEntry>) -> Void) {
        let entry = DevineEntry(date: .now, data: loadWidgetData())
        // Refresh every hour as a safety net; the main app calls
        // WidgetCenter.reloadAllTimelines() on every state change so
        // real-time updates happen without waiting for this deadline.
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    // MARK: - Shared data reader

    private func loadWidgetData() -> DevineWidgetData {
        guard
            let defaults = UserDefaults(suiteName: suiteName),
            defaults.bool(forKey: "widget_has_data")
        else {
            // App Group not yet configured, or the app hasn't launched once yet.
            return .empty
        }

        let rawScore = defaults.integer(forKey: "widget_glow_score")
        let glowScore: Int? = rawScore == -1 ? nil : rawScore
        let streakDays = defaults.integer(forKey: "widget_streak_days")
        let todayCompleted = defaults.integer(forKey: "widget_today_completed")
        let todayTotal = max(1, defaults.integer(forKey: "widget_today_total"))
        let goalName = defaults.string(forKey: "widget_goal_name") ?? "Getting started"

        return DevineWidgetData(
            glowScore: glowScore,
            streakDays: streakDays,
            todayCompleted: todayCompleted,
            todayTotal: todayTotal,
            goalName: goalName
        )
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 1. Glow Score Widget
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct GlowScoreWidgetView: View {
    let entry: DevineEntry

    var body: some View {
        if let score = entry.data.glowScore {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(WidgetTheme.Colors.textMuted.opacity(0.2), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100)
                        .stroke(
                            LinearGradient(
                                colors: WidgetTheme.Gradients.primaryCTA,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(score)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(WidgetTheme.Colors.textPrimary)
                }
                .frame(width: 64, height: 64)

                Text("Glow Score")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(WidgetTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: WidgetTheme.Gradients.primaryCTA,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Check in to\nunlock your score")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(WidgetTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct GlowScoreWidget: Widget {
    let kind = "GlowScoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DevineProvider()) { entry in
            GlowScoreWidgetView(entry: entry)
                .containerBackground(WidgetTheme.Colors.bgPrimary, for: .widget)
        }
        .configurationDisplayName("Glow Score")
        .description("Your current glow score at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 2. Streak Widget
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct StreakWidgetView: View {
    let entry: DevineEntry

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(WidgetTheme.Colors.warningAccent.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(WidgetTheme.Colors.warningAccent)
            }

            VStack(spacing: 2) {
                Text("\(entry.data.streakDays)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(WidgetTheme.Colors.textPrimary)

                Text(entry.data.streakDays == 1 ? "day streak" : "day streak")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(WidgetTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DevineProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(WidgetTheme.Colors.bgPrimary, for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("Keep your streak alive.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline])
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 3. Today's Actions Widget
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct TodayActionsWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: DevineEntry

    var body: some View {
        switch family {
        case .systemMedium:
            mediumLayout
        default:
            smallLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(WidgetTheme.Colors.textPrimary)

                Spacer()

                Text("\(entry.data.todayCompleted)/\(entry.data.todayTotal)")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(WidgetTheme.Colors.textMuted)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(WidgetTheme.Colors.textMuted.opacity(0.15))
                        .frame(height: 6)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: WidgetTheme.Gradients.primaryCTA,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(6, geo.size.width * progressFraction),
                            height: 6
                        )
                }
            }
            .frame(height: 6)

            Spacer()

            if entry.data.todayCompleted == entry.data.todayTotal {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(WidgetTheme.Colors.successAccent)
                    Text("All done!")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(WidgetTheme.Colors.successAccent)
                }
            } else {
                Text("\(max(0, entry.data.todayTotal - entry.data.todayCompleted)) left")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(WidgetTheme.Colors.ctaPrimary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var mediumLayout: some View {
        HStack(spacing: 16) {
            // Left: progress ring
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(WidgetTheme.Colors.textMuted.opacity(0.15), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: progressFraction)
                        .stroke(
                            LinearGradient(
                                colors: WidgetTheme.Gradients.primaryCTA,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(entry.data.todayCompleted)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(WidgetTheme.Colors.textPrimary)
                        Text("of \(entry.data.todayTotal)")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(WidgetTheme.Colors.textMuted)
                    }
                }
                .frame(width: 64, height: 64)

                Text("Today")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(WidgetTheme.Colors.textSecondary)
            }

            // Right: status + goal
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.data.goalName)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(WidgetTheme.Colors.ctaPrimary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                if entry.data.todayCompleted == entry.data.todayTotal {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.subheadline)
                                .foregroundStyle(WidgetTheme.Colors.successAccent)
                            Text("All done for today!")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(WidgetTheme.Colors.textPrimary)
                        }
                        Text("Consistency is your glow multiplier")
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(WidgetTheme.Colors.textSecondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(max(0, entry.data.todayTotal - entry.data.todayCompleted)) actions left")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(WidgetTheme.Colors.textPrimary)

                        Text("Tap to continue your glow-up")
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(WidgetTheme.Colors.textSecondary)
                    }
                }

                if entry.data.streakDays > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(WidgetTheme.Colors.warningAccent)
                        Text("\(entry.data.streakDays)-day streak")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(WidgetTheme.Colors.textMuted)
                    }
                }

                Spacer()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var progressFraction: CGFloat {
        guard entry.data.todayTotal > 0 else { return 0 }
        return CGFloat(entry.data.todayCompleted) / CGFloat(entry.data.todayTotal)
    }
}

struct TodayActionsWidget: Widget {
    let kind = "TodayActionsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DevineProvider()) { entry in
            TodayActionsWidgetView(entry: entry)
                .containerBackground(WidgetTheme.Colors.bgPrimary, for: .widget)
        }
        .configurationDisplayName("Today's Actions")
        .description("Track your daily glow-up progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Lock Screen Accessory Views

struct StreakAccessoryCircularView: View {
    let entry: DevineEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 1) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                Text("\(entry.data.streakDays)")
                    .font(.system(.body, design: .rounded, weight: .bold))
            }
        }
    }
}

struct StreakAccessoryInlineView: View {
    let entry: DevineEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
            Text("\(entry.data.streakDays)-day streak")
        }
    }
}

// MARK: - Previews

#Preview("Glow Score", as: .systemSmall) {
    GlowScoreWidget()
} timeline: {
    DevineEntry(date: .now, data: .placeholder)
}

#Preview("Streak", as: .systemSmall) {
    StreakWidget()
} timeline: {
    DevineEntry(date: .now, data: .placeholder)
}

#Preview("Today Small", as: .systemSmall) {
    TodayActionsWidget()
} timeline: {
    DevineEntry(date: .now, data: .placeholder)
}

#Preview("Today Medium", as: .systemMedium) {
    TodayActionsWidget()
} timeline: {
    DevineEntry(date: .now, data: .placeholder)
}
