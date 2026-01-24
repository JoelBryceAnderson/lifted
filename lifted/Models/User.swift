import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    var displayName: String?
    let createdAt: Date
    var preferences: UserPreferences
    var onboardingCompleted: Bool

    init(
        id: String,
        email: String,
        displayName: String? = nil,
        createdAt: Date = Date(),
        preferences: UserPreferences = UserPreferences(),
        onboardingCompleted: Bool = false
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
        self.preferences = preferences
        self.onboardingCompleted = onboardingCompleted
    }
}

struct UserPreferences: Codable {
    var units: WeightUnit
    var defaultRestSeconds: Int
    var showWarmupSets: Bool
    var hapticFeedbackEnabled: Bool
    var autoStartRestTimer: Bool

    init(
        units: WeightUnit = .lbs,
        defaultRestSeconds: Int = 90,
        showWarmupSets: Bool = true,
        hapticFeedbackEnabled: Bool = true,
        autoStartRestTimer: Bool = true
    ) {
        self.units = units
        self.defaultRestSeconds = defaultRestSeconds
        self.showWarmupSets = showWarmupSets
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.autoStartRestTimer = autoStartRestTimer
    }
}

enum WeightUnit: String, Codable, CaseIterable {
    case lbs
    case kg

    var displayName: String {
        switch self {
        case .lbs: return "Pounds (lbs)"
        case .kg: return "Kilograms (kg)"
        }
    }

    var shortName: String {
        rawValue
    }

    func convert(_ value: Double, to targetUnit: WeightUnit) -> Double {
        if self == targetUnit { return value }

        switch (self, targetUnit) {
        case (.lbs, .kg): return value * 0.453592
        case (.kg, .lbs): return value * 2.20462
        default: return value
        }
    }
}

struct PersonalRecord: Codable, Identifiable {
    let id: String
    let userId: String
    let exerciseId: String
    let weight: Double
    let reps: Int
    let date: Date
    let sessionId: String

    init(
        id: String = UUID().uuidString,
        userId: String,
        exerciseId: String,
        weight: Double,
        reps: Int,
        date: Date = Date(),
        sessionId: String
    ) {
        self.id = id
        self.userId = userId
        self.exerciseId = exerciseId
        self.weight = weight
        self.reps = reps
        self.date = date
        self.sessionId = sessionId
    }

    var estimatedOneRepMax: Double {
        weight * (1 + Double(reps) / 30)
    }
}

struct WarmupSet: Codable {
    let percentage: Double
    let reps: Int
    let weight: Double

    init(percentage: Double, reps: Int, workingWeight: Double) {
        self.percentage = percentage
        self.reps = reps
        self.weight = (workingWeight * percentage).rounded(toNearest: 2.5)
    }

    static func generateWarmupSets(forWorkingWeight workingWeight: Double, barWeight: Double = 45) -> [WarmupSet] {
        var warmupSets: [WarmupSet] = []

        if workingWeight > barWeight {
            warmupSets.append(WarmupSet(percentage: 0, reps: 10, workingWeight: barWeight))
        }

        if workingWeight > barWeight * 2 {
            warmupSets.append(WarmupSet(percentage: 0.5, reps: 8, workingWeight: workingWeight))
        }

        if workingWeight > barWeight * 2.5 {
            warmupSets.append(WarmupSet(percentage: 0.7, reps: 5, workingWeight: workingWeight))
        }

        if workingWeight > barWeight * 3 {
            warmupSets.append(WarmupSet(percentage: 0.85, reps: 3, workingWeight: workingWeight))
        }

        return warmupSets
    }
}
