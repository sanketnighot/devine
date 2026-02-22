import SwiftUI

struct MemberReportSheet: View {
    let member: CircleMember
    let onReport: (CircleReportReason) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var heroVisible = false
    @State private var selectedReason: CircleReportReason?
    @State private var additionalNote = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DevineTheme.Spacing.xl) {
                    header
                    reasonPicker
                    noteField
                    submitButton
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
            .navigationTitle("Report")
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

    private var header: some View {
        VStack(spacing: DevineTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DevineTheme.Colors.errorAccent.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.errorAccent)
            }
            .scaleEffect(heroVisible ? 1 : 0.6)
            .opacity(heroVisible ? 1 : 0)

            VStack(spacing: DevineTheme.Spacing.xs) {
                Text("Report \(member.displayName)")
                    .font(.system(.headline, design: .rounded, weight: .bold))

                Text("This is private. We review all reports.")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
            }
        }
    }

    private var reasonPicker: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
            Text("What happened?")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))

            VStack(spacing: DevineTheme.Spacing.sm) {
                ForEach(CircleReportReason.allCases) { reason in
                    Button {
                        DevineHaptic.tap.fire()
                        withAnimation(DevineTheme.Motion.quick) { selectedReason = reason }
                    } label: {
                        HStack(spacing: DevineTheme.Spacing.md) {
                            Text(reason.rawValue)
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(DevineTheme.Colors.textPrimary)

                            Spacer()

                            if selectedReason == reason {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                            }
                        }
                        .padding(DevineTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DevineTheme.Radius.md, style: .continuous)
                                .fill(
                                    selectedReason == reason
                                        ? DevineTheme.Colors.ctaPrimary.opacity(0.08)
                                        : DevineTheme.Colors.surfaceCard
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DevineTheme.Radius.md, style: .continuous)
                                .stroke(
                                    selectedReason == reason
                                        ? DevineTheme.Colors.ctaPrimary.opacity(0.3)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var noteField: some View {
        SurfaceCard(padding: DevineTheme.Spacing.md) {
            TextField("Additional context (optional)", text: $additionalNote, axis: .vertical)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .lineLimit(3...)
        }
    }

    private var submitButton: some View {
        Button {
            guard let reason = selectedReason else { return }
            DevineHaptic.actionComplete.fire()
            onReport(reason)
            dismiss()
        } label: {
            Text("Submit report")
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
        .disabled(selectedReason == nil)
        .opacity(selectedReason == nil ? 0.5 : 1)
    }
}
