import SwiftUI

struct ExportDataSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var heroVisible = false
    @State private var selectedFormat = "JSON"
    @State private var exportComplete = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DevineTheme.Spacing.xl) {
                    heroIcon
                    headline
                    exportPreview
                    formatPicker
                    exportButton
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
            .navigationTitle("Export Data")
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
        .presentationDetents([.medium, .large])
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

            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(DevineTheme.Colors.textOnGradient)
        }
        .scaleEffect(heroVisible ? 1 : 0.6)
        .opacity(heroVisible ? 1 : 0)
    }

    private var headline: some View {
        VStack(spacing: DevineTheme.Spacing.xs) {
            Text("Export your glow data")
                .font(.system(.headline, design: .rounded, weight: .bold))

            Text("Download everything devine knows about you.")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var exportPreview: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
                HStack {
                    Text("Preview")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Spacer()

                    Text(selectedFormat)
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                }

                Text(selectedFormat == "JSON" ? jsonPreview : csvPreview)
                    .font(.system(.caption2, design: .monospaced, weight: .regular))
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var formatPicker: some View {
        HStack(spacing: DevineTheme.Spacing.md) {
            ForEach(["JSON", "CSV"], id: \.self) { format in
                Button {
                    DevineHaptic.tap.fire()
                    withAnimation(DevineTheme.Motion.quick) { selectedFormat = format }
                } label: {
                    Text(format)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(
                            selectedFormat == format
                                ? DevineTheme.Colors.textOnGradient
                                : DevineTheme.Colors.textPrimary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DevineTheme.Spacing.md)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    selectedFormat == format
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: DevineTheme.Gradients.primaryCTA,
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        : AnyShapeStyle(DevineTheme.Colors.surfaceCard)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var exportButton: some View {
        VStack(spacing: DevineTheme.Spacing.md) {
            Button {
                DevineHaptic.actionComplete.fire()
                withAnimation(DevineTheme.Motion.standard) { exportComplete = true }
            } label: {
                Text("Export")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textOnGradient)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DevineTheme.Spacing.lg)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: DevineTheme.Gradients.primaryCTA,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .buttonStyle(.plain)

            if exportComplete {
                HStack(spacing: DevineTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DevineTheme.Colors.successAccent)
                    Text("Export ready — saved to Files")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(DevineTheme.Colors.successAccent)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
    }

    // MARK: - Mock Data

    private var jsonPreview: String {
        """
        {
          "goal": "face_definition",
          "streak_days": 5,
          "glow_score": 72,
          "checkins": [
            { "date": "2026-02-22", "tags": ["Hydrated"] },
            ...
          ]
        }
        """
    }

    private var csvPreview: String {
        """
        date,type,tags,score
        2026-02-22,checkin,"Hydrated",72
        2026-02-21,action,"Face yoga",68
        2026-02-20,checkin,"Good sleep",66
        ...
        """
    }
}
