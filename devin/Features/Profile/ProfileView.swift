import SwiftUI

struct ProfileView: View {
    let isSubscribed: Bool
    let onShowPaywall: () -> Void

    @State private var selectedLegalDoc: LegalDocument?

    var body: some View {
        NavigationStack {
            List {
                Section("Subscription") {
                    Label(
                        isSubscribed ? "Active" : "Limited mode",
                        systemImage: isSubscribed ? "checkmark.seal.fill" : "lock.fill"
                    )
                    Button(isSubscribed ? "Manage subscription" : "Upgrade") {
                        onShowPaywall()
                    }
                }

                Section("Account linking") {
                    Button("Continue with Apple") {}
                    Button("Continue with Google") {}
                }

                Section("Legal") {
                    Button("Terms of Service") {
                        selectedLegalDoc = .terms
                    }
                    Button("Privacy Policy") {
                        selectedLegalDoc = .privacy
                    }
                }

#if DEBUG
                Section("Developer") {
                    Toggle("Unlock all flows locally", isOn: UserDefaults.standard.binding(forKey: "debug_unlock_all"))
                }
#endif
            }
            .scrollContentBackground(.hidden)
            .background(DevineTheme.Colors.bgPrimary)
            .foregroundStyle(DevineTheme.Colors.textPrimary)
            .navigationTitle("Profile")
            .sheet(item: $selectedLegalDoc) { document in
                LegalWebView(document: document)
            }
        }
        .tint(DevineTheme.Colors.ctaPrimary)
    }
}
