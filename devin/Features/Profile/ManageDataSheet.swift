import SwiftUI

struct ManageDataSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var heroVisible = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DevineTheme.Spacing.xl) {
                    heroIcon
                    dataCategories
                    privacyNote
                }
                .padding(.horizontal, DevineTheme.Spacing.lg)
                .padding(.top, DevineTheme.Spacing.xl)
                .padding(.bottom, DevineTheme.Spacing.xxxl)
            }
            .background(
                LinearGradient(
                    colors: DevineTheme.Gradients.screenBackground,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .foregroundStyle(DevineTheme.Colors.textPrimary)
            .navigationTitle("Your Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            DevineHaptic.sheetPresent.fire()
            withAnimation(DevineTheme.Motion.expressive.delay(0.1)) {
                heroVisible = true
            }
        }
    }

    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: DevineTheme.Gradients.primaryCTA,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)

            Image(systemName: "externaldrive")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(DevineTheme.Colors.textOnGradient)
        }
        .scaleEffect(heroVisible ? 1 : 0.6)
        .opacity(heroVisible ? 1 : 0)
    }

    private var dataCategories: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
            Text("What devine stores")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .center)

            SurfaceCard {
                VStack(spacing: DevineTheme.Spacing.lg) {
                    dataRow(icon: "camera.fill", title: "Mirror check-in photos", location: "Photos app")
                    Divider()
                    dataRow(icon: "tag.fill", title: "Check-in tags & notes", location: "On-device")
                    Divider()
                    dataRow(icon: "checkmark.circle.fill", title: "Daily action completions", location: "On-device")
                    Divider()
                    dataRow(icon: "flame.fill", title: "Goal & streak history", location: "On-device")
                    Divider()
                    dataRow(icon: "sparkles", title: "Glow Score estimate", location: "Computed locally")
                }
            }
        }
    }

    private func dataRow(icon: String, title: String, location: String) -> some View {
        HStack(spacing: DevineTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                .frame(width: 24)

            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))

            Spacer()

            Text(location)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(DevineTheme.Colors.successAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule(style: .continuous)
                        .fill(DevineTheme.Colors.successAccent.opacity(0.1))
                )
        }
    }

    private var privacyNote: some View {
        HStack(spacing: DevineTheme.Spacing.sm) {
            Image(systemName: "lock.shield")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)

            Text("Nothing leaves your device unless you export it.")
                .font(.caption2)
                .foregroundStyle(DevineTheme.Colors.textMuted)
        }
    }
}
