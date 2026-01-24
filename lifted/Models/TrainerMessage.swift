import Foundation

struct TrainerChat: Codable, Identifiable {
    let id: String
    let userId: String
    var messages: [TrainerMessage]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        messages: [TrainerMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct TrainerMessage: Codable, Identifiable {
    let id: String
    let sessionId: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    var proposedActions: [ProposedAction]?

    init(
        id: String = UUID().uuidString,
        sessionId: String,
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        proposedActions: [ProposedAction]? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.proposedActions = proposedActions
    }

    var hasProposedActions: Bool {
        guard let actions = proposedActions else { return false }
        return !actions.isEmpty
    }

    var pendingActions: [ProposedAction] {
        proposedActions?.filter { $0.status == .pending } ?? []
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant

    var displayName: String {
        switch self {
        case .user: return "You"
        case .assistant: return "Trainer"
        }
    }
}

struct ProposedAction: Codable, Identifiable {
    let id: String
    let actionType: ActionType
    let description: String
    let changePayload: String
    var status: ActionStatus

    init(
        id: String = UUID().uuidString,
        actionType: ActionType,
        description: String,
        changePayload: String,
        status: ActionStatus = .pending
    ) {
        self.id = id
        self.actionType = actionType
        self.description = description
        self.changePayload = changePayload
        self.status = status
    }
}

enum ActionType: String, Codable, CaseIterable {
    case scheduleModification
    case exerciseSwap
    case progressionAdjustment
    case deloadTrigger
    case restDayInsertion

    var displayName: String {
        switch self {
        case .scheduleModification: return "Schedule Change"
        case .exerciseSwap: return "Exercise Swap"
        case .progressionAdjustment: return "Progression Adjustment"
        case .deloadTrigger: return "Deload"
        case .restDayInsertion: return "Rest Day"
        }
    }

    var description: String {
        switch self {
        case .scheduleModification: return "Modify your workout schedule"
        case .exerciseSwap: return "Replace an exercise with an alternative"
        case .progressionAdjustment: return "Adjust your weight progression targets"
        case .deloadTrigger: return "Take a recovery week with reduced weights"
        case .restDayInsertion: return "Add an extra rest day for recovery"
        }
    }

    var iconName: String {
        switch self {
        case .scheduleModification: return "calendar.badge.clock"
        case .exerciseSwap: return "arrow.triangle.2.circlepath"
        case .progressionAdjustment: return "chart.line.uptrend.xyaxis"
        case .deloadTrigger: return "arrow.down.circle"
        case .restDayInsertion: return "bed.double.fill"
        }
    }
}

enum ActionStatus: String, Codable {
    case pending
    case approved
    case rejected

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
}

struct AIContextType {
    static let formTips = "formTips"
    static let variations = "variations"
    static let progress = "progress"
    static let chat = "chat"
    static let scheduleOptimize = "scheduleOptimize"
}
