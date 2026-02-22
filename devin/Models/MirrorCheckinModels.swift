import Foundation

enum MirrorPhotoSource: String, Codable, CaseIterable {
    case camera = "camera"
    case photosLibrary = "photos_library"
}

struct MirrorCheckinEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    let tags: [String]
    let note: String
    let assetLocalIdentifier: String
    let source: MirrorPhotoSource

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        tags: [String],
        note: String,
        assetLocalIdentifier: String,
        source: MirrorPhotoSource
    ) {
        self.id = id
        self.createdAt = createdAt
        self.tags = tags
        self.note = note
        self.assetLocalIdentifier = assetLocalIdentifier
        self.source = source
    }
}

enum MirrorTimelineState: Equatable {
    case idle
    case loading
    case ready
    case empty
    case permissionBlocked
    case error(message: String)
}
