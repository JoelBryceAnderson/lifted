import SwiftUI

struct TrainerChatView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var trainerViewModel: TrainerViewModel

    @State private var showNotes = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome message if empty
                            if trainerViewModel.messages.isEmpty {
                                WelcomeMessage()
                            }

                            ForEach(trainerViewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            // Loading indicator
                            if trainerViewModel.isSending {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: trainerViewModel.messages.count) { _, _ in
                        if let lastMessage = trainerViewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input area
                ChatInputView()
            }
            .navigationTitle("AI Trainer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNotes = true
                    } label: {
                        Image(systemName: "note.text")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            if let userId = authViewModel.user?.id {
                                Task {
                                    await trainerViewModel.startNewChat(userId: userId)
                                }
                            }
                        } label: {
                            Label("New Conversation", systemImage: "plus.bubble")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showNotes) {
                TrainerNotesListView()
            }
            .task {
                await loadData()
            }
        }
    }

    private func loadData() async {
        guard let userId = authViewModel.user?.id else { return }
        await trainerViewModel.loadTrainerData(userId: userId)
    }
}

struct WelcomeMessage: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text("Hi! I'm your AI Trainer")
                    .font(.title2.bold())

                Text("Ask me anything about fitness, form, programming, or nutrition. I remember your notes and training history!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Suggestion chips
            VStack(spacing: 8) {
                SuggestionChip(text: "Review my recent progress")
                SuggestionChip(text: "Suggest a deload protocol")
                SuggestionChip(text: "Help with bench press form")
            }
        }
        .padding(32)
    }
}

struct SuggestionChip: View {
    @EnvironmentObject var trainerViewModel: TrainerViewModel

    let text: String

    var body: some View {
        Button {
            trainerViewModel.inputMessage = text
        } label: {
            Text(text)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
        }
        .foregroundColor(.primary)
    }
}

struct ChatInputView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var trainerViewModel: TrainerViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            TextField("Ask your trainer...", text: $trainerViewModel.inputMessage, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .lineLimit(1...5)
                .focused($isFocused)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundColor(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        !trainerViewModel.inputMessage.trimmed.isEmpty && !trainerViewModel.isSending
    }

    private func sendMessage() {
        guard let userId = authViewModel.user?.id else { return }

        Task {
            await trainerViewModel.sendMessage(userId: userId)
        }

        isFocused = false
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever()
                        .delay(Double(index) * 0.15),
                        value: animationOffset
                    )
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            animationOffset = -5
        }
    }
}

#Preview {
    TrainerChatView()
        .environmentObject(AuthViewModel())
        .environmentObject(TrainerViewModel())
}
