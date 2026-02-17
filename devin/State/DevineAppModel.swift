import Foundation
import Combine

final class DevineAppModel: ObservableObject {
    @Published private(set) var primaryGoal: GlowGoal = .faceDefinition
    @Published private(set) var todayActions: [PerfectAction] = PerfectAction.defaults(for: .faceDefinition)
    @Published private(set) var completedActionIDs: Set<UUID> = []
    @Published private(set) var streakDays: Int = 0
    @Published private(set) var glowScore: Int?
    @Published private(set) var confidence: Double = 0
    @Published private(set) var evidenceLedger: [EvidenceEvent] = []
    @Published private(set) var goalTrajectory: GoalTrajectory?
    @Published private(set) var lastUpdatedAt: Date = .now
    @Published private(set) var latestAdjustmentSeverity: PlanAdjustmentSeverity = .minorTweak

    private var currentDayKey = DevineAppModel.dayKey(for: .now)
    private var streakCreditedDayKey: String?

    func configure(goal: GlowGoal, hasInitialEvidence: Bool) {
        primaryGoal = goal
        todayActions = PerfectAction.defaults(for: goal)
        completedActionIDs.removeAll()
        goalTrajectory = nil
        glowScore = nil
        confidence = 0
        evidenceLedger.removeAll()
        latestAdjustmentSeverity = .minorTweak
        lastUpdatedAt = .now

        if hasInitialEvidence {
            recordMirrorCheckin(tags: ["onboarding_photo"], note: "Initial private check-in")
        }
    }

    func rollOverIfNeeded() {
        let newKey = DevineAppModel.dayKey(for: .now)
        guard newKey != currentDayKey else {
            return
        }
        currentDayKey = newKey
        completedActionIDs.removeAll()
        todayActions = PerfectAction.defaults(for: primaryGoal)
        latestAdjustmentSeverity = .resequence
    }

    func isActionDone(_ action: PerfectAction) -> Bool {
        completedActionIDs.contains(action.id)
    }

    var nextPendingAction: PerfectAction? {
        todayActions.first { !completedActionIDs.contains($0.id) }
    }

    func markActionDone(_ action: PerfectAction) {
        rollOverIfNeeded()
        completedActionIDs.insert(action.id)
        evaluatePlanAdjustment()

        if completedActionIDs.count == todayActions.count, streakCreditedDayKey != currentDayKey {
            streakDays += 1
            streakCreditedDayKey = currentDayKey
            lastUpdatedAt = .now
        }
    }

    func recordMirrorCheckin(tags: [String], note: String) {
        rollOverIfNeeded()

        let existingScore = glowScore ?? 66
        let completionRatio = Double(completedActionIDs.count) / Double(max(1, todayActions.count))
        let baseDelta = Int((completionRatio * 4).rounded())
        let positiveTagBonus = tags.contains("Hydrated") || tags.contains("Good sleep") ? 2 : 0
        let negativeTagPenalty = tags.contains("High stress") ? -1 : 0
        let nextScore = max(0, min(100, existingScore + baseDelta + positiveTagBonus + negativeTagPenalty))

        glowScore = nextScore
        confidence = min(0.92, max(0.36, 0.45 + Double(evidenceLedger.count) * 0.07))
        goalTrajectory = trajectory(for: nextScore, confidence: confidence)
        latestAdjustmentSeverity = completionRatio < 0.34 ? .resequence : .minorTweak
        lastUpdatedAt = .now

        let used = tags.isEmpty ? ["manual_checkin"] : tags
        var missing = ["Apple Health trends", "sleep consistency"]
        if !tags.isEmpty {
            missing = ["sleep consistency", "7-day check-in history"]
        }

        let summary = note.isEmpty ? "Mirror check-in recorded. Plan tuned for today." : note
        evidenceLedger.insert(
            EvidenceEvent(
                createdAt: .now,
                summary: summary,
                evidenceUsed: used,
                evidenceMissing: missing
            ),
            at: 0
        )
    }

    private func evaluatePlanAdjustment() {
        let ratio = Double(completedActionIDs.count) / Double(max(1, todayActions.count))
        if ratio == 1 {
            latestAdjustmentSeverity = .minorTweak
        } else if ratio >= 0.34 {
            latestAdjustmentSeverity = .resequence
        } else {
            latestAdjustmentSeverity = .pivot
        }
    }

    private func trajectory(for score: Int, confidence: Double) -> GoalTrajectory {
        let distance = max(8, 100 - score)
        let minWeeks = max(3, distance / 6)
        let likelyWeeks = minWeeks + 3
        let maxWeeks = likelyWeeks + 4
        return GoalTrajectory(minWeeks: minWeeks, likelyWeeks: likelyWeeks, maxWeeks: maxWeeks, confidence: confidence)
    }

    private static func dayKey(for date: Date) -> String {
        date.formatted(.iso8601.year().month().day())
    }
}
