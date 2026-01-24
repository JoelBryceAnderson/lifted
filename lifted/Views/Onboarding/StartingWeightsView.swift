import SwiftUI

struct StartingWeightsView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Starting Weights")
                    .font(.largeTitle.bold())

                Text("Optional: Set your current working weights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 24) {
                    // Info card
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("What's a working weight?")
                                .font(.subheadline.weight(.semibold))

                            Text("The weight you can lift for your target reps with good form. This becomes your baseline for progression.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Exercise inputs
                    VStack(spacing: 16) {
                        ForEach(onboardingViewModel.keyExercises, id: \.id) { exercise in
                            WeightInputRow(
                                exerciseName: exercise.name,
                                weight: Binding(
                                    get: {
                                        onboardingViewModel.startingWeights[exercise.id] ?? 0
                                    },
                                    set: { newValue in
                                        if newValue > 0 {
                                            onboardingViewModel.setStartingWeight(for: exercise.id, weight: newValue)
                                        } else {
                                            onboardingViewModel.startingWeights.removeValue(forKey: exercise.id)
                                        }
                                    }
                                )
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Skip hint
                    Text("You can always set or update these later in Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }

            Spacer()

            OnboardingNavigationButtons(
                nextTitle: onboardingViewModel.startingWeights.isEmpty ? "Skip" : "Continue"
            )
        }
    }
}

struct WeightInputRow: View {
    let exerciseName: String
    @Binding var weight: Double
    @State private var weightText = ""

    var body: some View {
        HStack {
            Text(exerciseName)
                .font(.subheadline.weight(.medium))

            Spacer()

            HStack(spacing: 8) {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: weightText) { _, newValue in
                        if let value = Double(newValue) {
                            weight = value
                        }
                    }
                    .onAppear {
                        if weight > 0 {
                            weightText = weight.weightString
                        }
                    }

                Text("lbs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    StartingWeightsView()
        .environmentObject(OnboardingViewModel())
}
