import Foundation

struct TrainerNote: Codable, Identifiable {
    let id: String
    let userId: String
    let content: String
    let category: NoteCategory
    let createdAt: Date
    var isActive: Bool

    init(
        id: String = UUID().uuidString,
        userId: String,
        content: String,
        category: NoteCategory,
        createdAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.userId = userId
        self.content = content
        self.category = category
        self.createdAt = createdAt
        self.isActive = isActive
    }
}

enum NoteCategory: String, Codable, CaseIterable {
    case injury
    case limitation
    case preference
    case goal
    case medical

    var displayName: String {
        switch self {
        case .injury: return "Injury"
        case .limitation: return "Limitation"
        case .preference: return "Preference"
        case .goal: return "Goal"
        case .medical: return "Medical"
        }
    }

    var description: String {
        switch self {
        case .injury: return "Current or past injuries to be aware of"
        case .limitation: return "Equipment, mobility, or time limitations"
        case .preference: return "Exercise likes, dislikes, or preferences"
        case .goal: return "Specific fitness targets or milestones"
        case .medical: return "Medical conditions affecting training"
        }
    }

    var iconName: String {
        switch self {
        case .injury: return "bandage.fill"
        case .limitation: return "exclamationmark.triangle.fill"
        case .preference: return "heart.fill"
        case .goal: return "target"
        case .medical: return "cross.case.fill"
        }
    }

    var color: String {
        switch self {
        case .injury: return "red"
        case .limitation: return "orange"
        case .preference: return "blue"
        case .goal: return "green"
        case .medical: return "purple"
        }
    }
}
