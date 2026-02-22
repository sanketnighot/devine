import SwiftUI

struct SettingsView: View {
    @AppStorage("setting_daily_reminder") private var dailyReminder = true
    @AppStorage("setting_streak_alerts") private var streakAlerts = true
    @AppStorage("setting_weekly_recap") private var weeklyRecapEnabled = true

    @State private var showHealthConnect = false

    var body: some View {
        ScrollView {
            VStack(spacing: DevineTheme.Spacing.xl) {
                notificationsSection
                integrationsSection
                appearanceSection
                privacySection
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
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showHealthConnect) {
            HealthConnectSheet()
                .presentationBackground(DevineTheme.Colors.bgPrimary)
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
            sectionLabel("Notifications")

            SurfaceCard(padding: DevineTheme.Spacing.md) {
                VStack(spacing: DevineTheme.Spacing.lg) {
                    settingToggle(
                        icon: "bell.badge",
                        title: "Daily reminder",
                        subtitle: "A gentle nudge to start your actions",
                        isOn: $dailyReminder
                    )

                    Divider()

                    settingToggle(
                        icon: "flame",
                        title: "Streak alerts",
                        subtitle: "Don't lose your streak!",
                        isOn: $streakAlerts
                    )

                    Divider()

                    settingToggle(
                        icon: "calendar",
                        title: "Weekly recap",
                        subtitle: "Your Monday glow-up summary",
                        isOn: $weeklyRecapEnabled
                    )
                }
            }
        }
    }

    // MARK: - Integrations

    private var integrationsSection: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
            sectionLabel("Integrations")

            SurfaceCard(padding: DevineTheme.Spacing.xs) {
                VStack(spacing: 0) {
                    Button {
                        DevineHaptic.tap.fire()
                        showHealthConnect = true
                    } label: {
                        settingRow(
                            icon: "heart.fill",
                            iconColor: DevineTheme.Colors.errorAccent,
                            title: "Apple Health",
                            trailing: .chevron
                        )
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.horizontal, DevineTheme.Spacing.lg)

                    settingRow(
                        icon: "circle.dotted",
                        iconColor: DevineTheme.Colors.textMuted,
                        title: "Oura Ring",
                        trailing: .comingSoon
                    )
                }
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
            sectionLabel("Appearance")

            SurfaceCard(padding: DevineTheme.Spacing.xs) {
                VStack(spacing: 0) {
                    settingRow(
                        icon: "app.badge",
                        iconColor: DevineTheme.Colors.ctaPrimary,
                        title: "App icon",
                        trailing: .comingSoon
                    )

                    Divider()
                        .padding(.horizontal, DevineTheme.Spacing.lg)

                    settingRow(
                        icon: "globe",
                        iconColor: DevineTheme.Colors.ctaSecondary,
                        title: "Language",
                        trailing: .comingSoon
                    )
                }
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: DevineTheme.Spacing.sm) {
            sectionLabel("Privacy & Data")

            SurfaceCard(padding: DevineTheme.Spacing.xs) {
                VStack(spacing: 0) {
                    settingRow(
                        icon: "externaldrive",
                        iconColor: DevineTheme.Colors.textMuted,
                        title: "Manage my data",
                        trailing: .chevron
                    )

                    Divider()
                        .padding(.horizontal, DevineTheme.Spacing.lg)

                    settingRow(
                        icon: "square.and.arrow.up",
                        iconColor: DevineTheme.Colors.textMuted,
                        title: "Export my data",
                        trailing: .chevron
                    )

                    Divider()
                        .padding(.horizontal, DevineTheme.Spacing.lg)

                    settingRow(
                        icon: "trash",
                        iconColor: DevineTheme.Colors.errorAccent,
                        title: "Delete account",
                        trailing: .none
                    )
                }
            }

            HStack(spacing: DevineTheme.Spacing.sm) {
                Image(systemName: "lock.shield")
                    .font(.caption2)
                    .foregroundStyle(DevineTheme.Colors.textMuted)

                Text("Your data never leaves this device unless you choose to share it.")
                    .font(.caption2)
                    .foregroundStyle(DevineTheme.Colors.textMuted)
            }
            .padding(.horizontal, DevineTheme.Spacing.xs)
        }
    }

    // MARK: - Components

    private enum TrailingType {
        case chevron, comingSoon, none
    }

    private func settingToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: DevineTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(DevineTheme.Colors.textMuted)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(DevineTheme.Colors.ctaPrimary)
        }
    }

    private func settingRow(icon: String, iconColor: Color, title: String, trailing: TrailingType) -> some View {
        HStack(spacing: DevineTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(
                    title == "Delete account"
                        ? DevineTheme.Colors.errorAccent
                        : DevineTheme.Colors.textPrimary
                )

            Spacer()

            switch trailing {
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
            case .comingSoon:
                Text("Soon")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule(style: .continuous)
                            .fill(DevineTheme.Colors.bgSecondary)
                    )
            case .none:
                EmptyView()
            }
        }
        .padding(.horizontal, DevineTheme.Spacing.lg)
        .padding(.vertical, DevineTheme.Spacing.md)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .rounded, weight: .bold))
            .foregroundStyle(DevineTheme.Colors.textMuted)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.leading, DevineTheme.Spacing.xs)
    }
}
