import SwiftUI
import FontAwesome_swift

struct ArtistDirectoryView: View {
    @StateObject private var viewModel = ArtistsViewModel()
    
    // User’s typed text for name filtering
    @State private var searchText = ""
    
    // User’s selected top-level genres (chips)
    @State private var selectedTopLevelGenres = Set<String>()
    
    // Extra filter states
    @State private var isRandomArtistMode: Bool = false
    @State private var isTimelineMode: Bool = false
    @State private var isRecentlyTouredMode: Bool = false
    @State private var randomArtist: Artist? = nil
    // Extra filter state for Recently Added
    @State private var isRecentlyAddedMode: Bool = false
    
    // Dictionary mapping top-level genres to subgenres
    let genreMapping: [String: [String]] = [
        "rock": [
            "rock", "alternative rock", "indie rock", "pop rock", "psychedelic rock", "stoner rock",
            "hard rock", "glam rock", "spanish rock", "soft rock", "surf rock", "garage rock",
            "grunge rock", "psychedlic rock", "grunge", "classic rock", "texicana", "death rock", "doom rock",
            "progressive rock", "art rock", "voidgaze", "ambient rock", "math rock", "avant rock", "post rock",
            "goth rock", "experimental progressive rock", "sad rock", "progressive pop rock", "chankla-gaze",
            "lofi rock", "post progressive", "beach rock"
        ],
        "punk": [
            "punk", "pop punk", "hardcore punk", "punk rock", "egg punk", "chain punk", "soft punk",
            "queercore", "psych punk", "synth punk", "emo", "emocore", "hardcore rock", "beatdown",
            "post hardcore", "easycore", "new wave", "digital hardcore", "hardcore", "dbeat", "mangel",
            "melodic hardcore", "dance punk", "gulf coast emo"
        ],
        "metal": [
            "metal", "symphonic metal", "doom metal", "black'n'roll", "nwobhm", "avant metal",
            "brutal death metal", "thrash metal", "black metal",
            "death metal", "power metal", "heavy metal", "groove metal", "war metal",
            "slam metal", "drone metal", "progressive metal", "speed metal", "deathcore",
            "nu-metalcore", "blackened death metal", "blackened deathcore", "trap metal", "grind", "grindcore",
            "metalcore", "doomgaze", "sludge", "hate metal",
            "alternative metal", "experimental metal", "groove metal", "voidgaze", "djent", "extreme metal",
            "downtempo", "false grind"
        ],
        "edm": [
            "edm", "techno", "house", "dubstep", "hard techno", "tech house", "psytrance", "deep house",
            "trance", "breakcore", "breakbeat hardcore", "electronica", "psychedelic trance", "digital hardcore", "electro", "gabber"
        ],
        "rap": [
            "rap", "hip hop", "trap", "experimental hip hop", "trill hop", "sample hop", "phonk", "trap metal",
            "latin rap", "gangsta rap"
        ],
        "experimental": [
            "experimental", "avant garde", "avant rock", "experimental pop", "experimental progressive rock",
            "experimental noise", "experimental rock", "experimental hip hop", "experimental metal", "industrial", "voidgaze",
            "witch house", "drone"
        ],
        "jazz": [
            "jazz", "neosoul"
        ],
        "pop": [
            "pop", "pop rock", "pop punk", "indie pop", "power pop", "bedroom pop", "alternative pop",
            "experimental pop", "dark pop", "electronic pop", "kawaii hip hop", "synth pop", "synth rock", "dream pop",
            "sad pop", "void pop", "jangle pop"
        ],
        "latin": [
            "latin", "bolero", "cumbia", "norteño", "latin pop", "reggaeton", "regional mexican", "tropifolk",
            "texicana", "perreo", "boleroglam"
        ],
        "reggae": [
            "reggae", "dub", "rocksteady", "ska", "dancehall"
        ],
        "electronic": [
            "electronic", "techno", "dubstep", "triphop", "tech house", "house", "electronica", "synthwave",
            "vaporwave", "darkwave", "coldwave", "ebm", "idm", "chiptune", "acid", "minimal", "rhythmic noise",
            "future beats", "gabber"
        ],
        "soul": [
            "soul", "neosoul", "indie soul"
        ],
        "acoustic": [
            "acoustic"
        ],
        "folk": [
            "folk", "americana folk", "folk pop", "folk rock", "folktronica"
        ],
        "blues": [
            "blues"
        ],
        "other": [
            "new age", "kitschwave", "chiptune. lsdj", "instrumental", "ambient", "psychedelic", "outsider", "goth",
            "disco", "club", "no wave", "midwest", "lofi", "neosoul", "acoustic", "instrumental",
            "world music", "orchestral", "rhythmic noise", "dirge",
            "fusion", "indie", "ebm", "dsmb", "alternative folk", "piano", "lounge", "indie soul"
        ]
    ]
    
