import Foundation

// MARK: - CheckinEvaluation

/// AI-generated evaluation result from a mirror check-in.
struct CheckinEvaluation: Codable, Identifiable {
    let id: UUID
    let updatedGlowScore: Int              // 0–100
    let updatedSubscores: [AISubscore]
    let feedback: String                    // Warm, personalized paragraph from Gemini
    let adjustmentSeverity: PlanAdjustmentSeverity
    let suggestedPlanUpdate: SuggestedPlanUpdate?

    init(
        id: UUID = UUID(),
        updatedGlowScore: Int,
        updatedSubscores: [AISubscore],
        feedback: String,
        adjustmentSeverity: PlanAdjustmentSeverity,
        suggestedPlanUpdate: SuggestedPlanUpdate? = nil
    ) {
        self.id = id
        self.updatedGlowScore = updatedGlowScore
        self.updatedSubscores = updatedSubscores
        self.feedback = feedback
        self.adjustmentSeverity = adjustmentSeverity
        self.suggestedPlanUpdate = suggestedPlanUpdate
    }
}

// MARK: - SuggestedPlanUpdate

/// An optional plan adjustment suggested by the AI after evaluating a check-in.
struct SuggestedPlanUpdate: Codable {
    let reason: String
    let updatedDailyPlans: [DailyPlan]
}

// MARK: - CheckinEvaluationState

/// Tracks the lifecycle of an AI check-in evaluation request.
enum CheckinEvaluationState: Equatable {
    case idle
    case loading
    case ready(CheckinEvaluation)
    case failed(String)

    static func == (lhs: CheckinEvaluationState, rhs: CheckinEvaluationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.ready(let a), .ready(let b)):
            return a.id == b.id
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}
