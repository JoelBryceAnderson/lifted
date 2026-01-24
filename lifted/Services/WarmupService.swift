import Foundation

struct WarmupService {
    static func generateWarmupSets(
        forWorkingWeight workingWeight: Double,
        equipment: Equipment,
        reps: Int = 10
    ) -> [ExerciseSet] {
        let barWeight: Double = equipment == .barbell ? 45 : 0

        var warmupSets: [ExerciseSet] = []

        if equipment == .barbell && workingWeight > barWeight {
            warmupSets.append(ExerciseSet(
                targetReps: 10,
                targetWeight: barWeight,
                isWarmup: true
            ))
        }

        if workingWeight > barWeight * 2 {
            let fiftyPercent = (workingWeight * 0.5).rounded(toNearest: 2.5)
            warmupSets.append(ExerciseSet(
                targetReps: 8,
                targetWeight: max(fiftyPercent, barWeight),
                isWarmup: true
            ))
        }

        if workingWeight > barWeight * 2.5 {
            let seventyPercent = (workingWeight * 0.7).rounded(toNearest: 2.5)
            warmupSets.append(ExerciseSet(
                targetReps: 5,
                targetWeight: seventyPercent,
                isWarmup: true
            ))
        }

        if workingWeight > barWeight * 3 {
            let eightyFivePercent = (workingWeight * 0.85).rounded(toNearest: 2.5)
            warmupSets.append(ExerciseSet(
                targetReps: 3,
                targetWeight: eightyFivePercent,
                isWarmup: true
            ))
        }

        return warmupSets
    }

    static func generateWorkingSets(
        targetWeight: Double,
        targetReps: Int,
        numberOfSets: Int
    ) -> [ExerciseSet] {
        (0..<numberOfSets).map { _ in
            ExerciseSet(
                targetReps: targetReps,
                targetWeight: targetWeight,
                isWarmup: false
            )
        }
    }

    static func generateExerciseLog(
        exerciseId: String,
        exercise: Exercise,
        targetWeight: Double,
        targetReps: Int = 10,
        workingSets: Int = 3,
        includeWarmup: Bool = true
    ) -> ExerciseLog {
        var sets: [ExerciseSet] = []

        if includeWarmup && exercise.category == .compound {
            sets.append(contentsOf: generateWarmupSets(
                forWorkingWeight: targetWeight,
                equipment: exercise.equipment
            ))
        }

        sets.append(contentsOf: generateWorkingSets(
            targetWeight: targetWeight,
            targetReps: targetReps,
            numberOfSets: workingSets
        ))

        return ExerciseLog(
            exerciseId: exerciseId,
            sets: sets
        )
    }
}

extension WarmupService {
    struct WarmupScheme {
        let name: String
        let description: String
        let percentages: [(percentage: Double, reps: Int)]

        static let standard = WarmupScheme(
            name: "Standard",
            description: "Bar, 50%, 70%, 85% warmup",
            percentages: [
                (0.0, 10),   // Bar only
                (0.5, 8),    // 50%
                (0.7, 5),    // 70%
                (0.85, 3)    // 85%
            ]
        )

        static let abbreviated = WarmupScheme(
            name: "Quick",
            description: "50%, 75% warmup",
            percentages: [
                (0.5, 8),
                (0.75, 3)
            ]
        )

        static let extended = WarmupScheme(
            name: "Extended",
            description: "More gradual warmup for heavy lifts",
            percentages: [
                (0.0, 10),
                (0.4, 8),
                (0.55, 5),
                (0.7, 5),
                (0.8, 3),
                (0.9, 2)
            ]
        )
    }

    static func generateWarmupSets(
        forWorkingWeight workingWeight: Double,
        equipment: Equipment,
        scheme: WarmupScheme
    ) -> [ExerciseSet] {
        let barWeight: Double = equipment == .barbell ? 45 : 0

        return scheme.percentages.compactMap { (percentage, reps) in
            let weight: Double
            if percentage == 0 {
                weight = barWeight
            } else {
                weight = (workingWeight * percentage).rounded(toNearest: 2.5)
            }

            guard weight >= barWeight else { return nil }

            return ExerciseSet(
                targetReps: reps,
                targetWeight: weight,
                isWarmup: true
            )
        }
    }
}
