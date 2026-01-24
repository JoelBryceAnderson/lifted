import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                // Progress indicator
                if onboardingViewModel.currentStep != .welcome {
                    OnboardingProgressBar(currentStep: onboardingViewModel.currentStep)
                        .padding(.horizontal)
                }

                // Content
                TabView(selection: $onboardingViewModel.currentStep) {
                    WelcomeView()
                        .tag(OnboardingStep.welcome)

                    CreateAccountView()
                        .tag(OnboardingStep.createAccount)

                    GoalSelectionView()
                        .tag(OnboardingStep.goalSelection)

                    ScheduleBuilderView()
                        .tag(OnboardingStep.scheduleBuilder)

                    StartingWeightsView()
                        .tag(OnboardingStep.startingWeights)

                    TrainerNotesIntroView()
                        .tag(OnboardingStep.trainerNotes)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: onboardingViewModel.currentStep)
            }
            .environmentObject(onboardingViewModel)
        }
    }
}

struct OnboardingProgressBar: View {
    let currentStep: OnboardingStep

    private var progress: Double {
        let totalSteps = OnboardingStep.allCases.count - 1 // Exclude welcome
        let currentIndex = currentStep.rawValue
        return Double(currentIndex) / Double(totalSteps)
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 4)

            HStack {
                Text(currentStep.title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                Spacer()
                if currentStep.isOptional {
                    Text("Optional")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct OnboardingNavigationButtons: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    let showBack: Bool
    let nextTitle: String
    let canProceed: Bool
    let onNext: (() -> Void)?
    let isLoading: Bool

    init(
        showBack: Bool = true,
        nextTitle: String = "Continue",
        canProceed: Bool = true,
        isLoading: Bool = false,
        onNext: (() -> Void)? = nil
    ) {
        self.showBack = showBack
        self.nextTitle = nextTitle
        self.canProceed = canProceed
        self.isLoading = isLoading
        self.onNext = onNext
    }

    var body: some View {
        HStack(spacing: 16) {
            if showBack {
                Button {
                    onboardingViewModel.previousStep()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(width: 50, height: 50)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }

            Button {
                if let onNext = onNext {
                    onNext()
                } else {
                    onboardingViewModel.nextStep()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(nextTitle)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canProceed ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canProceed || isLoading)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AuthViewModel())
}
