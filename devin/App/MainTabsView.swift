import SwiftUI

struct MainTabsView: View {
    @ObservedObject var model: DevineAppModel
    @ObservedObject var chatCoordinator: ChatCoordinator
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

            ChatThreadListView(coordinator: chatCoordinator, model: model)
                .tabItem { Label("Coach", systemImage: "wand.and.stars") }
                .tag(2)

            SocialView(model: model)
                .tabItem { Label("Social", systemImage: "person.3.fill") }
                .tag(3)

            ProfileView(model: model, chatCoordinator: chatCoordinator, isSubscribed: isSubscribed, onShowPaywall: onShowPaywall)
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(4)
        }
        // CoachNudge → create a new dedicated thread and auto-navigate to it.
        .onChange(of: model.coachNudge) { _, nudge in
            guard let nudge else { return }
            let name = model.userProfile?.name ?? "there"
            let goalLabel = model.chatStats.goalLabel
            let thread = chatCoordinator.createNudgeThread(
                seedMessage: nudge.seedMessage,
                name: name,
                goalLabel: goalLabel
            )
            chatCoordinator.pendingNavigationThreadID = thread.id
            model.selectedTab = 2
            model.dismissCoachNudge()
        }
    }
}
