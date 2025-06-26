import SwiftUI

struct NoteColumnView: View {
    let column: NoteColumn
    let notes: [Note]
    @ObservedObject var noteStore: NoteStore
    @State private var newNoteTitle = ""
    @State private var isAddingNote = false
    @State private var estimatedTime = "00:00"
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isTitleFieldFocused: Bool
    @State private var isHovering = false
    @State private var notesVisible = false
    
    // Define a consistent color palette
    private let primaryBgColor = Color(hex: "#1A1A1C")
    private let secondaryBgColor = Color(hex: "#242426") 
    private let cardBgColor = Color(hex: "#2C2C2E")
    private let accentColor = Color(hex: "#4CAF50")
    private let accentGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#4CAF50"), Color(hex: "#45A049")]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Column header with column color indicator
            columnHeader
            
            // Add note section
            addNoteSection
            
            // Notes list
            notesList
            
            // Empty state
            if notes.isEmpty {
                emptyStateView
            }
        }
        .background(Color(hex: "#1C1C1E"))
        .cornerRadius(12)
        .frame(width: 320)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovering ? (column.color ?? .gray).opacity(0.4) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    notesVisible = true
                }
            }
        }
        .dropDestination(for: String.self) { items, location in
            handleNoteDrop(items: items)
        }
    }
    
    // MARK: - View Components
    
    private var columnHeader: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(column.color ?? .gray)
                .frame(width: 12, height: 12)
            
            Text(column.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(notes.count) tasks")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#1C1C1E"))
                .cornerRadius(10)
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isAddingNote = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTitleFieldFocused = true
                    }
                }
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.gray)
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "#2C2C2E"))
                    .cornerRadius(14)
            }
            .buttonStyle(AnimatedButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#1C1C1E"))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2))
                .offset(y: 1),
            alignment: .bottom
        )
    }
    
    private var addNoteSection: some View {
        Group {
            if isAddingNote {
                VStack(spacing: 12) {
                    addNoteHeader
                    addNoteForm
                    addNoteActions
                }
                .background(Color(hex: "#1C1C1E"))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                addNoteButton
            }
        }
    }
    
    private var addNoteHeader: some View {
        HStack {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isAddingNote = false
                    resetForm()
                }
            }) {
                Text("CANCEL")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }
            .buttonStyle(AnimatedButtonStyle())
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
    }
    
    private var addNoteForm: some View {
        HStack {
            TextField("Enter task title*", text: $newNoteTitle)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isTitleFieldFocused)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(10)
                .background(cardBgColor)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onSubmit {
                    createNewNote()
                }
            
            TextField("00:00", text: $estimatedTime)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 60)
                .padding(10)
                .background(cardBgColor)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.horizontal)
    }
    
    private var addNoteActions: some View {
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
                    .background(accentGradient)
                    .cornerRadius(20)
                    .shadow(color: accentColor.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .buttonStyle(AnimatedButtonStyle())
            .disabled(newNoteTitle.isEmpty)
            .opacity(newNoteTitle.isEmpty ? 0.6 : 1)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var addNoteButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isAddingNote = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTitleFieldFocused = true
                }
            }
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(accentColor)
                    .font(.system(size: 16))
                Text("ADD TASK")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#2C2C2E").opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(AnimatedButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Array(zip(notes.indices, notes)), id: \.1.id) { index, note in
                    DraggableNoteCard(note: note, columnId: column.id, index: index, noteStore: noteStore)
                        .opacity(notesVisible ? 1 : 0)
                        .offset(y: notesVisible ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1 + Double(index) * 0.05), value: notesVisible)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.3))
                .padding(.bottom, 8)
            Text("All Clear")
                .font(.headline)
                .foregroundColor(.gray.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .opacity(notesVisible ? 1 : 0)
        .animation(.easeIn.delay(0.3), value: notesVisible)
    }
    
    // MARK: - Helper Methods
    
    private func createNewNote() {
        guard !newNoteTitle.isEmpty else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            let newNote = Note(
                id: UUID(),
                title: newNoteTitle,
                content: "",
                estimatedTime: estimatedTime.isEmpty ? "00:00" : estimatedTime
            )
            
            noteStore.addNote(
                id: newNote.id,
                title: newNoteTitle,
                content: ""
            )
            
            if let newNoteId = noteStore.notes.last?.id {
                var updatedColumn = column
                updatedColumn.noteIds.append(newNoteId)
                noteStore.updateColumn(updatedColumn)
            }
            
            resetForm()
        }
    }
    
    private func resetForm() {
        isAddingNote = false
        newNoteTitle = ""
        estimatedTime = "00:00"
        isTitleFieldFocused = false
    }
    
    private func handleNoteDrop(items: [String]) -> Bool {
        guard let droppedNoteId = items.first.flatMap({ UUID(uuidString: $0) }),
              let droppedNote = noteStore.notes.first(where: { $0.id == droppedNoteId }),
              let sourceColumn = noteStore.columns.first(where: { $0.noteIds.contains(droppedNoteId) }) else {
            return false
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            noteStore.moveNote(droppedNote, from: sourceColumn, to: column)
        }
        return true
    }
}
