import Foundation
import SwiftUI

struct EvidenceEvent: Identifiable {
    let id = UUID()
    let createdAt: Date
    let summary: String
    let evidenceUsed: [String]
    let evidenceMissing: [String]
}

struct GoalTrajectory {
    let minWeeks: Int
    let likelyWeeks: Int
    let maxWeeks: Int
    let confidence: Double
}

enum PlanAdjustmentSeverity: String {
    case minorTweak = "minor_tweak"
    case resequence = "resequence"
    case pivot = "pivot"
}

struct SubscoreEntry: Identifiable {
    let id: String
    let label: String
    let icon: String
    let value: Int
    let maxValue: Int
    let accentColor: Color
    let insight: String
}
