import SwiftUI
import AppKit
import AVFoundation
import UserNotifications

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
    @State private var isCompleted: Bool = false
    @State private var completedTaskTime: TimeInterval = 0
    @State private var dismissTimer: Timer?
    @State private var recentlySkippedNoteId: UUID? = nil
    
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

            if isCompleted {
                completedTaskView
            }
            
            taskListView
            
            if noteStore.getPendingNotes().count == 0 {
                Spacer()
                emptyStateView
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            
            completedTasksSection
            
            focusModeButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundWithResizeHandle)
        .cornerRadius(20)
        .onAppear {
            isFocused = true
            firstNote = findFirstNote()
            
            // Debug: Print tick sound file status
            print("Tick sound file status: \n\(TickSoundService.shared.debugSoundFileStatus())")
            
            // Try to copy the tick.wav file to Documents directory if not found
            if TickSoundService.shared.debugSoundFileStatus().contains("No sound file path set") ||
               !TickSoundService.shared.debugSoundFileStatus().contains("Exists: Yes") {
                print("Attempting to copy tick.wav file to Documents directory...")
                let success = TickSoundService.shared.copyTickSoundToDocuments()
                print("Copy result: \(success ? "Success" : "Failed")")
            }
            
            // Test play the sound once
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                TickSoundService.shared.playTestSound()
            }
        }
    }
    
    // MARK: - UI Components
    private var headerView: some View {
        HStack {
            Text("Today")
                .font(.system(size: 18, weight: .semibold))
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
                    .contentShape(Circle())
                    .hoverEffect(.highlight)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private var addTaskView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("CANCEL")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .onTapGesture {
                        isAddingNote = false
                    }
                    .keyboardShortcut(.escape)
                
                Spacer()
                
                Text("Title")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("Est time")
                    .font(.system(size: 12, weight: .medium))
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
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#2C2C2E"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
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
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#2C2C2E"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
            }
            .padding(.horizontal, 16)
            
            HStack {
                Text("Add a new task")
                    .font(.system(size: 12, weight: .medium))
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1C1C1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
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
                
                Spacer()
                
                Text("⌘ + T")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(hex: "#4CAF50").opacity(0.8))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "#2C2C2E"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(hex: "#4CAF50").opacity(0.2), lineWidth: 0.5)
                            )
                    )
            }
            .padding(.vertical, 12)
            .keyboardShortcut("t", modifiers: [.command])
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#2C2C2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private var taskListView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(noteStore.getPendingNotes()) { note in
                    TaskRowView(
                        note: note,
                        firstNote: firstNote,
                        noteStore: noteStore,
                        onDone: { elapsedTime in
                            firstNote = findFirstNote()
                            completedTaskTime = elapsedTime
                            isCompleted = true
                        },
                        onSkip: { skippedNote in
                            // Set the recently skipped note ID
                            recentlySkippedNoteId = skippedNote.id
                            
                            // Show a notification using UNUserNotificationCenter
                            let content = UNMutableNotificationContent()
                            content.title = "Task Moved"
                            content.body = "'\(skippedNote.title)' moved to the end of the list"
                            content.sound = UNNotificationSound.default
                            
                            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                            UNUserNotificationCenter.current().add(request) { error in
                                if let error = error {
                                    print("Error showing notification: \(error.localizedDescription)")
                                }
                            }
                            
                            // Clear the highlight after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    recentlySkippedNoteId = nil
                                }
                            }
                        }
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(note.id == recentlySkippedNoteId ? 
                                  Color(hex: "#9333EA").opacity(0.2) :
                                  Color(hex: "#2C2C2E"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(note.id == recentlySkippedNoteId ?
                                            Color(hex: "#9333EA").opacity(0.5) :
                                            Color.white.opacity(0.08), 
                                            lineWidth: 0.5)
                            )
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: recentlySkippedNoteId == note.id)
                    .overlay(
                        Group {
                            if note.id == recentlySkippedNoteId {
                                HStack {
                                    Spacer()
                                    Text("Moved to end")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color(hex: "#9333EA"))
                                        )
                                }
                                .padding(.trailing, 16)
                                .padding(.bottom, 4)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        , alignment: .bottomTrailing
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(hex: "#1C1C1E"))
        .onDisappear {
            dismissTimer?.invalidate()
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
                
            Text("Add a new task to get started")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.4))
                .padding(.top, 4)
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
                        .foregroundColor(.white)
                    
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
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#2C2C2E"), Color(hex: "#262628")]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.bottom, 14)
        .padding(.top, 8)
    }
    
    private var backgroundWithResizeHandle: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#1E1E20"),
                    Color(hex: "#1A1A1C")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
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
    
    private func formatTimeShort(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)min"
        } else {
            return "\(Int(time))s"
        }
    }

     private var completedTaskView: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#1C1C1E"),
                        Color(hex: "#2C2C2E")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                
                VStack(spacing: 6) {
                    Text(getCongratulationMessage(for: completedTaskTime))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    GifImageView(gifURL: getRandomCelebrationGif(category: getCelebrationCategory(for: completedTaskTime)))
                        .frame(width: 250, height: 250)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                    
                    Text(getCompletionMessage(for: firstNote?.title ?? ""))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            // Start tick sound for the next task
                            if let nextNote = noteStore.getPendingNotes().first {
                                TickSoundService.shared.startTicking(interval: 3.0)
                            }
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isCompleted = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14))
                                Text("Next Task")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#4CAF50"), Color(hex: "#45A049")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                            )
                            .cornerRadius(20)
                        }
                        .buttonStyle(AnimatedButtonStyle())
                        .shadow(color: Color(hex: "#4CAF50").opacity(0.3), radius: 5, x: 0, y: 3)
                        
                        Button(action: {
                            withAnimation {
                                isCompleted = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "gamecontroller.fill")
                                Text("Take a Break")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    HStack {
                        Text("Est: \(firstNote?.estimatedTime ?? "None")")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("Taken: \(formatTimeShort(completedTaskTime))")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#4CAF50"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isCompleted)
    }
    
    private func createNewNote() {
        if !newNoteTitle.isEmpty {
            noteStore.addNote(
                id: UUID(),
                title: newNoteTitle,
                content: "",
                category: .today
            )
            isAddingNote = false
            newNoteTitle = ""
            estimatedTime = "00:00"
            focusOnNewNote()
            firstNote = findFirstNote()


             if let newNoteId = noteStore.notes.last?.id,
                let updatedColumn = noteStore.columns.first(where: { $0.title == "Today" }) {
                var mutableColumn = updatedColumn
                mutableColumn.noteIds.append(newNoteId)
                noteStore.updateColumn(mutableColumn)
            }
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
    var firstNote: Note?
    @ObservedObject var noteStore: NoteStore
    let onDone: (TimeInterval) -> Void
    let onSkip: (Note) -> Void

    @State private var isNotes = false
    @State private var isSkipping = false
    
    @State private var isBreak = false
    @State private var breakTime: TimeInterval = 0
    @State private var isHovered = false
    @State private var editableTitle: String = ""
    @State private var timer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    @State private var hoveredButton: String? = nil
    @State private var tickCounter: Int = 0
    
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
                      // Start the tick sound service if this is the first note
                } else {
                    breakTime += 1
                }
            }
            
                // TickSoundService.shared.startTicking(interval: 300.0)
          
        }
        .onDisappear {
            timer?.invalidate()
            // Stop the tick sound if this is the first note
            if firstNote?.id == note.id {
                TickSoundService.shared.stopTicking()
            }
        }
        .offset(x: isSkipping ? -NSScreen.main!.frame.width : 0)
        .opacity(isSkipping ? 0 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSkipping)
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            if !isBreak {
                // Done button
                TaskActionButton(
                    icon: "checkmark.circle.fill",
                    label: "Done",
                    isHovered: hoveredButton == "done",
                    color: Color(hex: "#4CAF50"),
                    action: {
                        var updatedNote = note
                        updatedNote.isCompleted = true
                        updatedNote.actualTime = elapsedTime
                        noteStore.updateNote(updatedNote)
                        
                        // Stop the tick sound when marking a task as done
                        if firstNote?.id == note.id {
                            TickSoundService.shared.stopTicking()
                        }
                        
                        onDone(elapsedTime)
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
                    color: Color(hex: "#3B82F6"),
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
                    color: Color(hex: "#F59E0B"),
                    action: {
                        isBreak = true
                        breakTime = elapsedTime
                        
                        // Stop the tick sound during break
                        if firstNote?.id == note.id {
                            TickSoundService.shared.stopTicking()
                        }
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
                    color: Color(hex: "#9333EA"),
                    action: {
                        print("Task skipped: \(note.title)")
                        
                        // Move the task to the end of the list
                        if let firstNote = firstNote, note.id == firstNote.id {
                            // Trigger skip animation
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isSkipping = true
                            }
 
                            // Delay the actual reordering to allow animation to complete
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                noteStore.moveNoteToEnd(note)
                                // Stop ticking for current task and start for the new first task
                                TickSoundService.shared.stopTicking()
                                if let newFirstNote = noteStore.getPendingNotes().first {
                                    TickSoundService.shared.startTicking(interval: 3.0)
                                }
                                
                                // Reset the animation state
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isSkipping = false
                                }
                            }
                            
                            // Call onSkip with the skipped note
                            onSkip(note)
                        }
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
                    color: Color(hex: "#EF4444"),
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#2C2C2E"), Color(hex: "#262628")]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
        )
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
                label: "Resume",
                isHovered: hoveredButton == "skip",
                color: Color(hex: "#4CAF50"),
                action: {
                    isBreak = false
                    breakTime = 0
                    
                    // Resume the tick sound when returning from break
                    if firstNote?.id == note.id {
                        TickSoundService.shared.startTicking(interval: 3.0)
                    }
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
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#1C1C1E"), Color(hex: "#2C2C2E")]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
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
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            firstNote?.id == note.id ? Color(hex: "#2A332C") : Color(hex: "#2C2C2E"),
                            firstNote?.id == note.id ? Color(hex: "#263026") : Color(hex: "#262628")
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            firstNote?.id == note.id ? 
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#4CAF50").opacity(0.3), Color(hex: "#45A049").opacity(0.2)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ) : 
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                            lineWidth: 0.5
                        )
                )
        )
    }
    
    private var timerView: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#4CAF50").opacity(0.8))
            
            Text(formatTime(elapsedTime))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#4CAF50").opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#4CAF50").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#4CAF50").opacity(0.2), lineWidth: 0.5)
                )
        )
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
                    .fill(
                        isHovered ? 
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#3C3C3E"), Color(hex: "#343436")]),
                                startPoint: .top,
                                endPoint: .bottom
                            ) : 
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .overlay(
                        isHovered ?
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(color.opacity(0.3), lineWidth: 0.5) :
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.clear, lineWidth: 0)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .cornerRadius(8)
        .onHover { hovering in
            onHover(hovering)
        }
    }
}

