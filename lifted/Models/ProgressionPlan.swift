import Foundation

struct ProgressionPlan: Codable, Identifiable {
    let id: String
    let userId: String
    let goal: FitnessGoal
    let startDate: Date
    let deloadFrequencyWeeks: Int
    var lastDeloadDate: Date?

    init(
        id: String = UUID().uuidString,
        userId: String,
        goal: FitnessGoal,
        startDate: Date = Date(),
        deloadFrequencyWeeks: Int = 5,
        lastDeloadDate: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.goal = goal
        self.startDate = startDate
        self.deloadFrequencyWeeks = deloadFrequencyWeeks
        self.lastDeloadDate = lastDeloadDate
    }

    var weeksSinceStart: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: startDate, to: Date())
        return max(0, components.weekOfYear ?? 0)
    }

    var weeksSinceLastDeload: Int {
        guard let lastDeload = lastDeloadDate else {
            return weeksSinceStart
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: lastDeload, to: Date())
        return max(0, components.weekOfYear ?? 0)
    }

    var needsDeload: Bool {
        weeksSinceLastDeload >= deloadFrequencyWeeks
    }

    var weeksUntilDeload: Int {
        max(0, deloadFrequencyWeeks - weeksSinceLastDeload)
    }
}

enum FitnessGoal: String, Codable, CaseIterable {
    case bulk
    case cut
    case maintain
    case recomp

    var displayName: String {
        switch self {
        case .bulk: return "Bulk"
        case .cut: return "Cut"
        case .maintain: return "Maintain"
        case .recomp: return "Recomp"
        }
    }

    var description: String {
        switch self {
        case .bulk: return "Build muscle with aggressive weight progression. Expect +5 lbs on compounds and +2.5 lbs on isolation exercises weekly."
        case .cut: return "Maintain strength while losing fat. Conservative progression of +2.5 lbs on compounds and +1.25 lbs on isolation exercises weekly."
        case .maintain: return "Keep current strength levels. Increase weight only when RPE drops significantly."
        case .recomp: return "Build muscle while losing fat. Moderate progression of +2.5 lbs on all exercises weekly."
        }
    }

    var shortDescription: String {
        switch self {
        case .bulk: return "Build muscle mass"
        case .cut: return "Lose fat, keep muscle"
        case .maintain: return "Stay where you are"
        case .recomp: return "Build muscle, lose fat"
        }
    }

    var iconName: String {
        switch self {
        case .bulk: return "arrow.up.right.circle.fill"
        case .cut: return "arrow.down.right.circle.fill"
        case .maintain: return "equal.circle.fill"
        case .recomp: return "arrow.triangle.2.circlepath.circle.fill"
        }
    }

    var compoundIncrement: Double {
        switch self {
        case .bulk: return 5.0
        case .cut: return 2.5
        case .maintain: return 0.0
        case .recomp: return 2.5
        }
    }

    var isolationIncrement: Double {
        switch self {
        case .bulk: return 2.5
        case .cut: return 1.25
        case .maintain: return 0.0
        case .recomp: return 2.5
        }
    }

    var progressionMultiplier: Double {
        switch self {
        case .bulk: return 1.0
        case .cut: return 0.5
        case .maintain: return 0.25
        case .recomp: return 0.75
        }
    }
}

struct ExerciseProgression: Codable, Identifiable {
    let id: String
    let userId: String
    let exerciseId: String
    var startingWeight: Double
    var currentTargetWeight: Double
    var weeklyIncrement: Double
    var lastPerformedDate: Date?
    var consecutiveFailures: Int

    init(
        id: String = UUID().uuidString,
        userId: String,
        exerciseId: String,
        startingWeight: Double,
        currentTargetWeight: Double? = nil,
        weeklyIncrement: Double = 2.5,
        lastPerformedDate: Date? = nil,
        consecutiveFailures: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.exerciseId = exerciseId
        self.startingWeight = startingWeight
        self.currentTargetWeight = currentTargetWeight ?? startingWeight
        self.weeklyIncrement = weeklyIncrement
        self.lastPerformedDate = lastPerformedDate
        self.consecutiveFailures = consecutiveFailures
    }

    var needsDeload: Bool {
        consecutiveFailures >= 2
    }

    var deloadWeight: Double {
        (currentTargetWeight * 0.5).rounded(toNearest: 2.5)
    }

    mutating func recordFailure() {
        consecutiveFailures += 1
    }

    mutating func recordSuccess() {
        consecutiveFailures = 0
    }

    mutating func applyDeload() {
        currentTargetWeight = deloadWeight
        consecutiveFailures = 0
    }

    mutating func progressWeight() {
        currentTargetWeight = (currentTargetWeight + weeklyIncrement).rounded(toNearest: 2.5)
        lastPerformedDate = Date()
    }
}

extension Double {
    func rounded(toNearest value: Double) -> Double {
        (self / value).rounded() * value
    }
}