    private var topLevelGenres: [String] {
        let desiredOrder = ["rock", "punk", "metal", "experimental", "edm",
                            "rap", "jazz", "pop", "latin", "other"]
        return desiredOrder.filter { genreMapping.keys.contains($0) }
    }
    
    // Final list of artists based on name and genre filters
    private var filteredArtists: [Artist] {
        let nameFiltered: [Artist]
        if searchText.isEmpty {
            nameFiltered = viewModel.artists
        } else {
            nameFiltered = viewModel.artists.filter { artist in
                artist.name.lowercased().contains(searchText.lowercased())
            }
        }
        
        if selectedTopLevelGenres.isEmpty {
            return nameFiltered
        } else {
            return nameFiltered.filter { artist in
                let artistSubs = artist.genre.map { $0.lowercased() }
                for top in selectedTopLevelGenres {
                    if let subgenres = genreMapping[top] {
                        if !Set(artistSubs).isDisjoint(with: Set(subgenres)) {
                            return true
                        }
                    }
                }
                return false
            }
        }
    }
    
    // Final list after applying extra filters
    private var finalArtists: [Artist] {
        var artists = filteredArtists
        if isRecentlyTouredMode {
            // Exclude local artists (assuming local == "rgv")
            artists = artists.filter { $0.location.lowercased() != "rgv" }
        }
        if isTimelineMode {
            // Sort by start year (convert first 4 characters to Int)
            artists = artists.sorted {
                let year1 = Int($0.start.prefix(4)) ?? 0
                let year2 = Int($1.start.prefix(4)) ?? 0
                return year1 > year2
            }
        }
        if isRandomArtistMode, let artist = randomArtist {
            return [artist]
        }
        if isRecentlyAddedMode {
            // Sort descending by creation timestamp from the artist ID
            artists = artists.sorted {
                creationTimestamp(from: $0.id) > creationTimestamp(from: $1.id)
            }
        }
        return artists
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                
                // 3) Main scrollable list of artists using finalArtists
                ScrollView {
                    // 1) Free-text search field with clear button
                    ZStack(alignment: .trailing) {
                        TextField("Search artists...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                    .padding([.horizontal, .top])
                    
                    // 2b) Horizontal chips for top-level genres
                    // Horizontal chips for top-level genres with Clear All chip as left-most chip
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Genre chips
                            ForEach(topLevelGenres, id: \.self) { topLevel in
                                let isSelected = selectedTopLevelGenres.contains(topLevel)
                                Button {
                                    if isSelected {
                                        selectedTopLevelGenres.remove(topLevel)
                                    } else {
                                        selectedTopLevelGenres.insert(topLevel)
                                    }
                                } label: {
                                    Text(topLevel.capitalized)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color.primary : Color.gray.opacity(0.3))
                                        .foregroundColor(isSelected ? Color.black : .primary)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.vertical, 8)
                    
                    // 2c) Horizontal scroll view for extra filter chips (Random Artist, Timeline, Recently Toured)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Random Artist Chip
                            Button(action: {
                                isRandomArtistMode.toggle()
                                if isRandomArtistMode {
                                    randomArtist = filteredArtists.randomElement()
                                } else {
                                    randomArtist = nil
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("Random Artist")
                                    Image(systemName: "shuffle")
                                        .imageScale(.medium)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isRandomArtistMode ? Color.primary : Color.gray.opacity(0.3))
                                .foregroundColor(isRandomArtistMode ? Color.black : .primary)
                                .cornerRadius(16)
                            }
                            
                            // Timeline Chip
                            Button(action: {
                                isTimelineMode.toggle()
                            }) {
                                HStack(spacing: 4) {
                                    Text("Timeline")
                                    Image(systemName: "arrow.up.arrow.down")
                                        .imageScale(.medium)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isTimelineMode ? Color.primary : Color.gray.opacity(0.3))
                                .foregroundColor(isTimelineMode ? Color.black : .primary)
                                .cornerRadius(16)
                            }
                            
                            // Recently Toured Chip
                            Button(action: {
                                isRecentlyTouredMode.toggle()
                            }) {
                                HStack(spacing: 4) {
                                    Text("Recently Toured")
                                    Image(systemName: "bus")
                                        .imageScale(.medium)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isRecentlyTouredMode ? Color.primary : Color.gray.opacity(0.3))
                                .foregroundColor(isRecentlyTouredMode ? Color.black : .primary)
                                .cornerRadius(16)
                            }
                            
                            // Recently Added Chip
                            Button(action: {
                                isRecentlyAddedMode.toggle()
                            }) {
                                HStack(spacing: 4) {
                                    Text("Recently Added")
                                    Image(systemName: "clock")
                                        .imageScale(.medium)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isRecentlyAddedMode ? Color.primary : Color.gray.opacity(0.3))
                                .foregroundColor(isRecentlyAddedMode ? Color.black : .primary)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 8)  // Ensure explicit 8pt padding on left and right
                    }
                    .padding(.bottom, 8)
                    LazyVStack(alignment: .center, spacing: 0) {
                        if finalArtists.isEmpty && !viewModel.isLoading {
                            Text("No artists match search criteria.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.top, 40)
                        } else {
                            ForEach(finalArtists) { artist in
                                VStack(alignment: .center, spacing: 8) {
                                    // Only show creation date when Recently Added filter is active
                                    if isRecentlyAddedMode {
                                        Text("Added " + formattedCreationDate(from: artist.id))
                                            .italic()
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                            .padding(4)
                                            .background(Color(UIColor.systemBackground).opacity(0.8))
                                            .cornerRadius(4)
                                            .padding([.top, .trailing], 4)
                                    }
                                    // Artist name with location (if not "rgv")
                                    Text(artist.name + (artist.location.uppercased() != "RGV" ? " (\(artist.location.uppercased()))" : ""))
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    // Prepare display parts
                                    // Prepare parts
                                    let mediumPart = artist.medium ?? ""
                                    let genrePart = artist.genre.joined(separator: " · ")

                                    // Date range part with status when applicable
                                    let dateRangePart: String = {
                                        // Primary career leg (without status if a secondary leg exists)
                                        var primary = ""
                                        if !artist.start.isEmpty && artist.start.lowercased() != "pending" {
                                            let startYear = String(artist.start.prefix(4))
                                            if let endVal = artist.end, !endVal.isEmpty, endVal.lowercased() != "pending" {
                                                let endYear = String(endVal.prefix(4))
                                                primary = "\(startYear) - \(endYear)"
                                            } else {
                                                primary = "\(startYear) - current"
                                            }
                                        }
                                        
                                        // Secondary career leg (comeback) with status
                                        var secondary = ""
                                        if let start2 = artist.start2, !start2.isEmpty, start2.lowercased() != "pending" {
                                            let startYear2 = String(start2.prefix(4))
                                            if let end2 = artist.end2, !end2.isEmpty, end2.lowercased() != "pending" {
                                                let endYear2 = String(end2.prefix(4))
                                                secondary = "\(startYear2) - \(endYear2)"
                                            } else {
                                                secondary = "\(startYear2) - current"
                                            }
                                        }
                                        
                                        // Combine the two legs: if both exist, drop any status from the primary leg.
                                        if !primary.isEmpty && !secondary.isEmpty {
                                            if let commaIndex = primary.firstIndex(of: ",") {
                                                primary = String(primary[..<commaIndex])
                                            }
                                            return primary + ", " + secondary
                                        } else if !primary.isEmpty {
                                            return primary
                                        } else {
                                            return secondary
                                        }
                                    }()


                                    // In your view:
                                    VStack(alignment: .center, spacing: 4) {
                                        // Line 1: Genre only
                                        if !genrePart.isEmpty {
                                            Text(genrePart)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                        
                                        // Line 2: Medium and Date Range combined
                                        let mediumDateString: String = {
                                            var s = ""
                                            if !mediumPart.isEmpty {
                                                s += mediumPart
                                            }
                                            if !dateRangePart.isEmpty {
                                                if !s.isEmpty { s += "     " } // extra spacing if both present
                                                s += dateRangePart.replacingOccurrences(of: " - ", with: "\u{00A0}-\u{00A0}")
                                            }
                                            return s
                                        }()
                                        
                                        if !mediumDateString.isEmpty {
                                            Text(mediumDateString)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                    // Valid links
                                    if let links = artist.links {
                                        let validLinks = links.filter {
                                            if let url = URL(string: $0.value),
                                               let scheme = url.scheme,
                                               ["http", "https"].contains(scheme) {
                                                return true
                                            }
                                            return false
                                        }
                                        let customSortedLinks = validLinks.sorted { a, b in
                                            rank(for: a.key) < rank(for: b.key)
                                        }
                                        if !validLinks.isEmpty {
                                            HStack(spacing: 16) {
                                                ForEach(customSortedLinks, id: \.key) { key, value in
                                                    if let url = URL(string: value) {
                                                        let icon = fontAwesomeIcon(for: key)
                                                        Link(destination: url) {
                                                            Text(String.fontAwesomeIcon(name: icon))
                                                                .font(.custom(fontName(for: icon), size: 24))
                                                                .foregroundColor(.secondary)
                                                        }
                                                        .frame(width: 35, height: 40)
                                                    }
                                                }
                                            }
                                            .padding(.top, 4)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 16)
                                
                                Divider()
                            }
                            // Disclaimer at the bottom
                            if !viewModel.isLoading && !viewModel.artists.isEmpty {
                                Text("* Start and end years are best estimates")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("Artist Directory")
                .refreshable {
                    viewModel.fetchArtists(userInitiated: true)
                }
                
                if viewModel.isLoading {
                    VStack {
                        ProgressView("Loading Artists...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: -200)
                    .background(Color(UIColor.systemBackground).opacity(0.8))
                }
            }
        }
        .onAppear {
            if viewModel.artists.isEmpty {
                viewModel.fetchArtists()
            }
        }
    }
}

// MARK: - FontAwesome Helpers, Link Ranking, etc.
func fontAwesomeIcon(for key: String) -> FontAwesome {
    let lowerKey = key.lowercased()
    if lowerKey.contains("apple") {
        return .apple
    } else if lowerKey.contains("spotify") {
        return .spotify
    } else if lowerKey.contains("bandcamp") {
        return .bandcamp
    } else if lowerKey.contains("youtube") {
        return .youtube
    } else if lowerKey.contains("soundcloud") {
        return .soundcloud
    } else if lowerKey.contains("instagram") {
        return .instagram
    } else if lowerKey.contains("tiktok") {
        return .tiktok
    } else if lowerKey.contains("facebook") {
        return .facebook
    } else if lowerKey.contains("mixcloud") {
        return .mixcloud
    } else if lowerKey.contains("self") {
        return .globe
    } else if lowerKey.contains("x") {
        if let xTwitterIcon = FontAwesome(rawValue: "x-twitter") {
            return xTwitterIcon
        } else {
            return .twitter
        }
    } else {
        return .music
    }
}

func fontName(for icon: FontAwesome) -> String {
    switch icon {
    case .apple, .spotify, .bandcamp, .youtube, .instagram, .tiktok, .facebook, .twitter, .soundcloud:
        return "FontAwesome6Brands-Regular"
    default:
        return "FontAwesome6Free-Solid-900"
    }
}

let preferredOrder: [String] = [
    "spotify",
    "apple",
    "bandcamp",
    "soundcloud",
    "mixcloud",
    "youtube",
    "twitch",
    "facebook",
    "instagram",
    "myspace",
    "tiktok",
    "x",
    "threads",
    "tumblr",
    "self",
    "lastfm",
    "discogs",
    "deezer"
]

func rank(for key: String) -> Int {
    let lowerKey = key.lowercased()
    return preferredOrder.firstIndex(of: lowerKey) ?? Int.max
}

// Helper: Extract creation timestamp from a MongoDB ObjectID
func creationTimestamp(from objectId: String) -> TimeInterval {
    let hexString = String(objectId.prefix(8))
    if let timestamp = UInt32(hexString, radix: 16) {
        return TimeInterval(timestamp)
    }
    return 0
}

// Updated helper: Format the creation date using "MM/dd/yyyy, h:mm a" format
func formattedCreationDate(from objectId: String) -> String {
    let timestamp = creationTimestamp(from: objectId)
    let date = Date(timeIntervalSince1970: timestamp)
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yyyy, h:mm a"  // e.g., "04/27/2025, 3:45 PM"
    return formatter.string(from: date)
}
