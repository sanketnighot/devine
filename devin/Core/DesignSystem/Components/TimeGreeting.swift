import SwiftUI

struct TimeGreeting: View {
    var name: String? = nil
    var goal: GlowGoal? = nil
    var now: Date = .now

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Wind down"
        }
    }

    private var emoji: String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 5..<12: return "☀️"
        case 12..<17: return "✨"
        case 17..<21: return "🌙"
        default: return "💤"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
            Text("\(greeting)\(name.map { ", \($0)" } ?? "") \(emoji)")
                .font(.title2.bold())
                .foregroundStyle(DevineTheme.Colors.textPrimary)

            if let goal {
                GoalBadge(goal: goal, style: .compact)
            }
        }
    }
}
