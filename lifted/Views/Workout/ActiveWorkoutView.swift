import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    let session: WorkoutSession

    @State private var showCancelConfirmation = false
    @State private var showCompleteConfirmation = false

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(workoutViewModel.currentExercise?.name ?? "Workout")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                .alert("Cancel Workout?", isPresented: $showCancelConfirmation) {
                    cancelAlertButtons
                } message: {
                    Text("Your progress will not be saved.")
                }
                .alert("Finish Workout?", isPresented: $showCompleteConfirmation) {
                    completeAlertButtons
                } message: {
                    Text("This will save your workout and mark it as complete.")
                }
                .prCelebration(info: $workoutViewModel.prCelebrationInfo)
                .onChange(of: workoutViewModel.prCelebrationInfo) { _, newValue in
                    handlePRCelebrationChange(newValue)
                }
                .onChange(of: workoutViewModel.currentSession) { _, newValue in
                    handleSessionChange(newValue)
                }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Progress bar
            WorkoutProgressBar(
                current: workoutViewModel.currentExerciseIndex + 1,
                total: session.exercises.count,
                completionPercentage: workoutViewModel.completionPercentage
            )

            // Main content
            exerciseContent

            Spacer()

            // Rest timer (if active)
            if workoutViewModel.isRestTimerActive {
                RestTimerView()
            }

            // Navigation controls
            ExerciseNavigationControls()
        }
    }
    
    @ViewBuilder
    private var exerciseContent: some View {
        if let exerciseLog = workoutViewModel.currentExerciseLog {
            ExerciseLogView(exerciseLog: exerciseLog)
        } else {
            LoadingView(message: "Loading exercise...")
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                showCancelConfirmation = true
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button("Finish") {
                showCompleteConfirmation = true
            }
            .fontWeight(.semibold)
        }
    }
    
    @ViewBuilder
    private var cancelAlertButtons: some View {
        Button("Keep Going", role: .cancel) {}
        Button("Cancel Workout", role: .destructive) {
            Task {
                await workoutViewModel.cancelWorkout()
                dismiss()
            }
        }
    }
    
    @ViewBuilder
    private var completeAlertButtons: some View {
        Button("Keep Going", role: .cancel) {}
        Button("Finish") {
            Task {
                await workoutViewModel.completeWorkout()
            }
        }
    }
    
    private func handlePRCelebrationChange(_ newValue: PRCelebrationInfo?) {
        // Dismiss the view after PR celebration is dismissed
        if newValue == nil && workoutViewModel.currentSession == nil {
            dismiss()
        }
    }
    
    private func handleSessionChange(_ newValue: WorkoutSession?) {
        // Dismiss if session ended without PR
        if newValue == nil && workoutViewModel.prCelebrationInfo == nil {
            dismiss()
        }
    }
}

struct WorkoutProgressBar: View {
    let current: Int
    let total: Int
    let completionPercentage: Double

    @State private var animatedPercentage: Double = 0

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedPercentage)
                }
            }
            .frame(height: 4)
            .clipShape(Capsule())

            HStack {
                Text("Exercise \(current) of \(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(animatedPercentage * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animatedPercentage = completionPercentage
            }
        }
        .onChange(of: completionPercentage) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animatedPercentage = newValue
            }
        }
    }
}

struct ExerciseNavigationControls: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel

    var body: some View {
        HStack(spacing: 16) {
            Button {
                workoutViewModel.previousExercise()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .disabled(workoutViewModel.currentExerciseIndex == 0)

            // Exercise dots
            HStack(spacing: 6) {
                ForEach(0..<min(workoutViewModel.currentSession?.exercises.count ?? 0, 7), id: \.self) { index in
                    Circle()
                        .fill(index == workoutViewModel.currentExerciseIndex ? Color.blue : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }

                if (workoutViewModel.currentSession?.exercises.count ?? 0) > 7 {
                    Text("...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                workoutViewModel.nextExercise()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .disabled(workoutViewModel.currentExerciseIndex >= (workoutViewModel.currentSession?.exercises.count ?? 0) - 1)
        }
        .padding()
    }
}

#Preview {
    ActiveWorkoutView(
        session: WorkoutSession(
            userId: "test",
            workoutType: .push,
            scheduledDate: Date(),
            cycleDay: 0
        )
    )
    .environmentObject(WorkoutViewModel())
    .environmentObject(AuthViewModel())
}
