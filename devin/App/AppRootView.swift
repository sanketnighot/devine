import SwiftUI

struct AppRootView: View {
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    @AppStorage("has_active_subscription") private var hasActiveSubscription = false
    @AppStorage("paywall_dismissed_once") private var paywallDismissedOnce = false
#if DEBUG
    @AppStorage("debug_unlock_all") private var debugUnlockAll = false
#endif

    @StateObject private var model = DevineAppModel()

    private var isSubscribed: Bool {
#if DEBUG
        hasActiveSubscription || debugUnlockAll
#else
        hasActiveSubscription
#endif
    }

    private var shouldShowPaywall: Bool {
        !isSubscribed && !paywallDismissedOnce
    }

    var body: some View {
        ZStack {
            DevineTheme.Colors.bgPrimary
                .ignoresSafeArea()

            Group {
                if !hasCompletedOnboarding && !isSubscribed {
                    OnboardingFlowView { result in
                        model.configure(goal: result.goal, hasInitialEvidence: result.didProvidePhotoEvidence)
                        hasCompletedOnboarding = true
                        paywallDismissedOnce = false
                    }
                } else if shouldShowPaywall {
                    PaywallGateView(
                        onSubscribe: {
                            hasActiveSubscription = true
                            paywallDismissedOnce = true
                        },
                        onContinueLimited: {
                            paywallDismissedOnce = true
                        }
                    )
                } else {
                    MainTabsView(
                        model: model,
                        isSubscribed: isSubscribed,
                        onShowPaywall: {
                            paywallDismissedOnce = false
                        }
                    )
                }
            }
        }
        .tint(DevineTheme.Colors.ctaPrimary)
        .animation(.easeInOut(duration: 0.2), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.2), value: shouldShowPaywall)
    }
}
