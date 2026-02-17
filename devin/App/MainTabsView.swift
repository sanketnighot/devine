import SwiftUI

struct MainTabsView: View {
    @ObservedObject var model: DevineAppModel
    let isSubscribed: Bool
    let onShowPaywall: () -> Void

    var body: some View {
        TabView {
            HomeView(model: model, isSubscribed: isSubscribed, onShowPaywall: onShowPaywall)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            PlanView(model: model)
                .tabItem {
                    Label("Plan", systemImage: "list.bullet.clipboard")
                }

            SocialView()
                .tabItem {
                    Label("Social", systemImage: "person.3.fill")
                }

            ProfileView(isSubscribed: isSubscribed, onShowPaywall: onShowPaywall)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}
