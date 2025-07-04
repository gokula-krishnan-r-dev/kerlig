import SwiftUI

struct ModernNoteCard: View {
    let note: Note
    let noteStore: NoteStore
    let onUpdate: () -> Void
    @State private var isHovered = false
    @State private var isDragging = false
    @State private var dragOffset = CGSize.zero
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        toggleNoteCompletion()
                    }
                }) {
                    Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundColor(note.isCompleted ? .green : .gray)
                        .scaleEffect(isHovered ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                }
                .buttonStyle(PlainButtonStyle())
                .hoverEffect(.lift)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .strikethrough(note.isCompleted)
                        .lineLimit(2)
                        .opacity(note.isCompleted ? 0.7 : 1.0)
                    
                    if !note.content.isEmpty {
                        Text(note.content)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                            .opacity(note.isCompleted ? 0.6 : 1.0)
                    }
                }
                
                Spacer()
                
                // Drag handle indicator
                if isHovered && !note.isCompleted {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                        .transition(.opacity.combined(with: .scale))
                }
            }
            
            // Task metadata
            HStack {
                // Media indicator
                if note.mediaContent.hasContent {
                    mediaIndicator
                } else if let imageData = note.imageData, !imageData.isEmpty {
                    // Backward compatibility
                    Image(systemName: "photo.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue.opacity(0.6))
                        .padding(3)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                
                // Category badge
                Text(note.category.rawValue.capitalized)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                    )
                
                Spacer()
                
                // Priority indicator for scheduled tasks
                if note.priority != .medium {
                    Image(systemName: note.priority.iconName)
                        .font(.system(size: 10))
                        .foregroundColor(note.priority.color)
                }
                
                // Time indicator
                Text(note.creationDate, style: .relative)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                    .opacity(0.8)
            }
            
            // Estimated time and actual time
            if let estimatedTime = note.estimatedTime, !estimatedTime.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    Text("Est: \(estimatedTime)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.blue.opacity(0.8))
                    
                    if let actualTime = note.actualTime {
                        Text("• Actual: \(formatTime(actualTime))")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.green.opacity(0.8))
                    }
                }
            }
        }
        .padding(14)
        .background(noteCardBackground)
        .overlay(noteCardBorder)
        .scaleEffect(isDragging ? 0.95 : (isHovered ? 1.02 : 1.0))
        .rotationEffect(.degrees(isDragging ? 2 : 0))
        .offset(dragOffset)
        .opacity(isDragging ? 0.8 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isDragging)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .draggable(note) {
            DragPreviewCard(note: note)
        }
        .onChange(of: isDragging) { _, newValue in
            if !newValue {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    dragOffset = .zero
                }
            }
        }
    }
    
    private var mediaIndicator: some View {
        Group {
            switch note.mediaContent.type {
            case .image:
                if let imageData = note.mediaContent.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                } else {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue.opacity(0.6))
                        .padding(3)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            case .emoji:
                if let emoji = note.mediaContent.emoji {
                    Text(emoji)
                        .font(.system(size: 14))
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.05))
                        )
                }
            case .none:
                EmptyView()
            }
        }
    }
    
    private var noteCardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(isDragging ? 0.20 : (isHovered ? 0.12 : 0.08)),
                        Color.white.opacity(isDragging ? 0.15 : (isHovered ? 0.08 : 0.04))
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .shadow(
                color: Color.black.opacity(isDragging ? 0.25 : (isHovered ? 0.15 : 0.08)), 
                radius: isDragging ? 12 : (isHovered ? 6 : 3), 
                x: 0, 
                y: isDragging ? 6 : (isHovered ? 3 : 2)
            )
    }
    
    private var noteCardBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(isDragging ? 0.4 : (isHovered ? 0.25 : 0.15)),
                        Color.white.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isDragging ? 1.5 : 1
            )
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(Int(time))s"
        }
    }
    
    private func toggleNoteCompletion() {
        if let index = noteStore.notes.firstIndex(where: { $0.id == note.id }) {
            noteStore.notes[index].isCompleted.toggle()
            noteStore.saveNotes()
            onUpdate()
        }
    }
}

// MARK: - Drag Preview Card
struct DragPreviewCard: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                
                Text(note.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
            }
            
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.8))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
} 