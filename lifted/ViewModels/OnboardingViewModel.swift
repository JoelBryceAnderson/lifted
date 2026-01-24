import Foundation
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentStep: OnboardingStep = .welcome
    @Published var isLoading = false
    @Published var error: String?

    // Goal Selection
    @Published var selectedGoal: FitnessGoal?

    // Schedule Builder
    @Published var cycleDuration = 7
    @Published var scheduleDays: [ScheduledDayType] = Array(repeating: .rest, count: 7)

    // Starting Weights
    @Published var startingWeights: [String: Double] = [:]

    // Trainer Notes
    @Published var trainerNotes: [TrainerNote] = []
    @Published var newNoteContent = ""
    @Published var newNoteCategory: NoteCategory = .preference

    // MARK: - Dependencies

    private let firestoreService = FirestoreService.shared

    // MARK: - Key Exercises for Starting Weights

    let keyExercises: [(id: String, name: String)] = [
        ("bench-press", "Bench Press"),
        ("barbell-squat", "Squat"),
        ("deadlift", "Deadlift"),
        ("overhead-press", "Overhead Press"),
        ("barbell-row", "Barbell Row")
    ]

    // MARK: - Computed Properties

    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .createAccount:
            return true // Handled separately
        case .goalSelection:
            return selectedGoal != nil
        case .scheduleBuilder:
            return hasValidSchedule
        case .startingWeights:
            return true // Optional step
        case .trainerNotes:
            return true // Optional step
        }
    }

    var hasValidSchedule: Bool {
        scheduleDays.contains { !$0.isRest }
    }

    var workoutDaysCount: Int {
        scheduleDays.filter { !$0.isRest }.count
    }

    var restDaysCount: Int {
        scheduleDays.filter { $0.isRest }.count
    }

    // MARK: - Navigation

    func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .createAccount
        case .createAccount:
            currentStep = .goalSelection
        case .goalSelection:
            currentStep = .scheduleBuilder
        case .scheduleBuilder:
            currentStep = .startingWeights
        case .startingWeights:
            currentStep = .trainerNotes
        case .trainerNotes:
            break
        }
    }

    func previousStep() {
        switch currentStep {
        case .welcome:
            break
        case .createAccount:
            currentStep = .welcome
        case .goalSelection:
            currentStep = .createAccount
        case .scheduleBuilder:
            currentStep = .goalSelection
        case .startingWeights:
            currentStep = .scheduleBuilder
        case .trainerNotes:
            currentStep = .startingWeights
        }
    }

    // MARK: - Schedule Builder

    func updateCycleDuration(_ days: Int) {
        cycleDuration = days
        if scheduleDays.count < days {
            scheduleDays.append(contentsOf: Array(repeating: .rest, count: days - scheduleDays.count))
        } else if scheduleDays.count > days {
            scheduleDays = Array(scheduleDays.prefix(days))
        }
    }

    func setDayType(at index: Int, to type: ScheduledDayType) {
        guard index < scheduleDays.count else { return }
        scheduleDays[index] = type
    }

    func applyTemplate(_ template: ScheduleTemplate) {
        cycleDuration = template.days.count
        scheduleDays = template.days
    }

    // MARK: - Starting Weights

    func setStartingWeight(for exerciseId: String, weight: Double) {
        startingWeights[exerciseId] = weight
    }

    // MARK: - Trainer Notes

    func addTrainerNote(userId: String) {
        guard !newNoteContent.trimmed.isEmpty else { return }

        let note = TrainerNote(
            userId: userId,
            content: newNoteContent.trimmed,
            category: newNoteCategory
        )

        trainerNotes.append(note)
        newNoteContent = ""
    }

    func removeTrainerNote(at index: Int) {
        guard index < trainerNotes.count else { return }
        trainerNotes.remove(at: index)
    }

    // MARK: - Complete Onboarding

    func completeOnboarding(userId: String) async -> Bool {
        isLoading = true
        error = nil

        do {
            // 1. Save schedule
            if hasValidSchedule {
                let schedule = buildSchedule(userId: userId)
                let _ = try await firestoreService.createInSubcollection(
                    schedule,
                    parentCollection: .users,
                    parentId: userId,
                    subcollection: .schedules,
                    documentId: schedule.id
                )
            }

            // 2. Save progression plan
            if let goal = selectedGoal {
                let plan = ProgressionPlan(
                    userId: userId,
                    goal: goal
                )
                let _ = try await firestoreService.createInSubcollection(
                    plan,
                    parentCollection: .users,
                    parentId: userId,
                    subcollection: .progressionPlans,
                    documentId: plan.id
                )
            }

            // 3. Save exercise progressions for starting weights
            for (exerciseId, weight) in startingWeights {
                let exercise = ExerciseSeedData.exercises.first { $0.id == exerciseId }
                let weeklyIncrement = exercise?.category == .compound
                    ? (selectedGoal?.compoundIncrement ?? 5.0)
                    : (selectedGoal?.isolationIncrement ?? 2.5)

                let progression = ExerciseProgression(
                    userId: userId,
                    exerciseId: exerciseId,
                    startingWeight: weight,
                    weeklyIncrement: weeklyIncrement
                )

                let _ = try await firestoreService.createInSubcollection(
                    progression,
                    parentCollection: .users,
                    parentId: userId,
                    subcollection: .exerciseProgressions,
                    documentId: progression.id
                )
            }

            // 4. Save trainer notes
            for note in trainerNotes {
                let _ = try await firestoreService.createInSubcollection(
                    note,
                    parentCollection: .users,
                    parentId: userId,
                    subcollection: .trainerNotes,
                    documentId: note.id
                )
            }

            isLoading = false
            return true

        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }

    private func buildSchedule(userId: String) -> WorkoutSchedule {
        let days = scheduleDays.enumerated().map { index, dayType in
            ScheduledDay(dayIndex: index, dayType: dayType)
        }

        return WorkoutSchedule(
            userId: userId,
            cycleDurationDays: cycleDuration,
            days: days
        )
    }
}

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case createAccount
    case goalSelection
    case scheduleBuilder
    case startingWeights
    case trainerNotes

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .createAccount: return "Create Account"
        case .goalSelection: return "Your Goal"
        case .scheduleBuilder: return "Build Schedule"
        case .startingWeights: return "Starting Weights"
        case .trainerNotes: return "Trainer Notes"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome: return "Let's get you started"
        case .createAccount: return "Sign in or create an account"
        case .goalSelection: return "What are you training for?"
        case .scheduleBuilder: return "Design your workout week"
        case .startingWeights: return "Optional: Set your baselines"
        case .trainerNotes: return "Optional: Tell your AI trainer about you"
        }
    }

    var isOptional: Bool {
        switch self {
        case .startingWeights, .trainerNotes: return true
        default: return false
        }
    }
}

