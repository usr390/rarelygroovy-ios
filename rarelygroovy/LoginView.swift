//
//  LoginView.swift
//  rarelygroovy
//
//  Created by abs on 3/30/25.
//

import SwiftUI

struct LoginFormView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    @Environment(\.colorScheme) var colorScheme


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
        }
        .padding()
    }
}

struct LoginView: View {
    @ObservedObject var authManager = AuthManager.shared

    var body: some View {
        if authManager.user != nil {
            // user is logged in; show profile with nav title
            ProfileView()
        } else {
            // user is not logged in; show login form without nav bar
            LoginFormView()
                .navigationBarHidden(true)
        }
    }
}
#Preview {
    LoginView()
}
