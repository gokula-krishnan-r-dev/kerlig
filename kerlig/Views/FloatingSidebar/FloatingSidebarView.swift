import SwiftUI

struct FloatingSidebarView: View {
    // MARK: - Properties
    @StateObject private var noteStore = NoteStore()
    @State private var isAddingNote = false
    @State private var newNoteTitle = ""
    @State private var estimatedTime = "00:00"
    @FocusState private var isFocused: Bool
    @State private var sidebarWidth: CGFloat = 320
    @State private var isDraggingEdge = false
    @State private var firstNote: Note? = nil
    @State private var showCompletedTasks: Bool = true
    
    let controller: FloatingSidebarController
    let onClose: () -> Void
    let focusCardController = FocusCardController()
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            if isAddingNote {
                addTaskView
            } else {
                addTaskButton
            }
            
            taskListView
            
            if noteStore.getPendingNotes().count == 0 {
                Spacer()
                emptyStateView
                Spacer()
            }
            
            Divider()
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            
            completedTasksSection
            
            focusModeButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundWithResizeHandle)
        .cornerRadius(16)
        .onAppear {
            isFocused = true
            firstNote = findFirstNote()
        }
    }
    
    // MARK: - UI Components
    private var headerView: some View {
        HStack {
            Text("Today")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    controller.hideSidebar()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 16))
                    .padding(4)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Circle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#2C2C2E"), Color(hex: "#1C1C1E")]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var addTaskView: some View {
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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            HStack {
                TextField("Enter task title*", text: $newNoteTitle)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isFocused)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color(hex: "#2C2C2E"))
                    .cornerRadius(8)
                    .onSubmit {
                        createNewNote()
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isFocused = true
                        }
                    }
                
                TextField("00:00", text: $estimatedTime)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(width: 60)
                    .padding(10)
                    .background(Color(hex: "#2C2C2E"))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            
            HStack {
                Text("Add a new task")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: createNewNote) {
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
                .buttonStyle(PlainButtonStyle())
                .disabled(newNoteTitle.isEmpty)
                .opacity(newNoteTitle.isEmpty ? 0.5 : 1.0)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color(hex: "#1C1C1E"))
        .cornerRadius(12)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
    
    private var addTaskButton: some View {
        Button(action: {
            isAddingNote = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(Color(hex: "#4CAF50"))
                    .font(.system(size: 16))
                Text("ADD TASK")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#4CAF50"))
                
                Text("⌘ + T")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "#4CAF50"))
                    .padding(.leading, 4)
                    .background(Color(hex: "#2C2C2E"))
                    .cornerRadius(4)
            }
            .padding(.vertical, 12)
            .keyboardShortcut("t", modifiers: [.command])
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#2C2C2E"))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var taskListView: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(noteStore.getPendingNotes()) { note in
                    TaskRowView(
                        note: note,
                        firstNote: firstNote,
                        noteStore: noteStore,
                        onDone: {
                            firstNote = findFirstNote()
                        }
                    )
                    .background(Color(hex: "#2C2C2E"))
                    .cornerRadius(8)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(hex: "#1C1C1E"))
    }
    
    private var emptyStateView: some View {
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
    
    private var completedTasksSection: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Text("\(noteStore.getCompletedNotes().count)")
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text("Done")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(noteStore.getTotalTimeSpentOnCompletedNotes())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            
            if showCompletedTasks {
                completedTasksList
            }
        }
    }
    
    private var completedTasksList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 4) {
                ForEach(noteStore.getCompletedNotes()) { note in
                    CompletedTaskRow(note: note)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 200)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var focusModeButton: some View {
        Button(action: {
             onClose()
            focusCardController.toggleFocusCard()
        }) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 8, height: 8)
                Text("Focus Mode")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#2C2C2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.bottom, 12)
        .padding(.top, 8)
    }
    
    private var backgroundWithResizeHandle: some View {
        ZStack {
            Color(hex: "#1C1C1E")
            
            // Left edge handle for resizing
            HStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 8)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        if hovering {
                            NSCursor.resizeLeftRight.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 2)
                            .onChanged { value in
                                isDraggingEdge = true
                                let newWidth = sidebarWidth - value.translation.width
                                if newWidth >= 280 && newWidth <= 500 {
                                    sidebarWidth = newWidth
                                    controller.resizeWindow(width: sidebarWidth)
                                }
                            }
                            .onEnded { _ in
                                isDraggingEdge = false
                            }
                    )
                
                Spacer()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func findFirstNote() -> Note? {
        return noteStore.getPendingNotes().first
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func createNewNote() {
        if !newNoteTitle.isEmpty {
            noteStore.addNote(
                id: UUID(),
                title: newNoteTitle,
                content: "",
                category: .uncategorized
            )
            isAddingNote = false
            newNoteTitle = ""
            estimatedTime = "00:00"
            focusOnNewNote()
            firstNote = findFirstNote()
        }
    }
    
    private func focusOnNewNote() {
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isFocused = true
        }
        isAddingNote = true
        newNoteTitle = ""
        estimatedTime = "00:00"
    }
}

// MARK: - Completed Task Row
struct CompletedTaskRow: View {
    let note: Note
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
            
            Text(note.title)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
            
            Spacer()
            
            if let actualTime = note.actualTime {
                timeLabel(actualTime)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#232325"))
        .cornerRadius(6)
        .padding(.horizontal, 12)
    }
    
