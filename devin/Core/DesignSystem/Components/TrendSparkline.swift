import SwiftUI

struct TrendSparkline: View {
    let dataPoints: [Double]
    var accentColor: Color = DevineTheme.Colors.ctaPrimary
    var height: CGFloat = 40
    var showTrendArrow: Bool = true

    @State private var drawProgress: CGFloat = 0

    private var trend: Trend {
        guard dataPoints.count >= 2 else { return .neutral }
        let last = dataPoints.suffix(3)
        let avg = last.reduce(0, +) / Double(last.count)
        let earlier = dataPoints.prefix(max(dataPoints.count - 3, 1))
        let earlierAvg = earlier.reduce(0, +) / Double(earlier.count)
        let delta = avg - earlierAvg
        if delta > 1.5 { return .up }
        if delta < -1.5 { return .down }
        return .neutral
    }

    private enum Trend {
        case up, down, neutral
    }

    var body: some View {
        if dataPoints.count < 2 {
            emptyState
        } else {
            sparkline
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: DevineTheme.Spacing.sm) {
            dashedLine
            Text("More data soon")
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.textMuted)
        }
        .frame(height: height)
    }

    private var dashedLine: some View {
        GeometryReader { geo in
            Path { path in
                let midY = geo.size.height / 2
                path.move(to: CGPoint(x: 0, y: midY))
                path.addLine(to: CGPoint(x: geo.size.width * 0.6, y: midY))
            }
            .stroke(
                DevineTheme.Colors.textMuted.opacity(0.3),
                style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
            )
        }
    }

    // MARK: - Sparkline

    private var sparkline: some View {
        HStack(spacing: DevineTheme.Spacing.sm) {
            GeometryReader { geo in
                let points = normalizedPoints(in: geo.size)

                // Fill gradient below the line
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: CGPoint(x: first.x, y: geo.size.height))
                    path.addLine(to: first)
                    addSmoothCurve(to: &path, through: points)
                    path.addLine(to: CGPoint(x: points.last?.x ?? 0, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.15), accentColor.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask {
                    Rectangle()
                        .frame(width: geo.size.width * drawProgress)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Line stroke
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    addSmoothCurve(to: &path, through: points)
                }
                .trim(from: 0, to: drawProgress)
                .stroke(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )

                // End dot
                if let last = points.last {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 5, height: 5)
                        .position(last)
                        .opacity(Double(drawProgress))
                }
            }
            .frame(height: height)

            if showTrendArrow {
                trendArrow
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.2)) {
                drawProgress = 1
            }
        }
    }

    @ViewBuilder
    private var trendArrow: some View {
        switch trend {
        case .up:
            trendPill(icon: "arrow.up.right", color: DevineTheme.Colors.successAccent)
        case .down:
            trendPill(icon: "arrow.down.right", color: DevineTheme.Colors.warningAccent)
        case .neutral:
            EmptyView()
        }
    }

    private func trendPill(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
            .padding(5)
            .background(
                Circle()
                    .fill(color.opacity(0.12))
            )
    }

    // MARK: - Geometry Helpers

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard dataPoints.count >= 2 else { return [] }
        let minVal = (dataPoints.min() ?? 0) - 2
        let maxVal = (dataPoints.max() ?? 100) + 2
        let range = maxVal - minVal
        guard range > 0 else {
            return dataPoints.enumerated().map { i, _ in
                CGPoint(
                    x: CGFloat(i) / CGFloat(dataPoints.count - 1) * size.width,
                    y: size.height / 2
                )
            }
        }

        return dataPoints.enumerated().map { i, val in
            CGPoint(
                x: CGFloat(i) / CGFloat(dataPoints.count - 1) * size.width,
                y: size.height - ((val - minVal) / range) * size.height
            )
        }
    }

    private func addSmoothCurve(to path: inout Path, through points: [CGPoint]) {
        guard points.count >= 2 else { return }

        for i in 1 ..< points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let midX = (prev.x + curr.x) / 2

            path.addCurve(
                to: curr,
                control1: CGPoint(x: midX, y: prev.y),
                control2: CGPoint(x: midX, y: curr.y)
            )
        }
    }
}
