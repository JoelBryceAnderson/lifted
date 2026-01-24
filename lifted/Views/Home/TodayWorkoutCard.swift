import SwiftUI

struct TodayWorkoutCard: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @EnvironmentObject var progressionViewModel: ProgressionViewModel

    let onStartWorkout: () -> Void
    let onMarkMissed: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if scheduleViewModel.isLoading {
                LoadingView(message: "Loading...")
                    .frame(height: 200)
            } else if isSelectedDayRestDay {
                RestDayCard(date: scheduleViewModel.selectedDate)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .id("rest-\(scheduleViewModel.selectedDate)")
            } else if let session = currentSession {
                WorkoutCard(
                    session: session,
                    date: scheduleViewModel.selectedDate,
                    onStartWorkout: onStartWorkout,
                    onMarkMissed: onMarkMissed
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .id("workout-\(scheduleViewModel.selectedDate)")
            } else {
                NoScheduleCard()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: scheduleViewModel.selectedDate)
    }
    
    private var currentSession: WorkoutSession? {
        // If today is selected, use todaySession
        if scheduleViewModel.selectedDate.isToday {
            return scheduleViewModel.todaySession
        }
        // Otherwise, check if there's an existing session
        if let existingSession = scheduleViewModel.selectedDaySession {
            return existingSession
        }
        // Generate a preview session based on the schedule
        guard let schedule = scheduleViewModel.schedule,
              let workoutType = scheduleViewModel.selectedDayWorkoutType else {
            return nil
        }
        let cycleDay = ScheduleService.shared.getCycleDay(for: scheduleViewModel.selectedDate, schedule: schedule)
        // Create a preview session (not saved to database)
        return WorkoutSession(
            userId: schedule.userId,
            workoutType: workoutType,
            scheduledDate: scheduleViewModel.selectedDate,
            cycleDay: cycleDay,
            status: .scheduled
        )
    }
    
    private var isSelectedDayRestDay: Bool {
        // If there's an actual workout session, it's NOT a rest day (regardless of schedule)
        if scheduleViewModel.selectedDate.isToday {
            if scheduleViewModel.todaySession != nil {
                return false
            }
            return scheduleViewModel.isRestDay
        }
        
        // For other days, check if there's a session first
        if scheduleViewModel.selectedDaySession != nil {
            return false
        }
        return scheduleViewModel.isSelectedDayRestDay
    }
}

