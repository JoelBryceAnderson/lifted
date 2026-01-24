import SwiftUI
import Charts

struct ProgressDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var progressViewModel: ProgressViewModel
    @EnvironmentObject var exerciseViewModel: ExerciseViewModel

    @State private var selectedExercise: Exercise?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview stats
                    OverviewStatsSection()

                    // Personal Records
                    PRListView()

                    // Exercise Progress
                    ExerciseProgressSection(
                        selectedExercise: $selectedExercise
                    )
                }
                .padding()
            }
            .navigationTitle("Progress")
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }

    private func loadData() async {
        guard let userId = authViewModel.user?.id else { return }
        await progressViewModel.loadProgressData(userId: userId)
        await exerciseViewModel.loadExercises()
    }
}

struct OverviewStatsSection: View {
    @EnvironmentObject var progressViewModel: ProgressViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                LargeStatCard(
                    title: "Total Workouts",
                    value: "\(progressViewModel.totalWorkouts)",
                    trend: nil,
                    icon: "flame.fill",
                    color: .orange
                )

                LargeStatCard(
                    title: "Current Streak",
                    value: "\(progressViewModel.currentStreak) days",
                    trend: nil,
                    icon: "bolt.fill",
                    color: .yellow
                )

                LargeStatCard(
                    title: "Total Volume",
                    value: progressViewModel.totalVolume.volumeString + " lbs",
                    trend: nil,
                    icon: "scalemass.fill",
                    color: .blue
                )

                LargeStatCard(
                    title: "Avg Duration",
                    value: progressViewModel.averageSessionDuration.shortDuration,
                    trend: nil,
                    icon: "clock.fill",
                    color: .purple
                )
            }
        }
    }
}

struct PRListView: View {
    @EnvironmentObject var progressViewModel: ProgressViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(.headline)

            if progressViewModel.recentPRs.isEmpty {
                Text("Complete workouts to set PRs!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                ForEach(progressViewModel.recentPRs) { pr in
                    PRRow(personalRecord: pr)
                }
            }
        }
    }
}

struct PRRow: View {
    let personalRecord: PersonalRecord

    var exercise: Exercise? {
        ExerciseSeedData.exercises.first { $0.id == personalRecord.exerciseId }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .foregroundColor(.yellow)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise?.name ?? "Exercise")
                    .font(.subheadline.weight(.medium))

                Text(personalRecord.date.relativeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(personalRecord.weight.weightString) lbs")
                    .font(.subheadline.weight(.semibold))

                Text("\(personalRecord.reps) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ExerciseProgressSection: View {
    @EnvironmentObject var exerciseViewModel: ExerciseViewModel
    @Binding var selectedExercise: Exercise?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise Progress")
                .font(.headline)

            // Exercise picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ExerciseSeedData.getCompoundExercises().prefix(10)) { exercise in
                        Button {
                            selectedExercise = exercise
                        } label: {
                            Text(exercise.name)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedExercise?.id == exercise.id ? Color.blue : Color(.systemGray6))
                                .foregroundColor(selectedExercise?.id == exercise.id ? .white : .primary)
                                .cornerRadius(16)
                        }
                    }
                }
            }

            // Chart
            if let exercise = selectedExercise {
                ExerciseChartView(exercise: exercise)
            } else {
                Text("Select an exercise to see your progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(32)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    ProgressDashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(ProgressViewModel())
        .environmentObject(ExerciseViewModel())
}
