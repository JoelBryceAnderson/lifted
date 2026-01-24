import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var firebaseUser: FirebaseAuth.User?
    @Published var isLoading = true
    @Published var error: AuthError?
    @Published var hasCompletedOnboarding = false
    @Published var showOnboarding = false

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let authService = AuthService.shared
    private let firestoreService = FirestoreService.shared

    init() {
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                self?.firebaseUser = firebaseUser

                if let firebaseUser = firebaseUser {
                    await self?.fetchUser(userId: firebaseUser.uid)
                } else {
                    self?.user = nil
                    self?.hasCompletedOnboarding = false
                }

                self?.isLoading = false
            }
        }
    }

    private func fetchUser(userId: String) async {
        do {
            if let existingUser: User = try await firestoreService.getUser(userId: userId) {
                self.user = existingUser
                self.hasCompletedOnboarding = existingUser.onboardingCompleted
                self.showOnboarding = !existingUser.onboardingCompleted
            } else {
                // New user without a Firestore record
                self.showOnboarding = true
            }
        } catch {
            print("Error fetching user: \(error)")
            self.showOnboarding = true
        }
    }

    // MARK: - Email/Password Auth

    func signUp(email: String, password: String, displayName: String?) async {
        isLoading = true
        error = nil

        do {
            let firebaseUser = try await authService.signUp(email: email, password: password)

            let newUser = User(
                id: firebaseUser.uid,
                email: email,
                displayName: displayName,
                onboardingCompleted: false
            )

            try await firestoreService.saveUser(newUser)
            self.user = newUser
            self.hasCompletedOnboarding = false
            self.showOnboarding = true

        } catch {
            self.error = AuthError.from(error)
        }

        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil

        do {
            let firebaseUser = try await authService.signIn(email: email, password: password)
            await fetchUser(userId: firebaseUser.uid)
        } catch {
            self.error = AuthError.from(error)
        }

        isLoading = false
    }

    func signOut() {
        do {
            try authService.signOut()
            user = nil
            hasCompletedOnboarding = false
            showOnboarding = false
        } catch {
            self.error = AuthError.from(error)
        }
    }

    func resetPassword(email: String) async {
        isLoading = true
        error = nil

        do {
            try await authService.resetPassword(email: email)
        } catch {
            self.error = AuthError.from(error)
        }

        isLoading = false
    }

    // MARK: - Apple Sign-In

    func signInWithApple() async {
        isLoading = true
        error = nil

        do {
            let coordinator = AppleSignInCoordinator()
            let (idToken, nonce, fullName) = try await coordinator.signIn()

            let firebaseUser = try await authService.signInWithApple(
                idToken: idToken,
                rawNonce: nonce,
                fullName: fullName
            )

            if let existingUser: User = try await firestoreService.getUser(userId: firebaseUser.uid) {
                self.user = existingUser
                self.hasCompletedOnboarding = existingUser.onboardingCompleted
                self.showOnboarding = !existingUser.onboardingCompleted
            } else {
                var displayName: String?
                if let fullName = fullName {
                    displayName = [fullName.givenName, fullName.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                }

                let newUser = User(
                    id: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    displayName: displayName,
                    onboardingCompleted: false
                )

                try await firestoreService.saveUser(newUser)
                self.user = newUser
                self.hasCompletedOnboarding = false
                self.showOnboarding = true
            }
        } catch {
            self.error = AuthError.from(error)
        }

        isLoading = false
    }

    // MARK: - Onboarding Completion

    func completeOnboarding() async {
        guard var user = user else { return }

        user.onboardingCompleted = true

        do {
            try await firestoreService.saveUser(user)
            self.user = user
            self.hasCompletedOnboarding = true
            self.showOnboarding = false
        } catch {
            print("Error completing onboarding: \(error)")
        }
    }

    func updateUserPreferences(_ preferences: UserPreferences) async {
        guard var user = user else { return }

        user.preferences = preferences

        do {
            try await firestoreService.saveUser(user)
            self.user = user
        } catch {
            print("Error updating preferences: \(error)")
        }
    }

    func clearError() {
        error = nil
    }
}
