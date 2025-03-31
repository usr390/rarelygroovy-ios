import Foundation

class ArtistsViewModel: ObservableObject {
    @Published var artists: [Artist] = []
    @Published var isLoading: Bool = false
    private var firstLoad = true
    private var logoutObserver: Any?

    init() {
        logoutObserver = NotificationCenter.default.addObserver(forName: Notification.Name("UserDidLogout"), object: nil, queue: .main) { [weak self] _ in
            self?.fetchArtists()
        }
        NotificationCenter.default.addObserver(forName: Notification.Name("UserDidLogin"), object: nil, queue: .main) { [weak self] _ in
            self?.fetchArtists()
        }
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
        
        var urlComponents = URLComponents(string: "https://enm-project-production.up.railway.app/api/artistDirectory")
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
    }}
