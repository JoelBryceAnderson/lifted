import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @StateObject private var scheduleViewModel = ScheduleViewModel()
    @StateObject private var progressionViewModel = ProgressionViewModel()
    @StateObject private var exerciseViewModel = ExerciseViewModel()
    @StateObject private var progressViewModel = ProgressViewModel()
    @StateObject private var trainerViewModel = TrainerViewModel()

    var body: some View {
        let _ = print("📱 ContentView rendering - isLoading: \(authViewModel.isLoading), user: \(authViewModel.user?.email ?? "nil"), showOnboarding: \(authViewModel.showOnboarding)")
        
        return Group {
            if authViewModel.isLoading {
                LoadingOverlay(message: "Loading...")
            } else if authViewModel.user == nil {
                OnboardingContainerView()
            } else if authViewModel.showOnboarding {
                OnboardingContainerView()
            } else {
                MainTabView()
            }
        }
        .environmentObject(workoutViewModel)
        .environmentObject(scheduleViewModel)
        .environmentObject(progressionViewModel)
        .environmentObject(exerciseViewModel)
        .environmentObject(progressViewModel)
        .environmentObject(trainerViewModel)
        .onChange(of: authViewModel.showOnboarding) { oldValue, newValue in
            print("🔄 ContentView: showOnboarding changed from \(oldValue) to \(newValue)")
        }
        .onChange(of: authViewModel.hasCompletedOnboarding) { oldValue, newValue in
            print("🔄 ContentView: hasCompletedOnboarding changed from \(oldValue) to \(newValue)")
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(1)

            ExerciseLibraryView()
                .tabItem {
                    Label("Exercises", systemImage: "dumbbell.fill")
                }
                .tag(2)

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)

            TrainerChatView()
                .tabItem {
                    Label("Trainer", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
