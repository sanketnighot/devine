import SwiftUI

struct SocialView: View {
    @State private var circleMemberCount = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("Support Circles") {
                    Text("Private by default. No public rankings. No appearance leaderboards.")
                        .font(.footnote)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                    Stepper("Members: \(circleMemberCount)", value: $circleMemberCount, in: 3...8)
                    Button("Create Circle") {}
                    Button("Join via invite code") {}
                }

                Section("Glow Challenges") {
                    Text("Co-op only. Win as a team through daily check-ins.")
                        .font(.footnote)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                    Button("Start 7-day consistency challenge") {}
                }
            }
            .scrollContentBackground(.hidden)
            .background(DevineTheme.Colors.bgPrimary)
            .foregroundStyle(DevineTheme.Colors.textPrimary)
            .navigationTitle("Social")
        }
        .tint(DevineTheme.Colors.ctaPrimary)
    }
}
