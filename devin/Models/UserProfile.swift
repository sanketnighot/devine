import Foundation

struct UserProfile: Codable {
    var name: String
    var dateOfBirth: Date
    var heightCm: Double?
    var weightKg: Double?
    var prefersCentimetres: Bool = true
    var prefersKilograms: Bool = true

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    var zodiacSign: ZodiacSign {
        ZodiacSign.from(date: dateOfBirth)
    }

    // Display helpers
    var heightDisplay: String? {
        guard let h = heightCm else { return nil }
        if prefersCentimetres {
            return "\(Int(h)) cm"
        } else {
            let totalInches = h / 2.54
            let feet = Int(totalInches) / 12
            let inches = Int(totalInches) % 12
            return "\(feet)'\(inches)\""
        }
    }

    var weightDisplay: String? {
        guard let w = weightKg else { return nil }
        if prefersKilograms {
            return "\(Int(w)) kg"
        } else {
            return "\(Int(w * 2.20462)) lbs"
        }
    }
}

// MARK: - ZodiacSign

enum ZodiacSign: String, Codable, CaseIterable {
    case aries, taurus, gemini, cancer, leo, virgo
    case libra, scorpio, sagittarius, capricorn, aquarius, pisces

    var emoji: String {
        switch self {
        case .aries:       return "♈️"
        case .taurus:      return "♉️"
        case .gemini:      return "♊️"
        case .cancer:      return "♋️"
        case .leo:         return "♌️"
        case .virgo:       return "♍️"
        case .libra:       return "♎️"
        case .scorpio:     return "♏️"
        case .sagittarius: return "♐️"
        case .capricorn:   return "♑️"
        case .aquarius:    return "♒️"
        case .pisces:      return "♓️"
        }
    }

    var displayName: String { rawValue.capitalized }

    var personalityTeaser: String {
        switch self {
        case .aries:       return "bold, driven, and always first 🔥"
        case .taurus:      return "grounded, patient, and glowing steady 🌿"
        case .gemini:      return "quick, adaptable, and endlessly interesting ✨"
        case .cancer:      return "intuitive, nurturing, and deeply feeling 🌙"
        case .leo:         return "radiant, confident, and born to shine 👑"
        case .virgo:       return "precise, dedicated, and quietly powerful 💫"
        case .libra:       return "balanced, charming, and effortlessly magnetic ⚖️"
        case .scorpio:     return "intense, transformative, and magnetic 🖤"
        case .sagittarius: return "free-spirited, adventurous, and unstoppable 🏹"
        case .capricorn:   return "ambitious, disciplined, and quietly iconic 🏔️"
        case .aquarius:    return "original, visionary, and beautifully weird 💙"
        case .pisces:      return "dreamy, empathetic, and creatively gifted 🌊"
        }
    }

    // Uses local calendar month+day to avoid UTC timezone edge cases on cusps
    static func from(date: Date) -> ZodiacSign {
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let day   = cal.component(.day, from: date)

        switch (month, day) {
        case (3, 21...31), (4, 1...19): return .aries
        case (4, 20...30), (5, 1...20): return .taurus
        case (5, 21...31), (6, 1...20): return .gemini
        case (6, 21...30), (7, 1...22): return .cancer
        case (7, 23...31), (8, 1...22): return .leo
        case (8, 23...31), (9, 1...22): return .virgo
        case (9, 23...30), (10, 1...22): return .libra
        case (10, 23...31), (11, 1...21): return .scorpio
        case (11, 22...30), (12, 1...21): return .sagittarius
        case (12, 22...31), (1, 1...19): return .capricorn
        case (1, 20...31), (2, 1...18): return .aquarius
        default: return .pisces  // Feb 19 – Mar 20
        }
    }
}
