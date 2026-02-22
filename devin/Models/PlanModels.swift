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

    var label: String {
        switch self {
        case .minorTweak: "Fine-tune"
        case .resequence: "Resequence"
        case .pivot: "Pivot"
        }
    }

    var color: Color {
        switch self {
        case .minorTweak: DevineTheme.Colors.successAccent
        case .resequence: DevineTheme.Colors.warningAccent
        case .pivot: DevineTheme.Colors.errorAccent
        }
    }
}

struct PlanAdjustmentRecord: Identifiable {
    let id: UUID
    let createdAt: Date
    let severity: PlanAdjustmentSeverity
    let reason: String
    let associatedEvidence: [String]

    init(
        id: UUID = UUID(),
        createdAt: Date,
        severity: PlanAdjustmentSeverity,
        reason: String,
        associatedEvidence: [String] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.severity = severity
        self.reason = reason
        self.associatedEvidence = associatedEvidence
    }
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
