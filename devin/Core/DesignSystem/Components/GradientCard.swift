import SwiftUI

struct GradientCard<Content: View>: View {
    var colors: [Color] = DevineTheme.Gradients.heroCard
    var cornerRadius: CGFloat = DevineTheme.Radius.xl
    var showGlow: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(DevineTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay {
                if showGlow {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: colors.map { $0.opacity(0.5) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            }
            .shadow(color: colors.first?.opacity(0.2) ?? .clear, radius: showGlow ? 12 : 0, y: 4)
    }
}

struct SurfaceCard<Content: View>: View {
    var cornerRadius: CGFloat = DevineTheme.Radius.xl
    var padding: CGFloat = DevineTheme.Spacing.lg
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(DevineTheme.Colors.surfaceCard)
            )
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = DevineTheme.Radius.xl
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(DevineTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}
