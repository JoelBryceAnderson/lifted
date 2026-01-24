import SwiftUI
import AuthenticationServices

struct CreateAccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    @State private var isSignUp = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""

    var isFormValid: Bool {
        if isSignUp {
            return email.isValidEmail && password.count >= 6 && password == confirmPassword
        } else {
            return email.isValidEmail && password.count >= 6
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text(isSignUp ? "Create Account" : "Welcome Back")
                        .font(.largeTitle.bold())

                    Text(isSignUp ? "Start tracking your progress" : "Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                // Apple Sign In
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { _ in }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(12)
                .onTapGesture {
                    Task {
                        await authViewModel.signInWithApple()
                        if authViewModel.user != nil {
                            onboardingViewModel.nextStep()
                        }
                    }
                }
                .padding(.horizontal)

                // Divider
                HStack {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                    Text("or")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                }
                .padding(.horizontal)

                // Email form
                VStack(spacing: 16) {
                    if isSignUp {
                        TextField("Display Name (optional)", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                            .autocapitalization(.words)
                    }

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isSignUp ? .newPassword : .password)

                    if isSignUp {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                    }
                }
                .padding(.horizontal)

                // Error message
                if let error = authViewModel.error {
                    Text(error.errorDescription ?? "An error occurred")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Submit button
                Button {
                    Task {
                        if isSignUp {
                            await authViewModel.signUp(
                                email: email,
                                password: password,
                                displayName: displayName.isEmpty ? nil : displayName
                            )
                        } else {
                            await authViewModel.signIn(email: email, password: password)
                        }

                        if authViewModel.user != nil {
                            onboardingViewModel.nextStep()
                        }
                    }
                } label: {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || authViewModel.isLoading)
                .padding(.horizontal)

                // Toggle sign up/sign in
                Button {
                    withAnimation {
                        isSignUp.toggle()
                        authViewModel.clearError()
                    }
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                Spacer()
            }
        }
    }
}

#Preview {
    CreateAccountView()
        .environmentObject(AuthViewModel())
        .environmentObject(OnboardingViewModel())
}
