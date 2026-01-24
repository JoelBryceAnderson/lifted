import Foundation
import Combine

@MainActor
class WorkoutViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentSession: WorkoutSession?
    @Published var currentExerciseIndex = 0
    @Published var isLoading = false
    @Published var error: String?

    // Rest Timer
    @Published var isRestTimerActive = false
    @Published var restTimeRemaining: TimeInterval = 0
    @Published var currentRestDuration: TimeInterval = 90

    // Exercise Details
    @Published var exercises: [Exercise] = []
    @Published var exerciseProgressions: [String: ExerciseProgression] = [:]

    // PR Celebration
    @Published var prCelebrationInfo: PRCelebrationInfo?

    // MARK: - Dependencies

    private let firestoreService = FirestoreService.shared
    private let progressionService = ProgressionService.shared
    private let warmupService = WarmupService.self
    private var restTimer: Timer?

    // MARK: - Computed Properties

    var currentExerciseLog: ExerciseLog? {
        guard let session = currentSession,
              currentExerciseIndex < session.exercises.count else { return nil }
        return session.exercises[currentExerciseIndex]
    }

    var currentExercise: Exercise? {
        guard let log = currentExerciseLog else { return nil }
        return exercises.first { $0.id == log.exerciseId }
    }

    var isWorkoutInProgress: Bool {
        currentSession?.status == .inProgress
    }

    var completionPercentage: Double {
        guard let session = currentSession else { return 0 }
        let total = session.totalSets
        let completed = session.completedSets
        return total > 0 ? Double(completed) / Double(total) : 0
    }

    // MARK: - Workout Lifecycle

    func startWorkout(session: WorkoutSession, progressionPlan: ProgressionPlan?) async {
        isLoading = true

        var newSession = session
        newSession.startedAt = Date()
        newSession.status = .inProgress

        // Load exercises
        do {
            exercises = try await firestoreService.getAllExercises()
            
            // Fallback to seed data if Firestore is empty
            if exercises.isEmpty {
                print("⚠️ No exercises in Firestore, using seed data")
                exercises = ExerciseSeedData.exercises
            }
            
            let progressions = try await firestoreService.getExerciseProgressions(userId: session.userId)
            exerciseProgressions = Dictionary(uniqueKeysWithValues: progressions.map { ($0.exerciseId, $0) })

            // Generate exercise logs if empty
            if newSession.exercises.isEmpty {
                print("⚠️ Session has no exercises, generating them now")
                newSession.exercises = generateExerciseLogs(
                    for: session.workoutType,
                    userId: session.userId,
                    plan: progressionPlan
                )
            }
            
            print("✅ Starting workout with \(newSession.exercises.count) exercises")

            // Save session
            let _ = try await firestoreService.createInSubcollection(
                newSession,
                parentCollection: .users,
                parentId: session.userId,
                subcollection: .workoutSessions,
                documentId: newSession.id
            )

            currentSession = newSession
            currentExerciseIndex = 0

        } catch {
            print("❌ Error starting workout: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func generateExerciseLogs(for workoutType: WorkoutType, userId: String, plan: ProgressionPlan?) -> [ExerciseLog] {
        let exerciseIds = WorkoutDefaults.defaultExercises(for: workoutType)

        return exerciseIds.compactMap { exerciseId -> ExerciseLog? in
            guard let exercise = exercises.first(where: { $0.id == exerciseId }) else { return nil }

            let progression = exerciseProgressions[exerciseId]
            let targetWeight = progression?.currentTargetWeight ?? 0
            let (sets, reps) = WorkoutDefaults.defaultSetsReps(for: exercise)

            return WarmupService.generateExerciseLog(
                exerciseId: exerciseId,
                exercise: exercise,
                targetWeight: targetWeight,
                targetReps: reps,
                workingSets: sets
            )
        }
    }

    func completeWorkout() async {
        guard var session = currentSession else { return }

        session.completedAt = Date()
        session.status = .completed

        do {
            try await firestoreService.updateInSubcollection(
                session,
                parentCollection: .users,
                parentId: session.userId,
                subcollection: .workoutSessions,
                documentId: session.id
            )

            // Check for PRs and collect all new PRs
            var newPRs: [(exerciseId: String, weight: Double, reps: Int)] = []

            for exerciseLog in session.exercises {
                for set in exerciseLog.sets where !set.isWarmup && set.isCompleted {
                    if let weight = set.actualWeight, let reps = set.actualReps {
                        let isPR = try await progressionService.checkForPR(
                            userId: session.userId,
                            exerciseId: exerciseLog.exerciseId,
                            weight: weight,
                            reps: reps,
                            sessionId: session.id
                        )
                        if isPR {
                            newPRs.append((exerciseLog.exerciseId, weight, reps))
                        }
                    }
                }
            }

            // Show celebration for the best PR if any were hit
            if let bestPR = newPRs.max(by: { $0.weight * (1 + Double($0.reps) / 30) < $1.weight * (1 + Double($1.reps) / 30) }) {
                let exerciseName = exercises.first(where: { $0.id == bestPR.exerciseId })?.name ?? "Exercise"
                prCelebrationInfo = PRCelebrationInfo(
                    exerciseName: exerciseName,
                    weight: bestPR.weight,
                    reps: bestPR.reps
                )
            }

            currentSession = nil
            stopRestTimer()

        } catch {
            self.error = error.localizedDescription
        }
    }

    func cancelWorkout() async {
        guard var session = currentSession else { return }

        session.status = .scheduled
        session.startedAt = nil

        do {
            try await firestoreService.updateInSubcollection(
                session,
                parentCollection: .users,
                parentId: session.userId,
                subcollection: .workoutSessions,
                documentId: session.id
            )

            currentSession = nil
            stopRestTimer()

        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Set Management

    func completeSet(setIndex: Int, actualWeight: Double, actualReps: Int, rpe: Int?) async {
        guard var session = currentSession,
              currentExerciseIndex < session.exercises.count,
              setIndex < session.exercises[currentExerciseIndex].sets.count else { return }

        var set = session.exercises[currentExerciseIndex].sets[setIndex]
        set.actualWeight = actualWeight
        set.actualReps = actualReps
        set.rpe = rpe
        set.completedAt = Date()

        session.exercises[currentExerciseIndex].sets[setIndex] = set

        do {
            try await firestoreService.updateInSubcollection(
                session,
                parentCollection: .users,
                parentId: session.userId,
                subcollection: .workoutSessions,
                documentId: session.id
            )

            // Update progression
            if !set.isWarmup {
                try await progressionService.recordSetCompletion(
                    userId: session.userId,
                    exerciseId: session.exercises[currentExerciseIndex].exerciseId,
                    targetWeight: set.targetWeight,
                    actualWeight: actualWeight,
                    targetReps: set.targetReps,
                    actualReps: actualReps,
                    rpe: rpe
                )
            }

            currentSession = session

            // Start rest timer
            if let exercise = currentExercise {
                startRestTimer(duration: TimeInterval(exercise.defaultRestSeconds))
            }

            Haptics.success()

        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateSetTarget(setIndex: Int, weight: Double?, reps: Int?) {
        guard var session = currentSession,
              currentExerciseIndex < session.exercises.count,
              setIndex < session.exercises[currentExerciseIndex].sets.count else { return }

        if let weight = weight {
            session.exercises[currentExerciseIndex].sets[setIndex].targetWeight = weight
        }
        if let reps = reps {
            session.exercises[currentExerciseIndex].sets[setIndex].targetReps = reps
        }

        currentSession = session
    }

    // MARK: - Exercise Navigation

    func nextExercise() {
        guard let session = currentSession,
              currentExerciseIndex < session.exercises.count - 1 else { return }

        currentExerciseIndex += 1
        stopRestTimer()
        Haptics.selection()
    }

    func previousExercise() {
        guard currentExerciseIndex > 0 else { return }

        currentExerciseIndex -= 1
        stopRestTimer()
        Haptics.selection()
    }

    func goToExercise(at index: Int) {
        guard let session = currentSession,
              index >= 0 && index < session.exercises.count else { return }

        currentExerciseIndex = index
        stopRestTimer()
    }

    // MARK: - Rest Timer

    func startRestTimer(duration: TimeInterval) {
        currentRestDuration = duration
        restTimeRemaining = duration
        isRestTimerActive = true

        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.restTimeRemaining > 0 {
                    self.restTimeRemaining -= 1
                } else {
                    self.restTimerFinished()
                }
            }
        }
    }

    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isRestTimerActive = false
        restTimeRemaining = 0
    }

    func addRestTime(_ seconds: TimeInterval) {
        restTimeRemaining += seconds
    }

    func skipRestTimer() {
        stopRestTimer()
    }

    private func restTimerFinished() {
        stopRestTimer()
        Haptics.warning()
    }

    // MARK: - Notes

    func updateExerciseNotes(_ notes: String) async {
        guard var session = currentSession,
              currentExerciseIndex < session.exercises.count else { return }

        session.exercises[currentExerciseIndex].notes = notes.isEmpty ? nil : notes

        do {
            try await firestoreService.updateInSubcollection(
                session,
                parentCollection: .users,
                parentId: session.userId,
                subcollection: .workoutSessions,
                documentId: session.id
            )
            currentSession = session
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateSessionNotes(_ notes: String) async {
        guard var session = currentSession else { return }

        session.notes = notes.isEmpty ? nil : notes

        do {
            try await firestoreService.updateInSubcollection(
                session,
                parentCollection: .users,
                parentId: session.userId,
                subcollection: .workoutSessions,
                documentId: session.id
            )
            currentSession = session
        } catch {
            self.error = error.localizedDescription
        }
    }
}
