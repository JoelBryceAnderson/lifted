import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var progressViewModel: ProgressViewModel

    @State private var selectedSession: WorkoutSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Calendar View
                    CalendarView(
                        sessions: progressViewModel.workoutSessions,
                        onSelectSession: { session in
                            selectedSession = session
                        }
                    )

                    // Recent Workouts
                    RecentWorkoutsSection(
                        sessions: progressViewModel.completedSessions,
                        onSelectSession: { session in
                            selectedSession = session
                        }
                    )
                }
                .padding()
            }
            .navigationTitle("History")
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
            .sheet(item: $selectedSession) { session in
                WorkoutDetailView(session: session)
            }
        }
    }

    private func loadData() async {
        guard let userId = authViewModel.user?.id else { return }
        await progressViewModel.loadProgressData(userId: userId)
    }
}

struct RecentWorkoutsSection: View {
    let sessions: [WorkoutSession]
    let onSelectSession: (WorkoutSession) -> Void

    var recentSessions: [WorkoutSession] {
        sessions.sorted { $0.scheduledDate > $1.scheduledDate }.prefix(10).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)

            if recentSessions.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.clock",
                    title: "No Workouts Yet",
                    message: "Complete your first workout to see it here."
                )
            } else {
                ForEach(recentSessions) { session in
                    WorkoutHistoryRow(session: session) {
                        onSelectSession(session)
                    }
                }
            }
        }
    }
}

struct WorkoutHistoryRow: View {
    let session: WorkoutSession
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Type badge
                WorkoutTypeBadge(session.workoutType, size: .medium)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.workoutType.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(session.scheduledDate.fullDateString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Stats
                VStack(alignment: .trailing, spacing: 4) {
                    if let duration = session.formattedDuration {
                        Text(duration)
                            .font(.subheadline.weight(.medium))
                    }

                    Text("\(session.totalSets) sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    HistoryView()
        .environmentObject(AuthViewModel())
        .environmentObject(ProgressViewModel())
}
