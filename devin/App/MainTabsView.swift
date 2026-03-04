import SwiftUI

struct MainTabsView: View {
    @ObservedObject var model: DevineAppModel
    let isSubscribed: Bool
    let onShowPaywall: () -> Void

    var body: some View {
        TabView(selection: $model.selectedTab) {
            HomeView(model: model, isSubscribed: isSubscribed, onShowPaywall: onShowPaywall)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            PlanView(model: model)
                .tabItem { Label("Plan", systemImage: "list.bullet.clipboard") }
                .tag(1)

            ChatView(model: model)
                .tabItem { Label("Coach", systemImage: "wand.and.stars") }
                .tag(2)

            SocialView(model: model)
                .tabItem { Label("Social", systemImage: "person.3.fill") }
                .tag(3)

            ProfileView(model: model, isSubscribed: isSubscribed, onShowPaywall: onShowPaywall)
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(4)
        }
    }
}
