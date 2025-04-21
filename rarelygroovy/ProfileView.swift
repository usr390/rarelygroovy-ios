import SwiftUI
import StoreKit

struct ProfileView: View {
    @EnvironmentObject var store: Store
    
    @ObservedObject var authManager = AuthManager.shared
    @State private var showUpgradeDrawer = false
    @Environment(\.colorScheme) var colorScheme
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 24) {
            
            // Toolbar
            HStack {
                Spacer()
                Menu {
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
            
            // Stats
            HStack(spacing: 12) {
                StatCard(title: "Events", count: 12)
                StatCard(title: "Artists", count: 5)
                StatCard(title: "Bookmarks", count: 3)
            }
            .padding(.horizontal)
            
            // Premium Section
            if let user = authManager.user {
                VStack(alignment: .leading, spacing: 12) {
                    if user.plus {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Rarelygroovy+")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Access full artist history", systemImage: "music.note.list")
                                Label("See exclusive events", systemImage: "calendar")
                                Label("Support the local scene", systemImage: "heart.fill")
                            }
                            .font(.body)
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8) // tighter side padding *just for this block*
                    } else {
                        Text("Rarelygroovy+")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Unlock our full event list and artist directory.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
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
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16) // tighter left/right
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
                .padding(.horizontal) // keeps outer spacing consistent with other sections
            }
            Spacer()
        }
        .sheet(isPresented: $showUpgradeDrawer) {
            UpgradeDrawerOverlay(showDrawer: $showUpgradeDrawer, product: store.products.first!, purchasingEnabled: true)
        }
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
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Account deleted")
                DispatchQueue.main.async {
                    authManager.user = nil
                    NotificationCenter.default.post(name: Notification.Name("UserDidLogout"), object: nil)
                }
            } else {
                let message = String(data: data, encoding: .utf8) ?? "(no response)"
                print("❌ Failed to delete account")
            }
        } catch {
            print("❌ Error deleting account: \(error)")
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
                    // insert your logo image here
                    Image(colorScheme == .dark ? "logo-bw" : "logo-wb")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .padding(.bottom, 8)
                    
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
