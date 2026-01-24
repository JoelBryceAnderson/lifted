import SwiftUI

struct SetInputRow: View {
    let setNumber: Int
    let isWarmup: Bool
    let targetWeight: Double
    let targetReps: Int
    @Binding var actualWeight: String
    @Binding var actualReps: String
    @Binding var rpe: Int?
    let isCompleted: Bool
    let onComplete: () -> Void

    @State private var checkmarkScale: CGFloat = 1.0
    @State private var showCompletionFlash = false

    var body: some View {
        HStack(spacing: 12) {
            // Set indicator
            VStack(spacing: 2) {
                if isWarmup {
                    Text("W")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.orange)
                } else {
                    Text("\(setNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isCompleted ? .green : .primary)
                }
            }
            .frame(width: 28)

            // Target info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(targetWeight.weightString) lbs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(targetReps) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .leading)

            // Weight input
            TextField("Weight", text: $actualWeight)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
                .disabled(isCompleted)

            // Reps input
            TextField("Reps", text: $actualReps)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)
                .disabled(isCompleted)

            // RPE selector (only for working sets)
            if !isWarmup {
                RPESelector(rpe: $rpe)
                    .disabled(isCompleted)
            }

            Spacer()

            // Complete button with animation
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    checkmarkScale = 1.3
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
                    checkmarkScale = 1.0
                }
                showCompletionFlash = true
                onComplete()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .green : .gray)
                    .scaleEffect(checkmarkScale)
            }
            .disabled(isCompleted)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            ZStack {
                Color(isCompleted ? .green.opacity(0.1) : .blue.opacity(0.1))

                if showCompletionFlash {
                    Color.green.opacity(0.2)
                        .transition(.opacity)
                }
            }
        )
        .cornerRadius(8)
        .animation(.easeOut(duration: 0.3), value: isCompleted)
        .onChange(of: showCompletionFlash) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        showCompletionFlash = false
                    }
                }
            }
        }
    }
}

struct RPESelector: View {
    @Binding var rpe: Int?

    var body: some View {
        Menu {
            ForEach((6...10).reversed(), id: \.self) { value in
                Button {
                    rpe = value
                } label: {
                    Text("RPE \(value)")
                }
            }

            Button {
                rpe = nil
            } label: {
                Text("Clear")
            }
        } label: {
            HStack(spacing: 4) {
                if let rpe = rpe {
                    Text("\(rpe)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(rpeColor(rpe))
                } else {
                    Text("RPE")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        }
    }

    private func rpeColor(_ value: Int) -> Color {
        switch value {
        case 1...5: return .green
        case 6...7: return .yellow
        case 8: return .orange
        case 9...10: return .red
        default: return .primary
        }
    }
}

struct SetSummaryRow: View {
    let set: ExerciseSet
    let setNumber: Int

    var body: some View {
        HStack(spacing: 16) {
            // Set number
            Text(set.isWarmup ? "W" : "\(setNumber)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(set.isWarmup ? .orange : .primary)
                .frame(width: 24)

            // Weight and reps
            if let weight = set.actualWeight, let reps = set.actualReps {
                Text("\(weight.weightString) lbs")
                    .font(.subheadline)
                Text("×")
                    .foregroundColor(.secondary)
                Text("\(reps) reps")
                    .font(.subheadline)
            } else {
                Text("\(set.targetWeight.weightString) lbs × \(set.targetReps)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // RPE badge
            if let rpe = set.rpe {
                Text("RPE \(rpe)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(rpeColor(rpe))
                    .cornerRadius(12)
            }

            // Completion status
            if set.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private func rpeColor(_ value: Int) -> Color {
        switch value {
        case 1...5: return .green
        case 6...7: return .yellow
        case 8: return .orange
        case 9...10: return .red
        default: return .gray
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SetInputRow(
            setNumber: 1,
            isWarmup: true,
            targetWeight: 45,
            targetReps: 10,
            actualWeight: .constant("45"),
            actualReps: .constant("10"),
            rpe: .constant(nil),
            isCompleted: false
        ) {}

        SetInputRow(
            setNumber: 1,
            isWarmup: false,
            targetWeight: 135,
            targetReps: 10,
            actualWeight: .constant("135"),
            actualReps: .constant("10"),
            rpe: .constant(8),
            isCompleted: true
        ) {}

        Divider()

        SetSummaryRow(
            set: ExerciseSet(targetReps: 10, actualReps: 10, targetWeight: 135, actualWeight: 135, rpe: 8, completedAt: Date()),
            setNumber: 1
        )
    }
    .padding()
}
