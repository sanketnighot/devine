import SwiftUI

struct ActiveCircleView: View {
    @ObservedObject var model: DevineAppModel
    @Binding var showChallenge: Bool

    @State private var reportingMember: CircleMember?
    @State private var blockConfirmMember: CircleMember?
    @State private var showReportSheet = false
    @State private var headerVisible = false

    var body: some View {
        VStack(spacing: DevineTheme.Spacing.xl) {
            circleHero
            memberList
        }
        .sheet(isPresented: $showReportSheet) {
            if let member = reportingMember {
                MemberReportSheet(member: member) { _ in
                    reportingMember = nil
                }
                .presentationBackground(DevineTheme.Colors.bgPrimary)
            }
        }
        .confirmationDialog(
            "Block \(blockConfirmMember?.displayName ?? "")?",
            isPresented: Binding(
                get: { blockConfirmMember != nil },
                set: { if !$0 { blockConfirmMember = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Block", role: .destructive) {
                if let member = blockConfirmMember {
                    DevineHaptic.tap.fire()
                    model.blockMember(id: member.id)
                }
                blockConfirmMember = nil
            }
            Button("Cancel", role: .cancel) {
                blockConfirmMember = nil
            }
        } message: {
            Text("They won't be able to see your activity and will be removed from this circle.")
        }
        .onAppear {
            withAnimation(DevineTheme.Motion.expressive.delay(0.1)) {
                headerVisible = true
            }
        }
    }

    // MARK: - Hero

    private var circleHero: some View {
        GradientCard(colors: DevineTheme.Gradients.heroCard, showGlow: true) {
            VStack(spacing: DevineTheme.Spacing.lg) {
                if let circle = model.glowCircle {
                    HStack {
                        Text(circle.name)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(DevineTheme.Colors.textOnGradient)

                        Spacer()

                        Text("\(circle.members.count) members")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.7))
                            .padding(.horizontal, DevineTheme.Spacing.sm)
                            .padding(.vertical, DevineTheme.Spacing.xs)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.15))
                            )
                    }

                    // Member avatars row
                    HStack(spacing: DevineTheme.Spacing.md) {
                        ForEach(circle.members) { member in
                            VStack(spacing: DevineTheme.Spacing.xs) {
                                ZStack {
                                    Circle()
                                        .fill(avatarFill(member.avatarColor))
                                        .frame(width: 44, height: 44)

                                    Text(member.avatarInitials)
                                        .font(.system(.caption, design: .rounded, weight: .bold))
                                        .foregroundStyle(DevineTheme.Colors.textOnGradient)
                                }

                                HStack(spacing: 2) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 8))
                                    Text("\(member.streakDays)")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.8))
                            }
                        }

                        Spacer()
                    }

                    // Invite code
                    HStack(spacing: DevineTheme.Spacing.sm) {
                        Image(systemName: "link")
                            .font(.caption2)
                        Text("Invite: \(circle.inviteCode)")
                            .font(.system(.caption, design: .monospaced, weight: .semibold))
                    }
                    .foregroundStyle(DevineTheme.Colors.textOnGradient.opacity(0.6))

                    // Challenge CTA
                    Button {
                        DevineHaptic.tap.fire()
                        showChallenge = true
                    } label: {
                        HStack(spacing: DevineTheme.Spacing.sm) {
                            Image(systemName: "trophy.fill")
                                .font(.caption.weight(.semibold))
                            Text(circle.activeChallenge != nil ? "View challenge" : "Start a challenge")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                        }
                        .foregroundStyle(DevineTheme.Gradients.heroCard.first ?? .pink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DevineTheme.Spacing.md)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(headerVisible ? 1 : 0)
        .offset(y: headerVisible ? 0 : 16)
    }

    // MARK: - Member List

    private var memberList: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: DevineTheme.Spacing.md) {
                Text("Members")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)

                if let circle = model.glowCircle {
                    ForEach(circle.members) { member in
                        memberRow(member)
                            .contextMenu {
                                Button(role: .destructive) {
                                    reportingMember = member
                                    showReportSheet = true
                                } label: {
                                    Label("Report...", systemImage: "exclamationmark.triangle")
                                }

                                Button(role: .destructive) {
                                    blockConfirmMember = member
                                } label: {
                                    Label("Block", systemImage: "hand.raised")
                                }
                            }
                    }
                }
            }
        }
    }

    private func memberRow(_ member: CircleMember) -> some View {
        HStack(spacing: DevineTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(avatarFill(member.avatarColor))
                    .frame(width: 36, height: 36)

                Text(member.avatarInitials)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(member.displayName)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))

                HStack(spacing: DevineTheme.Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(DevineTheme.Colors.warningAccent)
                    Text("\(member.streakDays) day streak")
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                }
            }

            Spacer()
        }
        .padding(.vertical, DevineTheme.Spacing.xs)
    }

    // MARK: - Helpers

    private func avatarFill(_ color: CircleMemberColor) -> some ShapeStyle {
        switch color {
        case .rose:
            return AnyShapeStyle(
                LinearGradient(colors: [DevineTheme.Colors.ctaPrimary, DevineTheme.Colors.ctaPrimary.opacity(0.7)],
                               startPoint: .top, endPoint: .bottom)
            )
        case .peach:
            return AnyShapeStyle(
                LinearGradient(colors: [DevineTheme.Colors.peach, DevineTheme.Colors.peach.opacity(0.7)],
                               startPoint: .top, endPoint: .bottom)
            )
        case .plum:
            return AnyShapeStyle(
                LinearGradient(colors: [DevineTheme.Colors.plum, DevineTheme.Colors.plum.opacity(0.7)],
                               startPoint: .top, endPoint: .bottom)
            )
        case .sage:
            return AnyShapeStyle(
                LinearGradient(colors: [DevineTheme.Colors.successAccent, DevineTheme.Colors.successAccent.opacity(0.7)],
                               startPoint: .top, endPoint: .bottom)
            )
        case .sky:
            return AnyShapeStyle(
                LinearGradient(colors: [DevineTheme.Colors.ctaSecondary, DevineTheme.Colors.ctaSecondary.opacity(0.7)],
                               startPoint: .top, endPoint: .bottom)
            )
        }
    }
}
