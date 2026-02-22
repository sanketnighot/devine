import SwiftUI

struct CreateCircleSheet: View {
    let onCreate: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var heroVisible = false
    @State private var circleName = ""
    @State private var memberLimit = 5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DevineTheme.Spacing.xl) {
                    heroIcon
                    nameField
                    memberLimitPicker
                    inviteCodePreview
                    createButton
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
            .navigationTitle("New Circle")
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
        VStack(spacing: DevineTheme.Spacing.md) {
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

                Image(systemName: "person.3.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.textOnGradient)
            }
            .scaleEffect(heroVisible ? 1 : 0.6)
            .opacity(heroVisible ? 1 : 0)

            Text("Name your circle")
                .font(.system(.headline, design: .rounded, weight: .bold))
        }
    }

    private var nameField: some View {
        SurfaceCard(padding: DevineTheme.Spacing.md) {
            TextField("e.g. Glow Squad", text: $circleName)
                .font(.system(.body, design: .rounded, weight: .medium))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
    }

    private var memberLimitPicker: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
            Text("Up to \(memberLimit) members")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))

            HStack(spacing: DevineTheme.Spacing.sm) {
                ForEach(3...8, id: \.self) { num in
                    Button {
                        DevineHaptic.tap.fire()
                        withAnimation(DevineTheme.Motion.quick) { memberLimit = num }
                    } label: {
                        Text("\(num)")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(
                                memberLimit == num
                                    ? DevineTheme.Colors.ctaPrimary
                                    : DevineTheme.Colors.textSecondary
                            )
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(
                                        memberLimit == num
                                            ? DevineTheme.Colors.ctaPrimary.opacity(0.12)
                                            : DevineTheme.Colors.surfaceCard
                                    )
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        memberLimit == num
                                            ? DevineTheme.Colors.ctaPrimary.opacity(0.3)
                                            : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var inviteCodePreview: some View {
        SurfaceCard(padding: DevineTheme.Spacing.md) {
            HStack(spacing: DevineTheme.Spacing.md) {
                Image(systemName: "link")
                    .font(.body.weight(.medium))
                    .foregroundStyle(DevineTheme.Colors.ctaPrimary)

                Text("Your invite code will be generated when you create")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
            }
        }
    }

    private var createButton: some View {
        Button {
            DevineHaptic.actionComplete.fire()
            onCreate(circleName)
            dismiss()
        } label: {
            Text("Create circle")
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
        .disabled(circleName.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(circleName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
    }
}
