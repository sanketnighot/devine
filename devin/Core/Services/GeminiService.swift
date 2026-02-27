import Foundation
import UIKit

// MARK: - Errors

enum GeminiError: LocalizedError {
    case notConfigured
    case networkError(Error)
    case httpError(Int)
    case emptyResponse
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return GeminiConfig.missingKeyMessage
        case .networkError(let e):
            return "Network error: \(e.localizedDescription)"
        case .httpError(let code):
            return "HTTP error \(code) from Gemini API."
        case .emptyResponse:
            return "No content in Gemini response."
        case .decodingError(let msg):
            return "Failed to decode response: \(msg)"
        }
    }
}

// MARK: - Request / Response Models

private struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GenerationConfig?

    struct GenerationConfig: Encodable {
        let responseMimeType: String?
        let temperature: Double?
    }
}

private struct GeminiContent: Encodable {
    let parts: [GeminiPart]
}

private enum GeminiPart: Encodable {
    case text(String)
    case inlineData(mimeType: String, base64: String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let t):
            try container.encode(t, forKey: .text)
        case .inlineData(let mime, let b64):
            var nested = container.nestedContainer(keyedBy: InlineKeys.self, forKey: .inlineData)
            try nested.encode(mime, forKey: .mimeType)
            try nested.encode(b64, forKey: .data)
        }
    }

    enum CodingKeys: String, CodingKey { case text, inlineData }
    enum InlineKeys: String, CodingKey { case mimeType, data }
}

private struct GeminiResponse: Decodable {
    let candidates: [Candidate]?

    struct Candidate: Decodable {
        let content: Content?
        struct Content: Decodable {
            let parts: [Part]?
            struct Part: Decodable { let text: String? }
        }
    }

    var firstText: String? {
        candidates?.first?.content?.parts?.first?.text
    }
}

// MARK: - GeminiService

final class GeminiService {

    private let session = URLSession.shared
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .useDefaultKeys
        return e
    }()

    // MARK: - Non-streaming generate

    /// Sends a text (+ optional image) request and returns the full response string.
    func generate(prompt: String, imageData: Data? = nil) async throws -> String {
        guard GeminiConfig.isConfigured else {
            print("[GeminiService] ❌ API key not configured")
            throw GeminiError.notConfigured
        }

        print("[GeminiService] ✅ API key found, preparing request...")

        var parts: [GeminiPart] = [.text(prompt)]
        if let data = imageData {
            let b64 = data.base64EncodedString()
            parts.insert(.inlineData(mimeType: "image/jpeg", base64: b64), at: 0)
            print("[GeminiService] 📸 Including image data (\(data.count) bytes)")
        }

        let body = GeminiRequest(
            contents: [GeminiContent(parts: parts)],
            generationConfig: GeminiRequest.GenerationConfig(
                responseMimeType: "application/json",
                temperature: 0.7
            )
        )

        let url = URL(string: "\(GeminiConfig.baseURL)/models/\(GeminiConfig.model):generateContent?key=\(GeminiConfig.apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        request.timeoutInterval = 60  // generous timeout for complex generation

        print("[GeminiService] 🌐 Calling Gemini API (\(GeminiConfig.model))...")

        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse {
            print("[GeminiService] HTTP \(http.statusCode)")
            if !(200..<300).contains(http.statusCode) {
                if let errorBody = String(data: data, encoding: .utf8) {
                    print("[GeminiService] ❌ Error body: \(errorBody.prefix(500))")
                }
                throw GeminiError.httpError(http.statusCode)
            }
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.firstText else {
            print("[GeminiService] ❌ Empty response from Gemini")
            if let raw = String(data: data, encoding: .utf8) {
                print("[GeminiService] Raw response: \(raw.prefix(500))")
            }
            throw GeminiError.emptyResponse
        }

        print("[GeminiService] ✅ Got response (\(text.count) chars)")
        return text
    }

    // MARK: - Streaming generate (text only)

    /// Streams text chunks via SSE. Yields delta text strings as they arrive.
    func generateStreaming(prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard GeminiConfig.isConfigured else {
                continuation.finish(throwing: GeminiError.notConfigured)
                return
            }

            Task {
                do {
                    let parts: [GeminiPart] = [.text(prompt)]
                    let body = GeminiRequest(
                        contents: [GeminiContent(parts: parts)],
                        generationConfig: GeminiRequest.GenerationConfig(
                            responseMimeType: nil,
                            temperature: 0.8
                        )
                    )

                    let url = URL(string: "\(GeminiConfig.baseURL)/models/\(GeminiConfig.model):streamGenerateContent?key=\(GeminiConfig.apiKey)&alt=sse")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try self.encoder.encode(body)

                    let (bytes, response) = try await self.session.bytes(for: request)

                    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        continuation.finish(throwing: GeminiError.httpError(http.statusCode))
                        return
                    }

                    // Parse SSE: each chunk is a "data: {...}" line
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))
                        guard jsonString != "[DONE]",
                              let jsonData = jsonString.data(using: .utf8),
                              let chunk = try? JSONDecoder().decode(GeminiResponse.self, from: jsonData),
                              let text = chunk.firstText
                        else { continue }
                        continuation.yield(text)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
