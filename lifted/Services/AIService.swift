import Foundation
import FirebaseFunctions

actor AIService {
    static let shared = AIService()

    private let functions = Functions.functions()
    private let firestoreService = FirestoreService.shared

    private init() {}

    // MARK: - AI Request Types

    enum ContextType: String {
        case formTips
        case variations
        case progress
        case chat
        case scheduleOptimize
    }

    struct AIRequest {
        let prompt: String
        let contextType: ContextType
        let exerciseId: String?
        let includeHistory: Bool
        let includeNotes: Bool

        init(
            prompt: String,
            contextType: ContextType,
            exerciseId: String? = nil,
            includeHistory: Bool = false,
            includeNotes: Bool = true
        ) {
            self.prompt = prompt
            self.contextType = contextType
            self.exerciseId = exerciseId
            self.includeHistory = includeHistory
            self.includeNotes = includeNotes
        }
    }

    struct AIResponse {
        let content: String
        let proposedActions: [ProposedAction]
    }

    // MARK: - Main AI Interface

    func askClaude(
        userId: String,
        request: AIRequest
    ) async throws -> AIResponse {
        let requestData: [String: Any] = [
            "prompt": request.prompt,
            "contextType": request.contextType.rawValue,
            "exerciseId": request.exerciseId as Any,
            "includeHistory": request.includeHistory,
            "includeNotes": request.includeNotes
        ]

        let result = try await functions.httpsCallable("askClaude").call(requestData)

        guard let data = result.data as? [String: Any],
              let content = data["response"] as? String else {
            throw AIError.invalidResponse
        }

        var proposedActions: [ProposedAction] = []
        if let actionsData = data["proposedActions"] as? [[String: Any]] {
            proposedActions = actionsData.compactMap { parseProposedAction($0) }
        }

        return AIResponse(content: content, proposedActions: proposedActions)
    }

    // MARK: - Convenience Methods

    func getFormTips(userId: String, exercise: Exercise) async throws -> String {
        let request = AIRequest(
            prompt: "Give me 3-4 concise form tips for the \(exercise.name). Focus on the most important cues for safety and effectiveness.",
            contextType: .formTips,
            exerciseId: exercise.id,
            includeHistory: false,
            includeNotes: true
        )

        let response = try await askClaude(userId: userId, request: request)
        return response.content
    }

    func getExerciseVariations(userId: String, exercise: Exercise) async throws -> String {
        let request = AIRequest(
            prompt: "Suggest 3-5 alternative exercises to \(exercise.name) that work similar muscle groups. Consider any limitations I might have.",
            contextType: .variations,
            exerciseId: exercise.id,
            includeHistory: false,
            includeNotes: true
        )

        let response = try await askClaude(userId: userId, request: request)
        return response.content
    }

    func analyzeProgress(userId: String, exerciseId: String, exerciseName: String) async throws -> String {
        let request = AIRequest(
            prompt: "Analyze my progress on \(exerciseName) over the past 8 weeks. Look for trends, plateaus, and give actionable advice for improvement.",
            contextType: .progress,
            exerciseId: exerciseId,
            includeHistory: true,
            includeNotes: true
        )

        let response = try await askClaude(userId: userId, request: request)
        return response.content
    }

    func optimizeSchedule(userId: String) async throws -> AIResponse {
        let request = AIRequest(
            prompt: "Review my current workout schedule and recent performance. Suggest any optimizations to help me reach my goals more effectively.",
            contextType: .scheduleOptimize,
            includeHistory: true,
            includeNotes: true
        )

        return try await askClaude(userId: userId, request: request)
    }

    func chat(userId: String, message: String, conversationHistory: [TrainerMessage]) async throws -> AIResponse {
        var contextPrompt = message

        if !conversationHistory.isEmpty {
            let historyContext = conversationHistory.suffix(10).map { msg in
                "\(msg.role.rawValue): \(msg.content)"
            }.joined(separator: "\n")

            contextPrompt = "Previous conversation:\n\(historyContext)\n\nUser: \(message)"
        }

        let request = AIRequest(
            prompt: contextPrompt,
            contextType: .chat,
            includeHistory: true,
            includeNotes: true
        )

        return try await askClaude(userId: userId, request: request)
    }

    // MARK: - Action Management

    func applyProposedAction(userId: String, actionId: String, approved: Bool) async throws -> Bool {
        let requestData: [String: Any] = [
            "actionId": actionId,
            "approved": approved
        ]

        let result = try await functions.httpsCallable("applyProposedAction").call(requestData)

        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool else {
            throw AIError.invalidResponse
        }

        return success
    }

    // MARK: - Helper Methods

    private func parseProposedAction(_ data: [String: Any]) -> ProposedAction? {
        guard let id = data["id"] as? String,
              let actionTypeStr = data["actionType"] as? String,
              let actionType = ActionType(rawValue: actionTypeStr),
              let description = data["description"] as? String,
              let changePayload = data["changePayload"] as? String else {
            return nil
        }

        let statusStr = data["status"] as? String ?? "pending"
        let status = ActionStatus(rawValue: statusStr) ?? .pending

        return ProposedAction(
            id: id,
            actionType: actionType,
            description: description,
            changePayload: changePayload,
            status: status
        )
    }
}

// MARK: - AI Errors

enum AIError: LocalizedError {
    case invalidResponse
    case networkError
    case rateLimited
    case serviceUnavailable
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from AI service."
        case .networkError:
            return "Network error. Please check your connection."
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serviceUnavailable:
            return "AI service is temporarily unavailable."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - System Prompt Builder

extension AIService {
    static func buildSystemPrompt(
        goal: FitnessGoal?,
        schedule: WorkoutSchedule?,
        notes: [TrainerNote],
        recentSessions: [WorkoutSession]?
    ) -> String {
        var prompt = """
        You are a personal fitness trainer AI for the Lifted app. You are knowledgeable, encouraging, and safety-conscious.

        """

        if let goal = goal {
            prompt += "User's current goal: \(goal.displayName) - \(goal.description)\n\n"
        }

        if let schedule = schedule {
            let workoutDays = schedule.days.compactMap { day -> String? in
                if case .workout(let type) = day.dayType {
                    return "\(day.shortDayName): \(type.displayName)"
                }
                return nil
            }.joined(separator: ", ")
            prompt += "User's workout schedule: \(workoutDays)\n\n"
        }

        if !notes.isEmpty {
            prompt += "Important information about this user:\n"
            for note in notes {
                prompt += "- [\(note.category.displayName)] \(note.content)\n"
            }
            prompt += "\n"
        }

        if let sessions = recentSessions, !sessions.isEmpty {
            prompt += "Recent workout history available for context.\n\n"
        }

        prompt += """
        Guidelines:
        - Be concise and actionable in your responses
        - Always factor in any noted injuries, limitations, or preferences
        - If suggesting schedule changes, format them as structured ProposedActions
        - Prioritize safety over aggressive progression
        - Use encouraging but professional language
        """

        return prompt
    }
}
