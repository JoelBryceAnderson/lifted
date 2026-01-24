import SwiftUI

/// A temporary view for seeding Firestore with initial data
/// Remove this from production builds or protect with admin authentication
struct AdminSetupView: View {
    @State private var isUploading = false
    @State private var uploadComplete = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Admin Setup")
                .font(.largeTitle)
                .bold()

            Text("Use this view to upload seed data to Firestore")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if uploadComplete {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)

                    Text("Upload Complete!")
                        .font(.title2)
                        .bold()

                    Text("All exercises have been uploaded to Firestore")
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                Button {
                    uploadExercises()
                } label: {
                    HStack {
                        if isUploading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                        }
                        Text("Upload Exercises to Firestore")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .disabled(isUploading)
                .padding(.horizontal)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Spacer()

            Text("⚠️ Only run this once during initial setup")
                .font(.caption)
                .foregroundStyle(.orange)
        }
        .padding()
    }

    private func uploadExercises() {
        isUploading = true
        errorMessage = nil

        Task {
            do {
                try await ExerciseSeedData.uploadToFirestore()
                await MainActor.run {
                    isUploading = false
                    uploadComplete = true
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                    errorMessage = "Upload failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    AdminSetupView()
}
