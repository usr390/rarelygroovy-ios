//
//  ProfileView.swift
//  rarelygroovy
//
//  Created by abs on 3/30/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var authManager = AuthManager.shared

    var body: some View {
        VStack(spacing: 20) {
            if let user = authManager.user {
                // left align user info
                VStack(alignment: .leading, spacing: 10) {
                    Text(user.username)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(user.plus ? "Rarelygroovy+" : "Free")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // logout button remains centered/full width
                Button(action: {
                    authManager.user = nil
                    NotificationCenter.default.post(name: Notification.Name("UserDidLogout"), object: nil)
                }) {
                    Text("Log out")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 20)
            } else {
                Text("No user logged in.")
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
    }
}
#Preview {
    ProfileView()
}

