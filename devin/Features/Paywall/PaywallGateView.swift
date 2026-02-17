import SwiftUI

private enum PaywallLoadState {
    case loading
    case ready
    case failed
}

struct PaywallGateView: View {
    let onSubscribe: () -> Void
    let onContinueLimited: () -> Void

    @State private var loadState: PaywallLoadState = .loading
    @State private var isAnnual = true

    var body: some View {
        VStack(spacing: 20) {
            Text("Start your Glow Plan")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Personalized. Minimal. Real results.")
                .foregroundStyle(DevineTheme.Colors.textSecondary)

            Group {
                switch loadState {
                case .loading:
                    ProgressView("Loading subscriptions...")
                        .frame(maxWidth: .infinity, minHeight: 130)

                case .ready:
                    VStack(spacing: 12) {
                        payCard(
                            title: "$24 / month",
                            subtitle: "Flexible month-to-month",
                            selected: !isAnnual
                        ) {
                            isAnnual = false
                        }

                        payCard(
                            title: "$199 / year",
                            subtitle: "Save 31%",
                            selected: isAnnual
                        ) {
                            isAnnual = true
                        }

                        Button("Start My Glow Plan") {
                            onSubscribe()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)

                        Button("Restore Purchases") {
                            onSubscribe()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: 460)

                case .failed:
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Subscriptions are temporarily unavailable.")
                            .font(.headline)
                        Text("Retry, or continue with limited access for now.")
                            .foregroundStyle(DevineTheme.Colors.textSecondary)
                        HStack {
                            Button("Retry") {
                                loadProducts()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(DevineTheme.Colors.ctaPrimary)

                            Button("Continue Limited") {
                                onContinueLimited()
                            }
                            .buttonStyle(.bordered)
                            .tint(DevineTheme.Colors.ctaSecondary)
                        }
                    }
                    .frame(maxWidth: 460, alignment: .leading)
                }
            }

            if loadState == .ready {
                Button("Continue with limited access") {
                    onContinueLimited()
                }
                .buttonStyle(.plain)
                .foregroundStyle(DevineTheme.Colors.textSecondary)
            }

            Text("Cancel anytime. Subscription terms apply.")
                .font(.footnote)
                .foregroundStyle(DevineTheme.Colors.textSecondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [DevineTheme.Colors.bgPrimary, DevineTheme.Colors.bgSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .foregroundStyle(DevineTheme.Colors.textPrimary)
        .tint(DevineTheme.Colors.ctaPrimary)
        .task {
            loadProducts()
        }
    }

    private func loadProducts() {
        loadState = .loading
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            if ProcessInfo.processInfo.environment["SIMULATE_PAYWALL_FAILURE"] == "1" {
                loadState = .failed
            } else {
                loadState = .ready
            }
        }
    }

    private func payCard(title: String, subtitle: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? DevineTheme.Colors.ctaPrimary : DevineTheme.Colors.textMuted)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(DevineTheme.Colors.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected ? DevineTheme.Colors.ctaPrimary : DevineTheme.Colors.borderSubtle, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
