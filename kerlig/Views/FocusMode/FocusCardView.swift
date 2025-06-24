import SwiftUI
import AVFoundation

struct FocusCardView: View {
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var isHovered = false
    @State private var showNotification = false
    @State private var notificationMessage = ""
    @State private var lastNotificationTime: TimeInterval = 0
    @State private var animateBackground = false
    let controller: FocusCardController
    @ObservedObject var noteStore: NoteStore
    @State private var note: Note?
    @State private var hoveredButton: String? = nil
    @State private var isNotes = false
    @State private var isBreak = false
    @State private var breakTime: TimeInterval = 0
    @State private var elapsedTime: TimeInterval = 0
    @State private var showMaximizeButton = false
    @State private var isMaximizeButtonHovered = false
    
    // Create an instance of the sidebar controller
    private let sidebarController = FloatingSidebarController()

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                if isHovered {
                    HStack(spacing: 12) {
                        // Done button
                        TaskActionButton(
                            icon: "checkmark.circle.fill",
                            label: "Done",
                            isHovered: hoveredButton == "done",
                            color: .green,
                            action: {
                                if var updatedNote = note {
                                    updatedNote.isCompleted = true
                                    updatedNote.actualTime = timeRemaining
                                    noteStore.updateNote(updatedNote)
                                    SoundManager.shared.playSound("complete")
                                }

                                //refresh the note
                                noteStore.loadNotes()
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
                                SoundManager.shared.playSound("break")
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
                                note = noteStore.getPendingNotes().dropFirst().first
                                timeRemaining = note?.actualTime ?? 0
                                SoundManager.shared.playSound("skip")
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
                                if let noteId = note?.id {
                                    noteStore.deleteNote(id: noteId)
                                    note = noteStore.getFirstPendingNote()
                                    timeRemaining = note?.actualTime ?? 0
                                }
                            },
                            onHover: { isHovering in
                                hoveredButton = isHovering ? "delete" : nil
                            }
                        )
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center)))
                } else {
                    // Main timer row
                    HStack(spacing: 12) {
                        // Task indicator and time
                        HStack(spacing: 8) {
                            Circle()
                                .fill(isRunning ? Color.green : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: isRunning)
                                .shadow(color: isRunning ? Color.green.opacity(0.5) : Color.clear, radius: 2, x: 0, y: 0)

                            //show a note title
                            Text(note?.title ?? "")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Spacer()
                        
                            Text(timeString(from: timeRemaining))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                                .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                                    note = noteStore.getFirstPendingNote()
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center)))
                }
            }
            .frame(width: 300, height: 58)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: animateBackground ? "#232325" : "#1C1C1E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    .animation(.easeInOut(duration: 0.5), value: animateBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isRunning ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                    .animation(.easeInOut(duration: 0.3), value: isRunning)
            )
            
            // Maximize button overlay
            if showMaximizeButton {
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                // Toggle sidebar
                                sidebarController.toggleSidebar()
                                // Hide focus card
                                controller.hideFocusCard()
                            }
                        }) {
                            Image(systemName: "rectangle.expand.vertical")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isMaximizeButtonHovered ? .white : .gray.opacity(0.8))
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(isMaximizeButtonHovered ? Color(hex: "#3C3C3E") : Color.clear)
                                        .animation(.easeInOut(duration: 0.2), value: isMaximizeButtonHovered)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isMaximizeButtonHovered = hovering
                            }
                        }
                        .offset(x: -8, y: 0)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                    Spacer()
                }
                .frame(width: 300, height: 58)
            }
            
            // Notification overlay
            if showNotification {
                VStack {
                    Text(notificationMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.7))
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .onAppear {
            note = noteStore.notes.filter { !$0.isCompleted }.first
            timeRemaining = note?.actualTime ?? 0
            isRunning = true
            startTimer()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
                showMaximizeButton = hovering
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeRemaining += 1
            elapsedTime += 1
            
            // Check for 10-minute intervals
            if Int(timeRemaining) % 600 == 0 && timeRemaining > 0 && Int(timeRemaining) != Int(lastNotificationTime) {
                showTimeNotification()
                lastNotificationTime = timeRemaining
            }
            
            // Update note's actual time
            if var updatedNote = note {
                updatedNote.actualTime = timeRemaining
                noteStore.updateNote(updatedNote)
            }
            
            // Animate background every minute
            if Int(timeRemaining) % 60 == 0 && timeRemaining > 0 {
                pulseBackground()
            }
        }
    }
    
    private func pulseBackground() {
        withAnimation {
            animateBackground = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                animateBackground = false
            }
        }
    }
    
    private func showTimeNotification() {
        let minutes = Int(timeRemaining) / 60
        notificationMessage = "\(minutes) minutes completed for \(note?.title ?? "task")"
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showNotification = true
        }
        
        SoundManager.shared.playSound("notification")
        
        // Hide notification after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showNotification = false
            }
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}



// Helper view for action buttons
struct ActionButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(isHovered ? .white : .gray)
                .padding(6)
                .background(
                    Circle()
                        .fill(isHovered ? Color(hex: "#3C3C3E") : Color.clear)
                )
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Circle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}



