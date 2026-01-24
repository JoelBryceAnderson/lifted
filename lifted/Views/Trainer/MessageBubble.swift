import SwiftUI

struct MessageBubble: View {
    let message: TrainerMessage

    var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
            HStack {
                if isUser { Spacer() }

                VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(isUser ? .white : .primary)
                        .padding(12)
                        .background(bubbleColor)
                        .cornerRadius(16)

                    // Proposed actions
                    if let actions = message.proposedActions, !actions.isEmpty {
                        ForEach(actions) { action in
                            ProposedActionCard(action: action)
                        }
                    }
                }
                .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)

                if !isUser { Spacer() }
            }

            // Timestamp
            Text(message.timestamp.timeString)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
    }

    private var bubbleColor: Color {
        isUser ? .blue : Color(.systemGray6)
    }
}

struct ProposedActionCard: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var trainerViewModel: TrainerViewModel

    let action: ProposedAction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: action.actionType.iconName)
                    .foregroundColor(.blue)

                Text(action.actionType.displayName)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                statusBadge
            }

            // Description
            Text(action.description)
                .font(.caption)
                .foregroundColor(.secondary)

            // Action buttons (if pending)
            if action.status == .pending {
                HStack(spacing: 12) {
                    Button {
                        rejectAction()
                    } label: {
                        Text("Reject")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                    }

                    Button {
                        approveAction()
                    } label: {
                        Text("Approve")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusBorderColor, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch action.status {
        case .pending:
            Text("Pending")
                .font(.caption2.weight(.medium))
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(8)

        case .approved:
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                Text("Applied")
            }
            .font(.caption2.weight(.medium))
            .foregroundColor(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.15))
            .cornerRadius(8)

        case .rejected:
            HStack(spacing: 4) {
                Image(systemName: "xmark")
                Text("Rejected")
            }
            .font(.caption2.weight(.medium))
            .foregroundColor(.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red.opacity(0.15))
            .cornerRadius(8)
        }
    }

    private var statusBorderColor: Color {
        switch action.status {
        case .pending: return .orange.opacity(0.5)
        case .approved: return .green.opacity(0.5)
        case .rejected: return .red.opacity(0.5)
        }
    }

    private func approveAction() {
        guard let userId = authViewModel.user?.id else { return }
        Task {
            await trainerViewModel.approveAction(userId: userId, actionId: action.id)
        }
    }

    private func rejectAction() {
        guard let userId = authViewModel.user?.id else { return }
        Task {
            await trainerViewModel.rejectAction(userId: userId, actionId: action.id)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubble(
            message: TrainerMessage(
                sessionId: "test",
                role: .user,
                content: "Can you help me improve my bench press?"
            )
        )

        MessageBubble(
            message: TrainerMessage(
                sessionId: "test",
                role: .assistant,
                content: "Of course! Based on your recent training data, I notice you've been making good progress. Here are some suggestions...",
                proposedActions: [
                    ProposedAction(
                        actionType: .progressionAdjustment,
                        description: "Increase your bench press target by 5 lbs next week",
                        changePayload: "{}"
                    )
                ]
            )
        )
    }
    .padding()
    .environmentObject(AuthViewModel())
    .environmentObject(TrainerViewModel())
}
