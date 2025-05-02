//
//  AuthManager.swift
//  rarelygroovy
//
//  Created by abs on 3/30/25.
//

import Foundation
import SwiftUI

final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var user: User? {
        didSet {
            if let user = user {
                // encode user and store in UserDefaults
                if let encoded = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(encoded, forKey: "loggedInUser")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "loggedInUser")
            }
        }
    }
    
    init() {
        // load user from UserDefaults if available
        if let data = UserDefaults.standard.data(forKey: "loggedInUser"),
           let savedUser = try? JSONDecoder().decode(User.self, from: data) {
            user = savedUser
        }
    }
    
    struct User: Codable {
        let id: String
        let username: String
        var plus: Bool
        let appAccountToken_apple: String
    }
    
    struct LoginResponse: Codable {
        let user: User
    }
    
    @MainActor
    func login(username: String, password: String) async throws {
        guard let url = URL(string: "https://enm-project-production.up.railway.app/api/login") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = ["username": username, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        self.user = loginResponse.user
        NotificationCenter.default.post(name: Notification.Name("UserDidLogin"), object: nil)
    }}
func mapErrorToMessage(_ error: Error) -> String {
    if let urlError = error as? URLError {
        switch urlError.code {
        case .badServerResponse:
            return "Invalid credentials"
        default:
            return "Something went wrong. Please try again."
        }
    }
    return "An unexpected error occurred."
}
