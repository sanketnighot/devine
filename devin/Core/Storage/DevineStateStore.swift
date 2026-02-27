import Foundation

// MARK: - Persisted State Snapshot

struct DevinePersistedState: Codable {
    var userProfile: UserProfile?
    var primaryGoalRawValue: String
    var streakDays: Int
    var glowScore: Int?
    var confidence: Double
    var evidenceLedger: [EvidenceEvent]
    var planAdjustmentHistory: [PlanAdjustmentRecord]
    var generatedPlan: GeneratedPlan?
    /// ISO8601 day key (e.g. "2026-02-27") → array of completed action UUIDs
    var completedActionsByDay: [String: [UUID]]
    var streakCreditedDayKey: String?

    static var `default`: DevinePersistedState {
        DevinePersistedState(
            userProfile: nil,
            primaryGoalRawValue: GlowGoal.faceDefinition.rawValue,
            streakDays: 0,
            glowScore: nil,
            confidence: 0,
            evidenceLedger: [],
            planAdjustmentHistory: [],
            generatedPlan: nil,
            completedActionsByDay: [:],
            streakCreditedDayKey: nil
        )
    }
}

// MARK: - Store

final class DevineStateStore {
    private let fileManager = FileManager.default
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

    func save(_ state: DevinePersistedState) throws {
        let url = try stateFileURL()
        let data = try encoder.encode(state)
        try data.write(to: url, options: .atomicWrite)
    }

    func load() throws -> DevinePersistedState {
        let url = try stateFileURL()
        guard fileManager.fileExists(atPath: url.path) else {
            return .default
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(DevinePersistedState.self, from: data)
    }

    // MARK: - Private

    private func stateFileURL() throws -> URL {
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
        return dir.appendingPathComponent("app_state_v1.json")
    }
}
