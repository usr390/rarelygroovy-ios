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
                    
                    // Artists summary: joined with mid-dots; include state if not RGV
                    if let artists = event.artists, !artists.isEmpty {
                        let names = artists.map { artist -> String in
                            let rawName = artist.name.trimmingCharacters(in: .whitespacesAndNewlines)
                            if artist.location.lowercased() != "rgv" {
                                let state = artist.location.uppercased()
                                return "\(rawName) (\(state))"
                            } else {
                                return rawName
                            }
                        }
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
                                let dateRangePart: String = {
                                    if !artist.start.isEmpty && artist.start.lowercased() != "pending" {
                                        let startYear = String(artist.start.prefix(4))
                                        if let endVal = artist.end, !endVal.isEmpty, endVal.lowercased() != "pending" {
                                            let endYear = String(endVal.prefix(4))
                                            var result = "\(startYear) - \(endYear)"
                                            if let status = artist.status, !status.isEmpty {
                                                result += ", \(status)"
                                            }
                                            return result
                                        } else {
                                            return "\(startYear) - current"
                                        }
                                    }
                                    return ""
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
