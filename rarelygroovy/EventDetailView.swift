import SwiftUI
import FontAwesome_swift

struct EventDetailView: View {
    let event: Event
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                // Event summary (styled like the event cell)
                VStack(alignment: .center, spacing: 8) {
                    // Venue name
                    if let venue = event.venue {
                        Text(venue.name ?? "Unknown Venue")
                            .font(.title)
                            .multilineTextAlignment(.center)
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
                    
                    // Flyer link icon
                    if let flyerLink = event.flyer,
                       let url = URL(string: flyerLink) {
                        Link(destination: url) {
                            Image(systemName: "doc.text.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .padding(.vertical, 8)
                                .foregroundColor(.secondary)
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
                        Text("·")
                        if let showStr = event.dateTime.flatMap({ formatAsMonthDay($0) }) {
                            Text(showStr)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Text("·")
                        if let cover = event.cover {
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
                // Mini Artist Directory (Lineup)
                // Mini Artist Directory (Lineup)
                // Mini Artist Directory (Lineup)
                Text("Artist Directory").font(.title).padding(.top, 50)
                if let artists = event.artists, !artists.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(artists) { artist in
                            VStack(alignment: .center, spacing: 4) {
                                // Artist name with location (if not "rgv")
                                Text(artist.name + (artist.location.lowercased() != "rgv" ? " (\(artist.location))" : ""))
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                // Prepare parts
                                let mediumPart = artist.medium ?? ""
                                let genrePart = artist.genre.joined(separator: " · ")
                                let dateRangePart: String = {
                                    if !artist.start.isEmpty {
                                        let startYear = String(artist.start.prefix(4))
                                        if let endVal = artist.end, !endVal.isEmpty, endVal.lowercased() != "pending" {
                                            let endYear = String(artist.end!.prefix(4))
                                            return "\(startYear) - \(endYear)"
                                        } else {
                                            return "\(startYear) - current"
                                        }
                                    }
                                    return ""
                                }()
                                
                                // Combine the parts with extra spacing and non-breaking spaces for the date range.
                                let combinedString: String = {
                                    var s = ""
                                    if !genrePart.isEmpty {
                                        s += genrePart
                                    }
                                    if !mediumPart.isEmpty {
                                        if !s.isEmpty { s += "     " }  // extra spacing between medium and genre
                                        s += mediumPart
                                    }
                                    if !dateRangePart.isEmpty {
                                        if !s.isEmpty { s += "     " }  // extra spacing between genre and date range
                                        // Replace the normal dash separator with non-breaking spaces
                                        let fixedDateRange = dateRangePart.replacingOccurrences(of: " - ", with: "\u{00A0}-\u{00A0}")
                                        s += fixedDateRange
                                    }
                                    return s
                                }()
                                
                                Text(combinedString)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)  // adjust the value as needed
                                
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
                                                            .foregroundColor(.primary)
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
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Event Details")
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
