import SwiftUI

struct PlaceholderView: View {
    let isShowingProjects: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            Image(systemName: isShowingProjects ? "folder" : "note.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding()
                .symbolEffect(.pulse, options: .repeating)
            
            Text(isShowingProjects ? 
                "Select a project or create a new one" : 
                "Select a note or create a new one")
                .font(.title2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}


