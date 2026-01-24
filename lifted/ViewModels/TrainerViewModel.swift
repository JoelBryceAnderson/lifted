import Foundation
import Combine

@MainActor
class TrainerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var messages: [TrainerMessage] = []
    @Published var trainerNotes: [TrainerNote] = []
    @Published var currentChatId: String?
    @Published var inputMessage = ""
    @Published var isLoading = false
    @Published var isSending = false
    @Published var error: String?

    // Note Management
    @Published var isAddingNote = false
    @Published var newNoteContent = ""
    @Published var newNoteCategory: NoteCategory = .preference

    // MARK: - Dependencies

    private let firestoreService = FirestoreService.shared
    private let aiService = AIService.shared

    // MARK: - Computed Properties

    var activeNotes: [TrainerNote] {
        trainerNotes.filter { $0.isActive }
    }

    var notesByCategory: [NoteCategory: [TrainerNote]] {
        Dictionary(grouping: activeNotes) { $0.category }
    }

    var pendingActions: [ProposedAction] {
        messages.flatMap { $0.pendingActions }
    }

    // MARK: - Data Loading

    func loadTrainerData(userId: String) async {
        isLoading = true

        do {
            trainerNotes = try await firestoreService.getTrainerNotes(userId: userId, activeOnly: false)

            let chats: [TrainerChat] = try await firestoreService.readAllFromSubcollection(
                parentCollection: .users,
                parentId: userId,
                subcollection: .trainerChats
            )

            if let latestChat = chats.sorted(by: { $0.updatedAt > $1.updatedAt }).first {
                currentChatId = latestChat.id
                messages = latestChat.messages
            } else {
                await startNewChat(userId: userId)
            }

        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Chat Management

    func startNewChat(userId: String) async {
        let chatId = UUID().uuidString
        currentChatId = chatId
        messages = []

        let chat = TrainerChat(
            id: chatId,
            userId: userId
        )

        do {
            let _ = try await firestoreService.createInSubcollection(
                chat,
                parentCollection: .users,
                parentId: userId,
                subcollection: .trainerChats,
                documentId: chatId
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func sendMessage(userId: String) async {
        let content = inputMessage.trimmed
        guard !content.isEmpty, let chatId = currentChatId else { return }

        inputMessage = ""
        isSending = true

        // Add user message
        let userMessage = TrainerMessage(
            sessionId: chatId,
            role: .user,
            content: content
        )
        messages.append(userMessage)

        do {
            // Get AI response
            let response = try await aiService.chat(userId: userId, message: content, conversationHistory: messages)

            // Add assistant message
            let assistantMessage = TrainerMessage(
                sessionId: chatId,
                role: .assistant,
                content: response.content,
                proposedActions: response.proposedActions.isEmpty ? nil : response.proposedActions
            )
            messages.append(assistantMessage)

            // Check for "remember" commands
            await checkForRememberCommand(userId: userId, content: content, response: response.content)

            // Save chat
            await saveChat(userId: userId)

        } catch {
            self.error = "Failed to get response"
            messages.removeLast() // Remove user message on failure
        }

        isSending = false
    }

    private func saveChat(userId: String) async {
        guard let chatId = currentChatId else { return }

        let chat = TrainerChat(
            id: chatId,
            userId: userId,
            messages: messages,
            updatedAt: Date()
        )

        do {
            try await firestoreService.updateInSubcollection(
                chat,
                parentCollection: .users,
                parentId: userId,
                subcollection: .trainerChats,
                documentId: chatId
            )
        } catch {
            print("Error saving chat: \(error)")
        }
    }

    private func checkForRememberCommand(userId: String, content: String, response: String) async {
        let rememberPatterns = ["remember that", "remember this", "note that", "keep in mind"]

        let lowerContent = content.lowercased()

        for pattern in rememberPatterns {
            if lowerContent.contains(pattern) {
                if let range = lowerContent.range(of: pattern) {
                    let noteContent = String(content[range.upperBound...]).trimmed

                    if !noteContent.isEmpty {
                        let note = TrainerNote(
                            userId: userId,
                            content: noteContent,
                            category: inferNoteCategory(from: noteContent)
                        )

                        do {
                            let _ = try await firestoreService.createInSubcollection(
                                note,
                                parentCollection: .users,
                                parentId: userId,
                                subcollection: .trainerNotes,
                                documentId: note.id
                            )
                            trainerNotes.append(note)
                        } catch {
                            print("Error saving note: \(error)")
                        }
                    }
                }
                break
            }
        }
    }

    private func inferNoteCategory(from content: String) -> NoteCategory {
        let lowerContent = content.lowercased()

        if lowerContent.contains("injur") || lowerContent.contains("pain") || lowerContent.contains("hurt") {
            return .injury
        } else if lowerContent.contains("can't") || lowerContent.contains("unable") || lowerContent.contains("limit") {
            return .limitation
        } else if lowerContent.contains("goal") || lowerContent.contains("want to") || lowerContent.contains("target") {
            return .goal
        } else if lowerContent.contains("condition") || lowerContent.contains("medical") || lowerContent.contains("doctor") {
            return .medical
        } else {
            return .preference
        }
    }

    // MARK: - Note Management

    func addNote(userId: String) async {
        guard !newNoteContent.trimmed.isEmpty else { return }

        let note = TrainerNote(
            userId: userId,
            content: newNoteContent.trimmed,
            category: newNoteCategory
        )

        do {
            let _ = try await firestoreService.createInSubcollection(
                note,
                parentCollection: .users,
                parentId: userId,
                subcollection: .trainerNotes,
                documentId: note.id
            )
            trainerNotes.append(note)
            newNoteContent = ""
            isAddingNote = false
            Haptics.success()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func archiveNote(userId: String, noteId: String) async {
        guard let index = trainerNotes.firstIndex(where: { $0.id == noteId }) else { return }

        var note = trainerNotes[index]
        note.isActive = false

        do {
            try await firestoreService.updateInSubcollection(
                note,
                parentCollection: .users,
                parentId: userId,
                subcollection: .trainerNotes,
                documentId: note.id
            )
            trainerNotes[index] = note
        } catch {
            self.error = error.localizedDescription
        }
    }

    func reactivateNote(userId: String, noteId: String) async {
        guard let index = trainerNotes.firstIndex(where: { $0.id == noteId }) else { return }

        var note = trainerNotes[index]
        note.isActive = true

        do {
            try await firestoreService.updateInSubcollection(
                note,
                parentCollection: .users,
                parentId: userId,
                subcollection: .trainerNotes,
                documentId: note.id
            )
            trainerNotes[index] = note
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteNote(userId: String, noteId: String) async {
        do {
            try await firestoreService.deleteFromSubcollection(
                parentCollection: .users,
                parentId: userId,
                subcollection: .trainerNotes,
                documentId: noteId
            )
            trainerNotes.removeAll { $0.id == noteId }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Proposed Actions

    func approveAction(userId: String, actionId: String) async {
        await handleAction(userId: userId, actionId: actionId, approved: true)
    }

    func rejectAction(userId: String, actionId: String) async {
        await handleAction(userId: userId, actionId: actionId, approved: false)
    }

    private func handleAction(userId: String, actionId: String, approved: Bool) async {
        do {
            let success = try await aiService.applyProposedAction(userId: userId, actionId: actionId, approved: approved)

            if success {
                // Update local state
                for i in messages.indices {
                    if var actions = messages[i].proposedActions {
                        for j in actions.indices {
                            if actions[j].id == actionId {
                                actions[j].status = approved ? .approved : .rejected
                            }
                        }
                        messages[i].proposedActions = actions
                    }
                }

                await saveChat(userId: userId)
                Haptics.success()
            }
        } catch {
            self.error = "Failed to process action"
        }
    }

    // MARK: - Schedule Optimization

    func optimizeSchedule(userId: String) async {
        isSending = true

        do {
            let response = try await aiService.optimizeSchedule(userId: userId)

            let message = TrainerMessage(
                sessionId: currentChatId ?? "",
                role: .assistant,
                content: response.content,
                proposedActions: response.proposedActions.isEmpty ? nil : response.proposedActions
            )

            messages.append(message)
            await saveChat(userId: userId)

        } catch {
            self.error = "Failed to optimize schedule"
        }

        isSending = false
    }
}