struct WorkoutCard: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @State private var showWorkoutTypeChanger = false
    
    let session: WorkoutSession
    let date: Date
    let onStartWorkout: () -> Void
    let onMarkMissed: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutDateTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        WorkoutTypeBadge(session.workoutType, size: .medium)
                        Text(session.workoutType.displayName)
                            .font(.title2.bold())
                    }
                }

                Spacer()

                if session.status == .completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                }
            }

            // Description
            Text(session.workoutType.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Exercise preview
            if !session.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercises")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                    ForEach(session.exercises.prefix(3)) { log in
                        ExercisePreviewRow(exerciseLog: log)
                    }

                    if session.exercises.count > 3 {
                        Text("+ \(session.exercises.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Actions
            if date.isToday {
                switch session.status {
                case .scheduled:
                    HStack(spacing: 12) {
                        Button(action: onMarkMissed) {
                            Text("Skip")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }

                        Button(action: onStartWorkout) {
                            Text("Start Workout")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }

                case .inProgress:
                    Button(action: onStartWorkout) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Continue Workout")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .cornerRadius(12)
                    }

                case .completed:
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Completed")
                    }
                    .font(.headline)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(12)

                default:
                    EmptyView()
                }
            } else {
                // Preview mode for non-today dates
                HStack {
                    Image(systemName: "eye.fill")
                    Text(date.isPast ? "Past Workout" : "Scheduled")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .confirmationDialog(
            "Change Today's Workout",
            isPresented: $showWorkoutTypeChanger,
            titleVisibility: .visible
        ) {
            ForEach([WorkoutType.push, .pull, .legs, .upper, .lower, .fullBody], id: \.self) { workoutType in
                if workoutType != session.workoutType {
                    Button(workoutType.displayName) {
                        Task {
                            await changeWorkoutType(to: workoutType)
                        }
                    }
                }
            }
            
            Button("Make it a Rest Day", role: .destructive) {
                Task {
                    await changeWorkoutToRestDay()
                }
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will update today's workout and reschedule the rest of the week accordingly.")
        }
    }
    
    private func changeWorkoutType(to newType: WorkoutType) async {
        guard let schedule = scheduleViewModel.schedule else {
            return
        }
        
        await scheduleViewModel.changeWorkoutForToday(
            userId: session.userId,
            session: session,
            newWorkoutType: newType,
            schedule: schedule
        )
    }
    
    private func changeWorkoutToRestDay() async {
        guard let schedule = scheduleViewModel.schedule else {
            return
        }
        
        await scheduleViewModel.changeWorkoutToRestDay(
            userId: session.userId,
            session: session,
            schedule: schedule
        )
    }
    
    private var workoutDateTitle: String {
        if date.isToday {
            return "Today's Workout"
        } else if date.isTomorrow {
            return "Tomorrow's Workout"
        } else if date.isYesterday {
            return "Yesterday's Workout"
        } else {
            return date.relativeString
        }
    }
}

struct ExercisePreviewRow: View {
    let exerciseLog: ExerciseLog

    var exercise: Exercise? {
        ExerciseSeedData.exercises.first { $0.id == exerciseLog.exerciseId }
    }

    var body: some View {
        HStack {
            Text(exercise?.name ?? "Exercise")
                .font(.subheadline)

            Spacer()

            Text("\(exerciseLog.workingSets) sets")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct RestDayCard: View {
    @EnvironmentObject var scheduleViewModel: ScheduleViewModel
    @State private var showWorkoutTypeChanger = false
    
    var date: Date = Date()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with change button for today
            HStack {
                Spacer()
                
                if date.isToday {
                    Button {
                        showWorkoutTypeChanger = true
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 8)
            .frame(height: date.isToday ? nil : 0)
            .opacity(date.isToday ? 1 : 0)
            
            Image(systemName: "bed.double.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text(restDayTitle)
                    .font(.title2.bold())

                Text("Recovery is part of progress. Take it easy today!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .confirmationDialog(
            "Change Rest Day to Workout",
            isPresented: $showWorkoutTypeChanger,
            titleVisibility: .visible
        ) {
            ForEach([WorkoutType.push, .pull, .legs, .upper, .lower, .fullBody], id: \.self) { workoutType in
                Button(workoutType.displayName) {
                    Task {
                        await changeRestDayToWorkout(workoutType: workoutType)
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will convert today's rest day into a workout and may reschedule the rest of the week.")
        }
    }
    
    private func changeRestDayToWorkout(workoutType: WorkoutType) async {
        guard let schedule = scheduleViewModel.schedule else {
            return
        }
        
        await scheduleViewModel.changeRestDayToWorkout(
            userId: schedule.userId,
            date: date,
            workoutType: workoutType,
            schedule: schedule
        )
    }
    
    private var restDayTitle: String {
        if date.isToday {
            return "Rest Day"
        } else if date.isTomorrow {
            return "Rest Day Tomorrow"
        } else if date.isYesterday {
            return "Rest Day Yesterday"
        } else {
            return "Rest Day - \(date.relativeString)"
        }
    }
}

struct NoScheduleCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("No Schedule Set")
                    .font(.title2.bold())

                Text("Set up your workout schedule to get started.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

//            NavigationLink(destination: ScheduleEditorView()) {
//                Text("Create Schedule")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 14)
//                    .background(Color.blue)
//                    .cornerRadius(12)
//            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        TodayWorkoutCard(onStartWorkout: {}, onMarkMissed: {})
        RestDayCard()
    }
    .padding()
    .background(Color(.systemGray6))
    .environmentObject(ScheduleViewModel())
    .environmentObject(ProgressionViewModel())
}
