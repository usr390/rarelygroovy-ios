import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager = AuthManager.shared
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if authManager.user != nil {
            // User is logged in; show profile view
            ProfileView()
        } else {
            VStack {
                LoginFormView()
                NavigationLink(destination: SignUpView()) {
                    Text("Don't have an account? Sign up")
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .underline()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

struct LoginFormView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    @Environment(\.colorScheme) var colorScheme

    // Computed property to check that both fields have non-empty, trimmed input
    var isFormValid: Bool {
        return !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Log in to Rarelygroovy")
                .font(.largeTitle)
                .fontWeight(.bold)
            TextField("username", text: $username)
                .autocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            SecureField("password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            Button(action: {
                // Prevent request if form is invalid
                guard isFormValid else {
                    errorMessage = "Please fill in all fields."
                    return
                }
                isLoading = true
                Task {
                    do {
                        try await AuthManager.shared.login(username: username, password: password)
                    } catch {
                        errorMessage = mapErrorToMessage(error)
                    }
                    isLoading = false
                }
            }) {
                Text(isLoading ? "loading..." : "log in")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                    .cornerRadius(8)
            }
            .disabled(!isFormValid || isLoading)
        }
        .padding()
    }
}
