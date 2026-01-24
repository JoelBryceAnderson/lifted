import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var progressionViewModel: ProgressionViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            List {
                // User info section
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.user?.displayName ?? "User")
                                .font(.headline)

                            Text(authViewModel.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Schedule section
//                Section("Workout Schedule") {
//                    NavigationLink(destination: ScheduleEditorView()) {
//                        Label("Edit Schedule", systemImage: "calendar")
//                    }
//                }

                // Progression section
                Section("Progression") {
//                    NavigationLink(destination: ProgressionSettingsView()) {
//                        HStack {
//                            Label("Goal & Settings", systemImage: "target")
//                            Spacer()
//                            if let goal = progressionViewModel.currentGoal {
//                                Text(goal.displayName)
//                                    .font(.subheadline)
//                                    .foregroundColor(.secondary)
//                            }
//                        }
//                    }

                    NavigationLink(destination: StartingWeightsEditorView()) {
                        Label("Starting Weights", systemImage: "scalemass")
                    }
                }

                // Preferences section
                Section("Preferences") {
                    NavigationLink(destination: PreferencesView()) {
                        Label("App Settings", systemImage: "gear")
                    }

                    NavigationLink(destination: TrainerNotesListView()) {
                        Label("Trainer Notes", systemImage: "note.text")
                    }
                }

                // Account section
                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Sign Out?", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .task {
                if let userId = authViewModel.user?.id {
                    await progressionViewModel.loadProgressionData(userId: userId)
                }
            }
        }
    }
}

struct PreferencesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var units: WeightUnit = .lbs
    @State private var defaultRestSeconds: Double = 90
    @State private var showWarmupSets = true
    @State private var hapticFeedback = true
    @State private var autoStartRestTimer = true

    var body: some View {
        List {
            Section("Units") {
                Picker("Weight Unit", selection: $units) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
            }

            Section("Rest Timer") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Default Rest Time")
                        Spacer()
                        Text("\(Int(defaultRestSeconds))s")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $defaultRestSeconds, in: 30...300, step: 15)
                }

                Toggle("Auto-start Rest Timer", isOn: $autoStartRestTimer)
            }

            Section("Workout") {
                Toggle("Show Warmup Sets", isOn: $showWarmupSets)
            }

            Section("Feedback") {
                Toggle("Haptic Feedback", isOn: $hapticFeedback)
            }
        }
        .navigationTitle("Preferences")
        .onAppear {
            if let prefs = authViewModel.user?.preferences {
                units = prefs.units
                defaultRestSeconds = Double(prefs.defaultRestSeconds)
                showWarmupSets = prefs.showWarmupSets
                hapticFeedback = prefs.hapticFeedbackEnabled
                autoStartRestTimer = prefs.autoStartRestTimer
            }
        }
        .onChange(of: units) { _, _ in savePreferences() }
        .onChange(of: defaultRestSeconds) { _, _ in savePreferences() }
        .onChange(of: showWarmupSets) { _, _ in savePreferences() }
        .onChange(of: hapticFeedback) { _, _ in savePreferences() }
        .onChange(of: autoStartRestTimer) { _, _ in savePreferences() }
    }

    private func savePreferences() {
        let preferences = UserPreferences(
            units: units,
            defaultRestSeconds: Int(defaultRestSeconds),
            showWarmupSets: showWarmupSets,
            hapticFeedbackEnabled: hapticFeedback,
            autoStartRestTimer: autoStartRestTimer
        )

        Task {
            await authViewModel.updateUserPreferences(preferences)
        }
    }
}

struct StartingWeightsEditorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var progressionViewModel: ProgressionViewModel

    var body: some View {
        List {
            ForEach(progressionViewModel.exerciseProgressions) { progression in
                if let exercise = ExerciseSeedData.exercises.first(where: { $0.id == progression.exerciseId }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.subheadline.weight(.medium))

                            Text(exercise.category.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(progression.currentTargetWeight.weightString) lbs")
                                .font(.subheadline)

                            Text("+\(progression.weeklyIncrement.weightString)/wk")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .navigationTitle("Starting Weights")
        .task {
            if let userId = authViewModel.user?.id {
                await progressionViewModel.loadProgressionData(userId: userId)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(ProgressionViewModel())
}
