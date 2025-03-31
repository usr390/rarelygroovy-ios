import SwiftUI

struct SidebarView: View {
    var body: some View {
        NavigationView {
            // The sidebar list
            List {
                NavigationLink(destination: ArtistDirectoryView()) {
                    Label("Artists", systemImage: "music.mic")
                }
                NavigationLink(destination: EventsView()) {
                    Label("Events", systemImage: "calendar")
                }
            }
            .listStyle(SidebarListStyle())  // iPad/macOS: shows as a sidebar
            .navigationTitle("Main Menu")
            
            // Default detail if nothing is selected (mainly for iPad/macOS)
            Text("Select a page from the sidebar")
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
    }
}
