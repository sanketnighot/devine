import SwiftUI
import Combine
import Photos

final class DevineAppModel: ObservableObject {
    // MARK: - Published State

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
    @Published private(set) var aiSubscores: [AISubscore] = []
    @Published private(set) var checkinEvaluationState: CheckinEvaluationState = .idle

    // User Identity
    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var generatedPlan: GeneratedPlan?

    // Navigation & Coach Nudge
    @Published var selectedTab: Int = 0
    @Published var coachNudge: CoachNudge?

    // Social
    @Published var glowCircle: GlowCircle?

    // Plan History
    @Published private(set) var planAdjustmentHistory: [PlanAdjustmentRecord] = []

    // MARK: - Private

    private var currentDayKey = DevineAppModel.dayKey(for: .now)
    private var streakCreditedDayKey: String?
    private var completedActionsByDay: [String: [UUID]] = [:]
    private let mirrorMetadataStore = MirrorCheckinMetadataStore()
    private let stateStore = DevineStateStore()

    /// Whether the user can perform a post-task mirror check-in (all daily actions completed).
    var canDoMirrorCheckin: Bool {
        !todayActions.isEmpty && completedActionIDs.count == todayActions.count
    }

    /// Whether a mirror check-in has already been recorded today.
    var hasCheckedInToday: Bool {
        let cal = Calendar.current
        return mirrorCheckins.contains { cal.isDateInToday($0.createdAt) }
    }

    /// Stats snapshot used by the AI chat coach.
    var chatStats: ChatStats {
        ChatStats(
            glowScore: glowScore,
            streakDays: streakDays,
            goal: primaryGoal,
            completedToday: completedActionIDs.count,
            totalToday: todayActions.count,
            currentPlanDay: generatedPlan?.todayPlan?.dayNumber ?? 1,
            customGoalName: userProfile?.customGoalName
        )
    }

    /// Public read-only access for PlanView to check per-day completion.
    var completedActionsByDayPublic: [String: [UUID]] { completedActionsByDay }

    /// Public day key helper for views to look up completion data.
    static func dayKey(for date: Date) -> String {
        date.formatted(.iso8601.year().month().day())
    }

    // MARK: - Init

    init() {
        loadPersistedState()
        loadMirrorTimeline()
    }

    // MARK: - Public Setters (called from Onboarding)

    func setUserProfile(_ profile: UserProfile) {
        userProfile = profile
        persistState()
    }

    func setGeneratedPlan(_ plan: GeneratedPlan) {
        generatedPlan = plan

        // Set AI-generated scores
        glowScore = plan.initialGlowScore
        aiSubscores = plan.subscores
        confidence = 0.55  // Initial confidence from AI estimation
        goalTrajectory = trajectory(for: plan.initialGlowScore, confidence: confidence)
        lastUpdatedAt = plan.generatedAt

        // Load today's actions from the day-based plan
        loadTodayActionsFromPlan()
        persistState()
    }

    // MARK: - Configure (called after onboarding completion)

    func configure(goal: GlowGoal, hasInitialEvidence: Bool) {
        primaryGoal = goal

        // If we have a generated plan, preserve its AI scores — don't wipe them
        if let plan = generatedPlan, plan.goalRawValue == goal.rawValue {
            loadTodayActionsFromPlan()
            // Keep AI scores (glowScore, aiSubscores, confidence, goalTrajectory)
        } else {
            todayActions = PerfectAction.defaults(for: goal)
            glowScore = nil
            confidence = 0
            aiSubscores = []
            goalTrajectory = nil
        }

        completedActionIDs.removeAll()
        completedActionsByDay.removeAll()
        latestAdjustmentSeverity = .minorTweak
        lastUpdatedAt = .now
        mirrorCheckins.removeAll()
        persistMirrorCheckins()
        syncMirrorTimelineState()
        persistState()

        if hasInitialEvidence {
            recordMirrorCheckin(tags: ["onboarding_photo"], note: "Initial private check-in")
        }
    }

    // MARK: - Reset / Delete All Data

