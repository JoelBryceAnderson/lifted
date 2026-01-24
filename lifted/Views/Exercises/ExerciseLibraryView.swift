import SwiftUI

struct ExerciseLibraryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var exerciseViewModel: ExerciseViewModel

    @State private var selectedExercise: Exercise?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $exerciseViewModel.searchQuery)
                    .padding()

                // Filters
                FilterChipsView()

                // Exercise list
                if exerciseViewModel.isLoading {
                    LoadingView(message: "Loading exercises...")
                } else if exerciseViewModel.filteredExercises.isEmpty {
                    EmptySearchView()
                } else {
                    ExerciseListView(
                        onSelectExercise: { exercise in
                            selectedExercise = exercise
                        }
                    )
                }
            }
            .navigationTitle("Exercises")
            .task {
                await exerciseViewModel.loadExercises()
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search exercises...", text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FilterChipsView: View {
    @EnvironmentObject var exerciseViewModel: ExerciseViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Muscle group filter
                FilterMenu(
                    title: exerciseViewModel.selectedMuscleGroup?.displayName ?? "Muscle",
                    isActive: exerciseViewModel.selectedMuscleGroup != nil
                ) {
                    Button("All Muscles") {
                        exerciseViewModel.selectedMuscleGroup = nil
                    }
                    Divider()
                    ForEach(MuscleGroup.allCases, id: \.self) { group in
                        Button(group.displayName) {
                            exerciseViewModel.selectedMuscleGroup = group
                        }
                    }
                }

                // Equipment filter
                FilterMenu(
                    title: exerciseViewModel.selectedEquipment?.displayName ?? "Equipment",
                    isActive: exerciseViewModel.selectedEquipment != nil
                ) {
                    Button("All Equipment") {
                        exerciseViewModel.selectedEquipment = nil
                    }
                    Divider()
                    ForEach(Equipment.allCases, id: \.self) { equipment in
                        Button(equipment.displayName) {
                            exerciseViewModel.selectedEquipment = equipment
                        }
                    }
                }

                // Category filter
                FilterMenu(
                    title: exerciseViewModel.selectedCategory?.displayName ?? "Type",
                    isActive: exerciseViewModel.selectedCategory != nil
                ) {
                    Button("All Types") {
                        exerciseViewModel.selectedCategory = nil
                    }
                    Divider()
                    ForEach(ExerciseCategory.allCases, id: \.self) { category in
                        Button(category.displayName) {
                            exerciseViewModel.selectedCategory = category
                        }
                    }
                }

                // Clear filters
                if exerciseViewModel.selectedMuscleGroup != nil ||
                   exerciseViewModel.selectedEquipment != nil ||
                   exerciseViewModel.selectedCategory != nil {
                    Button {
                        exerciseViewModel.clearFilters()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("Clear")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

struct FilterMenu<Content: View>: View {
    let title: String
    let isActive: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? Color.blue : Color(.systemGray6))
            .foregroundColor(isActive ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct ExerciseListView: View {
    @EnvironmentObject var exerciseViewModel: ExerciseViewModel

    let onSelectExercise: (Exercise) -> Void

    var body: some View {
        List(exerciseViewModel.filteredExercises) { exercise in
            ExerciseRow(exercise: exercise) {
                onSelectExercise(exercise)
            }
        }
        .listStyle(.plain)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category indicator
                Circle()
                    .fill(exercise.category == .compound ? Color.blue : Color.green)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Label(exercise.equipment.displayName, systemImage: "dumbbell.fill")
                        Text("•")
                        Text(exercise.muscleGroups.map { $0.displayName }.joined(separator: ", "))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

struct EmptySearchView: View {
    @EnvironmentObject var exerciseViewModel: ExerciseViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No exercises found")
                .font(.headline)

            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                exerciseViewModel.clearFilters()
            } label: {
                Text("Clear Filters")
                    .font(.subheadline.weight(.medium))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ExerciseLibraryView()
        .environmentObject(AuthViewModel())
        .environmentObject(ExerciseViewModel())
}
