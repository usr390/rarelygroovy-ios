import SwiftUI

struct ProfileView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var showUpgradeDrawer = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            // Main content at the top with consistent horizontal padding
            if let user = authManager.user {
                VStack(alignment: .leading, spacing: 10) {
                    Text(user.username)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical)
                .padding(.horizontal)
            } else {
                Text("No user logged in.")
                    .padding(.horizontal)
            }
            
            Spacer()  // Pushes everything below to the bottom
            
            // Bottom button section with logout button on top
            VStack(spacing: 10) {
                Button(action: {
                    authManager.user = nil
                    NotificationCenter.default.post(name: Notification.Name("UserDidLogout"), object: nil)
                }) {
                    Text("log out")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    showUpgradeDrawer = true
                }) {
                    Text("upgrade account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colorScheme == .dark ? Color.white : Color.black)
                        .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(8)
                }
            }
            .padding([.horizontal, .bottom])
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showUpgradeDrawer) {
            UpgradeDrawerView(showDrawer: $showUpgradeDrawer)
        }
    }
}

struct UpgradeDrawerView: View {
    @Binding var showDrawer: Bool

    var body: some View {
        NavigationView {
            VStack {
                // X button to dismiss
                HStack {
                    Spacer()
                    Button(action: {
                        showDrawer = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                Spacer()
                // Placeholder content for upgrade details
                VStack(spacing: 16) {
                    Text("upgrade to Rarelygroovy+")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("""
Rarelygroovy+ unlocks full access to every event in our comprehensive list and the complete Artist Directory, featuring over 700 local artists spanning 40 years of valley music history.
""")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Text("To upgrade, send $5 to CashApp '$placeholder' with your username in the note.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ProfileView()
}
