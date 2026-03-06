import Foundation

// MARK: - ChatThread

/// A persisted conversation thread between the user and the AI coach.
struct ChatThread: Codable, Identifiable {
    let id: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
    var messages: [PersistedChatMessage]
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        messages: [PersistedChatMessage] = [],
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
        self.isPinned = isPinned
    }

    /// Last non-streaming message content, trimmed to 80 chars.
    var lastMessagePreview: String {
        guard let last = messages.last else { return "No messages yet" }
        let raw = last.content.replacingOccurrences(of: "\n", with: " ")
        return raw.count > 80 ? String(raw.prefix(80)) + "…" : raw
    }

    var lastMessageRole: ChatRole? { messages.last?.role }

    /// Auto-generates a title from the first user message (max 40 chars).
    static func autoTitle(from firstUserMessage: String) -> String {
        let cleaned = firstUserMessage
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "New chat" }
        return cleaned.count > 40 ? String(cleaned.prefix(40)) + "…" : cleaned
    }
}

// MARK: - PersistedChatMessage

/// Codable mirror of `ChatMessage`. `isStreaming` is not persisted — always false on load.
struct PersistedChatMessage: Codable, Identifiable {
    let id: UUID
    let role: ChatRole
    let content: String
    let timestamp: Date
    let attachedStats: Bool
    var planProposal: PersistedChatPlanProposal?

    func toChatMessage() -> ChatMessage {
        ChatMessage(
            id: id,
            role: role,
            content: content,
            timestamp: timestamp,
            planProposal: planProposal?.toChatPlanProposal(),
            attachedStats: attachedStats,
            isStreaming: false
        )
    }

    /// Returns nil for in-flight streaming messages — they must not be persisted.
    static func from(_ msg: ChatMessage) -> PersistedChatMessage? {
        guard !msg.isStreaming else { return nil }
        guard !msg.content.isEmpty else { return nil }
        return PersistedChatMessage(
            id: msg.id,
            role: msg.role,
            content: msg.content,
            timestamp: msg.timestamp,
            attachedStats: msg.attachedStats,
            planProposal: msg.planProposal.map { PersistedChatPlanProposal.from($0) }
        )
    }
}

// MARK: - PersistedChatPlanProposal

/// Codable mirror of `ChatPlanProposal`.
struct PersistedChatPlanProposal: Codable {
    let id: UUID
    let reason: String
    let suggestedFocus: String
    let severity: PlanAdjustmentSeverity
    var isApplied: Bool

    func toChatPlanProposal() -> ChatPlanProposal {
        ChatPlanProposal(
            id: id,
            reason: reason,
            suggestedFocus: suggestedFocus,
            severity: severity,
            isApplied: isApplied
        )
    }

    static func from(_ p: ChatPlanProposal) -> PersistedChatPlanProposal {
        PersistedChatPlanProposal(
            id: p.id,
            reason: p.reason,
            suggestedFocus: p.suggestedFocus,
            severity: p.severity,
            isApplied: p.isApplied
        )
    }
}
