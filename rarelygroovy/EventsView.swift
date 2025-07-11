import SwiftUI

struct EventsView: View {
    
    @StateObject private var viewModel = EventsViewModel()
    @StateObject private var statsVM = PlusStatsViewModel()
    
    @State private var searchQuery = ""
    @State private var nonRGVOnly = false  // New chip filter state
    @State private var recentlyAddedOnly = false  // New chip filter state
    @State private var selectedEventGenres = Set<String>()
    @State private var showDebutingOnly = false
    @Environment(\.colorScheme) var colorScheme
    @State private var showPlusOverlay = false
    @State private var showPastEventsOnly = false
    
    /// Takes any array of Events and applies your search + chip + genre + debut filters.
    private func applyFilters(to events: [Event]) -> [Event] {
        var list = events

        // 1) text search
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
          list = list.filter { event in
            let v = sanitize(event.venue?.name ?? "")
            let p = sanitize(event.promoter?.name ?? "")
            let c = sanitize(event.venue?.city ?? "")
            let artistMatch = event.artists?.contains {
              sanitize($0.name).localizedStandardContains(sanitize(trimmed))
            } ?? false

            return v.localizedStandardContains(sanitize(trimmed))
                || p.localizedStandardContains(sanitize(trimmed))
                || c.localizedStandardContains(sanitize(trimmed))
                || artistMatch
          }
        }

        // 2) touring
        if nonRGVOnly {
          list = list.filter { $0.artists?.contains { $0.location.lowercased() != "rgv" } ?? false }
        }

        // 3) recently added
        if recentlyAddedOnly {
          let cutoff = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
          list = list.filter {
            guard let s = parseCreatedAt($0.creationDateTime ?? "") else { return false }
            return s >= cutoff
          }
        }

        // 4) genre chips
        if !selectedEventGenres.isEmpty {
            // lowercased() must be *called*, not referenced
            let sel = Set(selectedEventGenres.map { $0.lowercased() })

            list = list.filter { event in
                guard let artists = event.artists else { return false }

                // flatten each artist’s genre array, lowercasing each string
                let genres = artists.flatMap { artist in
                    artist.genre.map { $0.lowercased() }
                }

                return !Set(genres).isDisjoint(with: sel)
            }
        }

        // 5) debuting
        if showDebutingOnly {
          list = list.filter {
            let v = $0.venue?.debut ?? false
            let p = $0.promoter?.debut ?? false
            let a = $0.artists?.contains { ($0.debut ?? false) || ($0.albumDebut ?? false) || ($0.rgvDebut ?? false) || ($0.lastShow ?? false) } ?? false
            return v || p || a
          }
        }

