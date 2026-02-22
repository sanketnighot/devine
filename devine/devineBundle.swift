import WidgetKit
import SwiftUI

@main
struct devineBundle: WidgetBundle {
    var body: some Widget {
        GlowScoreWidget()
        StreakWidget()
        TodayActionsWidget()
    }
}
