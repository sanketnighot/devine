import SwiftUI

struct WeekStrip: View {
    let completedDays: Set<Int>
    var todayIndex: Int = Self.currentWeekdayIndex()
    var accentColor: Color = DevineTheme.Colors.ctaPrimary

    var body: some View {
        HStack(spacing: DevineTheme.Spacing.sm) {
            ForEach(0..<7, id: \.self) { index in
                dayCircle(index: index)
            }
        }
    }

    private func dayCircle(index: Int) -> some View {
        let isToday = index == todayIndex
        let isCompleted = completedDays.contains(index)
        let dayLabel = Self.shortDayLabels[index]

        return VStack(spacing: DevineTheme.Spacing.xs) {
            Text(dayLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.textMuted)

            ZStack {
                Circle()
                    .fill(fillColor(isCompleted: isCompleted, isToday: isToday))
                    .frame(width: 32, height: 32)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DevineTheme.Colors.textOnGradient)
                } else if isToday {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(accentColor, lineWidth: 2)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func fillColor(isCompleted: Bool, isToday: Bool) -> Color {
        if isCompleted {
            return accentColor
        }
        if isToday {
            return Color.clear
        }
        return DevineTheme.Colors.bgSecondary
    }

    private static let shortDayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    static func currentWeekdayIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: .now)
        // Calendar weekday: 1=Sun, 2=Mon, ..., 7=Sat → convert to Mon=0
        return (weekday + 5) % 7
    }
}
