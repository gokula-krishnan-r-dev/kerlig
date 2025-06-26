import SwiftUI

struct DraggableNoteCard: View {
    let note: Note
    let columnId: UUID
    let index: Int?
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    @State private var isThreeDotPopoverPresented = false
    @State private var isNoteIcon = false
    @ObservedObject var noteStore: NoteStore
    @State private var editableTitle: String = ""
    @State private var isEditing = false
    @State private var isDragging = false
    @State private var isAppearing = false
    
    // Define a consistent color palette
    private let cardBgColor = Color(hex: "#2C2C2E")
    private let primaryBgColor = Color(hex: "#1A1A1C")
    private let secondaryBgColor = Color(hex: "#242426")
    private let accentColor = Color(hex: "#4CAF50")
    private let accentGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#4CAF50"), Color(hex: "#45A049")]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        HStack(spacing: 12) {
            // Title and time
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    // Task number indicator
                    Text("\((index ?? 0) + 1)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#1C1C1E"))
                        .cornerRadius(12)

                    // Task title field
                    TextField("", text: Binding(
                        get: { editableTitle },
                        set: { editableTitle = $0
                            saveTitle()
                            isEditing = false
                        }
                    ), onCommit: {
                        saveTitle()
                        isEditing = false
                    })
                    .font(.system(size: 14))
                    .foregroundColor(note.isCompleted ? .gray : .white)
                    .strikethrough(note.isCompleted)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        saveTitle()
                        isEditing = false
                    }   
                    .onAppear {
                        // Request focus when entering edit mode
                        DispatchQueue.main.async {
                            NSApp.keyWindow?.makeFirstResponder(nil)
                        }
                    }

                    Spacer()

                    if isHovered {
                        // Note icon button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isNoteIcon.toggle()
                            }
                        }) {
                            Image(systemName: isNoteIcon ? "note.text" : "note.text.badge.plus")
                                .foregroundColor(.white)
                                .font(.system(size: 12))
                                .padding(6)
                                .background(Color(hex: "#1C1C1E"))
                                .cornerRadius(12)
                        }
                        .buttonStyle(AnimatedButtonStyle())
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))

                        // Menu button
                        Button(action: {
                            isThreeDotPopoverPresented.toggle()
                        }) {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white)
                                .font(.system(size: 12))
                                .padding(6)
                                .background(Color(hex: "#1C1C1E"))
                                .cornerRadius(12)
                        }
                        .buttonStyle(AnimatedButtonStyle())
                        .popover(isPresented: $isThreeDotPopoverPresented) {
                            VStack(spacing: 0) {
                                Button(action: {
                                    // Schedule the note
                                }) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                            .frame(width: 24)
                                        
                                        Text("Schedule")
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                Button(action: {
                                    // Change list action
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.right.doc.on.clipboard")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                            .frame(width: 24)
                                        
                                        Text("Change list")
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                Button(action: {
                                    // Duplicate action
                                }) {
                                    HStack {
                                        Image(systemName: "plus.square.on.square")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                            .frame(width: 24)
                                        
                                        Text("Duplicate")
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                
                                Button(action: {
                                    // Delete the note
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        noteStore.deleteNote(id: note.id)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14))
                                            .foregroundColor(.red.opacity(0.8))
                                            .frame(width: 24)
                                        
                                        Text("Delete")
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .background(Color(hex: "#2C2C2E"))
                            .cornerRadius(12)
                            .frame(width: 180)
                            .padding(4)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }

                if isNoteIcon {
                    NotePadTextEditorView(noteStore: noteStore, isNoteIcon: $isNoteIcon)
                        .frame(height: 120)
                        .cornerRadius(8)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }

                if !isNoteIcon {
                    HStack {
                        Text("+ EST")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        Spacer()
                        
                        if let estimatedTime = note.estimatedTime, !estimatedTime.isEmpty {
                            Text(estimatedTime)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#1C1C1E"))
                                .cornerRadius(8)
                        } else {
                            Text("0 min")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#1C1C1E"))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: isHovered ? "#2C2C2E" : "#1C1C1E"))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isHovered ? accentColor.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .shadow(
            color: isDragging ? Color.black.opacity(0.2) : Color.clear, 
            radius: 10, 
            x: 0, 
            y: 5
        )
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .frame(maxWidth: .infinity)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .draggable(note.id.uuidString) {
            isDragging = true
            return DraggableNoteCard(note: note, columnId: columnId, index: 1, noteStore: noteStore)
                .frame(width: 300)
                .onDisappear {
                    isDragging = false
                }
        }
        .onAppear {
            editableTitle = note.title
            // Staggered appearance animation
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                isAppearing = true
            }
        }
        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 10)
    }
    
    private func saveTitle() {
        if editableTitle != note.title {
            var updatedNote = note
            updatedNote.title = editableTitle
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                noteStore.updateNote(updatedNote)
                //reload the note
                noteStore.loadNotes()
            }
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
        columnId: UUID(),
        index: 1,
        noteStore: NoteStore()
    )
    .padding()
    .background(Color.black)
} 
