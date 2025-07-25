import SwiftUI
import FontAwesome_swift

struct EventDetailView: View {
    @StateObject private var viewModel = EventsViewModel()
    let event: Event
    @Environment(\.colorScheme) var colorScheme

    
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

                    
                    // Flyer  link, ticket link
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
                .padding()
                .background(
                    Color(colorScheme == .dark ? .black : .white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.primary, lineWidth: 3)
                )
                
                // Mini Artist Directory (Lineup)
                if let artists = event.artists, !artists.isEmpty {
                    Text("Artist Directory").font(.title).padding(.top, 50).foregroundColor(.gray)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(artists) { artist in
                            VStack(alignment: .center, spacing: 4) {
                                // Artist name with location (if not "rgv")
                                let nameText = Text(artist.name)
                                let locationText = artist.location.uppercased() != "RGV"
                                    ? Text(",\(artist.location)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(red: 0.58, green: 0.44, blue: 0.86))
                                    : Text("")

                                (nameText + locationText)
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
                    }
                    .padding(.horizontal)
                }
                
                // Promoter section
                // only show if at least one promoter is valid
                let p1 = event.promoter
                let p2 = event.promoter2

                if (p1?.link != "pending") || (p2?.link != "pending") {
                  // header changes based on whether you have two
                  Text((p2 != nil ? "Promoters" : "Promoter"))
                    .font(.title)
                    .padding(.top, 50)
                    .foregroundColor(.gray)

                  VStack(spacing: 8) {
                    // first promoter
                    if let promo = p1, promo.link != "pending" {
                      Text(promo.name ?? "Unknown")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .center)

                      if let urlString = promo.link,
                         let url = URL(string: urlString) {
                        let icon = fontAwesomeIcon(for: "instagram")
                        Link(destination: url) {
                          Text(String.fontAwesomeIcon(name: icon))
                            .font(.custom(fontName(for: icon), size: 24))
                            .foregroundColor(.gray)
                        }
                        .frame(width: 35, height: 40)
                      }
                    }

                    // second promoter, if any
                    if let promo2 = p2, promo2.link != "pending" {
                      Text(promo2.name ?? "Unknown")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .center)

                      if let urlString = promo2.link,
                         let url = URL(string: urlString) {
                        let icon = fontAwesomeIcon(for: "instagram")
                        Link(destination: url) {
                          Text(String.fontAwesomeIcon(name: icon))
                            .font(.custom(fontName(for: icon), size: 24))
                            .foregroundColor(.gray)
                        }
                        .frame(width: 35, height: 40)
                      }
                    }
                  }
                  .padding(.horizontal)
                }
                
                if let venue = event.venue, venue.link != "pending" {
                    Text("Venue")
                        .font(.title)
                        .padding(.top, 50)
                        .foregroundColor(.gray)
                    VStack(alignment: .center, spacing: 8) {
                        // Promoter name
                        Text(venue.name ?? "Unknown")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Promoter link: check that it exists and is not empty
                        if let link = venue.link, !link.isEmpty, let url = URL(string: link) {
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
            .frame(maxWidth: .infinity, alignment: .center)

        }
        .frame(maxWidth: .infinity, alignment: .center)
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
