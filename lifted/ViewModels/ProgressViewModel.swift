import Foundation
import Combine

@MainActor
class ProgressViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var workoutSessions: [WorkoutSession] = []
    @Published var personalRecords: [PersonalRecord] = []
    @Published var selectedExerciseId: String?
    @Published var exerciseHistory: [ExerciseHistoryPoint] = []
    @Published var isLoading = false
    @Published var error: String?

    // Date Range
    @Published var startDate: Date = Date().adding(weeks: -8)
    @Published var endDate: Date = Date()

    // AI Analysis
    @Published var progressAnalysis: String?
    @Published var isLoadingAnalysis = false

    // MARK: - Dependencies

    private let firestoreService = FirestoreService.shared
    private let aiService = AIService.shared

    // MARK: - Computed Properties

    var completedSessions: [WorkoutSession] {
        workoutSessions.filter { $0.status == .completed }
    }

    var totalWorkouts: Int {
        completedSessions.count
    }

    var currentStreak: Int {
        calculateStreak()
    }

    var totalVolume: Double {
        completedSessions.reduce(0) { $0 + $1.totalVolume }
    }

    var averageSessionDuration: TimeInterval {
        let durations = completedSessions.compactMap { $0.duration }
        guard !durations.isEmpty else { return 0 }
        return durations.reduce(0, +) / Double(durations.count)
    }

    var workoutsByType: [WorkoutType: Int] {
        Dictionary(grouping: completedSessions) { $0.workoutType }
            .mapValues { $0.count }
    }

    var recentPRs: [PersonalRecord] {
        personalRecords
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Data Loading

    func loadProgressData(userId: String) async {
        isLoading = true

        do {
            workoutSessions = try await firestoreService.getWorkoutSessions(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )

            personalRecords = try await firestoreService.getPersonalRecords(userId: userId)

        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadExerciseHistory(userId: String, exerciseId: String) async {
        selectedExerciseId = exerciseId
        exerciseHistory = []

        let relevantSessions = completedSessions.filter { session in
            session.exercises.contains { $0.exerciseId == exerciseId }
        }

        exerciseHistory = relevantSessions.compactMap { session -> ExerciseHistoryPoint? in
            guard let log = session.exercises.first(where: { $0.exerciseId == exerciseId }) else { return nil }

            let workingSets = log.sets.filter { !$0.isWarmup && $0.isCompleted }
            guard !workingSets.isEmpty else { return nil }

            let maxWeight = workingSets.compactMap { $0.actualWeight }.max() ?? 0
            let totalVolume = log.totalVolume
            let averageReps = Double(workingSets.compactMap { $0.actualReps }.reduce(0, +)) / Double(workingSets.count)

            return ExerciseHistoryPoint(
                date: session.scheduledDate,
                maxWeight: maxWeight,
                totalVolume: totalVolume,
                averageReps: averageReps,
                sets: workingSets.count
            )
        }.sorted { $0.date < $1.date }
    }

    // MARK: - Date Range

    func setDateRange(weeks: Int) {
        startDate = Date().adding(weeks: -weeks)
        endDate = Date()
    }

    // MARK: - Streak Calculation

    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()

        let sortedSessions = completedSessions.sorted { $0.scheduledDate > $1.scheduledDate }

        for session in sortedSessions {
            let sessionDate = calendar.startOfDay(for: session.scheduledDate)
            let checkDate = calendar.startOfDay(for: currentDate)

            if calendar.isDate(sessionDate, inSameDayAs: checkDate) ||
               calendar.isDate(sessionDate, inSameDayAs: checkDate.adding(days: -1)) {
                streak += 1
                currentDate = sessionDate
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - AI Analysis

    func loadProgressAnalysis(userId: String, exerciseName: String) async {
        guard let exerciseId = selectedExerciseId else { return }

        isLoadingAnalysis = true
        progressAnalysis = nil

        do {
            progressAnalysis = try await aiService.analyzeProgress(
                userId: userId,
                exerciseId: exerciseId,
                exerciseName: exerciseName
            )
        } catch {
            self.error = "Failed to load progress analysis"
        }

        isLoadingAnalysis = false
    }

    // MARK: - PR Helpers

    func getPRs(for exerciseId: String) -> [PersonalRecord] {
        personalRecords
            .filter { $0.exerciseId == exerciseId }
            .sorted { $0.estimatedOneRepMax > $1.estimatedOneRepMax }
    }

    func getBestPR(for exerciseId: String) -> PersonalRecord? {
        getPRs(for: exerciseId).first
    }
}

// MARK: - Supporting Types

struct ExerciseHistoryPoint: Identifiable {
    let id = UUID()
    let date: Date
    let maxWeight: Double
    let totalVolume: Double
    let averageReps: Double
    let sets: Int
}

struct VolumeData: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Double
    let workoutType: WorkoutType
}
