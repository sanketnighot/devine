import Foundation

enum LegalDocument: String, Identifiable {
    case terms
    case privacy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .terms:
            return "Terms of Service"
        case .privacy:
            return "Privacy Policy"
        }
    }

    var urlString: String {
        switch self {
        case .terms:
            return "https://example.com/terms"
        case .privacy:
            return "https://example.com/privacy"
        }
    }
}
