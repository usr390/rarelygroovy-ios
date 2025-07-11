import Foundation

class ArtistsViewModel: ObservableObject {
    @Published var artists: [Artist] = []
    @Published var isLoading: Bool = false
    @Published var inactiveLocalCount: Int? = nil      // ← new
    @Published var touringArtistsCount: Int?   = nil  // ← number of touring artists

    
    private var firstLoad = true
    private var logoutObserver: Any?
    
    init() {
        logoutObserver = NotificationCenter.default.addObserver(forName: Notification.Name("UserDidLogout"), object: nil, queue: .main) { [weak self] _ in
            self?.fetchArtists()
        }
        NotificationCenter.default.addObserver(forName: Notification.Name("UserDidLogin"), object: nil, queue: .main) { [weak self] _ in
            self?.fetchArtists()
        }
        fetchLocalInactiveAndTouringCounts()                        // ← initial fetch
        
    }
    
    deinit {
        if let observer = logoutObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func fetchArtists(userInitiated: Bool = false) {
        if firstLoad || !userInitiated {
            DispatchQueue.main.async { self.isLoading = true }
        }
        
        var urlComponents = URLComponents(string: "https://enm-project-production.up.railway.app/api/artistDirectoryTrans")
        if let username = AuthManager.shared.user?.username {
            urlComponents?.queryItems = [URLQueryItem(name: "username", value: username)]
        }
        guard let url = urlComponents?.url else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async { self.isLoading = false }
            
            if let error = error {
                print("Error fetching artists: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let decodedArtists = try JSONDecoder().decode([Artist].self, from: data)
                let sortedArtists = decodedArtists.sorted { a, b in
                    let aIsRGV = a.location.lowercased() == "rgv"
                    let bIsRGV = b.location.lowercased() == "rgv"
                    if aIsRGV && !bIsRGV { return true }
                    if !aIsRGV && bIsRGV { return false }
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                }
                
                DispatchQueue.main.async {
                    self.artists = sortedArtists
                    self.firstLoad = false
                }
            } catch {
                print("Error decoding artists: \(error)")
            }
        }.resume()
    }
    
    func fetchLocalInactiveAndTouringCounts() {
        guard let url = URL(string: "https://enm-project-production.up.railway.app/api/artists/local-inactive-count")
        else {
            print("❌ Invalid URL for counts")
            return
        }

        URLSession.shared.dataTask(with: url) { data, resp, error in
            if let err = error {
                print("❌ Error fetching counts:", err)
                return
            }
            guard
              let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let data = data
            else {
                print("❌ Bad response fetching counts")
                return
            }
            do {
                let decoded = try JSONDecoder()
                    .decode(LocalVsTouringCountResponse.self, from: data)
                DispatchQueue.main.async {
                    self.inactiveLocalCount  = decoded.inactiveLocalArtists
                    self.touringArtistsCount = decoded.touringArtists
                }
            } catch {
                print("❌ Decoding counts failed:", error)
            }
        }
        .resume()
    }
    
}

