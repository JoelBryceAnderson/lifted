import SwiftUI

struct TrainerNotesListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var trainerViewModel: TrainerViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showArchived = false

    var body: some View {
        NavigationStack {
            List {
                // Add note section
                Section {
                    AddNoteRow()
                }

                // Active notes by category
                ForEach(NoteCategory.allCases, id: \.self) { category in
                    let notes = trainerViewModel.notesByCategory[category] ?? []
                    if !notes.isEmpty {
                        Section(header: CategoryHeader(category: category)) {
                            ForEach(notes) { note in
                                NoteRow(note: note)
                            }
                        }
                    }
                }

                // Archived notes
                if showArchived {
                    let archivedNotes = trainerViewModel.trainerNotes.filter { !$0.isActive }
                    if !archivedNotes.isEmpty {
                        Section(header: Text("Archived")) {
                            ForEach(archivedNotes) { note in
                                NoteRow(note: note, isArchived: true)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Trainer Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showArchived.toggle()
                        } label: {
                            Label(
                                showArchived ? "Hide Archived" : "Show Archived",
                                systemImage: "archivebox"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

struct CategoryHeader: View {
    let category: NoteCategory

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: category.iconName)
                .foregroundColor(Color.noteCategory(category))
            Text(category.displayName)
        }
    }
}

struct AddNoteRow: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var trainerViewModel: TrainerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(NoteCategory.allCases, id: \.self) { category in
                        Button {
                            trainerViewModel.newNoteCategory = category
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: category.iconName)
                                    .font(.caption)
                                Text(category.displayName)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                trainerViewModel.newNoteCategory == category
                                    ? Color.noteCategory(category)
                                    : Color(.systemGray6)
                            )
                            .foregroundColor(
                                trainerViewModel.newNoteCategory == category
                                    ? .white
                                    : .primary
                            )
                            .cornerRadius(12)
                        }
                    }
                }
            }

            // Input field
            HStack {
                TextField("Add a note...", text: $trainerViewModel.newNoteContent)
                    .textFieldStyle(.roundedBorder)

                Button {
                    addNote()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(
                            trainerViewModel.newNoteContent.trimmed.isEmpty
                                ? .gray
                                : .blue
                        )
                }
                .disabled(trainerViewModel.newNoteContent.trimmed.isEmpty)
            }
        }
        .padding(.vertical, 8)
    }

    private func addNote() {
        guard let userId = authViewModel.user?.id else { return }
        Task {
            await trainerViewModel.addNote(userId: userId)
        }
    }
}

struct NoteRow: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var trainerViewModel: TrainerViewModel

    let note: TrainerNote
    var isArchived = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: note.category.iconName)
                .foregroundColor(isArchived ? .gray : Color.noteCategory(note.category))

            VStack(alignment: .leading, spacing: 4) {
                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(isArchived ? .secondary : .primary)

                Text(note.createdAt.relativeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .swipeActions(edge: .trailing) {
            if isArchived {
                Button {
                    reactivateNote()
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.backward")
                }
                .tint(.blue)

                Button(role: .destructive) {
                    deleteNote()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } else {
                Button {
                    archiveNote()
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                .tint(.orange)
            }
        }
    }

    private func archiveNote() {
        guard let userId = authViewModel.user?.id else { return }
        Task {
            await trainerViewModel.archiveNote(userId: userId, noteId: note.id)
        }
    }

    private func reactivateNote() {
        guard let userId = authViewModel.user?.id else { return }
        Task {
            await trainerViewModel.reactivateNote(userId: userId, noteId: note.id)
        }
    }

    private func deleteNote() {
        guard let userId = authViewModel.user?.id else { return }
        Task {
            await trainerViewModel.deleteNote(userId: userId, noteId: note.id)
        }
    }
}

#Preview {
    TrainerNotesListView()
        .environmentObject(AuthViewModel())
        .environmentObject(TrainerViewModel())
}
