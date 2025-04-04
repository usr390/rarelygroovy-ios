import SwiftUI

// MARK: - Models

// Simple model for auto‑complete suggestions.
struct VenueSuggestion: Decodable, Identifiable {
    let id = UUID()
    let name: String
}

// MARK: - Generic AutoComplete Overlay

struct AutoCompleteOverlay: View {
    @Binding var text: String
    let suggestions: [String]
    let title: String  // Dynamic title parameter
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var isTextFieldFocused: Bool  // FocusState variable


    var filteredSuggestions: [String] {
        if text.isEmpty {
            return suggestions
        } else {
            return suggestions.filter { $0.lowercased().contains(text.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search...", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                List(filteredSuggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .onTapGesture {
                            text = suggestion
                            dismiss()
                        }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add Event View

struct AddEventView: View {
    // Event Fields
    @State private var venueName: String = ""
    @State private var promoterName: String = ""
    @State private var city: String = ""
    @State private var eventDate: Date = Date()
    @State private var doorTime: Date = Date(timeIntervalSince1970: 0) // defaults to 12:00 AM
    @State private var showTime: Date = Date(timeIntervalSince1970: 0) // defaults to 12:00 AM
    @State private var coverText: String = ""
    @State private var artistNames: [String] = [""]
    @State private var flyerLink: String = ""
    @State private var flyerImage: UIImage? = nil  // Stub for image upload

    // Auto-complete overlay triggers
    @State private var showVenueAutoComplete: Bool = false
    @State private var showPromoterAutoComplete: Bool = false
    // Instead of an array for each artist field, track which artist field is active.
    @State private var selectedArtistIndex: Int? = nil

    // Error & points feedback
    @State private var errorMessage: String?
    @State private var pointsEarned: Int = 0

    // Hardcoded suggestions for demo purposes.
    let venueSuggestions = ["Venue One", "Venue Two", "Venue Three", "Awesome Venue", "Cool Venue"]
    let promoterSuggestions = ["Promoter A", "Promoter B", "Promoter C"]
    let artistSuggestions = ["Artist X", "Artist Y", "Artist Z"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Venue Input with Auto-Complete
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Venue *")
                                .font(.headline)
                            Spacer()
                            Text("+10")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        TextField("Enter venue name", text: $venueName)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .onTapGesture {
                                showVenueAutoComplete = true
                            }
                    }
                    .padding(.horizontal)
                    
                    // Promoter Input with Auto-Complete
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Promoter")
                                .font(.headline)
                            Spacer()
                            Text("+5")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        TextField("Enter promoter name", text: $promoterName)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .onTapGesture {
                                showPromoterAutoComplete = true
                            }
                    }
                    .padding(.horizontal)
                    
                    // Event Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event Date *")
                            .font(.headline)
                        DatePicker("Select date", selection: $eventDate, in: Date()..., displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.horizontal)
                    
                    // Time Inputs for Door and Show Time (vertical layout)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Times (optional)")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Door Time")
                                .font(.caption)
                            DatePicker("", selection: $doorTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(WheelDatePickerStyle())
                            Text("Show Time")
                                .font(.caption)
                            DatePicker("", selection: $showTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(WheelDatePickerStyle())
                        }
                        Text("Default picker time is 12:00 AM")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Cover Input
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Cover (optional)")
                                .font(.headline)
                            Spacer()
                            Text("+3")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        HStack {
                            Text("$")
                            TextField("Enter cover amount", text: $coverText)
                                .keyboardType(.numberPad)
                                .onChange(of: coverText) { newValue in
                                    coverText = String(newValue.prefix(3).filter { "0123456789".contains($0) })
                                }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Artists Input with dynamic fields and auto-complete using full-screen overlay
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Artists (optional)")
                            .font(.headline)
                        ForEach(artistNames.indices, id: \.self) { index in
                            HStack {
                                TextField("Enter artist name", text: $artistNames[index])
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selectedArtistIndex = index
                                    }
                                if artistNames.count > 1 {
                                    Button(action: {
                                        artistNames.remove(at: index)
                                        // Adjust selectedArtistIndex if necessary.
                                        if let selected = selectedArtistIndex, selected == index {
                                            selectedArtistIndex = nil
                                        } else if let selected = selectedArtistIndex, selected > index {
                                            selectedArtistIndex = selected - 1
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        Button(action: {
                            artistNames.append("")
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Artist")
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    // Flyer Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Flyer Link")
                            .font(.headline)
                        TextField("Enter flyer URL (Instagram only)", text: $flyerLink)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        Button("Upload Flyer Image") {
                            uploadFlyerImage()
                        }
                        .foregroundColor(.blue)
                        Text("+5")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    .padding(.horizontal)
                    
                    // Submit Button
                    Button(action: {
                        submitEvent()
                    }) {
                        Text("Submit Event")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            // Full-screen auto-complete overlays
            .fullScreenCover(isPresented: $showVenueAutoComplete) {
                AutoCompleteOverlay(text: $venueName, suggestions: venueSuggestions, title: "Venues")
            }
            .fullScreenCover(isPresented: $showPromoterAutoComplete) {
                AutoCompleteOverlay(text: $promoterName, suggestions: promoterSuggestions, title: "Promoters")
            }
            .fullScreenCover(isPresented: Binding<Bool>(
                get: { selectedArtistIndex != nil },
                set: { if !$0 { selectedArtistIndex = nil } }
            )) {
                if let index = selectedArtistIndex {
                    AutoCompleteOverlay(text: $artistNames[index],
                                        suggestions: artistSuggestions,
                                        title: "Artists")
                        .onDisappear {
                            selectedArtistIndex = nil
                        }
                }
            }
        }
    }
    
    // Stub: Flyer image upload mechanism.
    func uploadFlyerImage() {
        print("Uploading flyer image...")
    }
    
    // Build tags from venue, promoter, and city.
    func buildTags() -> [String] {
        var tags = [String]()
        if !venueName.isEmpty { tags.append(venueName) }
        if !promoterName.isEmpty { tags.append(promoterName) }
        if !city.isEmpty { tags.append(city) }
        return tags
    }
    
    // Submit event function: build event object and print (simulate API call).
    func submitEvent() {
        guard !venueName.trimmingCharacters(in: .whitespaces).isEmpty,
              !city.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please fill in required fields (Venue and City)."
            return
        }
        
        var eventData = [String: Any]()
        eventData["venue"] = ["name": venueName]
        if !promoterName.isEmpty {
            eventData["promoter"] = ["name": promoterName]
        }
        eventData["city"] = city
        let isoFormatter = ISO8601DateFormatter()
        eventData["date"] = isoFormatter.string(from: eventDate)
        eventData["doorTime"] = isoFormatter.string(from: doorTime)
        eventData["dateTime"] = isoFormatter.string(from: showTime)
        if !coverText.isEmpty {
            eventData["cover"] = Int(coverText) ?? 0
        }
        let validArtists = artistNames.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if !validArtists.isEmpty {
            eventData["artists"] = validArtists
        }
        eventData["flyer"] = flyerLink
        eventData["tags"] = buildTags()
        // Add username if signed in (assuming authManager is set up).
        // e.g., eventData["submittedBy"] = authManager.user?.username
        
        errorMessage = nil
        print("Submitting event: \(eventData)")
        
        resetForm()
    }
    
    func resetForm() {
        venueName = ""
        promoterName = ""
        city = ""
        eventDate = Date()
        doorTime = Date(timeIntervalSince1970: 0)
        showTime = Date(timeIntervalSince1970: 0)
        coverText = ""
        artistNames = [""]
        flyerLink = ""
    }
}

#Preview {
    AddEventView()
}
