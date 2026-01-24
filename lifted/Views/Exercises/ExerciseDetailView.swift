import SwiftUI

struct ExerciseDetailView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var exerciseViewModel: ExerciseViewModel
    @EnvironmentObject var progressViewModel: ProgressViewModel
    @Environment(\.dismiss) var dismiss

    let exercise: Exercise

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    ExerciseDetailHeader(exercise: exercise)

                    // Quick info
                    QuickInfoSection(exercise: exercise)

                    // Instructions
                    if let instructions = exercise.instructions {
                        InstructionsSection(instructions: instructions)
                    }

                    // AI Section
                    AITipsSection(exercise: exercise)

                    // Personal stats
                    PersonalStatsSection(exerciseId: exercise.id)
                }
                .padding()
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                exerciseViewModel.selectExercise(exercise)
            }
        }
    }
}

struct ExerciseDetailHeader: View {
    let exercise: Exercise

    var body: some View {
        VStack(spacing: 12) {
            // Category badge
            HStack {
                Text(exercise.category.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(exercise.category == .compound ? Color.blue : Color.green)
                    .cornerRadius(12)

                Spacer()

                // Rest time
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                    Text("\(exercise.defaultRestSeconds)s rest")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            // Muscle groups
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(exercise.muscleGroups, id: \.self) { muscle in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                            Text(muscle.displayName)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}

struct QuickInfoSection: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Info")
                .font(.headline)

            HStack(spacing: 16) {
                InfoBadge(
                    icon: "dumbbell.fill",
                    title: "Equipment",
                    value: exercise.equipment.displayName
                )

                InfoBadge(
                    icon: "target",
                    title: "Primary",
                    value: exercise.muscleGroups.first?.displayName ?? "-"
                )

                InfoBadge(
                    icon: "timer",
                    title: "Rest",
                    value: "\(exercise.defaultRestSeconds)s"
                )
            }
        }
    }
}

struct InfoBadge: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption.weight(.medium))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InstructionsSection: View {
    let instructions: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.book.closed")
                    .foregroundColor(.blue)
                Text("Instructions")
                    .font(.headline)
            }

            Text(instructions)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AITipsSection: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var exerciseViewModel: ExerciseViewModel

    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("AI Trainer")
                    .font(.headline)
            }

            HStack(spacing: 12) {
                Button {
                    loadFormTips()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "figure.stand")
                            .font(.title2)
                        Text("Form Tips")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .foregroundColor(.primary)

                Button {
                    loadVariations()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title2)
                        Text("Alternatives")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .foregroundColor(.primary)
            }

            // Results
            if exerciseViewModel.isLoadingAI {
                HStack {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            if let tips = exerciseViewModel.formTips {
                AIResultCard(title: "Form Tips", content: tips)
            }

            if let variations = exerciseViewModel.variations {
                AIResultCard(title: "Alternatives", content: variations)
            }
        }
    }

    private func loadFormTips() {
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

struct AIResultCard: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PersonalStatsSection: View {
    @EnvironmentObject var progressViewModel: ProgressViewModel

    let exerciseId: String

    var bestPR: PersonalRecord? {
        progressViewModel.getBestPR(for: exerciseId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Stats")
                .font(.headline)

            if let pr = bestPR {
                HStack(spacing: 16) {
                    StatCard(
                        title: "Best Weight",
                        value: "\(pr.weight.weightString) lbs",
                        icon: "trophy.fill",
                        color: .yellow
                    )

                    StatCard(
                        title: "Best Reps",
                        value: "\(pr.reps)",
                        icon: "repeat",
                        color: .green
                    )
                }
            } else {
                Text("Complete this exercise to track your progress!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    ExerciseDetailView(exercise: ExerciseSeedData.exercises.first!)
        .environmentObject(AuthViewModel())
        .environmentObject(ExerciseViewModel())
        .environmentObject(ProgressViewModel())
}
