import SwiftUI

struct EventsView: View {
    @StateObject private var viewModel = EventsViewModel()
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Group events by day and iterate
                    ForEach(Array(groupEventsByDay(viewModel.events).enumerated()), id: \.element.dayStart) { (index, dayGroup) in
                        
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
                            // Wrap the event cell in a NavigationLink to push EventDetailView
                            NavigationLink(destination: EventDetailView(event: event)) {
                                VStack(alignment: .center, spacing: 8) {
                                    // Optional top divider for the first event of each day
                                    
                                    // Venue name
                                    if let venue = event.venue {
                                        Text(venue.name ?? "Unknown")
                                            .font(.title)
                                            .multilineTextAlignment(.center)
                                    }
                                    
                                    // Artists (joined with mid-dots)
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
                                    
                                    if let flyerLink = event.flyer,
                                       flyerLink.lowercased() != "pending",
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
                                            .padding(.bottom, 50)  // extra bottom padding added here
                                    }

                                    Divider()
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal)
                                .padding(.vertical, 16)
                            }
                        }
                    }
                    // Only show the disclaimer if loading is finished and events are available
                    if !viewModel.isLoading && !viewModel.events.isEmpty {
                        Text("* Start times might vary (e.g., punk time)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical)
                .padding(.horizontal)
                // disclaimer text pinned to bottom-left
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
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "h:mma"
    timeFormatter.locale = Locale(identifier: "en_US_POSIX")
    timeFormatter.timeZone = .current
    let rawTime = timeFormatter.string(from: date)
    let finalTime = rawTime
        .replacingOccurrences(of: "AM", with: "am")
        .replacingOccurrences(of: "PM", with: "pm")
    return finalTime
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
