import SwiftUI

struct ActionPill: View {
    let title: String
    let estimatedMinutes: Int
    let isCompleted: Bool
    let action: () -> Void

    @State private var showCheckmark = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: DevineTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? DevineTheme.Colors.successAccent.opacity(0.15) : DevineTheme.Colors.bgSecondary)
                        .frame(width: 40, height: 40)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(DevineTheme.Colors.successAccent)
                            .scaleEffect(showCheckmark ? 1 : 0.3)
                            .opacity(showCheckmark ? 1 : 0)
                    } else {
                        Text("\(estimatedMinutes)m")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }
                }

                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isCompleted ? DevineTheme.Colors.textMuted : DevineTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DevineTheme.Spacing.md)
            .padding(.horizontal, DevineTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DevineTheme.Radius.lg, style: .continuous)
                    .fill(DevineTheme.Colors.surfaceCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DevineTheme.Radius.lg, style: .continuous)
                    .stroke(
                        isCompleted ? DevineTheme.Colors.successAccent.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            if isCompleted {
                withAnimation(DevineTheme.Motion.celebration) {
                    showCheckmark = true
                }
            }
        }
        .onChange(of: isCompleted) {
            if isCompleted {
                withAnimation(DevineTheme.Motion.celebration) {
                    showCheckmark = true
                }
            } else {
                showCheckmark = false
            }
        }
    }
}
