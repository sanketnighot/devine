import Foundation

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
