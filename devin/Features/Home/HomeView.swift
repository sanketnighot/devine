import SwiftUI

struct HomeView: View {
    @ObservedObject var model: DevineAppModel
    let isSubscribed: Bool
    let onShowPaywall: () -> Void

    @State private var selectedAction: PerfectAction?
    @State private var showingMirrorCheckin = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !isSubscribed {
                        upgradeBanner
                    }

                    scoreSection
                    primaryActionCard
                    actionsSection
                    streakSection
                }
                .padding(16)
            }
            .background(DevineTheme.Colors.bgPrimary)
            .navigationTitle("devine")
            .foregroundStyle(DevineTheme.Colors.textPrimary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingMirrorCheckin = true
                    } label: {
                        Label("Mirror", systemImage: "camera.viewfinder")
                    }
                }
            }
            .sheet(item: $selectedAction) { action in
                ActionPlayerSheet(action: action) {
                    model.markActionDone(action)
                }
                .presentationBackground(DevineTheme.Colors.bgPrimary)
            }
            .sheet(isPresented: $showingMirrorCheckin) {
                MirrorCheckinSheet(model: model)
                    .presentationBackground(DevineTheme.Colors.bgPrimary)
            }
            .onAppear {
                model.rollOverIfNeeded()
            }
        }
    }

    private var upgradeBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Limited mode")
                .font(.headline)
            Text("Unlock your full adaptive plan, weekly upgrades, and premium retention flow.")
                .font(.subheadline)
                .foregroundStyle(DevineTheme.Colors.textSecondary)
            Button("Upgrade now") {
                onShowPaywall()
            }
            .buttonStyle(.borderedProminent)
            .tint(DevineTheme.Colors.ctaPrimary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DevineTheme.Colors.surfaceCard)
        )
    }

    private var scoreSection: some View {
        Group {
            if let score = model.glowScore {
                HStack(spacing: 16) {
                    ScoreRing(value: score)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Glow Score")
                            .font(.headline)
                        Text("Updated \(model.lastUpdatedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                        Text("Evidence-backed and private.")
                            .font(.footnote)
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(DevineTheme.Colors.surfaceCard)
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No verified Glow Score yet")
                        .font(.headline)
                    Text("Add your first mirror check-in to unlock a score based on real evidence.")
                        .font(.subheadline)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                    Button("Start mirror check-in") {
                        showingMirrorCheckin = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DevineTheme.Colors.ctaPrimary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(DevineTheme.Colors.surfaceCard)
                )
            }
        }
    }

    private var primaryActionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today")
                .font(.headline)
            if let next = model.nextPendingAction {
                Text(next.title)
                    .font(.title3.bold())
                Text(next.instructions)
                    .font(.subheadline)
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
                Button("Start next action") {
                    selectedAction = next
                }
                .buttonStyle(.borderedProminent)
                .tint(DevineTheme.Colors.ctaPrimary)
            } else {
                Text("All 3 actions complete.")
                    .font(.title3.bold())
                Text("Tiny win: consistency is your glow multiplier.")
                    .foregroundStyle(DevineTheme.Colors.textSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DevineTheme.Colors.surfaceCard)
        )
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("3 Perfect Actions")
                .font(.headline)
            ForEach(model.todayActions) { action in
                HStack(spacing: 12) {
                    Image(systemName: model.isActionDone(action) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(model.isActionDone(action) ? DevineTheme.Colors.successAccent : DevineTheme.Colors.textMuted)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.title)
                            .font(.subheadline.weight(.semibold))
                        Text("\(action.estimatedMinutes) min")
                            .font(.caption)
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Button("Open") {
                        selectedAction = action
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(DevineTheme.Colors.ctaSecondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DevineTheme.Colors.bgSecondary)
                )
            }
        }
    }

    private var streakSection: some View {
        HStack {
            Label("Streak: \(model.streakDays) day\(model.streakDays == 1 ? "" : "s")", systemImage: "flame.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DevineTheme.Colors.warningAccent)
            Spacer()
            Text("Goal: 5/7 check-ins")
                .font(.footnote)
                .foregroundStyle(DevineTheme.Colors.textSecondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DevineTheme.Colors.surfaceCard)
        )
    }
}

struct ScoreRing: View {
    let value: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(DevineTheme.Colors.ringTrack, lineWidth: 10)

            Circle()
                .trim(from: 0, to: CGFloat(value) / 100.0)
                .stroke(DevineTheme.Colors.ringProgress, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(DevineTheme.Colors.textPrimary)
        }
        .frame(width: 84, height: 84)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Glow Score")
        .accessibilityValue("\(value) out of 100")
    }
}
