import Foundation

/// Gemini API configuration.
///
/// The API key is resolved in order:
/// 1. Xcode scheme environment variable `GEMINI_API_KEY` (for local dev)
/// 2. Compile-time fallback constant (works on-device without Xcode)
///
/// To rotate the key, update either source.
enum GeminiConfig {
    // MARK: - Compile-time fallback key
    // This ensures the key works when the app is launched outside of Xcode
    // (e.g. directly from the device home screen).
    private static let fallbackAPIKey = "AIzaSyD0ICBULAbI5ST1BUjgbFhI_LPRKS-w_Gs"

    static var apiKey: String {
        let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
        let key = envKey.isEmpty ? fallbackAPIKey : envKey
        return key
    }

    /// Model used for plan generation (vision-capable, fast)
    static let model = "gemini-2.0-flash"

    static let baseURL = "https://generativelanguage.googleapis.com/v1beta"

    static var isConfigured: Bool { !apiKey.isEmpty }
}
