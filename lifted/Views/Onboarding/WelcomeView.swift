import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo and title
            VStack(spacing: 24) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 8) {
                    Text("Lifted")
                        .font(.largeTitle.bold())

                    Text("Your AI-Powered Fitness Journey")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // Features
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Smart Progression",
                    description: "Automated weight increases based on your goals"
                )

                FeatureRow(
                    icon: "calendar",
                    title: "Flexible Scheduling",
                    description: "Build a workout cycle that fits your life"
                )

                FeatureRow(
                    icon: "sparkles",
                    title: "AI Personal Trainer",
                    description: "Get form tips, alternatives, and personalized advice"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Get Started button
            Button {
                onboardingViewModel.nextStep()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(OnboardingViewModel())
}
