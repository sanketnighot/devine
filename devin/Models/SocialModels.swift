import Foundation

// MARK: - Circle

struct GlowCircle: Identifiable {
    let id: UUID
    var name: String
    var inviteCode: String
    var members: [CircleMember]
    let createdAt: Date
    var activeChallenge: GlowChallenge?

    init(
        id: UUID = UUID(),
        name: String,
        members: [CircleMember] = [],
        createdAt: Date = .now,
        activeChallenge: GlowChallenge? = nil
    ) {
        self.id = id
        self.name = name
        self.inviteCode = GlowCircle.generateCode()
        self.members = members
        self.createdAt = createdAt
        self.activeChallenge = activeChallenge
    }

    private static func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

// MARK: - Member

struct CircleMember: Identifiable {
    let id: UUID
    let displayName: String
    let avatarInitials: String
    let avatarColor: CircleMemberColor
    let streakDays: Int
    var isBlocked: Bool

    init(
        id: UUID = UUID(),
        displayName: String,
        avatarColor: CircleMemberColor = .allCases.randomElement()!,
        streakDays: Int = 0,
        isBlocked: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarInitials = String(displayName.prefix(2)).uppercased()
        self.avatarColor = avatarColor
        self.streakDays = streakDays
        self.isBlocked = isBlocked
    }
}

enum CircleMemberColor: String, CaseIterable {
    case rose, peach, plum, sage, sky
}

// MARK: - Challenge

struct GlowChallenge: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let durationDays: Int
    let startDate: Date
    var memberProgress: [UUID: Int]

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        durationDays: Int = 7,
        startDate: Date = .now,
        memberProgress: [UUID: Int] = [:]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.durationDays = durationDays
        self.startDate = startDate
        self.memberProgress = memberProgress
    }

    var isActive: Bool {
        let end = Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
        return Date.now < end
    }

    var overallProgress: Double {
        guard !memberProgress.isEmpty else { return 0 }
        let totalPossible = durationDays * memberProgress.count
        let totalDone = memberProgress.values.reduce(0, +)
        return Double(totalDone) / Double(max(1, totalPossible))
    }
}

// MARK: - Report

enum CircleReportReason: String, CaseIterable, Identifiable {
    case inappropriate = "Inappropriate content"
    case harassment = "Harassment or bullying"
    case spam = "Spam"
    case other = "Other"

    var id: String { rawValue }
}
