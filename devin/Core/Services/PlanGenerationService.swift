import Foundation
import UIKit

final class PlanGenerationService {
    private let gemini = GeminiService()

    /// Builds prompt from user profile + goal + optional photo, calls Gemini, parses the response.
    func generatePlan(
        profile: UserProfile,
        goal: GlowGoal,
        photo: UIImage?
    ) async throws -> GeneratedPlan {
        print("[PlanGeneration] Starting plan generation for \(profile.name), goal: \(goal.displayName)")

        let prompt = buildPrompt(profile: profile, goal: goal)
        let imageData = photo.flatMap { compressImage($0) }

        let rawJSON = try await gemini.generate(prompt: prompt, imageData: imageData)
        print("[PlanGeneration] Raw JSON response (\(rawJSON.count) chars): \(rawJSON.prefix(300))...")

        let plan = try parsePlan(from: rawJSON, goal: goal)
        print("[PlanGeneration] ✅ Parsed plan: \(plan.dailyPlans.count) days, score: \(plan.initialGlowScore), subscores: \(plan.subscores.count)")
        return plan
    }

    // MARK: - Prompt Construction

    private func buildPrompt(profile: UserProfile, goal: GlowGoal) -> String {
        let startDate = Date.now
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Build 7 day labels for the prompt
        var dayLabels: [String] = []
        for i in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: startDate)!
            let formatted = dateFormatter.string(from: date)
            let weekday = date.formatted(.dateTime.weekday(.wide))
            dayLabels.append("Day \(i + 1) (\(weekday), \(formatted))")
        }

        var lines: [String] = [
            "You are devine, a personal glow-up coach for girls aged 14–28.",
            "Be warm, encouraging, and use casual but empowering language. Never give medical advice.",
            "",
            "USER PROFILE:",
            "- Name: \(profile.name)",
            "- Age: \(profile.age)",
            "- Main goal: \(goal.displayName)",
        ]

        if let h = profile.heightDisplay { lines.append("- Height: \(h)") }
        if let w = profile.weightDisplay { lines.append("- Weight: \(w)") }

        lines += [
            "",
            "TASK:",
            "Generate a personalized 7-day glow-up plan starting from today.",
            "The plan dates are: \(dayLabels.joined(separator: ", ")).",
            "",
            "Requirements:",
            "- Each day must have a unique theme (e.g. 'Hydration Reset', 'Glow Prep Day')",
            "- Each day must have exactly 3 unique, specific, actionable tasks",
            "- Actions should be achievable in 2–15 minutes each",
            "- Actions should progress and build on each other across the week",
            "- Day 1 should be easier/introductory, Day 7 should feel like a payoff",
            "- Directly related to the goal: \(goal.displayName)",
            "- Encouraging, not medical or clinical",
            "",
            "Also provide:",
            "- An initial glow score estimate (0–100) based on the user's profile and goal",
            "- Category subscores for: skin, face, body, hair, energy, confidence (each 0–100)",
            "- Each subscore should have a brief personalized insight",
            "",
            "IMPORTANT: Return ONLY valid JSON. No markdown, no backticks, no explanation.",
            "JSON schema:",
            "{",
            "  \"dailyPlans\": [",
            "    {",
            "      \"dayNumber\": 1,",
            "      \"theme\": \"Hydration & Fresh Start\",",
            "      \"actions\": [",
            "        {\"title\": \"...\", \"instructions\": \"...\", \"estimatedMinutes\": 5},",
            "        {\"title\": \"...\", \"instructions\": \"...\", \"estimatedMinutes\": 10},",
            "        {\"title\": \"...\", \"instructions\": \"...\", \"estimatedMinutes\": 5}",
            "      ]",
            "    }",
            "  ],",
            "  \"summary\": \"A warm 2–3 sentence personal message addressing \(profile.name) directly.\",",
            "  \"rationale\": \"One sentence explaining why these actions suit this profile and goal.\",",
            "  \"initialGlowScore\": 62,",
            "  \"subscores\": [",
            "    {\"id\": \"skin\", \"label\": \"Skin\", \"value\": 65, \"insight\": \"...\"},",
            "    {\"id\": \"face\", \"label\": \"Face\", \"value\": 58, \"insight\": \"...\"},",
            "    {\"id\": \"body\", \"label\": \"Body\", \"value\": 60, \"insight\": \"...\"},",
            "    {\"id\": \"hair\", \"label\": \"Hair & Style\", \"value\": 70, \"insight\": \"...\"},",
            "    {\"id\": \"energy\", \"label\": \"Energy\", \"value\": 55, \"insight\": \"...\"},",
            "    {\"id\": \"confidence\", \"label\": \"Confidence\", \"value\": 50, \"insight\": \"...\"}",
            "  ]",
            "}",
            "",
            "Return all 7 days with 3 actions each. Make each day's actions different.",
        ]

        return lines.joined(separator: "\n")
    }

    // MARK: - Response Parsing

    private func parsePlan(from rawJSON: String, goal: GlowGoal) throws -> GeneratedPlan {
        // Strip any markdown code fences if Gemini adds them despite instructions
        let cleaned = rawJSON
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw GeminiError.decodingError("Could not convert response to data")
        }

        do {
            let response = try JSONDecoder().decode(GeminiPlanResponse.self, from: data)
            let startDate = Date.now

            let dailyPlans: [DailyPlan] = response.dailyPlans.map { day in
                let date = Calendar.current.date(byAdding: .day, value: day.dayNumber - 1, to: startDate)!
                let actions = day.actions.map { item in
                    PerfectActionCodable(
                        title: item.title,
                        instructions: item.instructions,
                        estimatedMinutes: item.estimatedMinutes
                    )
                }
                return DailyPlan(
                    dayNumber: day.dayNumber,
                    date: date,
                    theme: day.theme,
                    actions: Array(actions.prefix(3))
                )
            }

            guard !dailyPlans.isEmpty else {
                throw GeminiError.decodingError("No daily plans in response")
            }

            let subscores = response.subscores.map { s in
                AISubscore(id: s.id, label: s.label, value: max(0, min(100, s.value)), insight: s.insight)
            }

            let score = max(0, min(100, response.initialGlowScore))

            return GeneratedPlan(
                goalRawValue: goal.rawValue,
                dailyPlans: dailyPlans,
                summary: response.summary,
                rationale: response.rationale,
                initialGlowScore: score,
                subscores: subscores
            )
        } catch let decodingError as DecodingError {
            print("[PlanGeneration] ❌ JSON decode error: \(decodingError)")
            print("[PlanGeneration] Cleaned JSON was: \(cleaned.prefix(500))")
            throw GeminiError.decodingError(decodingError.localizedDescription)
        }
    }

    // MARK: - Image Compression

    private func compressImage(_ image: UIImage) -> Data? {
        let maxDimension: CGFloat = 512
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.7)
    }
}
