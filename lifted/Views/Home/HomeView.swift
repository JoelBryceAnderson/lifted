import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var progressionViewModel: ProgressionViewModel
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    @EnvironmentObject var trainerViewModel: TrainerViewModel

    @State private var showActiveWorkout = false
    @State private var showProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Week Calendar Strip
                    WeekCalendarStrip()
                        .padding(.top)

                    // Today's Workout Card
                    TodayWorkoutCard(
                        onStartWorkout: startWorkout,
                        onMarkMissed: markAsMissed
                    )
                    .padding(.horizontal)

                    // Quick Stats
                    QuickStatsSection()
                        .padding(.horizontal)

                    // AI Optimize Button
                    AIOptimizeSection()
                        .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Lifted")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .fullScreenCover(isPresented: $showActiveWorkout) {
                if let session = workoutViewModel.currentSession {
                    ActiveWorkoutView(session: session)
                }
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
            .onChange(of: scheduleViewModel.currentWeekStart) { _, _ in
                guard let userId = authViewModel.user?.id else { return }
                Task {
                    await scheduleViewModel.loadWeekSessions(userId: userId)
                }
            }
        }
    }

    private func loadData() async {
        guard let userId = authViewModel.user?.id else { return }
        await scheduleViewModel.loadSchedule(userId: userId)
        await progressionViewModel.loadProgressionData(userId: userId)
    }

    private func startWorkout() {
        guard let userId = authViewModel.user?.id,
              let session = scheduleViewModel.todaySession else { return }

        Task {
            await workoutViewModel.startWorkout(
                session: session,
                progressionPlan: progressionViewModel.progressionPlan
            )
            showActiveWorkout = true
        }
    }

    private func markAsMissed() {
        guard let userId = authViewModel.user?.id else { return }

        Task {
            await scheduleViewModel.markDayAsMissed(userId: userId)
        }
    }
}

struct QuickStatsSection: View {
    @EnvironmentObject var progressionViewModel: ProgressionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            HStack(spacing: 12) {
                StatCard(
                    title: "Weeks Active",
                    value: "\(progressionViewModel.weeksSinceStart)",
                    icon: "calendar",
                    color: .blue
                )

                StatCard(
                    title: "Until Deload",
                    value: "\(progressionViewModel.weeksUntilDeload) wks",
                    icon: "arrow.down.circle",
                    color: progressionViewModel.needsDeload ? .orange : .green
                )
            }
        }
    }
}

struct AIOptimizeSection: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var trainerViewModel: TrainerViewModel
    @State private var showOptimization = false

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

            Button {
                showOptimization = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Optimize My Week")
                            .font(.subheadline.weight(.medium))
                        Text("Get AI suggestions for your schedule")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .foregroundColor(.primary)
        }
        .sheet(isPresented: $showOptimization) {
            ScheduleOptimizationSheet()
        }
    }
}

struct ScheduleOptimizationSheet: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var trainerViewModel: TrainerViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                if trainerViewModel.isSending {
                    LoadingView(message: "Analyzing your schedule...")
                } else if let lastMessage = trainerViewModel.messages.last, lastMessage.role == .assistant {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(lastMessage.content)
                                .font(.body)

                            if let actions = lastMessage.proposedActions, !actions.isEmpty {
                                ForEach(actions) { action in
                                    ProposedActionCard(action: action)
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Ready to optimize your schedule?")
                            .font(.headline)

                        Text("The AI trainer will analyze your recent workouts and suggest improvements.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            if let userId = authViewModel.user?.id {
                                Task {
                                    await trainerViewModel.optimizeSchedule(userId: userId)
                                }
                            }
                        } label: {
                            Text("Optimize Now")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Schedule Optimization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
        .environmentObject(ScheduleViewModel())
        .environmentObject(ProgressionViewModel())
        .environmentObject(WorkoutViewModel())
        .environmentObject(TrainerViewModel())
}