        return list
    }
    
    
    
    var body: some View {
        ZStack {
            VStack {
                let raw = showPastEventsOnly ? viewModel.pastEvents : viewModel.events
                let eventsToShow = applyFilters(to: raw)
                ScrollView {
                    // Search input field
                    ZStack(alignment: .trailing) {
                        TextField("Search events...", text: $searchQuery)
                            .padding(10)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                    .padding([.horizontal, .top])
                    
                    // Genre chip filters for events
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Create chips for each top-level genre (using your topLevelGenres property)
                            ForEach(topLevelGenres, id: \.self) { topLevel in
                                let isSelected = selectedEventGenres.contains(topLevel)
                                Button {
                                    if isSelected {
                                        selectedEventGenres.remove(topLevel)
                                    } else {
                                        selectedEventGenres.insert(topLevel)
                                    }
                                } label: {
                                    Text(topLevel.capitalized)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            isSelected
                                            ? (colorScheme == .dark ? Color.white : Color.primary)
                                            : (colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3))
                                        )
                                        .foregroundColor(
                                            isSelected
                                            ? (colorScheme == .dark ? Color.black : Color.white)
                                            : (colorScheme == .dark ? Color.white : Color.primary)
                                        )                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.vertical, 8)
                    // Debuting, touring, recently added chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            
                            // Debuting chip: only show if any event has a debuting artist.
                            // Debuting chip: only show if any event has a debuting artist.
                            if hasDebutingArtist {
                                Button(action: {
                                    showDebutingOnly.toggle()
                                }) {
                                    HStack {
                                        Text("Debuting")
                                        Image(systemName: "sparkles")
                                            .imageScale(.medium)
                                    }
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(chipBackground(isSelected: showDebutingOnly))
                                    .foregroundColor(chipForeground(isSelected: showDebutingOnly))
                                    .cornerRadius(16)
                                }
                            }
                            
                            // Touring chip
                            Button(action: {
                                nonRGVOnly.toggle()
                            }) {
                                HStack {
                                    Text("Touring")
                                    Image(systemName: "bus")
                                        .imageScale(.medium)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(chipBackground(isSelected: nonRGVOnly))
                                .foregroundColor(chipForeground(isSelected: nonRGVOnly))
                                .cornerRadius(16)
                            }
                            
                            // Recently Added chip
                            Button(action: {
                                recentlyAddedOnly.toggle()
                            }) {
                                HStack {
                                    Text("Recently Added")
                                    Image(systemName: "clock")
                                        .imageScale(.medium)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(chipBackground(isSelected: recentlyAddedOnly))
                                .foregroundColor(chipForeground(isSelected: recentlyAddedOnly))
                                .cornerRadius(16)
                            }
                            
                            // Past Events chip
                            Button(action: {
                                if true {
                                    showPastEventsOnly.toggle()
                                    if showPastEventsOnly {
                                        viewModel.fetchPastEvents()
                                    }
                                } else {
                                    withAnimation {
                                        showPlusOverlay = true
                                    }
                                }
                            }) {
                                HStack {
                                    Text("Past Events")
                                    Image(systemName: "clock.arrow.circlepath")
                                        .imageScale(.medium)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(chipBackground(isSelected: showPastEventsOnly))
                                .foregroundColor(chipForeground(isSelected: showPastEventsOnly))
                                .cornerRadius(16)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.bottom, 8)
                    
                    if viewModel.isLoading {
                        VStack {
                            Spacer()
                            ProgressView("Loading Events...")
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemBackground).opacity(0.8))
                    } else {
                        HStack {
                            Text("\(eventsToShow.count) of \(raw.count) events listed")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                            Spacer()
                        }
                    }
                    
                    LazyVStack(alignment: .leading, spacing: 16) {
                                                
                        if eventsToShow.isEmpty && !(showPastEventsOnly ? viewModel.pastEvents.isEmpty : viewModel.events.isEmpty) {
                            VStack(spacing: 12) {
                                Divider()
                                
                                Text("No events match search criteria.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 8)
                                
                                Divider()
                                
                                if !showPastEventsOnly {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("* Be sure to verify event info with official sources!")
                                    }
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 8)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            ForEach(Array(groupPastEventsByDay(eventsToShow).enumerated()), id: \.element.dayStart) { index, dayGroup in
                                // Group filtered events by day and iterate
                                // Day header with conditional top padding
                                Text(dayGroup.dayLabel)
                                    .font(.title)
                                    .foregroundColor(.secondary)
                                    .padding(.top, index == 0 ? 0 : 50)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                Divider()
                                    // For each event in that day...
                                    ForEach(dayGroup.events.indices, id: \.self) { i in
                                        let event = dayGroup.events[i]
                                        NavigationLink(destination: EventDetailView(event: event)) {
                                            VStack(alignment: .center, spacing: 8) {
                                                
                                                if let label = listingLabel(for: event, recentlyAddedActive: recentlyAddedOnly) {
                                                    Text(label)
                                                        .font(.footnote)
                                                        .foregroundColor(.secondary)
                                                        .italic()
                                                }
                                                
                                                if let venue = event.venue {
                                                    let venueName = venue.name ?? "Unknown"
                                                    // Use a regex to find text in parentheses
                                                    if let range = venueName.range(of: #"(\(.*\))"#, options: .regularExpression) {
                                                        let mainText = String(venueName[..<range.lowerBound])
                                                        let parenText = String(venueName[range])
                                                        // Concatenate two Text views with different fonts
                                                        (Text(mainText)
                                                            .font(.title)
                                                         + Text(parenText)
                                                            .font(.footnote))
                                                        .multilineTextAlignment(.center)
                                                    } else {
                                                        Text(venueName)
                                                            .font(.title)
                                                            .multilineTextAlignment(.center)
                                                    }
                                                }
                                                
                                                if let artists = event.artists, !artists.isEmpty {
                                                    let artistLine = artists.enumerated().map { index, artist -> Text in
                                                        var t = Text(artist.name)
                                                        
                                                        if artist.location != "RGV" {
                                                            t = t + Text(",\(artist.location.uppercased())")
                                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                                .foregroundColor(Color(red: 0.58, green: 0.44, blue: 0.86))
                                                        }
                                                        
                                                        if artist.debut ?? false {
                                                            t = t + Text(",DEBUT")
                                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                                .foregroundColor(Color(red: 0.34, green: 0.72, blue: 0.67))
                                                        }
                                                        
                                                        if artist.albumDebut ?? false {
                                                            t = t + Text(" ,ALBUM DEBUT")
                                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                                .foregroundColor(Color(red: 0.34, green: 0.72, blue: 0.67))
                                                        }
                                                        
                                                        if artist.rgvDebut ?? false {
                                                            t = t + Text(",RGV DEBUT")
                                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                                .foregroundColor(Color(red: 0.34, green: 0.72, blue: 0.67))
                                                        }
                                                        
                                                        if artist.comeback ?? false {
                                                            t = t + Text(",COMEBACK SHOW")
                                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                                .foregroundColor(Color(red: 0.34, green: 0.72, blue: 0.67))
                                                        }
                                                        if artist.lastShow ?? false {
                                                            t = t + Text(",LAST SHOW")
                                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                                .foregroundColor(Color(red: 0.34, green: 0.72, blue: 0.67))
                                                        }
                                                        
                                                        // Add separator if not last
                                                        if index < artists.count - 1 {
                                                            t = t + Text(" · ")
                                                        }
                                                        
                                                        return t
                                                    }.reduce(Text(""), +)
                                                    
                                                    artistLine
                                                        .lineSpacing(15)
                                                        .multilineTextAlignment(.center)
                                                        .frame(maxWidth: .infinity, alignment: .center)
                                                }
                                                
                                                // Promoter(s)
                                                if let promoter1 = event.promoter {
                                                    Divider()
                                                        .frame(width: 50, height: 1)
                                                        .background(Color.gray)
                                                        .padding(.vertical, 8)

                                                    // Combine primary and secondary promoters if available
                                                    let name1 = promoter1.name ?? "Unknown"
                                                    if let promoter2 = event.promoter2 {
                                                        let name2 = promoter2.name ?? "Unknown"
                                                        Text("\(name1) & \(name2)")
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                    } else {
                                                        Text(name1)
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                
                                                // Flyer link, ticket link
                                                HStack(spacing: 32) {
                                                    if let flyerLink = event.flyer,
                                                       flyerLink.lowercased() != "pending",
                                                       let url = URL(string: flyerLink) {
                                                        Link(destination: url) {
                                                            ZStack {
                                                                Image(systemName: "doc.text.fill")
                                                                    .resizable()
                                                                    .aspectRatio(contentMode: .fit)
                                                            }
                                                            .frame(width: 24, height: 24)
                                                            .padding(.vertical, 8)
                                                            .foregroundColor(.secondary)
                                                        }
                                                    }
                                                    
                                                    if let ticketsLink = event.tickets,
                                                       ticketsLink.lowercased() != "pending",
                                                       let url = URL(string: ticketsLink) {
                                                        Link(destination: url) {
                                                            Image(systemName: "ticket.fill")
                                                                .resizable()
                                                                .frame(width: 24, height: 24)
                                                                .padding(.vertical, 8)
                                                                .foregroundColor(.secondary)
                                                        }
                                                    }
                                                }
                                                
                                                // Row for door time, show time, cover
                                                // just above your HStack:
                                                let doorStr  = event.doorTime.flatMap(formatAsLocalTime)
                                                let showStr  = event.dateTime.flatMap(formatAsLocalTime)
                                                let monthDay = event.dateTime.flatMap(formatAsMonthDay)

                                                HStack(spacing: 3) {
                                                    // 1) doors + show
                                                    if let door = doorStr, let show = showStr {
                                                        Text("doors \(door), \(show)")
                                                            .font(.subheadline).foregroundColor(.secondary)
                                                    } else if let door = doorStr {
                                                        Text("doors \(door)")
                                                            .font(.subheadline).foregroundColor(.secondary)
                                                    } else if let show = showStr {
                                                        Text(show)
                                                            .font(.subheadline).foregroundColor(.secondary)
                                                    }

                                                    // 2) month-day always shown if available, but only prefix “·” when something preceded it
                                                    if let month = monthDay {
                                                        if doorStr != nil || showStr != nil {
                                                            Text("·")
                                                        }
                                                        Text(month)
                                                            .font(.subheadline).foregroundColor(.secondary)
                                                    }

                                                    // 3) cover: only prefix “·” if *anything* came before
                                                    if let cover = event.cover {
                                                        if doorStr != nil || showStr != nil || monthDay != nil {
                                                            Text("·")
                                                        }
                                                        if cover == 0 {
                                                            Text("No Cover")
                                                                .font(.subheadline).foregroundColor(.secondary)
                                                        } else {
                                                            Text("$\(cover)")
                                                                .font(.subheadline).foregroundColor(.secondary)
                                                        }
                                                    }
                                                }
                                                .frame(maxWidth: .infinity, alignment: .center)
                                                
                                                // Address
                                                if let venue = event.venue,
                                                   let city = venue.city,
                                                   let address = venue.address {
                                                    Button(action: {
                                                        openInMaps(address: address, city: city)
                                                    }) {
                                                        Text("\(address), \(city)")
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary) // make it look tappable
                                                            .multilineTextAlignment(.center)
                                                            .padding(.bottom, 15)
                                                    }
                                                }
                                                
                                                
                                                Divider()
                                            }
                                            .frame(maxWidth: .infinity, alignment: .center)
                                        }
                                    }
                            }
                            
                            if !viewModel.isLoading && !viewModel.events.isEmpty && !showPastEventsOnly {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("* Be sure to verify event info with official sources!")
                                }
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
                    .padding(.horizontal)
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserDidPlusify"))) { _ in
                    viewModel.fetchEvents(userInitiated: false)
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserDidLogout"))) { _ in
                    // reset back to free‐list mode
                    showPastEventsOnly = false
                    viewModel.fetchEvents()  // optional: reload free week
                }
            }
        }
        .onAppear {
            if viewModel.events.isEmpty {
                viewModel.fetchEvents()
            }
        }
        .refreshable {
            viewModel.fetchEvents(userInitiated: true)
        }
        .sheet(isPresented: $showPlusOverlay) {
          EventsRarelygroovyPlusOverlay(statsVM: statsVM, userIsSignedIn: AuthManager.shared.user != nil)
        }
        
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
    func sanitize(_ string: String) -> String {
        return string.folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.punctuationCharacters)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    // Helper: parse ISO8601 string for event creation dates
    private func parseCreatedAt(_ isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: isoString)
    }
    var filteredEvents: [Event] {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        var events = trimmedQuery.isEmpty ? viewModel.events : viewModel.events.filter { event in
            let venueName = sanitize(event.venue?.name ?? "")
            let promoterName = sanitize(event.promoter?.name ?? "")
            let cityName = sanitize(event.venue?.city ?? "")
            
            let artistMatch = event.artists?.contains { artist in
                sanitize(artist.name).localizedStandardContains(sanitize(trimmedQuery))
            } ?? false
            
            return venueName.localizedStandardContains(sanitize(trimmedQuery))
            || promoterName.localizedStandardContains(sanitize(trimmedQuery))
            || cityName.localizedStandardContains(sanitize(trimmedQuery))
            || artistMatch
        }
        
        // Filter for non-RGV if active
        if nonRGVOnly {
            events = events.filter { event in
                event.artists?.contains { $0.location.lowercased() != "rgv" } ?? false
            }
        }
        
        // Filter for recently added (last 3 days)
        if recentlyAddedOnly {
            let now = Date()
            guard let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now) else { return events }
            events = events.filter { event in
                guard let createdAtStr = event.creationDateTime,
                      let createdAt = parseCreatedAt(createdAtStr) else { return false }
                return createdAt >= threeDaysAgo
            }
        }
        
        // Filter for selected genres
        if !selectedEventGenres.isEmpty {
            let selectedGenresLower = Set(selectedEventGenres.map { $0.lowercased() })
            events = events.filter { event in
                guard let artists = event.artists else { return false }
                let combinedGenres = artists.flatMap { $0.genre.map { $0.lowercased() } }
                return !Set(combinedGenres).isDisjoint(with: selectedGenresLower)
            }
        }
        
        // New: Filter for events with debuting information if the toggle is active
        if showDebutingOnly {
            events = events.filter { event in
                let venueDebut = event.venue?.debut ?? false
                let promoterDebut = event.promoter?.debut ?? false
                let artistDebut = event.artists?.contains {
                    ($0.debut ?? false) || ($0.albumDebut ?? false) || ($0.rgvDebut ?? false) || ($0.lastShow ?? false)
                } ?? false
                return venueDebut || promoterDebut || artistDebut
            }
        }
        
        return events
    }
    // Helper computed property to determine if there is any event with debuting info
    private var hasDebutingArtist: Bool {
        return viewModel.events.contains { event in
            let venueDebut = event.venue?.debut ?? false
            let promoterDebut = event.promoter?.debut ?? false
            let artistDebut = event.artists?.contains {
                ($0.debut ?? false) || ($0.albumDebut ?? false) || ($0.rgvDebut ?? false) || ($0.lastShow ?? false)
            } ?? false
            return venueDebut || promoterDebut || artistDebut
        }
    }
    // Helper: Open Apple Maps with the provided address
    func openInMaps(address: String, city: String) {
        let fullAddress = "\(address), \(city)"
        let encoded = fullAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fullAddress
        let urlString = "http://maps.apple.com/?q=\(encoded)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    // MARK: - Group events by day
    private func groupEventsByDay(_ events: [Event]) -> [DayGroup] {
        var dictionary = [Date: [Event]]()
        
        for event in events {
            guard let isoString = event.dateTime, let date = parseISODate(isoString) else { continue }
            let dayStart = startOfDay(for: date)
            dictionary[dayStart, default: []].append(event)
        }
        
        let sortedKeys = dictionary.keys.sorted()
        var results = [DayGroup]()
        
        for day in sortedKeys {
            let eventsInDay = dictionary[day]!.sorted {
                guard let d1 = parseISODate($0.dateTime ?? ""),
                      let d2 = parseISODate($1.dateTime ?? "") else { return false }
                return d1 < d2
            }
            let label = dayLabel(for: day)
            results.append(DayGroup(dayStart: day, dayLabel: label, events: eventsInDay))
        }
        
        return results
    }
    /// Groups events by day **in the order they appear** in the array,
    /// rather than sorting them.
    private func groupPastEventsByDay(_ events: [Event]) -> [DayGroup] {
        var dict = [Date: [Event]]()
        var dayOrder = [Date]()
        
        // Iterate in the array’s order
        for event in events {
            guard let iso = event.dateTime,
                  let date = parseISODate(iso) else { continue }
            let dayStart = startOfDay(for: date)
            if dict[dayStart] == nil {
                dayOrder.append(dayStart)
            }
            dict[dayStart, default: []].append(event)
        }
        
        // Build DayGroups in the same day order
        return dayOrder.map { day in
            DayGroup(
                dayStart: day,
                dayLabel: dayLabel(for: day),
                events: dict[day]!
            )
        }
    }
    // Parse an ISO8601 date
    private func parseISODate(_ isoString: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return isoFormatter.date(from: isoString)
    }
    // Truncate a date to midnight
    private func startOfDay(for date: Date) -> Date {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return Calendar.current.date(from: comps) ?? date
    }
    // Convert a date to "Today", "Tomorrow", or "EEEE, MMMM d"
    private func dayLabel(for day: Date) -> String {
        let calendar = Calendar.current
        let today = startOfDay(for: Date())
        let eventYear = calendar.component(.year, from: day)
        let currentYear = calendar.component(.year, from: today)

        if eventYear < currentYear {
            let df = DateFormatter()
            df.dateFormat = "EEEE, MM/dd/yyyy"
            df.locale = Locale(identifier: "en_US_POSIX")
            return df.string(from: day)
        }

        let daysAway = calendar.dateComponents([.day], from: today, to: day).day ?? 0

        let dfWeekday = DateFormatter()
        dfWeekday.dateFormat = "EEEE"
        dfWeekday.locale = Locale(identifier: "en_US_POSIX")

        let dfFullNoYear = DateFormatter()
        dfFullNoYear.dateFormat = "EEEE, MMMM d"
        dfFullNoYear.locale = Locale(identifier: "en_US_POSIX")

        switch daysAway {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        case 2...6: return dfWeekday.string(from: day)
        case -6...(-2): return "Last " + dfWeekday.string(from: day)
        default: return dfFullNoYear.string(from: day)
        }
    }
}


// MARK: - DayGroup model
fileprivate struct DayGroup {
    let dayStart: Date
    let dayLabel: String
    let events: [Event]
}

// MARK: - Format Helpers
func formatAsLocalTime(_ isoString: String) -> String? {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let date = isoFormatter.date(from: isoString) else { return nil }
    
    // check if time is 11:59pm
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: date)
    if components.hour == 23 && components.minute == 59 {
        return nil
    }

    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "h:mma"
    timeFormatter.locale = Locale(identifier: "en_US_POSIX")
    timeFormatter.timeZone = .current

    var time = timeFormatter.string(from: date)
        .replacingOccurrences(of: "AM", with: "am")
        .replacingOccurrences(of: "PM", with: "pm")

    // Remove ":00" if it's a whole hour
    if time.contains(":00") {
        time = time.replacingOccurrences(of: ":00", with: "")
    }

    return time
}
func formatAsMonthDay(_ isoString: String) -> String? {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let date = isoFormatter.date(from: isoString) else { return nil }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = .current
    return dateFormatter.string(from: date)
}
func listingLabel(for event: Event, recentlyAddedActive: Bool) -> String? {
    // Only show the label if the Recently Added filter is active
    guard recentlyAddedActive else { return nil }
    
    guard let createdAtString = event.creationDateTime,
          let createdAt = parseISODate(createdAtString) else { return nil }
    
    // Use calendar day boundaries for human-friendly comparisons
    let startOfCreated = Calendar.current.startOfDay(for: createdAt)
    let startOfToday = Calendar.current.startOfDay(for: Date())
    let daysAgo = Calendar.current.dateComponents([.day], from: startOfCreated, to: startOfToday).day ?? 0

    // Only show label if the event was listed within the last 3 days
    if daysAgo <= 3 {
        if daysAgo == 0 {
            return "Listed today"
        } else if daysAgo == 1 {
            return "Listed yesterday"
        } else {
            return "Listed \(daysAgo) days ago"
        }
    }
    return nil
}
func parseISODate(_ isoString: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: isoString)
}
func isElevenFiftyNinePM(_ isoString: String) -> Bool {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: isoString) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return components.hour == 23 && components.minute == 59
    }
    return false
}

import SwiftUI

struct EventsRarelygroovyPlusOverlay: View {
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
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                }

              // event perks first, then artist perks
                VStack {
                    PerkSection(title: "Events",  perks: statsVM.eventPerks)
                    PerkSection(title: "Artist Directory", perks: statsVM.artistPerks)
                      
                  Text("* Numbers continue to grow as we add events and artists to Rarelygroovy!")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 340, alignment: .leading)
                }


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
              Spacer()
            }
            .padding()
            .multilineTextAlignment(.center)
        }
    }
    .onAppear { statsVM.fetchAll() }
  }
}

