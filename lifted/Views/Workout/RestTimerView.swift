import SwiftUI

struct RestTimerView: View {
    @EnvironmentObject var workoutViewModel: WorkoutViewModel

    var progress: Double {
        guard workoutViewModel.currentRestDuration > 0 else { return 0 }
        return 1 - (workoutViewModel.restTimeRemaining / workoutViewModel.currentRestDuration)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Timer display
            HStack(spacing: 24) {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(timerColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)

                    VStack(spacing: 2) {
                        Text(timeString)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))

                        Text("REST")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                // Quick actions
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        TimerButton(title: "+15s") {
                            workoutViewModel.addRestTime(15)
                            Haptics.light()
                        }

                        TimerButton(title: "+30s") {
                            workoutViewModel.addRestTime(30)
                            Haptics.light()
                        }
                    }

                    Button {
                        workoutViewModel.skipRestTimer()
                        Haptics.medium()
                    } label: {
                        Text("Skip")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    private var timeString: String {
        let minutes = Int(workoutViewModel.restTimeRemaining) / 60
        let seconds = Int(workoutViewModel.restTimeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var timerColor: Color {
        if workoutViewModel.restTimeRemaining <= 10 {
            return .green
        } else if workoutViewModel.restTimeRemaining <= 30 {
            return .orange
        }
        return .blue
    }
}

struct TimerButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

struct RestTimerSettingsView: View {
    @Binding var duration: TimeInterval
    let onDismiss: () -> Void

    let presets: [TimeInterval] = [60, 90, 120, 150, 180, 240]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Default Rest Time")
                    .font(.headline)

                // Current value
                Text(duration.formattedDuration)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)

                // Presets
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            duration = preset
                            Haptics.selection()
                        } label: {
                            Text(preset.shortDuration)
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(duration == preset ? Color.blue : Color(.systemGray6))
                                .foregroundColor(duration == preset ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }

                // Slider
                VStack(spacing: 8) {
                    Slider(value: $duration, in: 30...300, step: 15)

                    HStack {
                        Text("30s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("5m")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Exercise type info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Rest Times")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        RestRecommendation(title: "Compound", time: "2-3 min")
                        RestRecommendation(title: "Isolation", time: "60-90 sec")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Spacer()
            }
            .padding()
            .navigationTitle("Rest Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }
}

struct RestRecommendation: View {
    let title: String
    let time: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(time)
                .font(.subheadline.weight(.medium))
        }
    }
}

struct SetRowView: View {
    let setNumber: Int
    let set: ExerciseSet

    var body: some View {
        HStack(spacing: 16) {
            // Set number
            Text(set.isWarmup ? "W" : "\(setNumber)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(set.isWarmup ? .orange : .primary)
                .frame(width: 28)

            // Weight
            VStack(alignment: .leading, spacing: 2) {
                Text("Weight")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(set.targetWeight.weightString) lbs")
                    .font(.subheadline)
            }

            // Reps
            VStack(alignment: .leading, spacing: 2) {
                Text("Reps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(set.targetReps)")
                    .font(.subheadline)
            }

            Spacer()

            // Status
            if set.isCompleted {
                HStack(spacing: 4) {
                    if let actualWeight = set.actualWeight, let actualReps = set.actualReps {
                        Text("\(actualWeight.weightString) × \(actualReps)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 20) {
        RestTimerView()

        RestTimerSettingsView(duration: .constant(90)) {}
    }
    .environmentObject(WorkoutViewModel())
}
