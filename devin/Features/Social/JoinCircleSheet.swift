import SwiftUI

struct JoinCircleSheet: View {
    let onJoin: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var heroVisible = false
    @State private var inviteCode = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DevineTheme.Spacing.xl) {
                    heroIcon
                    codeField
                    joinButton
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
            .navigationTitle("Join Circle")
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

                Image(systemName: "person.badge.plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.textOnGradient)
            }
            .scaleEffect(heroVisible ? 1 : 0.6)
            .opacity(heroVisible ? 1 : 0)

            VStack(spacing: DevineTheme.Spacing.xs) {
                Text("Join a circle")
                    .font(.system(.headline, design: .rounded, weight: .bold))

                Text("Ask your friend for their 6-character invite code")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var codeField: some View {
        SurfaceCard(padding: DevineTheme.Spacing.lg) {
            TextField("INVITE CODE", text: $inviteCode)
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .onChange(of: inviteCode) { _, newValue in
                    inviteCode = String(newValue.uppercased().prefix(6))
                }
        }
    }

    private var joinButton: some View {
        Button {
            DevineHaptic.actionComplete.fire()
            onJoin(inviteCode)
            dismiss()
        } label: {
            Text("Join")
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
        .disabled(inviteCode.count < 6)
        .opacity(inviteCode.count < 6 ? 0.5 : 1)
    }
}
