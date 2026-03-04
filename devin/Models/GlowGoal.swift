import Foundation

enum GlowGoal: String, CaseIterable, Identifiable {
    case faceDefinition = "face_definition"
    case skinGlow = "skin_glow"
    case bodySilhouette = "body_silhouette"
    case hairStyle = "hair_style"
    case energyFitness = "energy_fitness"
    case confidenceConsistency = "confidence_consistency"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .faceDefinition:
            return "Face definition"
        case .skinGlow:
            return "Skin glow"
        case .bodySilhouette:
            return "Body silhouette"
        case .hairStyle:
            return "Hair + style"
        case .energyFitness:
            return "Energy + fitness"
        case .confidenceConsistency:
            return "Confidence + consistency"
        case .custom:
            return "Something else"
        }
    }
}