    func resetAllData() {
        // 1. Delete persisted files
        stateStore.deleteFile()
        mirrorMetadataStore.deleteFile()

        // 2. Remove all known UserDefaults keys
        let keys = [
            "has_completed_onboarding",
            "has_active_subscription",
            "paywall_dismissed_once",
            "debug_unlock_all",
            "setting_daily_reminder",
            "setting_streak_alerts",
            "setting_weekly_recap",
            "last_recap_week",
        ]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        // 3. Reset all @Published properties to init defaults
        primaryGoal = .faceDefinition
        todayActions = PerfectAction.defaults(for: .faceDefinition)
        completedActionIDs = []
        streakDays = 0
        glowScore = nil
        confidence = 0
        evidenceLedger = []
        goalTrajectory = nil
        lastUpdatedAt = .now
        latestAdjustmentSeverity = .minorTweak
        mirrorCheckins = []
        mirrorTimelineState = .idle
        aiSubscores = []
        userProfile = nil
        generatedPlan = nil
        glowCircle = nil
        planAdjustmentHistory = []
        checkinEvaluationState = .idle
        selectedTab = 0
        coachNudge = nil

        // 4. Reset private state
        currentDayKey = DevineAppModel.dayKey(for: .now)
        streakCreditedDayKey = nil
        completedActionsByDay = [:]
    }

    // MARK: - Daily Rollover

    func rollOverIfNeeded() {
        let newKey = DevineAppModel.dayKey(for: .now)
        guard newKey != currentDayKey else { return }

        // Detect streak break: new day started but yesterday's actions weren't completed
        if streakCreditedDayKey != currentDayKey && streakDays > 1 {
            let brokenStreak = streakDays
            streakDays = 0
            coachNudge = CoachNudge(
                type: .streakBroken,
                headline: "Your \(brokenStreak)-day streak ended",
                subtitle: "Let's figure out what got in the way and restart",
                seedMessage: "I just lost my \(brokenStreak)-day glow streak. I want to understand what got in the way and build a realistic restart plan. What usually causes streaks to break, and what's the fastest way to rebuild momentum?"
            )
        }

        currentDayKey = newKey
        completedActionIDs.removeAll()
        loadTodayActionsFromPlan()
        latestAdjustmentSeverity = .resequence
        persistState()
    }

    // MARK: - Today's Plan Info

    /// Returns the current day's DailyPlan (if a generated plan exists).
    var todayDailyPlan: DailyPlan? {
        generatedPlan?.dailyPlan(for: .now) ?? generatedPlan?.dailyPlans.first
    }

    // MARK: - Actions

    func isActionDone(_ action: PerfectAction) -> Bool {
        completedActionIDs.contains(action.id)
    }

    var nextPendingAction: PerfectAction? {
        todayActions.first { !completedActionIDs.contains($0.id) }
    }

    func markActionDone(_ action: PerfectAction) {
        rollOverIfNeeded()
        completedActionIDs.insert(action.id)
        completedActionsByDay[currentDayKey] = Array(completedActionIDs)
        evaluatePlanAdjustment()

        if completedActionIDs.count == todayActions.count, streakCreditedDayKey != currentDayKey {
            streakDays += 1
            streakCreditedDayKey = currentDayKey
            lastUpdatedAt = .now
        }
        persistState()
    }

    // MARK: - Mirror Checkins

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
        rollOverIfNeeded()

