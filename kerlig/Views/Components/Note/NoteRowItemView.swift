import SwiftUI

// Note row item in the sidebar
struct NoteRowItem: View {
    let note: Note
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(note.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(isSelected ? .primary : .primary)
                    
                    Spacer()
                    
                    if note.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Text(note.content.isEmpty ? "No content" : note.content)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: note.category.iconName)
                        .font(.caption2)
                        .foregroundColor(note.category.color)
                    
                    Text(formattedDate(note.lastModified))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .contentShape(Rectangle())
    }
    
    // Format date to readable string
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
