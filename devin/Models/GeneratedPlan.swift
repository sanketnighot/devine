import Foundation

// MARK: - GeneratedPlan

/// A 7-day AI-generated plan with day-by-day actions, scores, and subscores.
struct GeneratedPlan: Codable, Identifiable {
    let id: UUID
    let generatedAt: Date
    let goalRawValue: String
    let dailyPlans: [DailyPlan]           // 7 days of unique actions
    let summary: String                    // Personalized message from Gemini
    let rationale: String                  // Brief reasoning
    let initialGlowScore: Int             // AI-estimated starting score (0–100)
    let subscores: [AISubscore]           // Category breakdowns from AI

    init(
        id: UUID = UUID(),
        generatedAt: Date = .now,
        goalRawValue: String,
        dailyPlans: [DailyPlan],
        summary: String,
        rationale: String,
        initialGlowScore: Int,
        subscores: [AISubscore]
    ) {
        self.id = id
        self.generatedAt = generatedAt
        self.goalRawValue = goalRawValue
        self.dailyPlans = dailyPlans
        self.summary = summary
        self.rationale = rationale
        self.initialGlowScore = initialGlowScore
        self.subscores = subscores
    }

    /// Returns the DailyPlan for a given date, or nil if no plan exists for that day.
    func dailyPlan(for date: Date) -> DailyPlan? {
        let cal = Calendar.current
        return dailyPlans.first { cal.isDate($0.date, inSameDayAs: date) }
    }

    /// Returns today's DailyPlan, falling back to the first day if today isn't in range.
    var todayPlan: DailyPlan? {
        dailyPlan(for: .now) ?? dailyPlans.first
    }
}

// MARK: - DailyPlan

/// One day's worth of actions within a weekly plan.
struct DailyPlan: Codable, Identifiable {
    let id: UUID
    let dayNumber: Int                    // 1–7
    let date: Date                        // The actual calendar date
    let theme: String                     // e.g. "Hydration & Skin Reset"
    let actions: [PerfectActionCodable]   // Exactly 3 actions

    init(
        id: UUID = UUID(),
        dayNumber: Int,
        date: Date,
        theme: String,
        actions: [PerfectActionCodable]
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.date = date
        self.theme = theme
        self.actions = actions
    }
}

// MARK: - AISubscore

/// An AI-generated category score with insight.
struct AISubscore: Codable, Identifiable {
    let id: String                        // "skin", "face", "body", etc.
    let label: String                     // "Skin", "Face", etc.
    let value: Int                        // 0–100
    let insight: String                   // AI-generated one-liner

    var icon: String {
        switch id {
        case "skin": return "sparkles"
        case "face": return "face.smiling"
        case "body": return "figure.stand"
        case "hair": return "comb"
        case "energy": return "bolt.fill"
        case "confidence": return "star.fill"
        default: return "circle"
        }
    }
}

// MARK: - PerfectActionCodable

/// Codable mirror of PerfectAction (which uses non-Codable types in extensions).
struct PerfectActionCodable: Codable, Identifiable {
    let id: UUID
    let title: String
    let instructions: String
    let estimatedMinutes: Int

    init(id: UUID = UUID(), title: String, instructions: String, estimatedMinutes: Int) {
        self.id = id
        self.title = title
        self.instructions = instructions
        self.estimatedMinutes = estimatedMinutes
    }

    func toPerfectAction() -> PerfectAction {
        PerfectAction(id: id, title: title, instructions: instructions, estimatedMinutes: estimatedMinutes)
    }
}

// MARK: - Gemini API Response Shapes

struct GeminiPlanResponse: Codable {
    let dailyPlans: [GeminiDailyPlan]
    let summary: String
    let rationale: String
    let initialGlowScore: Int
    let subscores: [GeminiSubscore]
}

struct GeminiDailyPlan: Codable {
    let dayNumber: Int
    let theme: String
    let actions: [GeminiActionItem]
}

struct GeminiActionItem: Codable {
    let title: String
    let instructions: String
    let estimatedMinutes: Int
}

struct GeminiSubscore: Codable {
    let id: String
    let label: String
    let value: Int
    let insight: String
}

// MARK: - Gemini Check-in Evaluation Response

struct GeminiCheckinEvaluationResponse: Codable {
    let updatedGlowScore: Int
    let subscores: [GeminiSubscore]
    let feedback: String
    let adjustmentSeverity: String          // "minor_tweak", "resequence", or "pivot"
    let suggestedPlanUpdate: GeminiSuggestedPlanUpdate?
}

struct GeminiSuggestedPlanUpdate: Codable {
    let reason: String
    let dailyPlans: [GeminiDailyPlan]       // Reuses existing type
}
