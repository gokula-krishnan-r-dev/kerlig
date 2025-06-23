import SwiftUI

struct FloatingSidebarView: View {
    @StateObject private var noteStore = NoteStore()
    @State private var isAddingNote = false
    @State private var newNoteTitle = ""
    @State private var estimatedTime = "00:00"
    @FocusState private var isFocused: Bool
    let controller: FloatingSidebarController
    let onClose: () -> Void
    let focusCardController = FocusCardController()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Tasks")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        controller.hideSidebar()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
            .padding()
            .background(Color(hex: "#1C1C1E"))
            
            // Add task section
            if isAddingNote {
                VStack(spacing: 12) {
                    HStack {
                        Text("CANCEL")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .onTapGesture {
                                isAddingNote = false
                            }
                            .keyboardShortcut(.escape)
                        
                        Spacer()
                        
                        Text("Title")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("Est time")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        TextField("Enter task title*", text: $newNoteTitle)
                            .textFieldStyle(PlainTextFieldStyle())
                            .focused($isFocused)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color(hex: "#2C2C2E"))
                            .cornerRadius(6)
                            .onSubmit {
                                createNewNote()
                            }
                        
                        TextField("00:00", text: $estimatedTime)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 60)
                            .padding(8)
                            .background(Color(hex: "#2C2C2E"))
                            .cornerRadius(6)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Add a new task")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Button(action: {
                            createNewNote()
                        }) {
                            Text("Confirm")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "#4CAF50"), Color(hex: "#45A049")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                        }
                        .disabled(newNoteTitle.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(Color(hex: "#1C1C1E"))
            } else {
                Button(action: {
                    isAddingNote = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .foregroundColor(.gray)
                        Text("ADD TASK")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#2C2C2E"))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // Tasks list
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(noteStore.notes) { note in
                        TaskRowView(note: note, noteStore: noteStore)
                    }
                }
                .padding(.vertical, 8)
            }
            
            if noteStore.notes.isEmpty {
                VStack {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("All Clear")
                        .font(.headline)
                        .foregroundColor(.gray.opacity(0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }

            //add button for focus mode
            Button(action: {
                onClose()  // Close the floating sidebar
                focusCardController.toggleFocusCard()  // Show the focus card
            }) {
                HStack {
                    Image(systemName: "timer")
                        .font(.system(size: 14))
                    Text("Focus Mode")
                        .font(.system(size: 14))
                }
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
        }
        .background(Color(hex: "#1C1C1E"))
        .onAppear {
            isFocused = true
        }
    }
    
    private func createNewNote() {
        if !newNoteTitle.isEmpty {
            let newNote = Note(
                title: newNoteTitle,
                content: "",
//                estimatedTime: estimatedTime
            )
            noteStore.addNote(
                title: newNoteTitle,
                content: "",
//                estimatedTime: estimatedTime
            )
            isAddingNote = false
            newNoteTitle = ""
            estimatedTime = "00:00"
            focusOnNewNote()
        }
    }
    
    private func focusOnNewNote() {
        isFocused = true
        isAddingNote = true
        newNoteTitle = ""
        estimatedTime = "00:00"
    }
}

struct TaskRowView: View {
    let note: Note
    @ObservedObject var noteStore: NoteStore
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(note.isCompleted ? Color(hex: "#4CAF50") : .gray)
                .font(.system(size: 18))
                .contentShape(Rectangle())
                .onTapGesture {
                    var updatedNote = note
                    updatedNote.isCompleted.toggle()
                    noteStore.updateNote(updatedNote)
                }
            
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
                        noteStore.deleteNote(note)
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
    }
}
