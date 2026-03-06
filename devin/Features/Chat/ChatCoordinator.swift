import Foundation
import Combine

@MainActor
final class ChatCoordinator: ObservableObject {

    @Published var threads: [ChatThread] = []
    /// Set when a CoachNudge fires. `ChatThreadListView` observes this to auto-push.
    @Published var pendingNavigationThreadID: UUID?

    private let store = ChatThreadStore()

    init() {
        loadThreads()
    }

    // MARK: - Thread Management

    @discardableResult
    func createThread() -> ChatThread {
        let thread = ChatThread(title: "New chat")
        threads.insert(thread, at: 0)
        saveThreads()
        return thread
    }

    /// Creates a thread pre-seeded with the coach's welcome and the nudge seed message.
    /// Called by MainTabsView when a CoachNudge fires.
    @discardableResult
    func createNudgeThread(seedMessage: String, name: String, goalLabel: String) -> ChatThread {
        let welcome = PersistedChatMessage(
            id: UUID(),
            role: .assistant,
            content: "hey \(name)! ✦ Your coach has something important to share about your \(goalLabel.lowercased()) journey.",
            timestamp: .now,
            attachedStats: false,
            planProposal: nil
        )
        let seed = PersistedChatMessage(
            id: UUID(),
            role: .user,
            content: seedMessage,
            timestamp: Date(timeIntervalSinceNow: 0.001),
            attachedStats: true,
            planProposal: nil
        )
        let title = ChatThread.autoTitle(from: seedMessage)
        let thread = ChatThread(
            title: title,
            messages: [welcome, seed]
        )
        threads.insert(thread, at: 0)
        saveThreads()
        return thread
    }

    func deleteThread(_ id: UUID) {
        threads.removeAll { $0.id == id }
        saveThreads()
    }

    func renameThread(_ id: UUID, title: String) {
        guard let idx = threads.firstIndex(where: { $0.id == id }) else { return }
        threads[idx].title = title
        threads[idx].updatedAt = .now
        saveThreads()
    }

    func pinThread(_ id: UUID, pinned: Bool) {
        guard let idx = threads.firstIndex(where: { $0.id == id }) else { return }
        threads[idx].isPinned = pinned
        sortThreads()
        saveThreads()
    }

    // MARK: - Message Persistence

    /// Persists finalized messages for a thread. Called by `ChatViewModel.finalize()`.
    /// Skips in-flight streaming messages and empty content.
    /// Auto-titles the thread from the first user message if still "New chat".
    func saveMessages(_ messages: [ChatMessage], for threadID: UUID) {
        guard let idx = threads.firstIndex(where: { $0.id == threadID }) else { return }
        let persisted = messages.compactMap { PersistedChatMessage.from($0) }
        threads[idx].messages = persisted
        threads[idx].updatedAt = .now

        // Auto-title from first user message
        if threads[idx].title == "New chat",
           let firstUser = persisted.first(where: { $0.role == .user }) {
            threads[idx].title = ChatThread.autoTitle(from: firstUser.content)
        }

        sortThreads()
        saveThreads()
    }

    /// Marks a plan proposal as applied within a persisted thread. Called after `applyProposal`.
    func markProposalApplied(threadID: UUID, messageID: UUID) {
        guard let tIdx = threads.firstIndex(where: { $0.id == threadID }),
              let mIdx = threads[tIdx].messages.firstIndex(where: { $0.id == messageID }) else { return }
        threads[tIdx].messages[mIdx].planProposal?.isApplied = true
        saveThreads()
    }

    // MARK: - Load Messages

    /// Returns the thread's messages converted to runtime `ChatMessage` values.
    func loadMessages(for threadID: UUID) -> [ChatMessage] {
        guard let thread = threads.first(where: { $0.id == threadID }) else { return [] }
        return thread.messages.map { $0.toChatMessage() }
    }

    // MARK: - Reset

    func clearAll() {
        threads = []
        pendingNavigationThreadID = nil
        store.deleteFile()
    }

    // MARK: - Private

    private func loadThreads() {
        threads = (try? store.load()) ?? []
        sortThreads()
    }

    private func saveThreads() {
        try? store.save(threads)
    }

    private func sortThreads() {
        // Pinned threads float to top, then sort by updatedAt descending.
        threads.sort {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.updatedAt > $1.updatedAt
        }
    }
}
