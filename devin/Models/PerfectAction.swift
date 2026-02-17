import Foundation

struct PerfectAction: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let instructions: String
    let estimatedMinutes: Int

    static func defaults(for goal: GlowGoal) -> [PerfectAction] {
        switch goal {
        case .faceDefinition:
            return [
                PerfectAction(
                    title: "AM hydration reset",
                    instructions: "Drink one full glass of water within ten minutes of waking.",
                    estimatedMinutes: 2
                ),
                PerfectAction(
                    title: "Posture stack",
                    instructions: "Two rounds of shoulder, neck, and jawline posture reset.",
                    estimatedMinutes: 4
                ),
                PerfectAction(
                    title: "Sleep anchor",
                    instructions: "Set a fixed lights-out time and keep it tonight.",
                    estimatedMinutes: 3
                )
            ]

        case .skinGlow:
            return [
                PerfectAction(title: "Hydration check", instructions: "Water + mineral-rich snack in the morning.", estimatedMinutes: 3),
                PerfectAction(title: "Barrier-safe cleanse", instructions: "Gentle cleanse and moisturizer routine.", estimatedMinutes: 5),
                PerfectAction(title: "Consistency reminder", instructions: "Set evening skincare reminder before 9 PM.", estimatedMinutes: 2)
            ]

        case .bodySilhouette:
            return [
                PerfectAction(title: "10-minute walk", instructions: "Take a brisk walk after your first meal.", estimatedMinutes: 10),
                PerfectAction(title: "Core posture set", instructions: "Complete one posture-friendly core routine.", estimatedMinutes: 6),
                PerfectAction(title: "Evening reset", instructions: "Light stretch before sleep.", estimatedMinutes: 4)
            ]

        case .hairStyle:
            return [
                PerfectAction(title: "Scalp care minute", instructions: "One minute of scalp massage.", estimatedMinutes: 1),
                PerfectAction(title: "Heat-protection step", instructions: "Apply protection before any heat styling.", estimatedMinutes: 2),
                PerfectAction(title: "Style planning", instructions: "Choose tomorrow's hair style tonight.", estimatedMinutes: 3)
            ]

        case .energyFitness:
            return [
                PerfectAction(title: "Morning movement", instructions: "Five minutes of low-friction movement.", estimatedMinutes: 5),
                PerfectAction(title: "Midday reset", instructions: "Two-minute breathing and mobility break.", estimatedMinutes: 2),
                PerfectAction(title: "Sleep prep", instructions: "Set wind-down reminder thirty minutes before bed.", estimatedMinutes: 2)
            ]

        case .confidenceConsistency:
            return [
                PerfectAction(title: "Tiny win list", instructions: "Write one thing you will finish today.", estimatedMinutes: 2),
                PerfectAction(title: "Action sprint", instructions: "Do one focused five-minute sprint.", estimatedMinutes: 5),
                PerfectAction(title: "Night reflection", instructions: "Log one completed promise to yourself.", estimatedMinutes: 2)
            ]
        }
    }
}
