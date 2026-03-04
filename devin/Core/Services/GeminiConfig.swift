import Foundation

/// Gemini API configuration.
///
/// The API key is resolved from the Xcode scheme environment variable `GEMINI_API_KEY`.
/// Set it in: Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables.
///
/// Never hardcode API keys in source code.
enum GeminiConfig {
    static var apiKey: String {
        // 1. Xcode scheme env var — set in Edit Scheme → Run → Environment Variables.
        //    This takes priority so CI and other devs can inject their own key.
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !key.isEmpty {
            return key
        }
        // 2. Compiled-in fallback — from Secrets.swift (gitignored).
        //    Ensures the app works on device when not launched from Xcode.
        return Secrets.geminiAPIKey
    }

    /// Model used for plan generation (vision-capable, fast)
    static let model = "gemini-2.0-flash"

    static let baseURL = "https://generativelanguage.googleapis.com/v1beta"

    static var isConfigured: Bool { !apiKey.isEmpty }

    static let missingKeyMessage = "Gemini API key not configured. Go to Xcode → Product → Scheme → Edit Scheme → Run → Environment Variables and add GEMINI_API_KEY."
}
