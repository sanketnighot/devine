import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.15),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: geo.size.width * phase)
                    .onAppear {
                        withAnimation(
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                        ) {
                            phase = 1.5
                        }
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: DevineTheme.Radius.md, style: .continuous))
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct ShimmerPlaceholder: View {
    var height: CGFloat = 120
    var cornerRadius: CGFloat = DevineTheme.Radius.xl

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(DevineTheme.Colors.bgSecondary)
            .frame(height: height)
            .shimmer()
    }
}
