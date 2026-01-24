import SwiftUI

struct ExerciseLogView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var exerciseViewModel: ExerciseViewModel

    let exerciseLog: ExerciseLog

//    @State private var setInputs: [SetInput] = []
    @State private var showAITips = false

    var exercise: Exercise? {
        ExerciseSeedData.exercises.first { $0.id == exerciseLog.exerciseId }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Exercise header
                ExerciseHeader(exercise: exercise, onAITap: {
                    showAITips = true
                })

                // Warmup sets
                if exerciseLog.sets.contains(where: { $0.isWarmup }) {
                    WarmupSetsView(sets: exerciseLog.sets.filter { $0.isWarmup })
                }

                // Working sets
                VStack(alignment: .leading, spacing: 12) {
                    Text("Working Sets")
                        .font(.headline)

                    let workingSets = exerciseLog.sets.filter { !$0.isWarmup }
                    ForEach(Array(workingSets.enumerated()), id: \.element.id) { index, set in
                        SetInputRowWrapper(
                            set: set,
                            setNumber: index + 1,
                            onComplete: { weight, reps, rpe in
                                let actualIndex = exerciseLog.sets.firstIndex(where: { $0.id == set.id }) ?? index
                                Task {
                                    await workoutViewModel.completeSet(
                                        setIndex: actualIndex,
                                        actualWeight: weight,
                                        actualReps: reps,
                                        rpe: rpe
                                    )
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)

                // Notes section
                NotesSection(exerciseId: exerciseLog.exerciseId)
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showAITips) {
            AITipsSheet(exercise: exercise)
        }
    }
}

struct ExerciseHeader: View {
    let exercise: Exercise?
    let onAITap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let exercise = exercise {
                        Text(exercise.name)
                            .font(.title2.bold())

                        HStack(spacing: 8) {
                            Label(exercise.equipment.displayName, systemImage: "dumbbell.fill")
                            Text("•")
                            Label(exercise.category.displayName, systemImage: "tag.fill")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()

                AIButtonSmall(action: onAITap)
            }

            // Muscle groups
            if let exercise = exercise {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(exercise.muscleGroups, id: \.self) { muscle in
                            Text(muscle.displayName)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct SetInputRowWrapper: View {
    let set: ExerciseSet
    let setNumber: Int
    let onComplete: (Double, Int, Int?) -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var rpe: Int?

    var body: some View {
        SetInputRow(
            setNumber: setNumber,
            isWarmup: set.isWarmup,
            targetWeight: set.targetWeight,
            targetReps: set.targetReps,
            actualWeight: $weightText,
            actualReps: $repsText,
            rpe: $rpe,
            isCompleted: set.isCompleted
        ) {
            guard let weight = Double(weightText),
                  let reps = Int(repsText) else { return }
            onComplete(weight, reps, rpe)
        }
        .onAppear {
            weightText = set.actualWeight?.weightString ?? set.targetWeight.weightString
            repsText = set.actualReps.map { String($0) } ?? String(set.targetReps)
            rpe = set.rpe
        }
    }
}

struct NotesSection: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel

    let exerciseId: String
    @State private var notes = ""
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Notes")
                    .font(.headline)

                Spacer()

                Button {
                    isEditing.toggle()
                } label: {
                    Text(isEditing ? "Done" : "Edit")
                        .font(.subheadline)
                }
            }

            if isEditing {
                TextEditor(text: $notes)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onChange(of: notes) { _, newValue in
                        Task {
                            await workoutViewModel.updateExerciseNotes(newValue)
                        }
                    }
            } else if !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                Text("Tap Edit to add notes...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.horizontal)
    }
}

struct AITipsSheet: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var exerciseViewModel: ExerciseViewModel
    @Environment(\.dismiss) var dismiss

    let exercise: Exercise?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Form tips
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("Form Tips")
                                .font(.headline)
                        }

                        if exerciseViewModel.isLoadingAI {
                            HStack {
                                ProgressView()
                                Text("Loading tips...")
                                    .foregroundColor(.secondary)
                            }
                        } else if let tips = exerciseViewModel.formTips {
                            Text(tips)
                                .font(.body)
                        } else {
                            Button("Get Form Tips") {
                                loadTips()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    Divider()

                    // Instructions
                    if let instructions = exercise?.instructions {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "text.book.closed")
                                    .foregroundColor(.blue)
                                Text("Instructions")
                                    .font(.headline)
                            }

                            Text(instructions)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Variations
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.green)
                            Text("Alternatives")
                                .font(.headline)
                        }

                        if let variations = exerciseViewModel.variations {
                            Text(variations)
                                .font(.body)
                        } else {
                            Button("Get Alternatives") {
                                loadVariations()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(exercise?.name ?? "Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            if let exercise = exercise {
                exerciseViewModel.selectExercise(exercise)
            }
        }
    }

    private func loadTips() {
        guard let userId = authViewModel.user?.id else { return }
        Task {
            await exerciseViewModel.loadFormTips(userId: userId)
        }
    }

    private func loadVariations() {
        guard let userId = authViewModel.user?.id else { return }
        Task {
            await exerciseViewModel.loadVariations(userId: userId)
        }
    }
}

#Preview {
    ExerciseLogView(
        exerciseLog: ExerciseLog(
            exerciseId: "bench-press",
            sets: [
                ExerciseSet(targetReps: 10, targetWeight: 45, isWarmup: true),
                ExerciseSet(targetReps: 10, targetWeight: 135),
                ExerciseSet(targetReps: 10, targetWeight: 135),
                ExerciseSet(targetReps: 10, targetWeight: 135)
            ]
        )
    )
    .environmentObject(WorkoutViewModel())
    .environmentObject(AuthViewModel())
    .environmentObject(ExerciseViewModel())
}
