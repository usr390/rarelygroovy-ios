import SwiftUI
import StoreKit

struct ProfileView: View {
    @EnvironmentObject var store: Store
    @ObservedObject var authManager = AuthManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showUpgradeDrawer = false
    @State private var showDeleteConfirmation = false
    @State private var showRestoreDialog = false
    @State private var restoreResultMessage: String? = nil
    @State private var showRestoreResultAlert = false
    @State private var showEmailErrorAlert = false
    @State private var emailErrorMessage = ""
    @State private var restoreWasSuccessful = false
    @StateObject private var statsVM = PlusStatsViewModel()

    var body: some View {
        VStack(spacing: 24) {
            
            // Toolbar
            HStack {
                Spacer()
                Menu {
                    // Email Us
                    Link(destination: URL(string: "mailto:rarelygroovy@gmail.com")!) {
                        VStack {
                            Text("Email us")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    // Instagram
                    Link(destination: URL(string: "https://instagram.com/rarelygroovy")!) {
                        VStack {
                            Text("Our Instagram")
                        }
                        .foregroundColor(.secondary)
                    }
                    Button("Restore purchases") {
                        Task {
                            await runRestore()
                        }
                    }
                    
                    Button("Log out", role: .destructive) {
                        authManager.user = nil
                        NotificationCenter.default.post(name: Notification.Name("UserDidLogout"), object: nil)
                    }
                    
                    Button("Delete account", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding()
                }
                .alert("Are you sure you want to delete your account?", isPresented: $showDeleteConfirmation) {
                    Button("Delete", role: .destructive) {
                        Task {
                            await deleteAccount()
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .alert("Restore Result", isPresented: $showRestoreResultAlert) {
                    Button("OK", role: .cancel) { }

                    if !restoreWasSuccessful {
                        Button("Contact Us") {
                            openSupportEmail()
                        }
                    }
                } message: {
                    Text(restoreResultMessage ?? "")
                }
                .alert("Email Error", isPresented: $showEmailErrorAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(emailErrorMessage)
                }
            }

            // Profile
            VStack(spacing: 8) {
                let userId = AuthManager.shared.user?.id ?? "fallback"
                AbstractAvatar(id: userId)
                
                if let user = authManager.user {
                    Text(user.username)
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            Spacer()
        }
        .sheet(isPresented: $showUpgradeDrawer) {
            UpgradeDrawerOverlay(showDrawer: $showUpgradeDrawer, statsVM: statsVM, product: store.products.first!, purchasingEnabled: true)
        }
    }

    func runRestore() async {
        var restored = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == "rarelygroovyplus" {

                let tokenFromApple = transaction.appAccountToken
                let currentToken = UUID(uuidString: AuthManager.shared.user?.appAccountToken_apple ?? "")

                if tokenFromApple == currentToken {
                    await store.updateCustomerProductStatus()
                    restoreResultMessage = "Rarelygroovy+ was restored successfully."
                    restoreWasSuccessful = true
                    restored = true
                    break
                } else {
                    restoreResultMessage = "Restore failed. Please make sure you're signed in to the Rarelygroovy account that made the Rarelygroovy+ purchase."
                    showRestoreResultAlert = true
                    restoreWasSuccessful = false
                    return
                }
            }
        }

        if !restored {
            restoreResultMessage = "No valid Rarelygroovy+ purchase was found to restore."
            restoreWasSuccessful = false
        }

        showRestoreResultAlert = true
    }

    func deleteAccount() async {
        guard let userId = authManager.user?.id else { return }

        guard let url = URL(string: "https://enm-project-production.up.railway.app/api/delete-user/\(userId)") else {
            print("❌ Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Account deleted")
                DispatchQueue.main.async {
                    authManager.user = nil
                    NotificationCenter.default.post(name: Notification.Name("UserDidLogout"), object: nil)
                }
            } else {
                print("❌ Failed to delete account")
            }
        } catch {
            print("❌ Error deleting account: \(error)")
        }
    }
    
    func openSupportEmail() {
        let email = "rarelygroovy@gmail.com"
        let subject = "Restore Purchase Help"
        let body = "Hi Rarelygroovy team,\n\nI'm having trouble restoring my Rarelygroovy+ purchase.\n\n(Describe your issue here)"
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            emailErrorMessage = "Could not open your email app. Please contact us manually at \(email)"
            showEmailErrorAlert = true
        }
    }
}

struct StatCard: View {
    var title: String
    var count: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
struct UpgradeDrawerOverlay: View {
    @EnvironmentObject var store: Store
    @State var errorTitle = ""
    @State var isShowingError: Bool = false
    @State var isPurchased: Bool = false
    @Binding var showDrawer: Bool
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var statsVM: PlusStatsViewModel
    
    let product: Product
    let purchasingEnabled: Bool


    
    let premiumFeatures = [
        "Access all upcoming events",
        "Access all artists in the Artist Directory",
        "700+ artists across 40 years of Rio Grande Valley music",
    ]
    
    var body: some View {
        ZStack {
            // Black background with opacity
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            ScrollView {
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
                        
                        VStack(spacing: 8) {
                          Image(colorScheme == .dark ? "logo-bw" : "logo-wb")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                          Text("Upgrade to Rarelygroovy+")
                            .font(.title2).fontWeight(.bold)
                            .foregroundColor(.primary)
                        }
                        
                        // Benefits list section
                        // perks + disclaimer
                        VStack(spacing: 16) {
                          PerkSection(title: "Artist Directory", perks: statsVM.artistPerks)
                          PerkSection(title: "Events",           perks: statsVM.eventPerks)

                          Text("* Numbers continue to grow as we add events and artists to Rarelygroovy!")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: 340, alignment: .leading)
                        }
                        
                        // spacer pushes button to bottom
                        Spacer(minLength: 20)
                        
                        VStack(spacing: 8) {
                            Button("upgrade for \(store.products[0].displayPrice)") {
                                Task {
                                    try await store.purchase(store.products[0])
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
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
                .offset(y: -10) // shifts the content up 20 points; adjust as needed
                
            }
        }
        .onAppear { statsVM.fetchAll() }
    }
}

#Preview {
    ProfileView()
}

struct AbstractAvatar: View {
    let id: String

    var body: some View {
        let hash = abs(stableHash(id))
        let baseHue = Double(hash % 360) / 360.0
        let cellCount = 5 + (hash % 5)
        let sporeSeed = (hash / 3) % 1000

        Canvas { context, size in
            let cellSize = size.width / CGFloat(cellCount)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            // 🌈 rainbow burst grid
            for x in 0..<cellCount {
                for y in 0..<cellCount {
                    let dx = Double(x) - Double(cellCount) / 2
                    let dy = Double(y) - Double(cellCount) / 2
                    let dist = sqrt(dx * dx + dy * dy)
                    let hue = (baseHue + dist * 0.1).truncatingRemainder(dividingBy: 1.0)

                    let sizeMod = sin(dist + Double(hash % 30)) * 0.5 + 0.8
                    let rect = CGRect(
                        x: CGFloat(x) * cellSize,
                        y: CGFloat(y) * cellSize,
                        width: cellSize * CGFloat(sizeMod),
                        height: cellSize * CGFloat(sizeMod)
                    )

                    context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(Color(hue: hue, saturation: 1, brightness: 1)))
                }
            }

            // 💥 central explosion — viscous bloom
            for i in 0..<12 {
                let angle = Double(i) * .pi / 6 + Double(hash % 20) * 0.01
                let radius = Double(20 + (hash % 10))
                let x = center.x + CGFloat(cos(angle) * radius)
                let y = center.y + CGFloat(sin(angle) * radius)
                let hue = (baseHue + Double(i) * 0.07).truncatingRemainder(dividingBy: 1.0)

                let spatterSize = CGFloat((hash % (i + 3)) + 4)

                let blob = CGRect(x: x, y: y, width: spatterSize, height: spatterSize)
                context.fill(Path(ellipseIn: blob), with: .color(Color(hue: hue, saturation: 1, brightness: 1)))
            }

            // 🦠 sentient spores expanding
            for i in 0..<40 {
                let angle = Double(i) * .pi / 20
                let orbit = Double(15 + (sporeSeed % (i + 5)))
                let x = center.x + CGFloat(cos(angle) * orbit)
                let y = center.y + CGFloat(sin(angle) * orbit)

                for gen in 0..<5 {
                    let offsetX = CGFloat(sin(Double(gen) + angle) * Double(gen) * 1.2)
                    let offsetY = CGFloat(cos(Double(gen) + angle) * Double(gen) * 1.2)
                    let hue = (baseHue + Double(i) * 0.03 + Double(gen) * 0.02).truncatingRemainder(dividingBy: 1.0)

                    let dotRect = CGRect(x: x + offsetX, y: y + offsetY, width: 1.5 + CGFloat(gen), height: 1.5 + CGFloat(gen))
                    context.fill(Path(ellipseIn: dotRect), with: .color(Color(hue: hue, saturation: 1, brightness: 1 - Double(gen) * 0.1)))
                }
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
    }
}
func stableHash(_ input: String) -> Int {
    input.utf8.reduce(0) { ($0 &* 31) &+ Int($1) }
}

