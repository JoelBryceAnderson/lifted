import Foundation
import Combine

@MainActor
class ExerciseViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var exercises: [Exercise] = []
    @Published var filteredExercises: [Exercise] = []
    @Published var selectedExercise: Exercise?
    @Published var searchQuery = ""
    @Published var selectedMuscleGroup: MuscleGroup?
    @Published var selectedEquipment: Equipment?
    @Published var selectedCategory: ExerciseCategory?
    @Published var isLoading = false
    @Published var error: String?

    // AI Integration
    @Published var formTips: String?
    @Published var variations: String?
    @Published var isLoadingAI = false

    // MARK: - Dependencies

    private let firestoreService = FirestoreService.shared
    private let aiService = AIService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupSearchObserver()
    }

    // MARK: - Setup

    private func setupSearchObserver() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest3($selectedMuscleGroup, $selectedEquipment, $selectedCategory)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadExercises() async {
        isLoading = true

        do {
            let fetchedExercises = try await firestoreService.getAllExercises()

            if fetchedExercises.isEmpty {
                exercises = ExerciseSeedData.exercises
            } else {
                exercises = fetchedExercises
            }

            filteredExercises = exercises

        } catch {
            exercises = ExerciseSeedData.exercises
            filteredExercises = exercises
        }

        isLoading = false
    }

    // MARK: - Filtering

    func applyFilters() {
        var result = exercises

        // Search query
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.muscleGroups.contains { $0.displayName.lowercased().contains(query) } ||
                $0.equipment.displayName.lowercased().contains(query)
            }
        }

        // Muscle group filter
        if let muscleGroup = selectedMuscleGroup {
            result = result.filter { $0.muscleGroups.contains(muscleGroup) }
        }

        // Equipment filter
        if let equipment = selectedEquipment {
            result = result.filter { $0.equipment == equipment }
        }

        // Category filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        filteredExercises = result
    }

    func clearFilters() {
        searchQuery = ""
        selectedMuscleGroup = nil
        selectedEquipment = nil
        selectedCategory = nil
        filteredExercises = exercises
    }

    // MARK: - Exercise Selection

    func selectExercise(_ exercise: Exercise) {
        selectedExercise = exercise
        formTips = nil
        variations = nil
    }

    func clearSelection() {
        selectedExercise = nil
        formTips = nil
        variations = nil
    }

    // MARK: - Grouped Exercises

    func exercisesByMuscleGroup() -> [MuscleGroup: [Exercise]] {
        Dictionary(grouping: filteredExercises) { exercise in
            exercise.muscleGroups.first ?? .chest
        }
    }

    func exercisesByEquipment() -> [Equipment: [Exercise]] {
        Dictionary(grouping: filteredExercises) { $0.equipment }
    }

    func exercisesByCategory() -> [ExerciseCategory: [Exercise]] {
        Dictionary(grouping: filteredExercises) { $0.category }
    }

    // MARK: - Workout Type Exercises

    func exercises(for workoutType: WorkoutType) -> [Exercise] {
        let muscleGroups = workoutType.primaryMuscleGroups
        return exercises.filter { exercise in
            exercise.muscleGroups.contains { muscleGroups.contains($0) }
        }
    }

    // MARK: - AI Integration

    func loadFormTips(userId: String) async {
        guard let exercise = selectedExercise else { return }

        isLoadingAI = true
        formTips = nil

        do {
            formTips = try await aiService.getFormTips(userId: userId, exercise: exercise)
        } catch {
            self.error = "Failed to load form tips"
        }

        isLoadingAI = false
    }

    func loadVariations(userId: String) async {
        guard let exercise = selectedExercise else { return }

        isLoadingAI = true
        variations = nil

        do {
            variations = try await aiService.getExerciseVariations(userId: userId, exercise: exercise)
        } catch {
            self.error = "Failed to load variations"
        }

        isLoadingAI = false
    }
}