// MARK: - GIF Image View
struct GifImageView: View {
    let gifURL: URL?
    @State private var isLoading = true
    @State private var loadError = false
    @State private var gifImage: NSImage? = nil
    
    var body: some View {
        ZStack {
            if isLoading {
                loadingView
            } else if loadError || gifImage == nil {
                fallbackView
            } else {
                GifNSImageView(image: gifImage)
                    .transition(.opacity)
            }
        }
        .onAppear(perform: loadGif)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading celebration...")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#1C1C1E"))
    }
    
    private var fallbackView: some View {
        VStack {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
                .padding()
            Text("Congratulations!")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#1C1C1E"))
    }
    
    private func loadGif() {
        guard let url = gifURL else {
            isLoading = false
            loadError = true
            return
        }
        
        // Check if the GIF is already in cache
        if let cachedImage = GifCache.shared.getImage(for: url) {
            self.gifImage = cachedImage
            withAnimation {
                self.isLoading = false
            }
            return
        }
        
        // If not in cache, download it
        DispatchQueue.global().async {
            if let image = NSImage(contentsOf: url) {
                // Store in cache
                GifCache.shared.storeImage(image, for: url)
                
                DispatchQueue.main.async {
                    self.gifImage = image
                    withAnimation {
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    withAnimation {
                        self.isLoading = false
                        self.loadError = true
                    }
                }
            }
        }
    }
}

struct GifNSImageView: NSViewRepresentable {
    let image: NSImage?
    
    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = true
        imageView.image = image
        return imageView
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = image
    }
}

