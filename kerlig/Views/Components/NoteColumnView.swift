import SwiftUI

struct NoteColumnView: View {
    let column: NoteColumn
    let notes: [Note]
    @ObservedObject var noteStore: NoteStore
    @State private var newNoteTitle = ""
    @State private var isAddingNote = false
    @State private var estimatedTime = "00:00"
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool 
    var body: some View {
        VStack(spacing: 0) {
            // Column header
            HStack {
                Text(column.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
//                Text("\(notes.count)/\(notes.filter { $0.isCompleted }.count) Done")
//                    .font(.caption)
//                    .foregroundColor(.gray)
                
                Button(action: {
                    isAddingNote = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(hex: "#1C1C1E"))
            
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
                .cornerRadius(12)
                .padding(.horizontal)
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
            
            // Notes list
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(notes) { note in
                        DraggableNoteCard(note: note, columnId: column.id)
                    }
                }
                .padding(.vertical, 8)
            }
            
            if notes.isEmpty {
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
        }
        .background(Color(hex: "#1C1C1E"))
        .cornerRadius(12)
        .frame(width: 320)
        .onAppear {
            isFocused = true
        }
        .dropDestination(for: String.self) { items, location in
            guard let droppedNoteId = items.first.flatMap({ UUID(uuidString: $0) }),
                  let droppedNote = noteStore.notes.first(where: { $0.id == droppedNoteId }),
                  let sourceColumn = noteStore.columns.first(where: { $0.noteIds.contains(droppedNoteId) }) else {
                return false
            }
            
            noteStore.moveNote(droppedNote, from: sourceColumn, to: column)
            return true
        }
    }


    //function for create new note
    func createNewNote() {
         if !newNoteTitle.isEmpty {
                                let newNote = Note(
                                    title: newNoteTitle,
                                    content: "",
                                    // estimatedTime: estimatedTime
                                )
                                noteStore.addNote(
                                    title: newNoteTitle,
                                    content: "",
                                    // estimatedTime: estimatedTime
                                )
                                if let newNoteId = noteStore.notes.last?.id {
                                    var updatedColumn = column
                                    updatedColumn.noteIds.append(newNoteId)
                                    noteStore.updateColumn(updatedColumn)
                                }
                                isAddingNote = false
                                newNoteTitle = ""
                                estimatedTime = "00:00"
                                focusOnNewNote()
                            }

    }


    //after successfully create new note, focus on the new note
    func focusOnNewNote() {
        isFocused = true
        isAddingNote = true
        newNoteTitle = ""
        estimatedTime = "00:00"
    }
}
