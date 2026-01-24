import SwiftUI

struct WorkoutDetailView: View {
    let session: WorkoutSession
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    WorkoutDetailHeader(session: session)

                    // Stats
                    WorkoutStatsRow(session: session)

                    // Exercises
                    ExercisesSummarySection(exercises: session.exercises)

                    // Notes
                    if let notes = session.notes, !notes.isEmpty {
                        DetailNotesSection(notes: notes)
                    }
                }
                .padding()
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct WorkoutDetailHeader: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 16) {
            WorkoutTypeBadge(session.workoutType, size: .large)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutType.displayName)
                    .font(.title2.bold())

                Text(session.scheduledDate.fullDateString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Status badge
                HStack(spacing: 6) {
                    Image(systemName: session.status.iconName)
                    Text(session.status.displayName)
                }
                .font(.caption.weight(.medium))
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .cornerRadius(8)
            }

            Spacer()
        }
    }

    private var statusColor: Color {
        switch session.status {
        case .completed: return .green
        case .missed: return .red
        case .inProgress: return .orange
        default: return .blue
        }
    }
}

struct WorkoutStatsRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Duration",
                value: session.formattedDuration ?? "-",
                icon: "clock.fill",
                color: .blue
            )

            StatCard(
                title: "Sets",
                value: "\(session.completedSets)/\(session.totalSets)",
                icon: "list.bullet",
                color: .green
            )

            StatCard(
                title: "Volume",
                value: session.totalVolume.volumeString,
                icon: "scalemass.fill",
                color: .purple
            )
        }
    }
}

struct ExercisesSummarySection: View {
    let exercises: [ExerciseLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.headline)

            ForEach(exercises) { log in
                ExerciseSummaryCard(exerciseLog: log)
            }
        }
    }
}

struct ExerciseSummaryCard: View {
    let exerciseLog: ExerciseLog

    var exercise: Exercise? {
        ExerciseSeedData.exercises.first { $0.id == exerciseLog.exerciseId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(exercise?.name ?? "Exercise")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(exerciseLog.completedSets)/\(exerciseLog.workingSets) sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Sets summary
            VStack(spacing: 4) {
                ForEach(Array(exerciseLog.sets.filter { !$0.isWarmup }.enumerated()), id: \.element.id) { index, set in
                    SetSummaryRow(set: set, setNumber: index + 1)
                }
            }

            // Notes
            if let notes = exerciseLog.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct DetailNotesSection: View {
    let notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.secondary)
                Text("Notes")
                    .font(.headline)
            }

            Text(notes)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
}

#Preview {
    WorkoutDetailView(
        session: WorkoutSession(
            userId: "test",
            workoutType: .push,
            scheduledDate: Date(),
            cycleDay: 0,
            startedAt: Date().addingTimeInterval(-3600),
            completedAt: Date(),
            status: .completed,
            exercises: [
                ExerciseLog(
                    exerciseId: "bench-press",
                    sets: [
                        ExerciseSet(targetReps: 10, actualReps: 10, targetWeight: 135, actualWeight: 135, rpe: 8, completedAt: Date()),
                        ExerciseSet(targetReps: 10, actualReps: 10, targetWeight: 135, actualWeight: 135, rpe: 8, completedAt: Date()),
                        ExerciseSet(targetReps: 10, actualReps: 8, targetWeight: 135, actualWeight: 135, rpe: 9, completedAt: Date())
                    ]
                )
            ],
            notes: "Good workout, felt strong today."
        )
    )
}