// MARK: - Schedule Templates

struct ScheduleTemplate {
    let name: String
    let description: String
    let days: [ScheduledDayType]

    static let ppl = ScheduleTemplate(
        name: "Push/Pull/Legs",
        description: "6 days, 1 rest",
        days: [
            .rest,
            .workout(.push),
            .workout(.pull),
            .workout(.legs),
            .workout(.push),
            .workout(.pull),
            .workout(.legs)
        ]
    )

    static let upperLower = ScheduleTemplate(
        name: "Upper/Lower",
        description: "4 days, 3 rest",
        days: [
            .rest,
            .workout(.upper),
            .workout(.lower),
            .rest,
            .workout(.upper),
            .workout(.lower),
            .rest
        ]
    )

    static let fullBody = ScheduleTemplate(
        name: "Full Body",
        description: "3 days, alternating",
        days: [
            .rest,
            .workout(.fullBody),
            .rest,
            .workout(.fullBody),
            .rest,
            .workout(.fullBody),
            .rest
        ]
    )

    static let bro = ScheduleTemplate(
        name: "Bro Split",
        description: "5 days, 2 rest",
        days: [
            .rest,
            .workout(.push),
            .workout(.pull),
            .workout(.legs),
            .workout(.push),
            .workout(.pull),
            .rest
        ]
    )

    static let templates = [ppl, upperLower, fullBody, bro]
}
