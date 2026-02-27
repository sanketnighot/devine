import Foundation

final class MirrorCheckinMetadataStore {
    private struct Payload: Codable {
        var entries: [MirrorCheckinEntry]
    }

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadEntries() throws -> [MirrorCheckinEntry] {
        let url = try metadataFileURL()
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        let payload = try decoder.decode(Payload.self, from: data)
        return payload.entries.sorted { $0.createdAt > $1.createdAt }
    }

    func saveEntries(_ entries: [MirrorCheckinEntry]) throws {
        let url = try metadataFileURL()
        let payload = Payload(entries: entries.sorted { $0.createdAt > $1.createdAt })
        let data = try encoder.encode(payload)
        try data.write(to: url, options: .atomic)
    }

    func deleteFile() {
        guard let url = try? metadataFileURL(),
              fileManager.fileExists(atPath: url.path) else { return }
        try? fileManager.removeItem(at: url)
    }

    private func metadataFileURL() throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = appSupport.appendingPathComponent("MirrorCheckins", isDirectory: true)

        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        return folder.appendingPathComponent("mirror_checkins_v1.json")
    }
}
