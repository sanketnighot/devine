import UIKit

enum DevineHaptic {
    case actionComplete
    case allActionsComplete
    case streakMilestone
    case scoreUpdate
    case sheetPresent
    case tap

    func fire() {
        switch self {
        case .actionComplete:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)

        case .allActionsComplete:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()

        case .streakMilestone:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()

        case .scoreUpdate:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()

        case .sheetPresent:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()

        case .tap:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
    }
}
