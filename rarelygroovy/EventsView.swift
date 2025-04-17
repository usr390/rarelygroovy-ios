import SwiftUI

struct EventsView: View {
    
    @StateObject private var viewModel = EventsViewModel()
    @State private var searchQuery = ""
    @State private var nonRGVOnly = false  // New chip filter state
    @State private var recentlyAddedOnly = false  // New chip filter state
    @State private var selectedEventGenres = Set<String>()
    @State private var showDebutingOnly = false
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    // Search input field
                    ZStack(alignment: .trailing) {
                        TextField("Search events…", text: $searchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
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
                                        .background(isSelected ? Color.primary : Color.gray.opacity(0.3))
                                        .foregroundColor(isSelected ? Color.black : .primary)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.vertical, 8)
                                        
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            
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
                                    .background(showDebutingOnly ? Color.primary : Color.gray.opacity(0.3))
                                    .foregroundColor(showDebutingOnly ? Color.black : .primary)
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
                                .background(nonRGVOnly ? Color.primary : Color.gray.opacity(0.3))
                                .foregroundColor(nonRGVOnly ? Color.black : .primary)
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
                                .background(recentlyAddedOnly ? Color.primary : Color.gray.opacity(0.3))
                                .foregroundColor(recentlyAddedOnly ? Color.black : .primary)
                                .cornerRadius(16)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Check if any events match the search criteria
                        if filteredEvents.isEmpty && !viewModel.isLoading && !searchQuery.isEmpty {
                            Text("No events match search criteria.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            // Group filtered events by day and iterate
                            ForEach(Array(groupEventsByDay(filteredEvents).enumerated()), id: \.element.dayStart) { (index, dayGroup) in
                                
                                
                                
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
                                                        t = t + Text(",\(artist.location)")
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
                                            
                                            // Promoter
                                            if let promoter = event.promoter {
                                                Divider()
                                                    .frame(width: 50, height: 1)
                                                    .background(Color.gray)
                                                    .padding(.vertical, 8)
                                                
                                                Text(promoter.name ?? "Unknown")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
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
                                            HStack(spacing: 3) {
                                                if let doorStr = event.doorTime.flatMap({ formatAsLocalTime($0) }),
                                                   let showStr = event.dateTime.flatMap({ formatAsLocalTime($0) }) {
                                                    Text("doors \(doorStr), \(showStr)")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                } else if let doorStr = event.doorTime.flatMap({ formatAsLocalTime($0) }) {
                                                    Text("doors \(doorStr)")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                } else if let showStr = event.dateTime.flatMap({ formatAsLocalTime($0) }) {
                                                    Text(showStr)
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                if let showStr = event.dateTime.flatMap({ formatAsMonthDay($0) }) {
                                                    Text("·")
                                                    Text(showStr)
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                                if let cover = event.cover {
                                                    Text("·")
                                                    if cover == 0 {
                                                        Text("No Cover")
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                    } else {
                                                        Text("$\(cover)")
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .onTapGesture {
                                                if let venue = event.venue,
                                                   let city = venue.city,
                                                   let address = venue.address {
                                                    openInMaps(address: address, city: city)
                                                }
                                            }
                                            
                                            // Address
                                            if let venue = event.venue,
                                               let city = venue.city,
                                               let address = venue.address {
                                                Text("\(address), \(city)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                    .multilineTextAlignment(.center)
                                                    .padding(.bottom, 50)
                                            }
                                            
                                            Divider()
                                        }
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 16)
                                    }
                                }
                            }
                            
                            if !viewModel.isLoading && !viewModel.events.isEmpty {
                                Text("* Start times might vary (e.g., punk time)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
                    .padding(.horizontal)
                }
            }
            
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading Events...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground).opacity(0.8))
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
                    ($0.debut ?? false) || ($0.albumDebut ?? false) || ($0.rgvDebut ?? false)
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
                ($0.debut ?? false) || ($0.albumDebut ?? false) || ($0.rgvDebut ?? false)
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
        let now = startOfDay(for: Date())
        let daysAway = calendar.dateComponents([.day], from: now, to: day).day ?? 0

        if daysAway == 0 {
            return "Today"
        } else if daysAway == 1 {
            return "Tomorrow"
        } else if daysAway <= 6 {
            let df = DateFormatter()
            df.dateFormat = "EEEE" // just weekday
            df.locale = Locale(identifier: "en_US_POSIX")
            return df.string(from: day)
        } else {
            let df = DateFormatter()
            df.dateFormat = "EEEE, MMMM d"
            df.locale = Locale(identifier: "en_US_POSIX")
            return df.string(from: day)
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
