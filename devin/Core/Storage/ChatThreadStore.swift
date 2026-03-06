import Foundation

final class ChatThreadStore {
    private let fileManager = FileManager.default
    private let maxThreads = 20

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func save(_ threads: [ChatThread]) throws {
        // Keep all pinned + most-recent unpinned up to maxThreads
        let pinned = threads.filter { $0.isPinned }
        let unpinned = threads.filter { !$0.isPinned }
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(max(0, maxThreads - pinned.count))
        let pruned = (pinned + unpinned).sorted { $0.updatedAt > $1.updatedAt }

        let url = try fileURL()
        let data = try encoder.encode(pruned)
        try data.write(to: url, options: .atomicWrite)
    }

    func load() throws -> [ChatThread] {
        let url = try fileURL()
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try decoder.decode([ChatThread].self, from: data)
    }

    func deleteFile() {
        guard let url = try? fileURL(),
              fileManager.fileExists(atPath: url.path) else { return }
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Private

    private func fileURL() throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = appSupport.appendingPathComponent("devine", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("chat_threads_v1.json")
    }
}
