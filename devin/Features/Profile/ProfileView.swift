import SwiftUI

struct ProfileView: View {
    @ObservedObject var model: DevineAppModel
    let isSubscribed: Bool
    let onShowPaywall: () -> Void

    @State private var selectedLegalDoc: LegalDocument?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DevineTheme.Spacing.xl) {
                    profileHeader
                    subscriptionCard
                    accountSection
                    appSection
                    #if DEBUG
                    developerSection
                    #endif
                }
                .padding(.horizontal, DevineTheme.Spacing.lg)
                .padding(.top, DevineTheme.Spacing.md)
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
            .navigationTitle("Profile")
            .sheet(item: $selectedLegalDoc) { document in
                LegalWebView(document: document)
            }
        }
        .tint(DevineTheme.Colors.ctaPrimary)
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        GradientCard(colors: DevineTheme.Gradients.heroCard, showGlow: true) {
            VStack(spacing: DevineTheme.Spacing.lg) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 72, height: 72)

                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DevineTheme.Colors.textOnGradient)
                }

                VStack(spacing: DevineTheme.Spacing.sm) {
                    Text("Hey, you \(greetingEmoji)")
                        .font(.title3.bold())
                        .foregroundStyle(DevineTheme.Colors.textOnGradient)

                    HStack(spacing: DevineTheme.Spacing.sm) {
                        // Goal badge (inverted for gradient bg)
                        HStack(spacing: DevineTheme.Spacing.xs) {
                            Image(systemName: model.primaryGoal.iconName)
                                .font(.caption2)
                            Text(model.primaryGoal.displayName)
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(DevineTheme.Colors.textOnGradient)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.2))
                        )

                        // Streak badge
                        if model.streakDays > 0 {
                            HStack(spacing: DevineTheme.Spacing.xs) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                Text("\(model.streakDays)-day streak")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundStyle(DevineTheme.Colors.textOnGradient)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.2))
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "☀️"
        case 12..<17: return "✨"
        case 17..<21: return "🌙"
        default: return "💤"
        }
    }

    // MARK: - Subscription

    private var subscriptionCard: some View {
        Group {
            if isSubscribed {
                SurfaceCard {
                    HStack(spacing: DevineTheme.Spacing.md) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundStyle(DevineTheme.Colors.successAccent)

                        VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                            Text("Premium active")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))

                            Text("Full adaptive plan unlocked")
                                .font(.caption)
                                .foregroundStyle(DevineTheme.Colors.textSecondary)
                        }

                        Spacer()

                        Button {
                            onShowPaywall()
                        } label: {
                            Text("Manage")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                                .padding(.horizontal, DevineTheme.Spacing.md)
                                .padding(.vertical, DevineTheme.Spacing.sm)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(DevineTheme.Colors.ctaPrimary.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                upgradeCard
            }
        }
    }

    private var upgradeCard: some View {
        Button {
            DevineHaptic.tap.fire()
            onShowPaywall()
        } label: {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                HStack(spacing: DevineTheme.Spacing.md) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: DevineTheme.Gradients.primaryCTA,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: DevineTheme.Spacing.xs) {
                        Text("Limited mode")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))

                        Text("Unlock your full adaptive plan and premium features")
                            .font(.caption)
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }

                    Spacer()
                }

                HStack(spacing: DevineTheme.Spacing.sm) {
                    Text("Upgrade")
                        .font(.subheadline.weight(.bold))
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(DevineTheme.Colors.textOnGradient)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DevineTheme.Spacing.md)
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
            .padding(DevineTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DevineTheme.Radius.xl, style: .continuous)
                    .fill(DevineTheme.Colors.surfaceCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DevineTheme.Radius.xl, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: DevineTheme.Gradients.primaryCTA.map { $0.opacity(0.4) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Account

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
            sectionLabel("Account")

            SurfaceCard(padding: DevineTheme.Spacing.xs) {
                VStack(spacing: 0) {
                    profileRow(icon: "apple.logo", label: "Continue with Apple") {}
                    Divider()
                        .padding(.horizontal, DevineTheme.Spacing.lg)
                    profileRow(icon: "g.circle.fill", label: "Continue with Google") {}
                }
            }
        }
    }

    // MARK: - App (Settings + Legal)

    private var appSection: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
            sectionLabel("App")

            SurfaceCard(padding: DevineTheme.Spacing.xs) {
                VStack(spacing: 0) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        HStack(spacing: DevineTheme.Spacing.md) {
                            Image(systemName: "gearshape")
                                .font(.body.weight(.medium))
                                .foregroundStyle(DevineTheme.Colors.textMuted)
                                .frame(width: 24)

                            Text("Settings")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(DevineTheme.Colors.textPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(DevineTheme.Colors.textMuted)
                        }
                        .padding(.horizontal, DevineTheme.Spacing.lg)
                        .padding(.vertical, DevineTheme.Spacing.md)
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.horizontal, DevineTheme.Spacing.lg)

                    profileRow(icon: "doc.text", label: "Terms of Service") {
                        selectedLegalDoc = .terms
                    }
                    Divider()
                        .padding(.horizontal, DevineTheme.Spacing.lg)
                    profileRow(icon: "hand.raised", label: "Privacy Policy") {
                        selectedLegalDoc = .privacy
                    }
                }
            }
        }
    }

    // MARK: - Developer

    #if DEBUG
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
            sectionLabel("Developer")

            SurfaceCard(padding: DevineTheme.Spacing.md) {
                Toggle(isOn: UserDefaults.standard.binding(forKey: "debug_unlock_all")) {
                    HStack(spacing: DevineTheme.Spacing.md) {
                        Image(systemName: "hammer")
                            .font(.body.weight(.medium))
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                            .frame(width: 24)

                        Text("Unlock all flows")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                    }
                }
                .tint(DevineTheme.Colors.ctaPrimary)
            }
        }
    }
    #endif

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .rounded, weight: .bold))
            .foregroundStyle(DevineTheme.Colors.textMuted)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.leading, DevineTheme.Spacing.xs)
    }

    private func profileRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DevineTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
                    .frame(width: 24)

                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(DevineTheme.Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
            }
            .padding(.horizontal, DevineTheme.Spacing.lg)
            .padding(.vertical, DevineTheme.Spacing.md)
        }
        .buttonStyle(.plain)
    }
}
