import SwiftUI

struct AIButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String = "AI", isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(20)
        }
        .disabled(isLoading)
    }
}

struct AIButtonSmall: View {
    let isLoading: Bool
    let action: () -> Void

    init(isLoading: Bool = false, action: @escaping () -> Void) {
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(.purple)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .disabled(isLoading)
    }
}

struct AIResponseCard: View {
    let content: String
    let isLoading: Bool

    init(content: String?, isLoading: Bool = false) {
        self.content = content ?? ""
        self.isLoading = isLoading
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("AI Trainer")
                    .font(.headline)
                Spacer()
            }

            if isLoading {
                HStack {
                    ProgressView()
                    Text("Thinking...")
                        .foregroundColor(.secondary)
                }
            } else if !content.isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 20) {
        AIButton("Form Tips") {}
        AIButton("Analyzing...", isLoading: true) {}
        AIButtonSmall {}
        AIResponseCard(content: "Here are some tips for better form...", isLoading: false)
        AIResponseCard(content: nil, isLoading: true)
    }
    .padding()
}
