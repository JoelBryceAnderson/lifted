import SwiftUI

struct TrainerNotesIntroView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Tell Your Trainer")
                    .font(.largeTitle.bold())

                Text("Optional: Share anything that affects your training")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 24) {
                    // Categories explanation
                    VStack(spacing: 12) {
                        ForEach(NoteCategory.allCases, id: \.self) { category in
                            NoteCategoryRow(category: category)
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Add note section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add a Note")
                            .font(.headline)
                            .padding(.horizontal)

                        // Category picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(NoteCategory.allCases, id: \.self) { category in
                                    CategoryChip(
                                        category: category,
                                        isSelected: onboardingViewModel.newNoteCategory == category
                                    ) {
                                        onboardingViewModel.newNoteCategory = category
                                        Haptics.selection()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Note input
                        HStack {
                            TextField("e.g., \"Bad left knee from old injury\"", text: $onboardingViewModel.newNoteContent)
                                .textFieldStyle(.roundedBorder)

                            Button {
                                if let userId = authViewModel.user?.id {
                                    onboardingViewModel.addTrainerNote(userId: userId)
                                    Haptics.success()
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .disabled(onboardingViewModel.newNoteContent.trimmed.isEmpty)
                        }
                        .padding(.horizontal)
                    }

                    // Added notes
                    if !onboardingViewModel.trainerNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Notes")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(Array(onboardingViewModel.trainerNotes.enumerated()), id: \.element.id) { index, note in
                                TrainerNoteRow(note: note) {
                                    onboardingViewModel.removeTrainerNote(at: index)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }

            Spacer()

            OnboardingNavigationButtons(
                nextTitle: "Finish Setup",
                isLoading: onboardingViewModel.isLoading
            ) {
                Task {
                    if let userId = authViewModel.user?.id {
                        let success = await onboardingViewModel.completeOnboarding(userId: userId)
                        if success {
                            await authViewModel.completeOnboarding()
                        }
                    }
                }
            }
        }
    }
}

struct NoteCategoryRow: View {
    let category: NoteCategory

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.iconName)
                .font(.title3)
                .foregroundColor(Color.noteCategory(category))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.subheadline.weight(.medium))

                Text(category.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CategoryChip: View {
    let category: NoteCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.caption)
                Text(category.displayName)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.noteCategory(category) : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct TrainerNoteRow: View {
    let note: TrainerNote
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: note.category.iconName)
                .foregroundColor(Color.noteCategory(note.category))

            Text(note.content)
                .font(.subheadline)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    TrainerNotesIntroView()
        .environmentObject(AuthViewModel())
        .environmentObject(OnboardingViewModel())
}
