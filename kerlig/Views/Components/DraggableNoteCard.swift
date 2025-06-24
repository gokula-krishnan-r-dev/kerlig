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
    
    var body: some View {
        HStack(spacing: 12) {
            // Title and time
            VStack(alignment: .leading, spacing: 4) {
                HStack{

                    //show number 1 23  
                    Text("\((index ?? 0) + 1)")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#2C2C2E"))
                        .cornerRadius(12)

                // if isEditing {
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
                // } else {
                //     Text(note.title)
                //         .font(.system(size: 14))
                //         .foregroundColor(note.isCompleted ? .gray : .white)
                //         .strikethrough(note.isCompleted)
                //         .lineLimit(1)
                //         .truncationMode(.tail)
                //         .onTapGesture {
                //             if isHovered {
                //                 editableTitle = note.title
                //                 isEditing = true
                //             } else {
                //                 NotificationCenter.default.post(
                //                     name: Notification.Name("EditNoteContent"),
                //                     object: nil,
                //                     userInfo: ["noteId": note.id]
                //                 )
                //             }
                //         }
                // }

                    Spacer()

                    if isHovered {
                        //add a button for note icon button
                        Button(action: {
                            //add a button for note icon button 
                            isNoteIcon.toggle()
                        }) {
                            Image(systemName: isNoteIcon ? "note.text" : "note.text.badge.plus")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)


                        // Menu button
                        Button(action: {
                            isThreeDotPopoverPresented.toggle()
                        }) {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .popover(isPresented: $isThreeDotPopoverPresented) {
                            VStack(spacing: 0) {
                                Button(action: {
                                    // Schedule the note
                                }) {
                                    HStack {
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
                                }) {
                                    HStack {
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
                        }
                    }
                }




                if isNoteIcon {
                    NotePadTextEditorView(noteStore: noteStore , isNoteIcon: $isNoteIcon)
                }

if !isNoteIcon {
                HStack{

                    Text("+ EST")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)


                    Spacer()
                if let estimatedTime = note.estimatedTime, !estimatedTime.isEmpty {
                    Text(estimatedTime)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }else{
                    Text("0 min")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                }
                Spacer()

}
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: isHovered ? "#2C2C2E" : "#1C1C1E"))
        .frame(maxWidth: .infinity)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .draggable(note.id.uuidString) {
            DraggableNoteCard(note: note, columnId: columnId, index: 1, noteStore: noteStore)
                .frame(width: 300)
        }
        .onAppear {
            editableTitle = note.title
        }
    }
    
    private func saveTitle() {
        if editableTitle != note.title {
            var updatedNote = note
            updatedNote.title = editableTitle
            noteStore.updateNote(updatedNote)

            //reload the note
            noteStore.loadNotes()


            print("Note updated")
            print(editableTitle + "  dfdfdf" + note.title + " sdsds " + note.id.uuidString)

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
