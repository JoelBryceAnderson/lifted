import Foundation
import UIKit

enum AppConstants {
    // MARK: - Rest Timer Defaults
    static let defaultRestSeconds = 90
    static let compoundRestSeconds = 150
    static let isolationRestSeconds = 75

    // MARK: - Progression Defaults
    static let defaultDeloadFrequencyWeeks = 5
    static let defaultCycleDurationDays = 7
    static let minDeloadWeight = 0.5 // 50% of working weight

    // MARK: - Weight Increments
    static let compoundWeightIncrement = 5.0
    static let isolationWeightIncrement = 2.5
    static let weightRoundingFactor = 2.5

    // MARK: - Workout Defaults
    static let defaultWorkingSets = 3
    static let defaultReps = 10
    static let barWeight = 45.0

    // MARK: - UI Constants
    static let maxNotesLength = 500
    static let maxExerciseSearchResults = 50
    static let weekCalendarDays = 7

    // MARK: - RPE Scale
    static let rpeMin = 1
    static let rpeMax = 10
    static let rpeDescriptions: [Int: String] = [
        1: "Very Light",
        2: "Light",
        3: "Light-Moderate",
        4: "Moderate",
        5: "Moderate-Challenging",
        6: "Challenging",
        7: "Hard",
        8: "Very Hard",
        9: "Near Max",
        10: "Maximum Effort"
    ]

    // MARK: - Animation Durations
    static let quickAnimation = 0.2
    static let standardAnimation = 0.3
    static let slowAnimation = 0.5

    // MARK: - Cache Durations
    static let exerciseCacheDuration: TimeInterval = 3600 // 1 hour
    static let sessionCacheDuration: TimeInterval = 300 // 5 minutes
}

enum WorkoutDefaults {
    static func defaultExercises(for workoutType: WorkoutType) -> [String] {
        switch workoutType {
        case .push:
            return ["bench-press", "incline-dumbbell-press", "overhead-press", "lateral-raises", "tricep-pushdown", "cable-crossover"]
        case .pull:
            return ["deadlift", "barbell-row", "lat-pulldown", "face-pulls", "barbell-curl", "hammer-curl"]
        case .legs:
            return ["barbell-squat", "romanian-deadlift", "leg-press", "leg-extension", "lying-leg-curl", "standing-calf-raise"]
        case .pushPull:
            return ["bench-press", "barbell-row", "overhead-press", "lat-pulldown", "tricep-pushdown", "barbell-curl"]
        case .upper:
            return ["bench-press", "barbell-row", "overhead-press", "lat-pulldown", "lateral-raises", "barbell-curl", "tricep-pushdown"]
        case .lower:
            return ["barbell-squat", "romanian-deadlift", "leg-press", "walking-lunges", "lying-leg-curl", "standing-calf-raise"]
        case .fullBody:
            return ["barbell-squat", "bench-press", "barbell-row", "overhead-press", "romanian-deadlift", "barbell-curl"]
        case .cardio, .rest:
            return []
        }
    }

    static func defaultSetsReps(for exercise: Exercise) -> (sets: Int, reps: Int) {
        switch exercise.category {
        case .compound:
            return (4, 8)
        case .isolation:
            return (3, 12)
        }
    }
}

enum Haptics {
    static func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    static func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    static func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }

    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }

    static func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }

    static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }

    static func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}
