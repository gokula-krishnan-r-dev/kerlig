import SwiftUI

struct NoteDetailView: View {
    @State private var editedNote: Note
    let onUpdate: (Note) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    init(note: Note, onUpdate: @escaping (Note) -> Void) {
        _editedNote = State(initialValue: note)
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    editedNote.isFavorite.toggle()
                    onUpdate(editedNote)
                }) {
                    Image(systemName: editedNote.isFavorite ? "star.fill" : "star")
                        .foregroundColor(editedNote.isFavorite ? .yellow : .gray)
                        .font(.title2)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Menu {
                    ForEach(NoteCategory.allCases) { category in
                        Button {
                            editedNote.category = category
                            onUpdate(editedNote)
                        } label: {
                            Label(category.rawValue, systemImage: category.iconName)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: editedNote.category.iconName)
                        Text(editedNote.category.rawValue)
                    }
                    .foregroundColor(editedNote.category.color)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .strokeBorder(editedNote.category.color, lineWidth: 1)
                    )
                }
                
                Spacer()
                
                Text(formatDate(editedNote.lastModified))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            
            TextField("Title", text: $editedNote.title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
                .focused($isTitleFocused)
                .onChange(of: editedNote.title) { _ in
                    onUpdate(editedNote)
                }
            
            TextEditor(text: $editedNote.content)
                .font(.body)
                .padding()
                .background(colorScheme == .dark ? Color.black : Color.white)
                .focused($isContentFocused)
                .onChange(of: editedNote.content) { _ in
                    onUpdate(editedNote)
                }
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .onAppear {
            // Add a small delay before focusing to allow animations to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isContentFocused = true
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleNote = Note(title: "Sample Note", content: "This is a sample note content", category: .personal)
    return NoteDetailView(note: sampleNote) { _ in }
} 