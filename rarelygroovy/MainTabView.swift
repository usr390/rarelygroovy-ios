import SwiftUI
import UIKit  // for UIImpactFeedbackGenerator

struct MainTabView: View {
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            
            NavigationView {
                EventsView()
                    .navigationTitle("Events")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tag(0)
            .tabItem { Label("Events", systemImage: "calendar") }
            
            NavigationView {
                ArtistDirectoryView()
                    .navigationTitle("Artist Directory")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tag(1)
            .tabItem { Label("Artist Directory", systemImage: "music.mic") }
            
            NavigationView {
                AddEventView()
                    .navigationTitle("Add Event")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tag(2)
            .tabItem { Label("Add Event", systemImage: "plus") }
            
            NavigationView {
                LoginView() // handles login and profile display based on state
                    .navigationBarHidden(true) // hide the header for a centered layout
            }
            .tag(3)
            .tabItem { Label("Profile", systemImage: "person") }
        }
        .accentColor(.primary)
        // swipe gesture to change tabs
        .gesture(
            DragGesture().onEnded { value in
                let dragThreshold: CGFloat = 50
                withAnimation(.easeInOut(duration: 0.4)) {
                    if value.translation.width < -dragThreshold {
                        selection = min(selection + 1, 3)
                    } else if value.translation.width > dragThreshold {
                        selection = max(selection - 1, 0)
                    }
                }
            }
        )
        // light haptic feedback on tab change
        .onChange(of: selection) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}



