import SwiftUI
import UIKit

// MARK: - Generic AutoComplete Overlay
struct AutoCompleteOverlay: View {
    @Binding var text: String
    let suggestions: [String]
    let title: String  // Dynamic title parameter
    @Environment(\.dismiss) var dismiss

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
                ZStack(alignment: .trailing) {
                    TextField("Search...", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    if !text.isEmpty {
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 8)
                        }
                    }
                }
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
// MARK: - Add Event View
// Custom wrapper for a time picker with 15-minute intervals that works with an optional Date.
struct OptionalTimeInputView: View {
    let label: String
    @Binding var time: Date?
    @State private var showPicker: Bool = false
    @State private var tempTime: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label with optional marker.
            Text("\(label)")
                .font(.headline)
            
            Button(action: {
                // When tapping, use the existing time or current time as a default.
                tempTime = time ?? Date()
                showPicker = true
            }) {
                HStack {
                    if let time = time {
                        Text(timeFormatted(time))
                            .foregroundColor(.primary)
                    } else {
                        Text("")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            }
            .sheet(isPresented: $showPicker) {
                OptionalTimePickerOverlay(time: $time, tempTime: $tempTime, label: label)
            }
        }
    }

    func timeFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
struct OptionalTimePickerOverlay: View {
    @Binding var time: Date?
    @Binding var tempTime: Date
    let label: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("", selection: $tempTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(WheelDatePickerStyle())
                    .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                    .environment(\.calendar, Calendar(identifier: .gregorian))
                    .padding()
                Spacer()
            }
            .navigationTitle("\(label)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        time = tempTime
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        time = nil
                        dismiss()
                    }
                }
            }
        }
    }
}
struct OptionalDateInputView: View {
    let label: String
    @Binding var date: Date?
    @State private var showPicker: Bool = false
    @State private var tempDate: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            (Text("\(label) ")
                .font(.headline)
             +
             Text("*")
                .italic()
                .foregroundColor(.secondary)
            )
            Button(action: {
                tempDate = date ?? Date()
                showPicker = true
            }) {
                HStack {
                    if let date = date {
                        Text(dateFormatted(date))
                            .foregroundColor(.primary)
                    } else {
                        Text("") // placeholder could go here if needed
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            }
            .sheet(isPresented: $showPicker) {
                OptionalDatePickerOverlay(date: $date, tempDate: $tempDate, label: label)
            }
        }
    }

