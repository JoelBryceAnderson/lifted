import Foundation
import Combine

@MainActor
class ProgressionViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var progressionPlan: ProgressionPlan?
    @Published var exerciseProgressions: [ExerciseProgression] = []
    @Published var progressionSummary: ProgressionSummary?
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Dependencies

    private let firestoreService = FirestoreService.shared
    private let progressionService = ProgressionService.shared

    // MARK: - Computed Properties

    var currentGoal: FitnessGoal? {
        progressionPlan?.goal
    }

    var weeksSinceStart: Int {
        progressionPlan?.weeksSinceStart ?? 0
    }

    var needsDeload: Bool {
        progressionPlan?.needsDeload ?? false
    }

    var weeksUntilDeload: Int {
        progressionPlan?.weeksUntilDeload ?? 0
    }

    // MARK: - Data Loading

    func loadProgressionData(userId: String) async {
        isLoading = true

        do {
            progressionPlan = try await firestoreService.getProgressionPlan(userId: userId)
            exerciseProgressions = try await firestoreService.getExerciseProgressions(userId: userId)
            progressionSummary = try await progressionService.getProgressionSummary(userId: userId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Goal Management

    func updateGoal(userId: String, newGoal: FitnessGoal) async {
        guard var plan = progressionPlan else { return }

        plan = ProgressionPlan(
            id: plan.id,
            userId: userId,
            goal: newGoal,
            startDate: plan.startDate,
            deloadFrequencyWeeks: plan.deloadFrequencyWeeks,
            lastDeloadDate: plan.lastDeloadDate
        )

        do {
            try await firestoreService.updateInSubcollection(
                plan,
                parentCollection: .users,
                parentId: userId,
                subcollection: .progressionPlans,
                documentId: plan.id
            )

            // Update weekly increments for all progressions
            for var progression in exerciseProgressions {
                let exercise = ExerciseSeedData.exercises.first { $0.id == progression.exerciseId }
                let baseIncrement = exercise?.category == .compound ? 5.0 : 2.5
                progression.weeklyIncrement = baseIncrement * newGoal.progressionMultiplier

                try await firestoreService.updateInSubcollection(
                    progression,
                    parentCollection: .users,
                    parentId: userId,
                    subcollection: .exerciseProgressions,
                    documentId: progression.id
                )
            }

            progressionPlan = plan
            await loadProgressionData(userId: userId)

        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Deload Management

    func triggerDeload(userId: String) async {
        guard let plan = progressionPlan else { return }

        isLoading = true

        do {
            try await progressionService.triggerManualDeload(userId: userId, plan: plan)
            await loadProgressionData(userId: userId)
            Haptics.success()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func updateDeloadFrequency(userId: String, weeks: Int) async {
        guard let plan = progressionPlan else { return }

        let updatedPlan = ProgressionPlan(
            id: plan.id,
            userId: userId,
            goal: plan.goal,
            startDate: plan.startDate,
            deloadFrequencyWeeks: weeks,
            lastDeloadDate: plan.lastDeloadDate
        )

        do {
            try await firestoreService.updateInSubcollection(
                updatedPlan,
                parentCollection: .users,
                parentId: userId,
                subcollection: .progressionPlans,
                documentId: updatedPlan.id
            )

            progressionPlan = updatedPlan

        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Exercise Progression Management

    func updateExerciseProgression(userId: String, progressionId: String, newWeight: Double) async {
        guard let index = exerciseProgressions.firstIndex(where: { $0.id == progressionId }) else { return }

        var progression = exerciseProgressions[index]
        progression.currentTargetWeight = newWeight

        do {
            try await firestoreService.updateInSubcollection(
                progression,
                parentCollection: .users,
                parentId: userId,
                subcollection: .exerciseProgressions,
                documentId: progression.id
            )

            exerciseProgressions[index] = progression

        } catch {
            self.error = error.localizedDescription
        }
    }

    func resetProgression(userId: String, progressionId: String) async {
        guard let index = exerciseProgressions.firstIndex(where: { $0.id == progressionId }) else { return }

        var progression = exerciseProgressions[index]
        progression.currentTargetWeight = progression.startingWeight
        progression.consecutiveFailures = 0

        do {
            try await firestoreService.updateInSubcollection(
                progression,
                parentCollection: .users,
                parentId: userId,
                subcollection: .exerciseProgressions,
                documentId: progression.id
            )

            exerciseProgressions[index] = progression

        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Target Weight Calculation

    func getTargetWeight(for exerciseId: String) -> Double {
        guard let progression = exerciseProgressions.first(where: { $0.exerciseId == exerciseId }),
              let plan = progressionPlan else {
            return 0
        }

        if progression.needsDeload {
            return progression.deloadWeight
        }

        return progression.currentTargetWeight
    }

    func getProgression(for exerciseId: String) -> ExerciseProgression? {
        exerciseProgressions.first { $0.exerciseId == exerciseId }
    }
}