extension FloatingSidebarView {
    enum CelebrationCategory {
        case success
        case achievement
        case random
    }
    
    func getRandomCelebrationGif(category: CelebrationCategory = .random) -> URL? {
        // Collection of celebration GIFs organized by category
        let successGifs = [
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExazBxeGRkbzM5czV5bXQ4eW81Z2ZhZzZjaWIweHAyOHJ0aHNjZmZ0bCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/cEODGfeOYMRxK/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNzN2OWI2cG9hZDhiZmVkMGp4dHF3ZnI4N2hpYWRpOGJqeWZlZiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/artj92V8o75VPL7AeQ/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExOTJqMjV0ZWNhcGUzZnNhZGdtazZnMzRkMHN4ZzJlZTVjZGxzeSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0MYt5jPR6QX5pnqM/giphy.gif"
        ]
        
        let achievementGifs = [
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMHBtdDNwZmZqeGlxYnZicGdkOHd3NnRvbzBuNnpzMWs3YXRqOXhpZCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7abIileRivlGr8Nq/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExOTdvNHFsOHRkZGc2ZHU5cG1zcXV6ZGZ4MjFxcjZtdGNmcGpzNGw2ZCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/g9582DNuQppxC/giphy.gif",
            "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExYmx6OTEyZXZ3YXNwOGZkYTRnNGdxbWxjMnI0Z2JjOXdtcTdkZiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/LSNqpYqGRqwrS/giphy.gif"
        ]
        
        // Select the appropriate category of GIFs
        var gifsToChooseFrom: [String]
        
        switch category {
        case .success:
            gifsToChooseFrom = successGifs
        case .achievement:
            gifsToChooseFrom = achievementGifs
        case .random:
            // Combine all categories for random selection
            gifsToChooseFrom = successGifs + achievementGifs
        }
        
        // Select a random GIF from the chosen category
        let randomIndex = Int.random(in: 0..<gifsToChooseFrom.count)
        return URL(string: gifsToChooseFrom[randomIndex])
    }
    
