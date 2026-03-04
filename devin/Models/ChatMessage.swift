import Foundation

// MARK: - ChatRole

enum ChatRole: String, Codable {
    case user
    case assistant
}

// MARK: - ChatMessage

struct ChatMessage: Identifiable {
    let id: UUID
    let role: ChatRole
    var content: String
    let timestamp: Date
    var planProposal: ChatPlanProposal?
    var attachedStats: Bool   // whether stats were included in this user message
    var isStreaming: Bool

    init(
        id: UUID = UUID(),
        role: ChatRole,
        content: String,
        timestamp: Date = .now,
        planProposal: ChatPlanProposal? = nil,
        attachedStats: Bool = false,
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.planProposal = planProposal
        self.attachedStats = attachedStats
        self.isStreaming = isStreaming
    }
}

// MARK: - ChatPlanProposal

struct ChatPlanProposal: Identifiable {
    let id: UUID
    let reason: String
    let suggestedFocus: String
    let severity: PlanAdjustmentSeverity
    var isApplied: Bool

    init(
        id: UUID = UUID(),
        reason: String,
        suggestedFocus: String,
        severity: PlanAdjustmentSeverity,
        isApplied: Bool = false
    ) {
        self.id = id
        self.reason = reason
        self.suggestedFocus = suggestedFocus
        self.severity = severity
        self.isApplied = isApplied
    }
}

// MARK: - CoachNudge

struct CoachNudge: Equatable {
    enum NudgeType: Equatable {
        case postCheckin
        case scoreRise
        case scoreDrop
        case streakBroken
    }
    let type: NudgeType
    let headline: String
    let subtitle: String
    let seedMessage: String
}

// MARK: - ChatStats

struct ChatStats {
    let glowScore: Int?
    let streakDays: Int
    let goal: GlowGoal
    let completedToday: Int
    let totalToday: Int
    let currentPlanDay: Int
    let customGoalName: String?

    var goalLabel: String { customGoalName ?? goal.displayName }
}