        // Save timeline entry immediately (synchronous, user-visible right away)
        if let assetLocalIdentifier, let source {
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

        // Start async AI evaluation
        checkinEvaluationState = .loading
        let capturedTags = assetLocalIdentifier != nil ? tags + ["photo_evidence"] : tags
        let capturedNote = note
        let capturedIdentifier = assetLocalIdentifier

        Task { @MainActor in
            do {
                // Load photo if available
                var photo: UIImage? = nil
                if let identifier = capturedIdentifier {
                    photo = await withCheckedContinuation { continuation in
                        var hasResumed = false
                        MirrorPhotoLibraryService.shared.requestImage(
                            localIdentifier: identifier,
                            targetSize: CGSize(width: 512, height: 512),
                            contentMode: .aspectFit
                        ) { image in
                            guard !hasResumed else { return }
                            hasResumed = true
                            continuation.resume(returning: image)
                        }
                    }
                }

                let recentSummaries = evidenceLedger.prefix(5).map { $0.summary }

                let evaluation = try await PlanGenerationService().evaluateCheckin(
                    currentPlan: generatedPlan,
                    userProfile: userProfile,
                    primaryGoal: primaryGoal,
                    currentGlowScore: glowScore,
                    currentSubscores: aiSubscores,
                    completedActionsByDay: completedActionsByDay,
                    todayActions: todayActions,
                    completedActionIDs: completedActionIDs,
                    streakDays: streakDays,
                    checkinTags: capturedTags,
                    checkinNote: capturedNote,
                    recentEvidenceSummary: Array(recentSummaries),
                    photo: photo
                )

                checkinEvaluationState = .ready(evaluation)
            } catch {
                print("[DevineAppModel] AI check-in eval failed: \(error.localizedDescription). Falling back to hardcoded scoring.")
                applyMirrorCheckinScoring(tags: capturedTags, note: capturedNote)
                checkinEvaluationState = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: - Check-in Evaluation Accept / Dismiss

    /// Accept AI evaluation: apply scores + subscores + optional plan update.
    func acceptCheckinEvaluation() {
        guard case .ready(let evaluation) = checkinEvaluationState else { return }

        let previousScore = glowScore
        glowScore = evaluation.updatedGlowScore
        aiSubscores = evaluation.updatedSubscores
        confidence = min(0.92, max(0.36, 0.45 + Double(evidenceLedger.count) * 0.07))
        goalTrajectory = trajectory(for: evaluation.updatedGlowScore, confidence: confidence)
        latestAdjustmentSeverity = evaluation.adjustmentSeverity
        lastUpdatedAt = .now

        // Record evidence event
        let used = evaluation.updatedSubscores.map { $0.label }
        evidenceLedger.insert(
            EvidenceEvent(
                createdAt: .now,
                summary: evaluation.feedback,
                evidenceUsed: used,
                evidenceMissing: [],
                scoreAtTime: evaluation.updatedGlowScore
            ),
            at: 0
        )

        // Apply plan update if present
        if let planUpdate = evaluation.suggestedPlanUpdate, var plan = generatedPlan {
            let mergedDays = mergeUpdatedDays(existing: plan.dailyPlans, updated: planUpdate.updatedDailyPlans)
            plan = GeneratedPlan(
                id: plan.id,
                generatedAt: plan.generatedAt,
                goalRawValue: plan.goalRawValue,
                dailyPlans: mergedDays,
                summary: plan.summary,
                rationale: plan.rationale,
                initialGlowScore: plan.initialGlowScore,
                subscores: evaluation.updatedSubscores
            )
            generatedPlan = plan
            loadTodayActionsFromPlan()

            planAdjustmentHistory.append(PlanAdjustmentRecord(
                createdAt: .now,
                severity: evaluation.adjustmentSeverity,
                reason: planUpdate.reason,
                associatedEvidence: used
            ))
        }

        // Set coach nudge based on score change
        coachNudge = buildCheckinNudge(
            newScore: evaluation.updatedGlowScore,
            previousScore: previousScore,
            feedback: evaluation.feedback
        )

        checkinEvaluationState = .idle
        persistState()
    }

    /// Dismiss AI evaluation: apply scores only, keep current plan.
    func dismissCheckinEvaluation() {
        guard case .ready(let evaluation) = checkinEvaluationState else { return }

        let previousScore = glowScore
        glowScore = evaluation.updatedGlowScore
        aiSubscores = evaluation.updatedSubscores
        confidence = min(0.92, max(0.36, 0.45 + Double(evidenceLedger.count) * 0.07))
        goalTrajectory = trajectory(for: evaluation.updatedGlowScore, confidence: confidence)
        lastUpdatedAt = .now

        // Record evidence event (score only, no plan change)
        evidenceLedger.insert(
            EvidenceEvent(
                createdAt: .now,
                summary: evaluation.feedback,
                evidenceUsed: evaluation.updatedSubscores.map { $0.label },
                evidenceMissing: [],
                scoreAtTime: evaluation.updatedGlowScore
            ),
            at: 0
        )

        // Set coach nudge based on score change
        coachNudge = buildCheckinNudge(
            newScore: evaluation.updatedGlowScore,
            previousScore: previousScore,
            feedback: evaluation.feedback
        )

        checkinEvaluationState = .idle
        persistState()
    }

    // MARK: - Coach Nudge

    func dismissCoachNudge() {
        coachNudge = nil
    }

    // MARK: - Chat Plan Adjustment

    /// Calls Gemini to regenerate future plan days and merges them into the current plan.
    func applyCoachPlanAdjustment(reason: String, suggestedFocus: String, severity: PlanAdjustmentSeverity) async throws {
        let updatedDays = try await PlanGenerationService().adjustPlanFromCoach(
            currentPlan: generatedPlan,
            userProfile: userProfile,
            primaryGoal: primaryGoal,
            reason: reason,
            suggestedFocus: suggestedFocus,
            severity: severity
        )

        guard var plan = generatedPlan else { return }
        let mergedDays = mergeUpdatedDays(existing: plan.dailyPlans, updated: updatedDays)
        plan = GeneratedPlan(
            id: plan.id,
            generatedAt: plan.generatedAt,
            goalRawValue: plan.goalRawValue,
            dailyPlans: mergedDays,
            summary: plan.summary,
            rationale: plan.rationale,
            initialGlowScore: plan.initialGlowScore,
            subscores: plan.subscores
        )
        generatedPlan = plan
        latestAdjustmentSeverity = severity
        planAdjustmentHistory.append(PlanAdjustmentRecord(
            createdAt: .now,
            severity: severity,
            reason: "\(reason). Focus: \(suggestedFocus)",
            associatedEvidence: ["chat_coach"]
        ))
        loadTodayActionsFromPlan()
        persistState()
    }

    /// Legacy synchronous record — kept for internal use only.
    func recordChatPlanAdjustment(reason: String, suggestedFocus: String, severity: PlanAdjustmentSeverity) {
        latestAdjustmentSeverity = severity
        planAdjustmentHistory.append(PlanAdjustmentRecord(
            createdAt: .now,
            severity: severity,
            reason: "\(reason). Focus: \(suggestedFocus)",
            associatedEvidence: ["chat_coach"]
        ))
        persistState()
    }

    func loadMirrorTimeline() {
        mirrorTimelineState = .loading
        do {
            mirrorCheckins = try mirrorMetadataStore.loadEntries()
            syncMirrorTimelineState()
        } catch {
            mirrorCheckins = []
            mirrorTimelineState = .error(message: "Couldn't load your timeline.")
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

    // MARK: - Social

    func createCircle(name: String) {
        let mockMembers: [CircleMember] = [
            CircleMember(displayName: "Mia K.", avatarColor: .rose, streakDays: 7),
            CircleMember(displayName: "Zara T.", avatarColor: .peach, streakDays: 3),
        ]
        var circle = GlowCircle(name: name, members: mockMembers)
        let challenge = GlowChallenge(
            title: "7-Day Glow Challenge",
            description: "Complete your daily actions for 7 days straight — as a team.",
            durationDays: 7,
            startDate: Calendar.current.date(byAdding: .day, value: -2, to: .now)!,
            memberProgress: Dictionary(uniqueKeysWithValues: mockMembers.map { ($0.id, Int.random(in: 1...3)) })
        )
        circle.activeChallenge = challenge
        glowCircle = circle
    }

    func joinCircle(inviteCode: String) {
        guard !inviteCode.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let mockMembers: [CircleMember] = [
            CircleMember(displayName: "Luna R.", avatarColor: .plum, streakDays: 12),
            CircleMember(displayName: "Kai S.", avatarColor: .sage, streakDays: 5),
            CircleMember(displayName: "Nova B.", avatarColor: .sky, streakDays: 9),
        ]
        var circle = GlowCircle(name: "Glow Squad", members: mockMembers)
        let challenge = GlowChallenge(
            title: "7-Day Glow Challenge",
            description: "Complete your daily actions for 7 days straight — as a team.",
            durationDays: 7,
            startDate: Calendar.current.date(byAdding: .day, value: -3, to: .now)!,
            memberProgress: Dictionary(uniqueKeysWithValues: mockMembers.map { ($0.id, Int.random(in: 2...5)) })
        )
        circle.activeChallenge = challenge
        glowCircle = circle
    }

    func blockMember(id: UUID) {
        glowCircle?.members.removeAll { $0.id == id }
    }

    // MARK: - Subscores (uses AI data when available, fallback to computed)

    var subscores: [SubscoreEntry] {
        // Use AI-generated subscores if available
        if !aiSubscores.isEmpty {
            return aiSubscores.map { sub in
                SubscoreEntry(
                    id: sub.id,
                    label: sub.label,
                    icon: sub.icon,
                    value: sub.value,
                    maxValue: 100,
                    accentColor: accentColorForSubscore(sub.id),
                    insight: sub.insight
                )
            }
        }

        // Fallback: derive from glowScore if no AI subscores
        guard let score = glowScore else { return [] }
        let categories: [(id: String, label: String, icon: String, goal: GlowGoal, offset: Int, insight: String)] = [
            ("skin", "Skin", "sparkles", .skinGlow, 3, "Hydration and sleep are your biggest levers here."),
            ("face", "Face", "face.smiling", .faceDefinition, -2, "Facial exercises and mewing consistency matter."),
            ("body", "Body", "figure.stand", .bodySilhouette, -5, "Movement habits are building your silhouette."),
            ("hair", "Hair & Style", "comb", .hairStyle, 1, "Routine consistency keeps your style on point."),
            ("energy", "Energy", "bolt.fill", .energyFitness, 4, "Sleep quality is your secret energy weapon."),
            ("confidence", "Confidence", "star.fill", .confidenceConsistency, -1, "Showing up daily is the real confidence hack."),
        ]
        return categories.map { cat in
            let clamped = max(0, min(100, score + cat.offset))
            return SubscoreEntry(id: cat.id, label: cat.label, icon: cat.icon,
                                 value: clamped, maxValue: 100,
                                 accentColor: cat.goal.accentColor, insight: cat.insight)
        }
    }

    private func accentColorForSubscore(_ id: String) -> SwiftUI.Color {
        switch id {
        case "skin": return GlowGoal.skinGlow.accentColor
        case "face": return GlowGoal.faceDefinition.accentColor
        case "body": return GlowGoal.bodySilhouette.accentColor
        case "hair": return GlowGoal.hairStyle.accentColor
        case "energy": return GlowGoal.energyFitness.accentColor
        case "confidence": return GlowGoal.confidenceConsistency.accentColor
        default: return DevineTheme.Colors.ctaPrimary
        }
    }

    // MARK: - Weekly Stats

    var thisWeekCheckinCount: Int {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return mirrorCheckins.filter { $0.createdAt >= weekStart }.count
    }

    var thisWeekMoodTags: [String: Int] {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        var freq: [String: Int] = [:]
        for entry in mirrorCheckins.filter({ $0.createdAt >= weekStart }) {
            for tag in entry.tags { freq[tag, default: 0] += 1 }
        }
        return freq
    }

    // MARK: - Private Helpers

    private func loadTodayActionsFromPlan() {
        if let plan = generatedPlan, plan.goalRawValue == primaryGoal.rawValue,
           let dailyPlan = plan.dailyPlan(for: .now) ?? plan.dailyPlans.first {
            todayActions = dailyPlan.actions.map { $0.toPerfectAction() }
        } else {
            todayActions = PerfectAction.defaults(for: primaryGoal)
        }
        completedActionIDs = Set(completedActionsByDay[currentDayKey] ?? [])
    }

    private func buildCheckinNudge(newScore: Int, previousScore: Int?, feedback: String) -> CoachNudge {
        let delta = newScore - (previousScore ?? newScore)
        if delta <= -3 {
            return CoachNudge(
                type: .scoreDrop,
                headline: "Your score dipped — let's recover",
                subtitle: "Coach has a targeted plan to get you back up",
                seedMessage: "My glow score just dropped to \(newScore) after my check-in (was \(previousScore ?? newScore)). The AI noted: \"\(feedback)\". What specifically might have caused this drop and what's the fastest, most targeted way to recover?"
            )
        } else if delta >= 5 {
            return CoachNudge(
                type: .scoreRise,
                headline: "Your glow score went up! \(newScore) ✦",
                subtitle: "Coach can help you lock in this momentum",
                seedMessage: "My glow score just jumped to \(newScore) after my check-in! The AI said: \"\(feedback)\". What specifically is working that I should double down on? And what's the #1 thing to keep this momentum going?"
            )
        } else {
            return CoachNudge(
                type: .postCheckin,
                headline: "Coach reviewed your check-in",
                subtitle: "Get personalized next steps based on your data",
                seedMessage: "I just completed my mirror check-in. My glow score is \(newScore). Here's what was noted: \"\(feedback)\". Based on this, what should I prioritize for the next few days to make the most progress?"
            )
        }
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
        let missing = tags.isEmpty ? ["Apple Health trends", "sleep consistency"] : ["sleep consistency", "7-day check-in history"]
        let summary = note.isEmpty ? "Mirror check-in recorded. Plan tuned for today." : note
        evidenceLedger.insert(EvidenceEvent(createdAt: .now, summary: summary, evidenceUsed: used, evidenceMissing: missing, scoreAtTime: nextScore), at: 0)
        persistState()
    }

    private func persistMirrorCheckins() {
        do {
            try mirrorMetadataStore.saveEntries(mirrorCheckins)
        } catch {
            mirrorTimelineState = .error(message: "Couldn't save your timeline.")
        }
    }

    private func syncMirrorTimelineState() {
        if case .permissionBlocked = mirrorTimelineState { return }
        mirrorTimelineState = mirrorCheckins.isEmpty ? .empty : .ready
    }

    /// Merge plan days: keep days <= today from existing, replace future days with updated ones.
    private func mergeUpdatedDays(existing: [DailyPlan], updated: [DailyPlan]) -> [DailyPlan] {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: .now)
        let pastAndToday = existing.filter { cal.startOfDay(for: $0.date) <= todayStart }
        return pastAndToday + updated
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

    // MARK: - Persistence

    private func persistState() {
        let snapshot = DevinePersistedState(
            userProfile: userProfile,
            primaryGoalRawValue: primaryGoal.rawValue,
            streakDays: streakDays,
            glowScore: glowScore,
            confidence: confidence,
            evidenceLedger: evidenceLedger,
            planAdjustmentHistory: planAdjustmentHistory,
            generatedPlan: generatedPlan,
            completedActionsByDay: completedActionsByDay,
            streakCreditedDayKey: streakCreditedDayKey
        )
        try? stateStore.save(snapshot)
    }

    private func loadPersistedState() {
        guard let state = try? stateStore.load() else { return }

        userProfile = state.userProfile
        generatedPlan = state.generatedPlan
        primaryGoal = GlowGoal(rawValue: state.primaryGoalRawValue) ?? .faceDefinition
        streakDays = state.streakDays
        glowScore = state.glowScore
        confidence = state.confidence
        evidenceLedger = state.evidenceLedger
        planAdjustmentHistory = state.planAdjustmentHistory
        completedActionsByDay = state.completedActionsByDay
        streakCreditedDayKey = state.streakCreditedDayKey

        // Restore AI subscores from plan
        if let plan = generatedPlan {
            aiSubscores = plan.subscores
        }

        // Restore today's completed actions
        completedActionIDs = Set(completedActionsByDay[currentDayKey] ?? [])

        // Set today's actions from the correct day's plan
        loadTodayActionsFromPlan()

        if glowScore != nil {
            goalTrajectory = trajectory(for: glowScore!, confidence: confidence)
        }
    }
}
