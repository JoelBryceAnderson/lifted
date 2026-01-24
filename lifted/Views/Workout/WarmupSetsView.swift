import SwiftUI

struct WarmupSetsView: View {
    let sets: [ExerciseSet]
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Warmup Sets")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("(\(sets.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                        WarmupSetRow(set: set, setNumber: index + 1)
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct WarmupSetRow: View {
    let set: ExerciseSet
    let setNumber: Int

    var body: some View {
        HStack {
            // Set indicator
            Text("W\(setNumber)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.orange)
                .frame(width: 32)

            // Weight
            Text("\(set.targetWeight.weightString) lbs")
                .font(.subheadline)

            Text("×")
                .foregroundColor(.secondary)

            // Reps
            Text("\(set.targetReps) reps")
                .font(.subheadline)

            Spacer()

            // Percentage badge
            if set.targetWeight > 0 {
                Text("Warmup")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }

            // Completion indicator
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(set.isCompleted ? .green : .gray)
        }
        .padding(.vertical, 4)
    }
}

struct WarmupInfoCard: View {
    let workingWeight: Double

    var warmupSets: [WarmupSetInfo] {
        var sets: [WarmupSetInfo] = []

        if workingWeight > 45 {
            sets.append(WarmupSetInfo(percentage: "Bar", weight: 45, reps: 10))
        }
        if workingWeight > 90 {
            sets.append(WarmupSetInfo(percentage: "50%", weight: workingWeight * 0.5, reps: 8))
        }
        if workingWeight > 115 {
            sets.append(WarmupSetInfo(percentage: "70%", weight: workingWeight * 0.7, reps: 5))
        }
        if workingWeight > 135 {
            sets.append(WarmupSetInfo(percentage: "85%", weight: workingWeight * 0.85, reps: 3))
        }

        return sets
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Warmup Protocol")
                    .font(.headline)
            }

            Text("Warming up properly prepares your muscles and joints for heavy lifting, reducing injury risk and improving performance.")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            VStack(spacing: 8) {
                ForEach(warmupSets) { set in
                    HStack {
                        Text(set.percentage)
                            .font(.caption.weight(.medium))
                            .frame(width: 40, alignment: .leading)

                        Text("\(set.weight.rounded(toNearest: 2.5).weightString) lbs")
                            .font(.subheadline)

                        Text("×")
                            .foregroundColor(.secondary)

                        Text("\(set.reps) reps")
                            .font(.subheadline)

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct WarmupSetInfo: Identifiable {
    let id = UUID()
    let percentage: String
    let weight: Double
    let reps: Int
}

#Preview {
    VStack(spacing: 20) {
        WarmupSetsView(sets: [
            ExerciseSet(targetReps: 10, targetWeight: 45, isWarmup: true),
            ExerciseSet(targetReps: 8, targetWeight: 67.5, isWarmup: true),
            ExerciseSet(targetReps: 5, targetWeight: 95, isWarmup: true)
        ])

        WarmupInfoCard(workingWeight: 135)
            .padding(.horizontal)
    }
}
