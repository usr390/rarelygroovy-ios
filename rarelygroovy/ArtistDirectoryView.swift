import SwiftUI
import FontAwesome_swift

struct ArtistDirectoryView: View {
    
    @StateObject private var viewModel = ArtistsViewModel()
    @StateObject private var statsVM = PlusStatsViewModel()
    
    // User’s typed text for name filtering
    @State private var searchText = ""
    
    // User’s selected top-level genres (chips)
    @State private var selectedTopLevelGenres = Set<String>()
    
    // Extra filter states
    @State private var isRandomArtistMode: Bool = false
    @State private var isTimelineMode: Bool = false
    @State private var isRecentlyTouredMode: Bool = false
    @State private var isWomanFrontedMode: Bool = false
    @State private var randomArtist: Artist? = nil
    // Extra filter state for Recently Added
    @State private var isRecentlyAddedMode: Bool = false
    @State private var selectedPlatformChips = Set<String>()
    @Environment(\.colorScheme) var colorScheme
    @State private var showPlusOverlay = false
    @State private var isPastArtistsMode: Bool = false
    private func matchesPastArtistsFilter(_ artist: Artist) -> Bool {
        guard isPastArtistsMode else { return true }
        return artist.status.lowercased() != "active"
    }
    
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
    
    let platformChips: [(key: String, label: String)] = [
            ("spotify", "Spotify"),
            ("apple", "Apple Music"),
            ("bandcamp", "Bandcamp"),
            ("soundcloud", "SoundCloud"),
            ("mixcloud", "Mixcloud"),
            ("youtube", "YouTube"),
            ("twitch", "Twitch"),
            ("instagram", "Instagram"),
            ("facebook", "Facebook"),
            ("tiktok", "TikTok"),
            ("x", "X"),
            ("threads", "Threads"),
            ("tumblr", "Tumblr"),
            ("self", "Website"),
            ("lastfm", "Last.fm"),
            ("discogs", "Discogs"),
            ("deezer", "Deezer")
        ]

    private var filteredArtists: [Artist] {
        viewModel.artists
            .filter(matchesSearchText)
            .filter(matchesGenreSelection)
            .filter(matchesPlatformFilter)
            .filter(matchesRecentlyTouredFilter)
            .filter(matchesPastArtistsFilter)
            .filter(matchesWomanFrontedFilter)
    }

    private var sortedArtists: [Artist] {
        if isTimelineMode {
            return filteredArtists.sorted { ($0.start.prefix(4)) > ($1.start.prefix(4)) }
        } else if isRecentlyAddedMode {
            return filteredArtists.sorted { creationTimestamp(from: $0.id) > creationTimestamp(from: $1.id) }
        } else {
            return filteredArtists
        }
    }

    private var displayedArtists: [Artist] {
        if isRandomArtistMode, let artist = randomArtist {
            return [artist]
        } else {
            return sortedArtists
        }
    }

    private func matchesSearchText(_ artist: Artist) -> Bool {
        searchText.isEmpty || artist.name.lowercased().contains(searchText.lowercased())
    }

    private func matchesGenreSelection(_ artist: Artist) -> Bool {
        guard !selectedTopLevelGenres.isEmpty else { return true }
        let artistSubs = artist.genre.map { $0.lowercased() }
        return selectedTopLevelGenres.contains {
            guard let subgenres = genreMapping[$0] else { return false }
            return !Set(artistSubs).isDisjoint(with: subgenres)
        }
    }

    private func matchesPlatformFilter(_ artist: Artist) -> Bool {
      guard !selectedPlatformChips.isEmpty else { return true }
      // OR-style: show artist if they have *any* of the selected platforms
      return selectedPlatformChips.contains { platform in
        guard let link = artist.links?[platform] else { return false }
        return link.lowercased() != "pending"
      }
    }

    private func matchesRecentlyTouredFilter(_ artist: Artist) -> Bool {
        if isRecentlyTouredMode {
            return artist.location.lowercased() != "rgv" // non-RGV only
        } else {
            return true // show all by default
        }
    }
    
    private func matchesWomanFrontedFilter(_ artist: Artist) -> Bool {
        guard isWomanFrontedMode else { return true }
        return artist.womanfronted ?? false
    }
    
    // Final list after applying extra filters
    private var finalArtists: [Artist] {
        var artists = filteredArtists

        if isTimelineMode {
            artists = artists.sorted {
                let year1 = Int($0.start.prefix(4)) ?? 0
                let month1 = Int($0.start.dropFirst(5).prefix(2)) ?? 0
                let day1 = Int($0.start.dropFirst(8).prefix(2)) ?? 0
                
                let year2 = Int($1.start.prefix(4)) ?? 0
                let month2 = Int($1.start.dropFirst(5).prefix(2)) ?? 0
                let day2 = Int($1.start.dropFirst(8).prefix(2)) ?? 0
                
                if year1 != year2 {
                    return year1 > year2
                } else if month1 != month2 {
                    return month1 > month2
                } else {
                    return day1 > day2
                }
            }
        }

        if isRandomArtistMode, let artist = randomArtist {
            return [artist]
        }

        if isRecentlyAddedMode {
            artists = artists.sorted {
                creationTimestamp(from: $0.id) > creationTimestamp(from: $1.id)
            }
        }

        return artists
    }
    
