import SwiftUI

struct SignUpView: View {
    var body: some View {
        SignUpFormView()
    }
}

struct SignUpFormView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var promoCode = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var didAttemptSubmit = false // flag to control when to show validation errors
    
    @Environment(\.colorScheme) var colorScheme

    // Validation settings
    private let usernameMinLength = 3
    private let usernameMaxLength = 20
    private let passwordMinLength = 8
    private let passwordMaxLength = 20
    
    // Regex pattern: allow only alphanumerics and underscores
    private let usernamePattern = "^[A-Za-z0-9_]+$"
    
    // Computed properties for validation
    var usernameError: String? {
        if username.isEmpty {
            return "Username is required."
        }
        if username.count < usernameMinLength {
            return "Username must be at least \(usernameMinLength) characters."
        }
        if username.count > usernameMaxLength {
            return "Username must be at most \(usernameMaxLength) characters."
        }
        let predicate = NSPredicate(format: "SELF MATCHES %@", usernamePattern)
        if !predicate.evaluate(with: username) {
            return "Username can only contain letters, numbers, and underscores."
        }
        return nil
    }
    
    var passwordError: String? {
        if password.isEmpty {
            return "Password is required."
        }
        if password.count < passwordMinLength {
            return "Password must be at least \(passwordMinLength) characters."
        }
        if password.count > passwordMaxLength {
            return "Password must be at most \(passwordMaxLength) characters."
        }
        return nil
    }
    
    var isFormValid: Bool {
        return usernameError == nil && passwordError == nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sign up for a Rarelygroovy account")
                .font(.largeTitle)
                .fontWeight(.bold)
            TextField("Username", text: $username)
                .autocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            // Only show the username error after submission attempt
            if didAttemptSubmit, let error = usernameError {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            // Only show the password error after submission attempt
            if didAttemptSubmit, let error = passwordError {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            Button(action: {
                didAttemptSubmit = true // flag that submission was attempted
                // Only attempt sign up if the form is valid
                guard isFormValid else { return }
                isLoading = true
                Task {
                    do {
                        try await AuthManager.shared.signUp(username: username, password: password, promoCode: promoCode)
                    } catch {
                        errorMessage = mapErrorToMessage(error)
                    }
                    isLoading = false
                }
            }) {
                Text(isLoading ? "loading..." : "sign up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                    .cornerRadius(8)
            }
            .disabled(isLoading)
                        
            // Disclaimer text at the bottom
            Text("* We do not require an email address to sign up")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .padding()
        .padding(.bottom, 20)
    }
}

extension AuthManager {
    func signUp(username: String, password: String, promoCode: String) async throws {
        guard let url = URL(string: "https://enm-project-production.up.railway.app/api/create-user") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body: [String: Any] = [
            "username": username,
            "password": password,
            "promoCode": promoCode
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let signUpResponse = try JSONDecoder().decode(AuthManager.LoginResponse.self, from: data)
        DispatchQueue.main.async {
            self.user = signUpResponse.user
            NotificationCenter.default.post(name: Notification.Name("UserDidSignUp"), object: nil)
        }
    }
}
