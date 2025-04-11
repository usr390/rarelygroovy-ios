import SwiftUI
import FontAwesome_swift

struct EventDetailView: View {
    @StateObject private var viewModel = EventsViewModel()
    let event: Event
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                // Event summary (styled like the event cell)
                VStack(alignment: .center, spacing: 8) {
                    // Venue name
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
                    
                    // Artists (joined with mid-dots)
                    if let artists = event.artists, !artists.isEmpty {
                        let names = artists.map { displayName(for: $0) }
                        let joinedNames = names.joined(separator: " · ")
                        Text(joinedNames)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .lineSpacing(12)
                            .frame(maxWidth: .infinity)
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
                    
                    HStack(spacing: 32) {
                        if let flyerLink = event.flyer,
                           flyerLink.lowercased() != "pending",
                           let url = URL(string: flyerLink) {
                            Link(destination: url) {
                                ZStack {
                                    // Base icon remains the same.
                                    Image(systemName: "doc.text.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                    
                                    // Compressed linear gradient overlay
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color(#colorLiteral(red: 0.9882, green: 0.9333, blue: 0.1294, alpha: 1)), location: 0.0),  // Yellow (#FCEE21)
                                            .init(color: Color(#colorLiteral(red: 0.96, green: 0.52, blue: 0.16, alpha: 1)), location: 0.20),      // Orange (#F58529)
                                            .init(color: Color(#colorLiteral(red: 0.99, green: 0.18, blue: 0.0, alpha: 1)), location: 0.40),       // Red (#FC2F00)
                                            .init(color: Color(#colorLiteral(red: 0.87, green: 0.16, blue: 0.48, alpha: 1)), location: 0.60),      // Magenta (#DD2A7B)
                                            .init(color: Color(#colorLiteral(red: 0.51, green: 0.20, blue: 0.69, alpha: 1)), location: 0.80)       // Deep Purple (#8134AF)
                                        ]),
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                    .blendMode(.multiply)
                                    .mask(
                                        Image(systemName: "doc.text.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    )
                                }
                                .frame(width: 24, height: 24)
                                .padding(.vertical, 8)
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
                        if let doorStr = event.doorTime.flatMap({ formatAsLocalTime($0) }) {
                            Text("doors \(doorStr)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if let showStr = event.dateTime.flatMap({ formatAsLocalTime($0) }) {
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
                        // Tapping this row opens Apple Maps with the venue address
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
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
                .padding(.vertical, 16)
                
                // Mini Artist Directory (Lineup)
                if let artists = event.artists, !artists.isEmpty {
                    Text("Artist Directory").font(.title).padding(.top, 50).foregroundColor(.gray)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(artists) { artist in
                            VStack(alignment: .center, spacing: 4) {
                                // Artist name with location (if not "rgv")
                                Text(artist.name + (artist.location.uppercased() != "RGV" ? " (\(artist.location.uppercased()))" : ""))
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                // Prepare parts
                                let mediumPart = artist.medium ?? ""
                                let genrePart = artist.genre.joined(separator: " · ")

                                // Date range part with status when applicable
                                // Updated date range logic:
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

                                // Valid links for this artist
                                if let links = artist.links {
                                    let validLinks = links.filter { entry in
                                        if let url = URL(string: entry.value),
                                           let scheme = url.scheme,
                                           ["http", "https"].contains(scheme) {
                                            return true
                                        }
                                        return false
                                    }
                                    let sortedLinks = validLinks.sorted { a, b in
                                        rank(for: a.key) < rank(for: b.key)
                                    }
                                    
                                    if !sortedLinks.isEmpty {
                                        HStack(spacing: 16) {
                                            ForEach(sortedLinks, id: \.key) { key, value in
                                                if let url = URL(string: value) {
                                                    let icon = fontAwesomeIcon(for: key)
                                                    Link(destination: url) {
                                                        Text(String.fontAwesomeIcon(name: icon))
                                                            .font(.custom(fontName(for: icon), size: 24))
                                                            .foregroundColor(.gray)
                                                    }
                                                    .frame(width: 35, height: 40)
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                            Divider()
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Promoter section
                // Promoter section: only display if promoter info exists
                if let promoter = event.promoter, promoter.link != "pending" {
                    Text("Promoter")
                        .font(.title)
                        .padding(.top, 50)
                        .foregroundColor(.gray)
                    VStack(alignment: .center, spacing: 8) {
                        // Promoter name
                        Text(promoter.name ?? "Unknown")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Promoter link: check that it exists and is not empty
                        if let link = promoter.link, !link.isEmpty, let url = URL(string: link) {
                            let icon = fontAwesomeIcon(for: "instagram")
                            Link(destination: url) {
                                Text(String.fontAwesomeIcon(name: icon))
                                    .font(.custom(fontName(for: icon), size: 24))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 35, height: 40)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
        }
        .refreshable {
            viewModel.fetchEvents(userInitiated: true)
        }
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

func displayName(for artist: Artist) -> String {
    let rawName = artist.name.trimmingCharacters(in: .whitespacesAndNewlines)
    var qualifiers: [String] = []
    
    // Include location if provided and it isn't "rgv"
    let trimmedLocation = artist.location.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedLocation.isEmpty, artist.location.lowercased() != "rgv" {
        // You can choose to uppercase it or format it as needed.
        qualifiers.append(trimmedLocation.uppercased())
    }
    
    // Add debut flags if true
    if artist.debut ?? false {
        qualifiers.append("debut")
    }
    if artist.albumDebut ?? false {
        qualifiers.append("album debut")
    }
    if artist.rgvDebut ?? false {
        qualifiers.append("rgv debut")
    }
    
    if !qualifiers.isEmpty {
        return "\(rawName) (\(qualifiers.joined(separator: ", ")))"
    } else {
        return rawName
    }
}

