import Foundation

struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let muscleGroups: [MuscleGroup]
    let equipment: Equipment
    let category: ExerciseCategory
    let defaultRestSeconds: Int
    let instructions: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        muscleGroups: [MuscleGroup],
        equipment: Equipment,
        category: ExerciseCategory,
        defaultRestSeconds: Int? = nil,
        instructions: String? = nil
    ) {
        self.id = id
        self.name = name
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.category = category
        self.defaultRestSeconds = defaultRestSeconds ?? (category == .compound ? 150 : 75)
        self.instructions = instructions
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }
}

enum MuscleGroup: String, Codable, CaseIterable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case quads
    case hamstrings
    case glutes
    case calves
    case core
    case forearms
    case traps

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .quads: return "Quadriceps"
        case .hamstrings: return "Hamstrings"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        case .core: return "Core"
        case .forearms: return "Forearms"
        case .traps: return "Traps"
        }
    }
}

enum Equipment: String, Codable, CaseIterable {
    case barbell
    case dumbbell
    case cable
    case machine
    case bodyweight
    case kettlebell
    case bands
    case none

    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .cable: return "Cable"
        case .machine: return "Machine"
        case .bodyweight: return "Bodyweight"
        case .kettlebell: return "Kettlebell"
        case .bands: return "Resistance Bands"
        case .none: return "No Equipment"
        }
    }
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case compound
    case isolation

    var displayName: String {
        switch self {
        case .compound: return "Compound"
        case .isolation: return "Isolation"
        }
    }

    var description: String {
        switch self {
        case .compound: return "Multi-joint movements that work multiple muscle groups"
        case .isolation: return "Single-joint movements that target one muscle group"
        }
    }
}

enum WorkoutType: String, Codable, CaseIterable {
    case push
    case pull
    case legs
    case pushPull
    case upper
    case lower
    case fullBody
    case cardio
    case rest

    var displayName: String {
        switch self {
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return "Legs"
        case .pushPull: return "Push/Pull"
        case .upper: return "Upper Body"
        case .lower: return "Lower Body"
        case .fullBody: return "Full Body"
        case .cardio: return "Cardio"
        case .rest: return "Rest Day"
        }
    }

    var description: String {
        switch self {
        case .push: return "Chest, shoulders, and triceps"
        case .pull: return "Back and biceps"
        case .legs: return "Quads, hamstrings, glutes, and calves"
        case .pushPull: return "Upper body push and pull combined"
        case .upper: return "All upper body muscle groups"
        case .lower: return "All lower body muscle groups"
        case .fullBody: return "All major muscle groups"
        case .cardio: return "Cardiovascular training"
        case .rest: return "Recovery day"
        }
    }

    var iconName: String {
        switch self {
        case .push: return "arrow.up.circle.fill"
        case .pull: return "arrow.down.circle.fill"
        case .legs: return "figure.walk"
        case .pushPull: return "arrow.up.arrow.down.circle.fill"
        case .upper: return "figure.arms.open"
        case .lower: return "figure.run"
        case .fullBody: return "figure.strengthtraining.traditional"
        case .cardio: return "heart.fill"
        case .rest: return "bed.double.fill"
        }
    }

    var color: String {
        switch self {
        case .push: return "blue"
        case .pull: return "green"
        case .legs: return "purple"
        case .pushPull: return "teal"
        case .upper: return "orange"
        case .lower: return "pink"
        case .fullBody: return "red"
        case .cardio: return "yellow"
        case .rest: return "gray"
        }
    }

    var primaryMuscleGroups: [MuscleGroup] {
        switch self {
        case .push: return [.chest, .shoulders, .triceps]
        case .pull: return [.back, .biceps, .forearms]
        case .legs: return [.quads, .hamstrings, .glutes, .calves]
        case .pushPull: return [.chest, .shoulders, .triceps, .back, .biceps]
        case .upper: return [.chest, .back, .shoulders, .biceps, .triceps]
        case .lower: return [.quads, .hamstrings, .glutes, .calves]
        case .fullBody: return MuscleGroup.allCases
        case .cardio: return []
        case .rest: return []
        }
    }
}
