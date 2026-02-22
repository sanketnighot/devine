import Foundation
import Combine
import Photos

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
    @Published private(set) var mirrorCheckins: [MirrorCheckinEntry] = []
    @Published private(set) var mirrorTimelineState: MirrorTimelineState = .idle

    private var currentDayKey = DevineAppModel.dayKey(for: .now)
    private var streakCreditedDayKey: String?
    private let mirrorMetadataStore = MirrorCheckinMetadataStore()

    init() {
        loadMirrorTimeline()
    }

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
        mirrorCheckins.removeAll()
        persistMirrorCheckins()
        syncMirrorTimelineState()

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
        applyMirrorCheckinScoring(tags: tags, note: note)
    }

    func recordMirrorCheckin(
        tags: [String],
        note: String,
        assetLocalIdentifier: String?,
        source: MirrorPhotoSource?,
        photoCapturedAt: Date? = nil
    ) {
        var augmentedTags = tags
        if assetLocalIdentifier != nil {
            augmentedTags.append("photo_evidence")
        }
        applyMirrorCheckinScoring(tags: augmentedTags, note: note)

        guard let assetLocalIdentifier, let source else {
            return
        }

        let entry = MirrorCheckinEntry(
            createdAt: photoCapturedAt ?? .now,
            tags: tags,
            note: note,
            assetLocalIdentifier: assetLocalIdentifier,
            source: source
        )
        mirrorCheckins.insert(entry, at: 0)
        mirrorCheckins.sort { $0.createdAt > $1.createdAt }
        persistMirrorCheckins()
        syncMirrorTimelineState()
    }

    func loadMirrorTimeline() {
        mirrorTimelineState = .loading
        do {
            mirrorCheckins = try mirrorMetadataStore.loadEntries()
            syncMirrorTimelineState()
        } catch {
            mirrorCheckins = []
            mirrorTimelineState = .error(message: "Couldn’t load your timeline.")
        }
    }

    func setMirrorTimelineAuthorization(status: PHAuthorizationStatus) {
        switch status {
        case .authorized, .limited:
            syncMirrorTimelineState()
        case .denied, .restricted:
            mirrorTimelineState = .permissionBlocked
        case .notDetermined:
            mirrorTimelineState = .loading
        @unknown default:
            mirrorTimelineState = .error(message: "Photo permission state is unavailable.")
        }
    }

    func removeMirrorCheckin(entryID: UUID) {
        mirrorCheckins.removeAll { $0.id == entryID }
        persistMirrorCheckins()
        syncMirrorTimelineState()
    }

    private func applyMirrorCheckinScoring(tags: [String], note: String) {
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

    private func persistMirrorCheckins() {
        do {
            try mirrorMetadataStore.saveEntries(mirrorCheckins)
        } catch {
            mirrorTimelineState = .error(message: "Couldn’t save your timeline.")
        }
    }

    private func syncMirrorTimelineState() {
        if case .permissionBlocked = mirrorTimelineState {
            return
        }
        mirrorTimelineState = mirrorCheckins.isEmpty ? .empty : .ready
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

    // MARK: - Subscores

    var subscores: [SubscoreEntry] {
        guard let score = glowScore else { return [] }

        let categories: [(id: String, label: String, icon: String, goal: GlowGoal, offset: Int, insight: String)] = [
            ("skin", "Skin", "sparkles", .skinGlow, 3,
             "Hydration and sleep are your biggest levers here."),
            ("face", "Face", "face.smiling", .faceDefinition, -2,
             "Facial exercises and mewing consistency matter."),
            ("body", "Body", "figure.stand", .bodySilhouette, -5,
             "Movement habits are building your silhouette."),
            ("hair", "Hair & Style", "comb", .hairStyle, 1,
             "Routine consistency keeps your style on point."),
            ("energy", "Energy", "bolt.fill", .energyFitness, 4,
             "Sleep quality is your secret energy weapon."),
            ("confidence", "Confidence", "star.fill", .confidenceConsistency, -1,
             "Showing up daily is the real confidence hack."),
        ]

        return categories.map { cat in
            let raw = score + cat.offset
            let clamped = max(0, min(100, raw))
            return SubscoreEntry(
                id: cat.id,
                label: cat.label,
                icon: cat.icon,
                value: clamped,
                maxValue: 100,
                accentColor: cat.goal.accentColor,
                insight: cat.insight
            )
        }
    }

    // MARK: - Weekly Stats

    var thisWeekCheckinCount: Int {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return mirrorCheckins.filter { $0.createdAt >= weekStart }.count
    }

    var thisWeekMoodTags: [String: Int] {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        let weekCheckins = mirrorCheckins.filter { $0.createdAt >= weekStart }
        var freq: [String: Int] = [:]
        for entry in weekCheckins {
            for tag in entry.tags {
                freq[tag, default: 0] += 1
            }
        }
        return freq
    }
}