// keep your existing PerkCard and Perk definitions:
struct PerkCard: View {
    let perks: [Perk]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(perks) { perk in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(perk.title)
                            .font(.body)
                            .fontWeight(.semibold)
                        if let desc = perk.description {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(colorScheme == .dark ? .black : .white))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white, lineWidth: 2)
        )
        .cornerRadius(12)
    }
}
struct Perk: Identifiable {
    let id = UUID()
    let title: String
    let description: String?
}

final class PlusStatsViewModel: ObservableObject {
  @Published var extraEvents: Int?
  @Published var furthestMonth: String?
    @Published var pastEvents: Int?
  @Published var inactiveLocalArtists: Int?
  @Published var touringArtists: Int?

  private var hasFetched = false

  func fetchAll() {
    guard !hasFetched
    else { return }
    hasFetched = true

    fetchEventStats()
    fetchArtistStats()
  }

  // … your fetchEventStats()/fetchArtistStats() …
    /// Call when the Events sheet appears
    func fetchEventStats() {
        print(">> fetchEventStats called")

        let url = URL(string: "https://enm-project-production.up.railway.app/api/enmEvents/number-of-events-passed-free-limit")!
        URLSession.shared.dataTask(with: url) { data, _, error in
          if let e = error {
            print("⚠️ eventStats error:", e)
            return
          }
          guard let data = data else {
            print("⚠️ eventStats no data")
            return
          }
          // for debugging, dump the raw JSON:
          print("📥 eventStats raw:", String(decoding: data, as: UTF8.self))

            struct Resp: Decodable { let extraEvents: Int; let furthestMonth: String?; let pastEvents: Int }
          if let r = try? JSONDecoder().decode(Resp.self, from: data) {
            print("✅ eventStats decoded:", r)
            DispatchQueue.main.async {
              self.extraEvents   = r.extraEvents
              self.furthestMonth = r.furthestMonth
                self.pastEvents    = r.pastEvents
            }
          } else {
            print("⚠️ eventStats decode failure")
          }
        }.resume()
      }
    /// Call when the Artists sheet appears
    func fetchArtistStats() {
        let url = URL(string: "https://enm-project-production.up.railway.app/api/artists/local-inactive-count")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            struct Resp: Decodable { let inactiveLocalArtists: Int; let touringArtists: Int }
            if let r = try? JSONDecoder().decode(Resp.self, from: data) {
                DispatchQueue.main.async {
                    self.inactiveLocalArtists = r.inactiveLocalArtists
                    self.touringArtists       = r.touringArtists
                }
            }
        }.resume()
    }

  // ——— New dynamic Perk lists ———
  var eventPerks: [Perk] {
    [
      Perk(
        title: "Remove weekly limit",
        description: {
          guard let extra = extraEvents,
                let month = furthestMonth
          else { return "Loading event stats…" }
          return "Access to an additional *\(extra) upcoming events through \(month)."
        }()
      ),
      Perk(
        title: "See past events",
        description: {
            guard let pastEvents = pastEvents
            else { return "Loading event stats…" }
            return "Access to an additional *\(pastEvents) past events dating back to early 2023"
          }()
      )
    ]
  }

  var artistPerks: [Perk] {
    [
      Perk(
        title: "See past artists",
        description: {
          guard let cnt = inactiveLocalArtists else { return "Loading artist stats…" }
          return "Access to *\(cnt) inactive RGV artists dating back to 1985."
        }()
      ),
      Perk(
        title: "See touring artists",
        description: {
          guard let touring = touringArtists else { return "Loading artist stats…" }
          return "Access to *\(touring) artists that’ve recently toured the RGV."
        }()
      )
    ]
  }
}

// your response structs:
struct FreeExtraCountResponse: Decodable {
  let extraEvents: Int
  let furthestMonth: String?
    let pastEvents: Int
}
struct LocalVsTouringCountResponse: Decodable {
    let inactiveLocalArtists: Int
    let touringArtists:       Int
}

struct PerkSection: View {
  @Environment(\.colorScheme) private var colorScheme
  let title: String
  let perks: [Perk]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.headline)
        .foregroundColor(.secondary)

      PerkCard(perks: perks)
        // force all cards to be the same width:
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(colorScheme == .dark ? .black : .white))
    }
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity) // <-- 👈 this is the pinning line
  }
}
