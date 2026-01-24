import Foundation

actor ProgressionService {
    static let shared = ProgressionService()

    private let firestoreService = FirestoreService.shared

    private init() {}

    // MARK: - Weight Calculation

    func calculateTargetWeight(
        exercise: Exercise,
        progression: ExerciseProgression?,
        goal: FitnessGoal,
        weeksSinceStart: Int
    ) -> Double {
        guard let progression = progression else {
            return 0
        }

        let baseIncrement: Double = exercise.category == .compound ? 5.0 : 2.5
        let goalMultiplier = goal.progressionMultiplier
        let weeklyIncrement = baseIncrement * goalMultiplier

        var targetWeight = progression.startingWeight + (weeklyIncrement * Double(weeksSinceStart))

        if progression.needsDeload {
            targetWeight = progression.deloadWeight
        }

        return targetWeight.rounded(toNearest: 2.5)
    }

    func getTargetWeight(
        userId: String,
        exerciseId: String,
        exercise: Exercise,
        plan: ProgressionPlan
    ) async throws -> Double {
        let progressions = try await firestoreService.getExerciseProgressions(userId: userId)
        let progression = progressions.first { $0.exerciseId == exerciseId }

        return calculateTargetWeight(
            exercise: exercise,
            progression: progression,
            goal: plan.goal,
            weeksSinceStart: plan.weeksSinceStart
        )
    }

    // MARK: - Progression Updates

    func recordSetCompletion(
        userId: String,
        exerciseId: String,
        targetWeight: Double,
        actualWeight: Double,
        targetReps: Int,
        actualReps: Int,
        rpe: Int?
    ) async throws {
        var progressions = try await firestoreService.getExerciseProgressions(userId: userId)

        guard let index = progressions.firstIndex(where: { $0.exerciseId == exerciseId }) else {
            let newProgression = ExerciseProgression(
                userId: userId,
                exerciseId: exerciseId,
                startingWeight: actualWeight,
                currentTargetWeight: actualWeight
            )

            let _ = try await firestoreService.createInSubcollection(
                newProgression,
                parentCollection: .users,
                parentId: userId,
                subcollection: .exerciseProgressions,
                documentId: newProgression.id
            )
            return
        }

        var progression = progressions[index]

        let hitTarget = actualReps >= targetReps && actualWeight >= targetWeight
        let isHighRPE = (rpe ?? 7) >= 9

        if hitTarget && !isHighRPE {
            progression.recordSuccess()
        } else if !hitTarget {
            progression.recordFailure()
        }

        if actualWeight > progression.currentTargetWeight {
            progression.currentTargetWeight = actualWeight
            progression.startingWeight = actualWeight
        }

        progression.lastPerformedDate = Date()

        try await firestoreService.updateInSubcollection(
            progression,
            parentCollection: .users,
            parentId: userId,
            subcollection: .exerciseProgressions,
            documentId: progression.id
        )
    }

    // MARK: - Deload Management

    func checkAndApplyDeload(userId: String, plan: ProgressionPlan) async throws -> Bool {
        guard plan.needsDeload else { return false }

        var progressions = try await firestoreService.getExerciseProgressions(userId: userId)

        for i in progressions.indices {
            progressions[i].applyDeload()
            try await firestoreService.updateInSubcollection(
                progressions[i],
                parentCollection: .users,
                parentId: userId,
                subcollection: .exerciseProgressions,
                documentId: progressions[i].id
            )
        }

        var updatedPlan = plan
        updatedPlan.lastDeloadDate = Date()

        try await firestoreService.updateInSubcollection(
            updatedPlan,
            parentCollection: .users,
            parentId: userId,
            subcollection: .progressionPlans,
            documentId: updatedPlan.id
        )

        return true
    }

    func triggerManualDeload(userId: String, plan: ProgressionPlan) async throws {
        var progressions = try await firestoreService.getExerciseProgressions(userId: userId)

        for i in progressions.indices {
            progressions[i].applyDeload()
            try await firestoreService.updateInSubcollection(
                progressions[i],
                parentCollection: .users,
                parentId: userId,
                subcollection: .exerciseProgressions,
                documentId: progressions[i].id
            )
        }

        var updatedPlan = plan
        updatedPlan.lastDeloadDate = Date()

        try await firestoreService.updateInSubcollection(
            updatedPlan,
            parentCollection: .users,
            parentId: userId,
            subcollection: .progressionPlans,
            documentId: updatedPlan.id
        )
    }

    // MARK: - Weekly Increment Calculation

    func calculateWeeklyIncrement(for exercise: Exercise, goal: FitnessGoal) -> Double {
        let baseIncrement: Double = exercise.category == .compound ? 5.0 : 2.5
        return baseIncrement * goal.progressionMultiplier
    }

    // MARK: - Personal Records

    func checkForPR(
        userId: String,
        exerciseId: String,
        weight: Double,
        reps: Int,
        sessionId: String
    ) async throws -> Bool {
        let existingRecords = try await firestoreService.getPersonalRecords(userId: userId)

        let exerciseRecords = existingRecords.filter { $0.exerciseId == exerciseId }

        let estimated1RM = weight * (1 + Double(reps) / 30)

        let isPR = exerciseRecords.allSatisfy { $0.estimatedOneRepMax < estimated1RM }

        if isPR || exerciseRecords.isEmpty {
            let newPR = PersonalRecord(
                userId: userId,
                exerciseId: exerciseId,
                weight: weight,
                reps: reps,
                sessionId: sessionId
            )

            let _ = try await firestoreService.createInSubcollection(
                newPR,
                parentCollection: .users,
                parentId: userId,
                subcollection: .personalRecords,
                documentId: newPR.id
            )

            return true
        }

        return false
    }

    // MARK: - Progression Summary

    func getProgressionSummary(userId: String) async throws -> ProgressionSummary {
        let progressions = try await firestoreService.getExerciseProgressions(userId: userId)
        let records = try await firestoreService.getPersonalRecords(userId: userId)
        let plan = try await firestoreService.getProgressionPlan(userId: userId)

        let totalWeightIncreased = progressions.reduce(0.0) { total, prog in
            total + (prog.currentTargetWeight - prog.startingWeight)
        }

        let exercisesWithFailures = progressions.filter { $0.consecutiveFailures > 0 }.count

        return ProgressionSummary(
            totalProgressions: progressions.count,
            totalWeightIncreased: totalWeightIncreased,
            exercisesNeedingDeload: exercisesWithFailures,
            totalPRs: records.count,
            weeksSinceStart: plan?.weeksSinceStart ?? 0,
            weeksUntilDeload: plan?.weeksUntilDeload ?? 0
        )
    }
}

struct ProgressionSummary {
    let totalProgressions: Int
    let totalWeightIncreased: Double
    let exercisesNeedingDeload: Int
    let totalPRs: Int
    let weeksSinceStart: Int
    let weeksUntilDeload: Int
}
