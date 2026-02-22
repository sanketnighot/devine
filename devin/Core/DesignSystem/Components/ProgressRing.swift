import SwiftUI

struct ProgressRing: View {
    let value: Double
    var maxValue: Double = 100
    var size: CGFloat = 84
    var lineWidth: CGFloat = 10
    var gradientColors: [Color] = DevineTheme.Gradients.scoreRing
    var trackColor: Color = DevineTheme.Colors.ringTrack
    var showLabel: Bool = true
    var showGlow: Bool = true

    @State private var animatedProgress: Double = 0

    private var progress: Double {
        guard maxValue > 0 else { return 0 }
        return min(max(value / maxValue, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: gradientColors + [gradientColors.first ?? .pink],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            if showGlow && animatedProgress > 0 {
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        gradientColors.first ?? .pink,
                        style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 6)
                    .opacity(0.3)
            }

            if showLabel {
                Text("\(Int(value))")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .foregroundStyle(DevineTheme.Colors.textPrimary)
                    .contentTransition(.numericText(value: value))
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(value)) out of \(Int(maxValue))")
        .onAppear {
            withAnimation(DevineTheme.Motion.expressive) {
                animatedProgress = progress
            }
        }
        .onChange(of: value) {
            withAnimation(DevineTheme.Motion.expressive) {
                animatedProgress = progress
            }
        }
    }
}

struct MiniProgressBar: View {
    let value: Double
    var maxValue: Double = 3
    var height: CGFloat = 8
    var gradientColors: [Color] = DevineTheme.Gradients.primaryCTA

    @State private var animatedProgress: Double = 0

    private var progress: Double {
        guard maxValue > 0 else { return 0 }
        return min(max(value / maxValue, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(DevineTheme.Colors.ringTrack)

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * animatedProgress)
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(DevineTheme.Motion.expressive) {
                animatedProgress = progress
            }
        }
        .onChange(of: value) {
            withAnimation(DevineTheme.Motion.expressive) {
                animatedProgress = progress
            }
        }
    }
}