    private func timeLabel(_ actualTime: TimeInterval) -> some View {
        let seconds = Int(actualTime)
        let minutes = seconds / 60
        let displayText = minutes > 0 ? "\(minutes)m" : "\(seconds)s"
        
        return Text(displayText)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: "#2C2C2E"))
            .cornerRadius(4)
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    var note: Note
    let firstNote: Note?
    @ObservedObject var noteStore: NoteStore
    let onDone: () -> Void

    @State private var isNotes = false
    
    @State private var isBreak = false
    @State private var breakTime: TimeInterval = 0
    @State private var isHovered = false
    @State private var editableTitle: String = ""
    @State private var timer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    @State private var hoveredButton: String? = nil
    
    var body: some View {
        VStack {
            if !isNotes && isHovered && firstNote?.id == note.id {
                actionButtonsView
            } else {
                if isBreak {
                    breakModeView
                } else {
                        normalTaskView
                }
            }


             if isNotes {
                     NotePadTextEditorView(noteStore: noteStore , isNoteIcon: $isNotes)
                    }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
                if !hovering {
                    hoveredButton = nil
                }
            }
        }
        .onAppear {
            editableTitle = note.title
   timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !isBreak {
                elapsedTime += 1

                //save the timer to the note
                var updatedNote = note
                updatedNote.actualTime = elapsedTime
                noteStore.updateNote(updatedNote)
            }else{
                breakTime += 1
            }
        }


       
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            if !isBreak {
                // Done button
                TaskActionButton(
                    icon: "checkmark.circle.fill",
                    label: "Done",
                    isHovered: hoveredButton == "done",
                    color: .green,
                    action: {
                        var updatedNote = note
                        updatedNote.isCompleted = true
                        updatedNote.actualTime = elapsedTime
                        noteStore.updateNote(updatedNote)
                        onDone()
                    },
                    onHover: { isHovering in
                        hoveredButton = isHovering ? "done" : nil
                    }
                )
                
                // Notes button
                TaskActionButton(
                    icon: "note.text",
                    label: "Notes",
                    isHovered: hoveredButton == "notes",
                    color: .blue,
                    action: {
                        isNotes.toggle()
                    },
                    onHover: { isHovering in
                        hoveredButton = isHovering ? "notes" : nil
                    }
                )
                
                // Break button
                TaskActionButton(
                    icon: "timer",
                    label: "Break",
                    isHovered: hoveredButton == "break",
                    color: .orange,
                    action: {
                        isBreak = true
                        breakTime = elapsedTime
                    },
                    onHover: { isHovering in
                        hoveredButton = isHovering ? "break" : nil
                    }
                )
                
                // Skip button
                TaskActionButton(
                    icon: "arrow.right.circle",
                    label: "Skip",
                    isHovered: hoveredButton == "skip",
                    color: .purple,
                    action: {
                        print("Task skipped: \(note.title)")
                    },
                    onHover: { isHovering in
                        hoveredButton = isHovering ? "skip" : nil
                    }
                )
                
                // Delete button
                TaskActionButton(
                    icon: "trash",
                    label: "Delete",
                    isHovered: hoveredButton == "delete",
                    color: .red,
                    action: {
                        noteStore.deleteNote(id: note.id)
                    },
                    onHover: { isHovering in
                        hoveredButton = isHovering ? "delete" : nil
                    }
                )
            } else {
                
                    breakModeView

            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(10)
    }
    
    private var breakModeView: some View {
        HStack {
            Text("Break")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(formatTime(breakTime))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            
            TaskActionButton(
                icon: "arrow.right.circle",
                label: "Skip",
                isHovered: hoveredButton == "skip",
                color: .purple,
                action: {
                    isBreak = false
                    breakTime = 0
                },
                onHover: { isHovering in
                    hoveredButton = isHovering ? "skip" : nil
                }
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )

    }
    
    private var normalTaskView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("", text: Binding(
                    get: { editableTitle },
                    set: { 
                        editableTitle = $0
                        saveTitle()
                    }
                ), onCommit: {
                    saveTitle()
                })
                .font(.system(size: 14, weight: note.isCompleted ? .regular : .medium))
                .foregroundColor(note.isCompleted ? .gray : .white)
                .strikethrough(note.isCompleted)
                .textFieldStyle(PlainTextFieldStyle())
                .lineLimit(1)
                .onSubmit {
                    saveTitle()
                }
                .onAppear {
                    DispatchQueue.main.async {
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
                }
                
                if let estimatedTime = note.estimatedTime, !estimatedTime.isEmpty {
                    Text(estimatedTime)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer(minLength: 4)
            
            if firstNote?.id == note.id {
                timerView
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: firstNote?.id == note.id ? "#2A332C" : "#2C2C2E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(firstNote?.id == note.id ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
    
    private var timerView: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 14))
                .foregroundColor(.green.opacity(0.8))
            
            Text(formatTime(elapsedTime))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.green.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
   


    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func saveTitle() {
        if editableTitle != note.title {
            var updatedNote = note
            updatedNote.title = editableTitle
            noteStore.updateNote(updatedNote)
        }
    }
}

// MARK: - Task Action Button
struct TaskActionButton: View {
    let icon: String
    let label: String
    let isHovered: Bool
    let color: Color
    let action: () -> Void
    let onHover: (Bool) -> Void
    var borderColor: Color? = nil
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(isHovered ? borderColor ?? color : .gray)
                
                if isHovered {
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isHovered ? .white : .gray)
                        .transition(.opacity)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color(hex: "#3C3C3E") : Color.clear)
            )
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .cornerRadius(55)
        .border(borderColor ?? Color.clear, width: borderColor != nil ? 1 : 0)
        .onHover { hovering in
            onHover(hovering)
        }
    }
}