    func chipBackground(isSelected: Bool) -> Color {
        if isSelected {
            return colorScheme == .dark ? Color.white : Color.primary
        } else {
            return colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)
        }
    }

    func chipForeground(isSelected: Bool) -> Color {
        if isSelected {
            return colorScheme == .dark ? Color.black : Color.white
        } else {
            return colorScheme == .dark ? Color.white : Color.primary
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                
                // 3) Main scrollable list of artists using finalArtists
                ScrollView {
                    // 1) Free-text search field with clear button
                    ZStack(alignment: .trailing) {
                        TextField("Search artists...", text: $searchText)
                            .padding(10)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
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
                    
                    // Genre chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
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
                                        .background(chipBackground(isSelected: isSelected))
                                        .foregroundColor(chipForeground(isSelected: isSelected))
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.vertical, 8)

                    // Social media / streaming platform chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(platformChips, id: \.key) { platform in
                                // in your ScrollView(forEach platformChips)…
                                let isSelected = selectedPlatformChips.contains(platform.key)
                                Button {
                                  if isSelected {
                                    selectedPlatformChips.remove(platform.key)
                                  } else {
                                    selectedPlatformChips.insert(platform.key)
                                  }
                                } label: {
                                  Text(platform.label)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(chipBackground(isSelected: isSelected))
                                        .foregroundColor(chipForeground(isSelected: isSelected))
                                        .cornerRadius(16)                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.bottom, 8)

                    // Horizontal scroll view for extra filter chips (Random Artist, Timeline, Recently Toured)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Random Artist Chip
                            Button(action: {
                                isRandomArtistMode.toggle()
                                randomArtist = isRandomArtistMode ? sortedArtists.randomElement() : nil
                            }) {
                                HStack(spacing: 4) {
                                    Text("Random Artist")
                                    Image(systemName: "shuffle")
                                        .imageScale(.medium)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(chipBackground(isSelected: isRandomArtistMode))
                                .foregroundColor(chipForeground(isSelected: isRandomArtistMode))
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
                                .background(chipBackground(isSelected: isRecentlyAddedMode))
                                .foregroundColor(chipForeground(isSelected: isRecentlyAddedMode))
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
                                .background(chipBackground(isSelected: isTimelineMode))
                                .foregroundColor(chipForeground(isSelected: isTimelineMode))
                                .cornerRadius(16)
                            }
                            
                            Button(action: {
                                if true {
                                    isPastArtistsMode.toggle()
                                } else {
                                    withAnimation {
                                        showPlusOverlay = true  // make sure this state is declared and tied to your perks overlay
                                    }
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("Past Artists")
                                    Image(systemName: "clock.arrow.circlepath")
                                        .imageScale(.medium)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(chipBackground(isSelected: isPastArtistsMode))
                                .foregroundColor(chipForeground(isSelected: isPastArtistsMode))
                                .cornerRadius(16)
                            }
                            
                            Button(action: {
                                isWomanFrontedMode.toggle()
                            }) {
                                HStack(spacing: 4) {
                                    Text("Woman Fronted")
                                    Image(systemName: "crown.fill")
                                        .imageScale(.medium)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(chipBackground(isSelected: isWomanFrontedMode))
                                .foregroundColor(chipForeground(isSelected: isWomanFrontedMode))
                                .cornerRadius(16)
                            }
                            
                            Button(action: {
                                if true {
                                    isRecentlyTouredMode.toggle()
                                } else {
                                    withAnimation {
                                        showPlusOverlay = true
                                    }
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("Recently Toured")
                                    Image(systemName: "bus")
                                        .imageScale(.medium)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(chipBackground(isSelected: isRecentlyTouredMode))
                                .foregroundColor(chipForeground(isSelected: isRecentlyTouredMode))
                                .cornerRadius(16)
                            }                        }
                        .padding(.horizontal, 8) // Explicit 8pt padding left/right
                    }
                    .padding(.bottom, 8)
                    
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading Artists...")
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemBackground).opacity(0.8))

                    }
                    if !viewModel.isLoading {
                        HStack {
                            Text("\(finalArtists.count) of \(viewModel.artists.count) artists shown")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                            Spacer()
                        }
                    }
                    
                    LazyVStack(alignment: .center, spacing: 0) {
                        
                        if finalArtists.isEmpty && !viewModel.artists.isEmpty {
                            VStack(spacing: 12) {
                                Divider()
                                
                                Text("No artists match search criteria.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 8)
                                
                                Divider()

                                VStack(alignment: .leading, spacing: 4) {
                                  Text("* Information presented is our best estimate")
                                }
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                            }
                            .padding(.horizontal)
                        }
                    else {
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
                                    let nameText = Text(artist.name)
                                    let locationText = artist.location.uppercased() != "RGV"
                                    ? Text(",\(artist.location.uppercased())")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color(red: 0.58, green: 0.44, blue: 0.86))
                                        : Text("")

                                    (nameText + locationText)
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
                                                primary = "\(startYear) - \(endYear), \(artist.status)"
                                            } else {
                                                primary = "\(startYear) - \(artist.status)"
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
                                    let validLinks = (artist.links ?? [:]).filter {
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

                                    let threshold = 6
                                    let firstRow = Array(customSortedLinks.prefix(threshold))
                                    let secondRow = Array(customSortedLinks.dropFirst(threshold))

                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 16) {
                                            ForEach(firstRow, id: \.key) { key, value in
                                                if let url = URL(string: value) {
                                                    let icon = fontAwesomeIcon(for: key)
                                                    Link(destination: url) {
                                                        Text(String.fontAwesomeIcon(name: icon))
                                                            .font(.custom(fontName(for: icon), size: 24))
                                                            .foregroundColor(.secondary)
                                                            .frame(width: 35, height: 40)
                                                    }
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .center)


                                        if !secondRow.isEmpty {
                                            HStack(spacing: 16) {
                                                ForEach(secondRow, id: \.key) { key, value in
                                                    if let url = URL(string: value) {
                                                        let icon = fontAwesomeIcon(for: key)
                                                        Link(destination: url) {
                                                            Text(String.fontAwesomeIcon(name: icon))
                                                                .font(.custom(fontName(for: icon), size: 24))
                                                                .foregroundColor(.secondary)
                                                                .frame(width: 35, height: 40)
                                                        }
                                                    }
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .center)
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 16)
                                
                                Divider()
                            }
                            if !viewModel.isLoading && !viewModel.artists.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                  Text("* Information presented is our best estimate")
                                }
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
                    .padding(.horizontal)
                }
                .refreshable {
                    viewModel.fetchArtists(userInitiated: true)
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserDidPlusify"))) { _ in
                    viewModel.fetchArtists(userInitiated: false)
                }
            }
        }
        .onAppear {
            if viewModel.artists.isEmpty {
                viewModel.fetchArtists()
            }
        }
        .sheet(isPresented: $showPlusOverlay) {
          ArtistsRarelygroovyPlusOverlay(statsVM: statsVM, userIsSignedIn: AuthManager.shared.user != nil)
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
        if let mixcloudIcon = FontAwesome(rawValue: "mixcloud") {
            return mixcloudIcon
        } else {
            return .mixcloud
        }
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



struct ArtistsRarelygroovyPlusOverlay: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme
  @ObservedObject var statsVM: PlusStatsViewModel
    @EnvironmentObject var store: Store
    let userIsSignedIn: Bool


  var body: some View {
    ZStack {
      Color(colorScheme == .dark ? .black : .white)
        .ignoresSafeArea()

      ScrollView {
        VStack(spacing: 24) {
          HStack {
            Spacer()
            Button { dismiss() } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.secondary)
            }
          }

          VStack(spacing: 8) {
            Image(colorScheme == .dark ? "logo-bw" : "logo-wb")
              .resizable()
              .scaledToFit()
              .frame(width: 100, height: 100)
            Text("Upgrade to Rarelygroovy+")
              .font(.title2).fontWeight(.bold)
              .foregroundColor(.primary)
          }

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

          // themed action button
            Group {
              if userIsSignedIn {
                  VStack(spacing: 8) {
                      Button("upgrade for \(store.products[0].displayPrice)") {
                          Task {
                              try await store.purchase(store.products[0])
                          }
                      }
                      .frame(maxWidth: .infinity)
                      .padding()
                      .background(colorScheme == .dark ? Color.white : Color.black)
                      .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                      .cornerRadius(12)
                      
                      Text("(one time purchase)")
                          .font(.footnote)
                          .foregroundColor(.white)
                  }
              } else {
                Text("Log in or sign up for Rarelygroovy to upgrade")
                  .font(.body)
                  .foregroundColor(.secondary)
                  .frame(maxWidth: .infinity)
                  .multilineTextAlignment(.center)
                  .padding()
                  .overlay(
                    RoundedRectangle(cornerRadius: 12)
                      .stroke(Color.secondary, lineWidth: 1)
                  )
              }
            }
            .padding(.horizontal)
        }
        .padding()
        .multilineTextAlignment(.center)
      }
    }
    .onAppear { statsVM.fetchAll() }
  }
}
