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
            UpgradeDrawerOverlay(showDrawer: $showUpgradeDrawer)
        }
    }
}

struct UpgradeDrawerOverlay: View {
    @Binding var showDrawer: Bool
    @StateObject var store = Store()
    
    let premiumFeatures = [
        "Access to all upcoming events",
        "Access to all artists in the Artist Directory",
        "700+ artists across 40 years of Rio Grande Valley music",
    ]
    
    var body: some View {
        ZStack {
            // Black background with opacity
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            // Top Cancel button overlay
            VStack {
                HStack {
                    Spacer()
                    Button("Cancel") {
                        showDrawer = false
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                Spacer()
            }
            
            // Centered content
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Upgrade to Rarelygroovy+")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Benefits list section
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(premiumFeatures, id: \.self) { feature in
                            HStack {
                                Text(feature)
                                    .font(.body)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                    
                    if let product = store.products.first {
                        Button("upgrade for \(product.displayPrice)") {
                            Task {
                                await store.purchase(product)
                                showDrawer = false
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        Text("(one time purchase)")
                            .font(.footnote)
                            .foregroundColor(.white)
                    } else {
                        Text("Loading purchase options…")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
}
#Preview {
    ProfileView()
}

import StoreKit

class Store: ObservableObject {
    @Published var products: [Product] = []
    
    init() {
        Task {
            do {
                let storeProducts = try await Product.products(for: ["rarelygroovyplus"])
                DispatchQueue.main.async {
                    self.products = storeProducts
                }
            } catch {
                print("Failed to fetch products: \(error)")
            }
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(.verified(let transaction)):
                print("✅ Purchase success")
                await transaction.finish()

                // 🔥 Grab receipt data
                guard let appReceiptURL = Bundle.main.appStoreReceiptURL,
                      let receiptData = try? Data(contentsOf: appReceiptURL) else {
                    print("❌ Couldn't find receipt")
                    return
                }

                let base64Receipt = receiptData.base64EncodedString()

                // ✅ Send to your backend
                await verifyReceiptWithBackend(base64Receipt)

            default:
                break
            }
        } catch {
            print("❌ Purchase failed: \(error)")
        }
    }
    func verifyReceiptWithBackend(_ receipt: String, retries: Int = 3) async {
        guard let userId = AuthManager.shared.user?.id else {
            print("❌ Missing user ID")
            return
        }

        let payload: [String: Any] = [
            "userId": userId,
            "receiptData": receipt
        ]

        guard let url = URL(string: "https://enm-project-production.up.railway.app/api/verify-apple-receipt"),
              let body = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("❌ Bad request setup")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let updatedUser = try JSONDecoder().decode(AuthManager.User.self, from: data)

            DispatchQueue.main.async {
                AuthManager.shared.user = updatedUser
                print("✅ Backend verification succeeded and user updated")
            }

        } catch {
            print("⚠️ Verification failed: \(error.localizedDescription) — \(retries) retries left")

            if retries > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await verifyReceiptWithBackend(receipt, retries: retries - 1)
            } else {
                print("❌ Failed to verify receipt after retries")
            }
        }
    }
    
}