    // Cache for storing already downloaded GIFs
    private static var gifCache: [URL: NSImage] = [:]
    
    // Determine celebration category based on task completion time
    func getCelebrationCategory(for completionTime: TimeInterval) -> CelebrationCategory {
        // If there's an estimated time, check if completed faster than estimated
        if let estimatedTimeStr = firstNote?.estimatedTime, !estimatedTimeStr.isEmpty {
            // Parse estimated time (format: "HH:MM" or "MM:SS")
            let components = estimatedTimeStr.components(separatedBy: ":")
            if components.count == 2, 
               let minutes = Int(components[0]), 
               let seconds = Int(components[1]) {
                
                let estimatedSeconds = minutes * 60 + seconds
                
                // If completed in significantly less time than estimated
                if completionTime < Double(estimatedSeconds) * 0.75 {
                    return .achievement
                }
            }
        }
        
        // For tasks that took less than 5 minutes
        if completionTime < 300 {
            return .success
        }
        // For longer tasks (achievement for completing something substantial)
        else if completionTime > 1800 { // 30 minutes
            return .achievement
        }
        
        // Default to random for other cases
        return .random
    }
    
    // Generate a dynamic congratulatory message based on task completion
    func getCongratulationMessage(for completionTime: TimeInterval) -> String {
        let category = getCelebrationCategory(for: completionTime)
        
        let successMessages = [
            "Well done! 💥",
            "Great job! 🎉",
            "Task complete! ✅",
            "Success! 🚀",
            "You did it! 👏"
        ]
        
        let achievementMessages = [
            "Outstanding! 🏆",
            "Impressive work! 💪",
            "Amazing effort! 🌟",
            "Brilliant! 🔥",
            "Exceptional! 🎯"
        ]
        
        let randomIndex: Int
        
        switch category {
        case .success:
            randomIndex = Int.random(in: 0..<successMessages.count)
            return successMessages[randomIndex]
        case .achievement:
            randomIndex = Int.random(in: 0..<achievementMessages.count)
            return achievementMessages[randomIndex]
        case .random:
            // Combine all messages for random selection
            let allMessages = successMessages + achievementMessages
            randomIndex = Int.random(in: 0..<allMessages.count)
            return allMessages[randomIndex]
        }
    }
    
    // Generate a dynamic completion message based on task title
    func getCompletionMessage(for taskTitle: String) -> String {
        if taskTitle.isEmpty {
            return "You finished the task!"
        }
        
        // Check if the task title is short enough to include
        if taskTitle.count < 30 {
            let messages = [
                "'\(taskTitle)' completed!",
                "You finished '\(taskTitle)'!",
                "Task '\(taskTitle)' is done!"
            ]
            return messages.randomElement() ?? "You finished the task!"
        } else {
            // For longer titles, use generic messages
            let messages = [
                "Task completed successfully!",
                "You finished the task!",
                "One more task down!",
                "Mission accomplished!"
            ]
            return messages.randomElement() ?? "You finished the task!"
        }
    }
}

// MARK: - GIF Cache
class GifCache {
    static let shared = GifCache()
    private var cache: [URL: NSImage] = [:]
    private let queue = DispatchQueue(label: "com.kerlig.gifcache", attributes: .concurrent)
    
    private init() {}
    
    func storeImage(_ image: NSImage, for url: URL) {
        queue.async(flags: .barrier) {
            self.cache[url] = image
        }
    }
    
    func getImage(for url: URL) -> NSImage? {
        var result: NSImage?
        queue.sync {
            result = cache[url]
        }
        return result
    }
    
    func clearCache() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
}

