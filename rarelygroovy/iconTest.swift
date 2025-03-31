import SwiftUI

struct DebugFontsView: View {
    var body: some View {
        Text("Debug Fonts")
            .onAppear {
                for family in UIFont.familyNames.sorted() {
                    print("Family: \(family)")
                    for name in UIFont.fontNames(forFamilyName: family).sorted() {
                        print("   \(name)")
                    }
                }
            }
    }
}

struct DebugFontsView_Previews: PreviewProvider {
    static var previews: some View {
        DebugFontsView()
    }
}
