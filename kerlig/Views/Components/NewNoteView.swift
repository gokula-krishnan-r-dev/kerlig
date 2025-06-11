import SwiftUI

struct NewNoteView: View {
    @Binding var title: String
    @Binding var content: String
    let onSave: () -> Void
    let onCancel: () -> Void
    var selectedCategory: NoteCategory?
    @State private var noteCategory: NoteCategory
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    init(title: Binding<String>, content: Binding<String>, onSave: @escaping () -> Void, onCancel: @escaping () -> Void, selectedCategory: NoteCategory? = nil) {
        self._title = title
        self._content = content
        self.onSave = onSave
        self.onCancel = onCancel
        self.selectedCategory = selectedCategory
        self._noteCategory = State(initialValue: selectedCategory ?? .uncategorized)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .foregroundColor(.accentColor)
                
                Spacer()
                
                Menu {
                    ForEach(NoteCategory.allCases) { category in
                        Button {
                            noteCategory = category
                        } label: {
                            Label(category.rawValue, systemImage: category.iconName)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: noteCategory.iconName)
                        Text(noteCategory.rawValue)
                    }
                    .foregroundColor(noteCategory.color)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .strokeBorder(noteCategory.color, lineWidth: 1)
                    )
                }
                
                Spacer()
                
                Button("Save") {
                    onSave()
                }
                .foregroundColor(.accentColor)
                .disabled(title.isEmpty && content.isEmpty)
            }
            .padding()
            
            TextField("Title", text: $title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
                .focused($isTitleFocused)
            
            TextEditor(text: $content)
                .font(.body)
                .padding()
                .background(colorScheme == .dark ? Color.black : Color.white)
                .focused($isContentFocused)
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .onAppear {
            // Add a small delay before focusing to allow animations to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTitleFocused = true
            }
        }
    }
}

