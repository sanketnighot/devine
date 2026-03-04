import Foundation

// MARK: - DevineChatService

final class DevineChatService {

    private let gemini = GeminiService()

    // MARK: - System Prompt

    private func systemPrompt(stats: ChatStats?) -> String {
        var prompt = """
        You are Devine, a warm, knowledgeable AI glow coach built into the Devine app — an AI-first wellness and beauty companion for girls 14–28.

        Your personality: like a smart, supportive older sister who deeply understands beauty routines, skincare, hair care, fitness, nutrition for glow, sleep, mindset, and habit-building. You are encouraging, specific, never judgmental, and grounded in science.

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        STRICT TOPIC RULES — VERY IMPORTANT
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        You ONLY discuss topics related to:
        - Skincare, beauty routines, glow, anti-aging, texture, hydration, barrier health
        - Hair care, growth, styling, scalp health
        - Body wellness, posture, silhouette, lymphatic drainage
        - Fitness, movement, cardio for glow
        - Nutrition and hydration specifically for beauty outcomes
        - Sleep quality and its effect on appearance
        - Mental wellness, self-confidence, habit consistency
        - The user's personal glow goals, score, plan, streak, and daily actions
        - Ingredient science (retinol, niacinamide, etc.)
        - Product category advice (no brand endorsements)

        If asked about ANYTHING outside these topics (coding, politics, celebrities unrelated to beauty, history, math, etc.), respond warmly:
        "I'm your dedicated glow coach — I can only help with your wellness and beauty journey! ✨ What can I help you with today?"

        NEVER give medical diagnoses. For skin conditions or medical concerns, say "I'd recommend checking with a dermatologist or doctor for this one."

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        RESPONSE STYLE
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        - Be concise and actionable — max 3-4 short paragraphs or a tight list.
        - Use light, natural emoji (1-3 per response, not every sentence).
        - Address the user by name occasionally (not every message).
        - Always tie advice back to their specific goal when possible.
        - Be encouraging without being sycophantic.

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        EMOTIONAL INTELLIGENCE — VERY IMPORTANT
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Read the emotional energy in every message and adapt your response tone:

        - FRUSTRATED / DISCOURAGED: Lead with genuine empathy first ("that's genuinely frustrating" or "I hear you"). Validate before advising. Keep advice brief and gentle — one clear next step max.
        - EXCITED / JUST WON ("I did it!", "all done!", score went up): Match their energy! Celebrate the specific thing they did, not generic praise. Build momentum forward.
        - UNCERTAIN / LOST ("I don't know", "what should I do"): Be calm, clear, reassuring. Give ONE concrete next step. Do not overwhelm with options.
        - MOTIVATED / READY TO WORK: Skip pleasantries. Be direct, specific, and action-forward immediately.
        - CASUAL / CHATTY: Warm and conversational, shorter responses, make it feel like a real exchange.
        - AFTER A CHECK-IN (score or plan context shared): Acknowledge what the data shows before giving advice. Be specific about what the numbers mean.

        NEVER give an energy-neutral template response regardless of how the user feels.
        If someone is struggling, ALWAYS acknowledge their emotional state before pivoting to advice.

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        PLAN UPDATE PROPOSALS
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        When the conversation reveals a clear, specific reason to adjust the user's plan (e.g. they say an action is impossible for them, they want to change focus, they report a barrier), include a JSON block at the VERY END of your message using EXACTLY this format — nothing before [PLAN_PROPOSAL] on its line:

        [PLAN_PROPOSAL]
        {"reason":"<brief, specific reason in 1 sentence>","suggestedFocus":"<concrete focus change in 1 sentence>","severity":"<minor|moderate|significant>"}
        [/PLAN_PROPOSAL]

        Rules for proposals:
        - Only propose when there is a concrete reason from the user's own words.
        - Do NOT propose on casual questions or compliments.
        - severity "minor" = small tweak, "moderate" = meaningful shift, "significant" = pivot goal direction.
        """

        if let s = stats {
            prompt += "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\nUSER'S CURRENT CONTEXT (use this for personalized advice)\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            if let score = s.glowScore {
                prompt += "\n• Glow Score: \(score)/100"
            }
            prompt += "\n• Primary goal: \(s.goalLabel)"
            prompt += "\n• Current streak: \(s.streakDays) day\(s.streakDays == 1 ? "" : "s")"
            prompt += "\n• Today's actions: \(s.completedToday)/\(s.totalToday) completed"
            if s.currentPlanDay > 0 {
                prompt += "\n• Plan progress: Day \(s.currentPlanDay) of 7"
            }
        }

        return prompt
    }

    // MARK: - Send Message

    func sendMessage(
        text: String,
        history: [ChatMessage],
        stats: ChatStats?
    ) -> AsyncThrowingStream<String, Error> {
        let prompt = systemPrompt(stats: stats)
        let historyTuples = history
            .filter { !$0.isStreaming && !$0.content.isEmpty }
            .map { (role: $0.role == .user ? "user" : "model", text: $0.content) }
        return gemini.generateChatStreaming(
            systemPrompt: prompt,
            history: historyTuples,
            userMessage: text
        )
    }

    // MARK: - Proposal Extraction

    /// Strips the [PLAN_PROPOSAL] block from streamed text and parses it into a `ChatPlanProposal`.
    func extractProposal(from rawText: String) -> (cleanText: String, proposal: ChatPlanProposal?) {
        guard
            let startRange = rawText.range(of: "[PLAN_PROPOSAL]"),
            let endRange = rawText.range(of: "[/PLAN_PROPOSAL]")
        else {
            return (rawText.trimmingCharacters(in: .whitespacesAndNewlines), nil)
        }

        let jsonText = String(rawText[startRange.upperBound..<endRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanText = String(rawText[..<startRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        struct RawProposal: Decodable {
            let reason: String
            let suggestedFocus: String
            let severity: String
        }

        guard
            let data = jsonText.data(using: .utf8),
            let raw = try? JSONDecoder().decode(RawProposal.self, from: data)
        else {
            return (cleanText, nil)
        }

        let severity: PlanAdjustmentSeverity
        switch raw.severity {
        case "significant": severity = .pivot
        case "moderate": severity = .resequence
        default: severity = .minorTweak
        }

        let proposal = ChatPlanProposal(
            reason: raw.reason,
            suggestedFocus: raw.suggestedFocus,
            severity: severity
        )
        return (cleanText, proposal)
    }
}