    func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
struct OptionalDatePickerOverlay: View {
    @Binding var date: Date?
    @Binding var tempDate: Date
    let label: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("", selection: $tempDate, in: Date()..., displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(WheelDatePickerStyle())
                    .padding()
                Spacer()
            }
            .navigationTitle("\(label)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        date = tempDate
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
// A simplified auto-complete overlay for venues, promoters, and artists.
struct VenueAutoCompleteOverlay: View {
    @Binding var text: String
    @Binding var selectedVenue: Venue?
    let suggestions: [Venue]  // now an array of Venue objects
    let title: String
    @Environment(\.dismiss) var dismiss

    var filteredSuggestions: [Venue] {
        if text.isEmpty {
            return suggestions
        } else {
            return suggestions.filter { ($0.name ?? "").lowercased().contains(text.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                ZStack(alignment: .trailing) {
                    TextField("Search...", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    if !text.isEmpty {
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 8)
                        }
                    }
                }
                List(filteredSuggestions) { venue in
                    Button(action: {
                        text = venue.name ?? ""
                        selectedVenue = venue
                        dismiss()
                    }) {
                        HStack {
                            Text(venue.name ?? "Unknown")
                            Spacer()
                        }
                        .contentShape(Rectangle()) // ensures the full row is tappable
                    }
                    .buttonStyle(PlainButtonStyle()) // removes default button styling
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
struct PromoterAutoCompleteOverlay: View {
    @Binding var text: String
    @Binding var selectedPromoter: Promoter?
    let suggestions: [Promoter]
    let title: String
    @Environment(\.dismiss) var dismiss

    var filteredSuggestions: [Promoter] {
        if text.isEmpty {
            return suggestions
        } else {
            return suggestions.filter { ($0.name ?? "").lowercased().contains(text.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                ZStack(alignment: .trailing) {
                    TextField("Search...", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    if !text.isEmpty {
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 8)
                        }
                    }
                }
                List(filteredSuggestions) { promoter in
                    Button(action: {
                        text = promoter.name ?? ""
                        selectedPromoter = promoter
                        dismiss()
                    }) {
                        HStack {
                            Text(promoter.name ?? "Unknown")
                            Spacer()
                        }
                        .contentShape(Rectangle()) // ensures the full row is tappable
                    }
                    .buttonStyle(PlainButtonStyle()) // removes default button styling
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
struct ArtistAutoCompleteOverlay: View {
    @Binding var text: String
    @Binding var selectedArtist: Artist?
    let suggestions: [Artist]
    let title: String
    @Environment(\.dismiss) var dismiss

    var filteredSuggestions: [Artist] {
        if text.isEmpty {
            return suggestions
        } else {
            return suggestions.filter { $0.name.lowercased().contains(text.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                ZStack(alignment: .trailing) {
                    TextField("Search...", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    if !text.isEmpty {
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 8)
                        }
                    }
                }
                List(filteredSuggestions) { artist in
                    Button(action: {
                        text = artist.name
                        selectedArtist = artist
                        dismiss()
                    }) {
                        HStack {
                            Text(artist.name)
                            Spacer()
                        }
                        .contentShape(Rectangle()) // ensures the entire row is tappable
                    }
                    .buttonStyle(PlainButtonStyle()) // keeps default text look
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
struct PasteTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        // Use CustomTextField instead of plain UITextField
        let textField = CustomTextField()
        textField.placeholder = placeholder
        textField.textContentType = .URL  // This hints for URL/paste support
        textField.autocorrectionType = .no
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator,
                            action: #selector(Coordinator.textDidChange(_:)),
                            for: .editingChanged)
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PasteTextField
        
        init(_ parent: PasteTextField) {
            self.parent = parent
        }
        
        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            // Delay slightly before showing the menu so that the text field is fully active
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let menu = UIMenuController.shared
                // Set the target rectangle to the entire bounds of the text field.
                menu.setTargetRect(textField.bounds, in: textField)
                menu.setMenuVisible(true, animated: true)
            }
        }
    }
}
// Custom UITextField subclass that always enables paste.
class CustomTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
struct SuccessOverlay: View {
    var doneAction: () -> Void
    var addAnotherAction: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(colorScheme == .dark ? .white : .black)

            Text("Thanks!")
                .font(.headline)

            Text("We'll review your event and make it available shortly!")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            HStack(spacing: 20) {
                Button(action: {
                    doneAction()
                    dismiss()
                }) {
                    Text("dismiss")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .cornerRadius(8)
                }
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}

// Example usage in your AddEventView:
struct AddEventView: View {
    // Event Fields
    @State private var venueName: String = ""
    @FocusState private var isVenueFocused: Bool   // Focus state for venue input
    @State private var promoterName: String = ""
    @State private var eventDate: Date? = nil    // Optional time fields: initially nil
    @State private var doorTime: Date? = nil
    @State private var showTime: Date? = nil
    @State private var coverText: String = ""
    @State private var flyerLink: String = ""
    @State private var flyerImage: UIImage? = nil  // Stub for image upload
    @State private var errorMessage: String? = nil
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var authManager = AuthManager.shared

    // Auto-complete overlay triggers
    @State private var showVenueAutoComplete: Bool = false
    @State private var showPromoterAutoComplete: Bool = false

    // Update your state to store Venue objects.
    @State private var venueSuggestions: [Venue] = []
    // And add a state variable for the selected venue.
    @State private var selectedVenue: Venue? = nil  
    // Update your state to store Venue objects.
    @State private var promoterSuggestions: [Promoter] = []
    // And add a state variable for the selected venue.
    @State private var selectedPromoter: Promoter? = nil
    @State private var artistSuggestions: [Artist] = []
    // And add a state variable for the selected venue.
    @State private var artistNames: [String] = [""]
    @State private var selectedArtists: [Artist?] = [nil]
    @State private var selectedArtistIndex: Int? = nil
    @State private var showSuccess = true

    var body: some View {
            ScrollView {
                VStack(spacing: 20) {                    
                    // Venue Input with Auto-Complete
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            (Text("Venue ")
                                .font(.headline)
                             +
                             Text("*")
                                .italic()
                                .foregroundColor(.secondary)
                            )
                            Spacer()
                        }
                        TextField("Venue", text: $venueName)
                            .autocorrectionDisabled(true)
                            .disabled(true) // prevents keyboard from showing
                            .allowsHitTesting(true) // still lets user tap
                            .focused($isVenueFocused)
                            .onChange(of: isVenueFocused) { focused in
                                if focused {
                                    fetchVenues()
                                } else {
                                    // Optionally clear suggestions when focus is lost
                                    // venueSuggestions = []
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .onTapGesture {
                                showVenueAutoComplete = true
                            }
                    }
                    .padding(.horizontal)
                    
                    // Event Date Picker
                    OptionalDateInputView(label: "Date", date: $eventDate)
                        .padding(.horizontal)
                    
                    // Time Inputs using our custom OptionalTimeInputView
                    HStack(alignment: .top, spacing: 16) {
                        OptionalTimeInputView(label: "Doors", time: $doorTime)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        OptionalTimeInputView(label: "Show Time", time: $showTime)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    
                    // Promoter Input with Auto-Complete
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Promoter")
                                .font(.headline)
    
                            Spacer()
                        }
                        TextField("Promoter", text: $promoterName)
                            .autocorrectionDisabled(true)
                            .disabled(true) // prevents keyboard from showing
                            .allowsHitTesting(true) // still lets user tap
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .onTapGesture {
                                showPromoterAutoComplete = true
                            }
                    }
                    .padding(.horizontal)
                    
                    
                    // Cover Input
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Cover")
                                .font(.headline)
                            Spacer()
                        }
                        HStack {
                            Text("$")
                            TextField("Cover", text: $coverText)
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
                        Text("Artists ")
                            .font(.headline)

                        ForEach(artistNames.indices, id: \.self) { index in
                            HStack {
                                TextField("Artist", text: $artistNames[index])
                                    .autocorrectionDisabled(true)
                                    .disabled(true)  // prevents direct keyboard interaction
                                    .allowsHitTesting(true)  // tap events still come through
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        // force any current first responder to resign (e.g., cover input)
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        selectedArtistIndex = index
                                    }
                                
                                if !artistNames[index].trimmingCharacters(in: .whitespaces).isEmpty {
                                    Button(action: {
                                        artistNames.remove(at: index)
                                        selectedArtists.remove(at: index)

                                        if artistNames.isEmpty {
                                            artistNames.append("")
                                            selectedArtists.append(nil)
                                        }

                                        if let selected = selectedArtistIndex {
                                            if selected == index {
                                                selectedArtistIndex = nil
                                            } else if selected > index {
                                                selectedArtistIndex = selected - 1
                                            }
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .background(colorScheme == .dark ? Color.black : Color.white)
                                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    }
                                }
                            }
                        }
                        Button(action: {
                            artistNames.append("")
                            selectedArtists.append(nil)  // New artist field starts with no selection.
                            selectedArtistIndex = artistNames.count - 1
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .background(colorScheme == .dark ? Color.black : Color.white)
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    .font(.footnote)
                                Text("Add Artist")
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    .font(.footnote)
                            }
                        }
                        .disabled(artistNames.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                        .padding(.top, 4) // <- this is the tweak
                    }
                    .padding(.horizontal)
                    
                    // Flyer Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Flyer Link")
                            .font(.headline)
                        
                        PasteTextField(text: $flyerLink, placeholder: "Paste URL here")
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        
                        // Use the helper to check the URL's host
                        if !flyerLink.isEmpty, !isTrustedFlyerLink(flyerLink) {
                            Text("Please use links only from Instagram or Facebook")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            uploadFlyerImage()
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.doc.fill")
                                    .background(colorScheme == .dark ? Color.black : Color.white)
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    .font(.footnote)
                                Text("Upload Flyer Image")
                                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                    .font(.footnote)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal)

                    // Submit Button
                    Button(action: {
                        // Dismiss keyboard before submitting
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        submitEvent()
                    }) {
                        Text("add event")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colorScheme == .dark ? Color.white : Color.black)
                            .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 32)
                    
                    Spacer()
                }
            }
            .fullScreenCover(isPresented: $showSuccess) {
                SuccessOverlay {
                    showSuccess = false
                } addAnotherAction: {
                    resetForm()
                    showSuccess = false
                }
            }
            .fullScreenCover(isPresented: $showVenueAutoComplete) {
                VenueAutoCompleteOverlay(text: $venueName, selectedVenue: $selectedVenue, suggestions: venueSuggestions, title: "Venues")
                    .onAppear {
                        fetchVenues()
                    }
                    .onDisappear {
                        isVenueFocused = false
                    }
            }
            // Full-screen auto-complete overlay for Promoter
            .fullScreenCover(isPresented: $showPromoterAutoComplete) {
                PromoterAutoCompleteOverlay(text: $promoterName, selectedPromoter: $selectedPromoter, suggestions: promoterSuggestions, title: "Promoters")
                    .onAppear {
                        fetchPromoters()
                    }
                    .onDisappear {
                        if selectedPromoter == nil || (selectedPromoter?.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
                            promoterName = ""
                            selectedPromoter = nil
                        }
                    }
            }
            // Full-screen auto-complete overlay for Artists using selectedArtistIndex
            .fullScreenCover(isPresented: Binding<Bool>(
                get: { selectedArtistIndex != nil },
                set: { if !$0 { selectedArtistIndex = nil } }
            )) {
                if let index = selectedArtistIndex {
                    // Create a binding for the selected artist at the current index.
                    let selectedArtistBinding = Binding<Artist?>(
                        get: { selectedArtists[index] },
                        set: { newValue in
                            selectedArtists[index] = newValue
                        }
                    )
                    ArtistAutoCompleteOverlay(text: $artistNames[index],
                                              selectedArtist: selectedArtistBinding,
                                              suggestions: artistSuggestions,
                                              title: "Artists")
                    .onAppear {
                        fetchArtists()
                    }
                    .onDisappear {
                        selectedArtistIndex = nil
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
        if let city = selectedVenue?.city, !city.isEmpty {
            tags.append(city)
        }
        return tags
    }
    
    // Fetch venues from API.
    // Fetch venues from the API.
    func fetchVenues() {
        guard let url = URL(string: "https://enm-project-production.up.railway.app/api/venues") else { return }
        Task {
            do {
                let venues: [Venue] = try await fetchWithRetry(url: url)
                DispatchQueue.main.async {
                    venueSuggestions = venues
                }
            } catch {
                print("Error fetching venues: \(error)")
            }
        }
    }    
    func fetchPromoters() {
        guard let url = URL(string: "https://enm-project-production.up.railway.app/api/promoters") else { return }
        Task {
            do {
                let promoters: [Promoter] = try await fetchWithRetry(url: url)
                DispatchQueue.main.async {
                    promoterSuggestions = promoters
                }
            } catch {
                print("Error fetching promoters: \(error)")
            }
        }
    }
    func fetchArtists() {
        guard let url = URL(string: "https://enm-project-production.up.railway.app/api/artists") else { return }
        Task {
            do {
                let artists: [Artist] = try await fetchWithRetry(url: url)
                DispatchQueue.main.async {
                    artistSuggestions = artists
                }
            } catch {
                print("Error fetching artists: \(error)")
            }
        }
    }
        
    // Submit event function: build event object and print (simulate API call).
    func submitEvent() {
        // Validate required fields.
        guard !venueName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please fill in required fields (Venue and City)."
            return
        }
        
        // Validate flyer link
        if !flyerLink.isEmpty && !isTrustedFlyerLink(flyerLink) {
            errorMessage = "Please use a flyer link from Instagram or Facebook."
            return
        }
        
        var eventData = [String: Any]()
        
        // Venue
        if let venue = selectedVenue {
            if let data = try? JSONEncoder().encode(venue),
               var venueDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                eventData["venue"] = unwrapID(from: venueDict)
            } else {
                eventData["venue"] = ["name": venueName]
            }
        } else {
            eventData["venue"] = ["name": venueName]
        }

        // Promoter
        if let promoter = selectedPromoter {
            if let data = try? JSONEncoder().encode(promoter),
               var promoterDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                eventData["promoter"] = unwrapID(from: promoterDict)
            } else {
                eventData["promoter"] = ["name": promoterName]
            }
        } else {
            eventData["promoter"] = ["name": promoterName]
        }
        
        // Create an ISO8601DateFormatter with fractional seconds.
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // 1. "date": Use only the date portion from eventDate.
        guard let unwrappedDate = eventDate else {
            errorMessage = "Please select a date."
            return
        }
        let eventDateAtStart = Calendar.current.startOfDay(for: unwrappedDate)
        eventData["date"] = isoFormatter.string(from: eventDateAtStart)

        // 2. "doorTime": Combine the doorTime's time with today's date.
        if let doorTime = doorTime {
            let now = Date()
            let timeComponents = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: doorTime)
            if let doorCombined = Calendar.current.date(bySettingHour: timeComponents.hour ?? 0,
                                                          minute: timeComponents.minute ?? 0,
                                                          second: timeComponents.second ?? 0,
                                                          of: now) {
                eventData["doorTime"] = isoFormatter.string(from: doorCombined)
            }
        } else {
            eventData["doorTime"] = ""
        }

        // 3. "dateTime": Combine the date from eventDate with the time from showTime.
        if let showTime = showTime {
            let timeComponents = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: showTime)
            if let showCombined = Calendar.current.date(bySettingHour: timeComponents.hour ?? 0,
                                                        minute: timeComponents.minute ?? 0,
                                                        second: timeComponents.second ?? 0,
                                                        of: eventDateAtStart) {
                eventData["dateTime"] = isoFormatter.string(from: showCombined)
            }
        } else if doorTime == nil {
            // default to 11:59 PM if both times are missing
            if let fallbackTime = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: eventDateAtStart) {
                eventData["dateTime"] = isoFormatter.string(from: fallbackTime)
            }
        } else {
            eventData["dateTime"] = ""
        }
        
        if !coverText.isEmpty {
            eventData["cover"] = Int(coverText) ?? 0
        }
        
        // In your submitEvent() function, update the artists section.
        // If you have a selected artist (from auto‑complete) for an artist field, encode it;
        // otherwise, fall back to the plain text in artistNames.
        // Artists: process each artist in your array.
        let validArtists: [[String: Any]] = artistNames.enumerated().compactMap { index, artistName in
            let trimmed = artistName.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return nil }
            // Use the corresponding selected artist if available.
            if let selectedArtist = selectedArtists[index] {
                if let data = try? JSONEncoder().encode(selectedArtist),
                   var artistDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    return unwrapID(from: artistDict)
                }
            }
            // Fallback: just use the name.
            return ["name": trimmed]
        }

        if !validArtists.isEmpty {
            eventData["artists"] = validArtists
        }
        
        eventData["flyer"] = flyerLink
        eventData["tags"] = buildTags()
        // Optionally add "submittedBy" if needed.
         eventData["submittedBy"] = authManager.user?.username
        
        errorMessage = nil
                
        // Convert eventData to JSON for pretty-printing in the console.
        if let jsonData = try? JSONSerialization.data(withJSONObject: eventData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Submitting event:\n\(jsonString)")
        } else {
            print("Submitting event: \(eventData)")
        }
        
        // Now send the payload to the API.
        guard let url = URL(string: "https://enm-project-production.up.railway.app/api/enmEvent") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: eventData, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error serializing eventData: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error submitting event: \(error)")
                return
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response from API:\n\(responseString)")
            }
        }.resume()
        
        showSuccess = true
        resetForm()
    }
    func resetForm() {
        venueName = ""
        promoterName = ""
        eventDate = nil
        doorTime = nil
        showTime = nil
        coverText = ""
        artistNames = [""]
        flyerLink = ""
    }
    func unwrapID(from dict: [String: Any]) -> [String: Any] {
        var newDict = dict
        if let idObject = dict["_id"] as? [String: Any],
           let oid = idObject["$oid"] as? String {
            newDict["_id"] = oid
        }
        return newDict
    }
    func fetchWithRetry<T: Decodable>(url: URL, maxRetries: Int = 3, initialDelay: UInt64 = 1_000_000_000) async throws -> T {
        var currentRetries = 0
        var delayTime = initialDelay
        while true {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                if currentRetries < maxRetries {
                    currentRetries += 1
                    try await Task.sleep(nanoseconds: delayTime)
                    delayTime *= 2  // exponential backoff
                } else {
                    throw error
                }
            }
        }
    }
    func isTrustedFlyerLink(_ link: String) -> Bool {
        guard let url = URL(string: link),
              let host = url.host?.lowercased() else {
            return false
        }
        return host.hasSuffix("instagram.com") || host.hasSuffix("facebook.com")
    }
}

#Preview {
    AddEventView()
}
