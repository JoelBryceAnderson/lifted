import SwiftUI

struct GoalSelectionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("What's Your Goal?")
                    .font(.largeTitle.bold())

                Text("This determines how quickly you'll progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)

            // Goal options
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(FitnessGoal.allCases, id: \.self) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: onboardingViewModel.selectedGoal == goal
                        ) {
                            withAnimation {
                                onboardingViewModel.selectedGoal = goal
                            }
                            Haptics.selection()
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            OnboardingNavigationButtons(
                showBack: authViewModel.user == nil, // Only show back button if not logged in
                canProceed: onboardingViewModel.selectedGoal != nil
            )
        }
    }
}

struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: goal.iconName)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 56, height: 56)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .cornerRadius(12)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(goal.shortDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Progression info
                    HStack(spacing: 16) {
                        ProgressionBadge(
                            title: "Compound",
                            value: goal.compoundIncrement > 0 ? "+\(goal.compoundIncrement.weightString) lbs/wk" : "Maintain"
                        )
                        ProgressionBadge(
                            title: "Isolation",
                            value: goal.isolationIncrement > 0 ? "+\(goal.isolationIncrement.weightString) lbs/wk" : "Maintain"
                        )
                    }
                    .padding(.top, 4)
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color(.systemGray5), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

struct ProgressionBadge: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

#Preview {
    GoalSelectionView()
        .environmentObject(AuthViewModel())
        .environmentObject(OnboardingViewModel())
}
