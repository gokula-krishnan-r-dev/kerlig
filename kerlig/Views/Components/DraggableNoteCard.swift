import SwiftUI

struct DraggableNoteCard: View {
    let note: Note
    let columnId: UUID
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(note.isCompleted ? Color(hex: "#4CAF50") : .gray)
                .font(.system(size: 18))
                .contentShape(Rectangle())
                .onTapGesture {
                    // Toggle completion
                }
            
            // Title and time
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.system(size: 14))
                    .foregroundColor(note.isCompleted ? .gray : .white)
                    .strikethrough(note.isCompleted)
                
                if let estimatedTime = note.estimatedTime, !estimatedTime.isEmpty {
                    Text(estimatedTime)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Task actions
            if isHovered {
                HStack(spacing: 8) {
                    Button(action: {
                        // Edit action
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        // Delete action
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: isHovered ? "#2C2C2E" : "#1C1C1E"))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .draggable(note.id.uuidString) {
            DraggableNoteCard(note: note, columnId: columnId)
                .frame(width: 300)
        }
    }
}

#Preview {
    DraggableNoteCard(
        note: Note(
            title: "Sample Task",
            content: "",
            estimatedTime: "02:00",
            isCompleted: false
        ),
        columnId: UUID()
    )
    .padding()
    .background(Color.black)
} 