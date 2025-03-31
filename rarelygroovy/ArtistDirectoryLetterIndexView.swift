import SwiftUI
import UIKit

/// A vertical letter index that calls onLetterChange whenever the letter changes while dragging.
struct LetterIndexView: View {
    // letters to display (you could also limit to only those that appear)
    let letters: [String] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }
    
    // Callback when the user drags over a new letter.
    var onLetterChange: (String) -> Void

    // track the current letter (for haptic feedback control)
    @State private var currentLetter: String = ""
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(letters, id: \.self) { letter in
                Text(letter)
                    .font(.caption)
                    .foregroundColor(letter == currentLetter ? .blue : .primary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
        .background(Color.clear)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Determine the letter based on the y position
                    let totalHeight = UIScreen.main.bounds.height
                    // ideally, you’d base letter height on the actual view size;
                    // for simplicity, assume totalHeight divided by number of letters
                    let letterHeight = totalHeight / CGFloat(letters.count)
                    let index = min(max(Int((value.location.y) / letterHeight), 0), letters.count - 1)
                    let letter = letters[index]
                    
                    if letter != currentLetter {
                        currentLetter = letter
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onLetterChange(letter)
                    }
                }
        )
    }
}
