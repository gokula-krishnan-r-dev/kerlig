import SwiftUI
import AVFoundation

struct FocusCardView: View {
    let controller: FocusCardController
    @ObservedObject var noteStore: NoteStore
    
    @State private var isHovered = false
    @State private var showNotification = false
    @State private var notificationMessage = ""
    @State private var animateBackground = false
    @State private var hoveredButton: String? = nil
    @State private var showMaximizeButton = false
    @State private var isMaximizeButtonHovered = false
    @State private var lastNotificationTime: TimeInterval = 0
    @State private var showSessionStats = false
    @State private var pulseAnimation = false
    
    // Create an instance of the sidebar controller
    private let sidebarController = FloatingSidebarController()

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                if isHovered && noteStore.activeTimerNote != nil {
                    // Enhanced action buttons when hovered
                    actionButtonsView
                } else {
                    // Main timer display
                    mainTimerView
                }
                
                // Session statistics (optional)
                if showSessionStats {
                    sessionStatsView
                        .transition(.slide)
                }
            }
            .frame(width: showSessionStats ? 350 : 300, height: showSessionStats ? 120 : 58)
            .background(backgroundView)
            .overlay(borderOverlay)
            
            // Maximize button overlay
            if showMaximizeButton {
                maximizeButtonOverlay
            }
            
            // Notification overlay
            if showNotification {
                notificationOverlay
            }
        }
        .onAppear {
            setupInitialState()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
                showMaximizeButton = hovering
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateTimerDisplay()
        }
    }

    // MARK: - Main Timer View
    private var mainTimerView: some View {
        HStack(spacing: 12) {
            // Task status indicator
            statusIndicator
            
            // Task title and timer info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(noteStore.activeTimerNote?.title ?? "No active task")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    // Timer display
                    timerDisplay
                }
                
                // Additional info row
                if let activeNote = noteStore.activeTimerNote {
                    HStack(spacing: 8) {
                        // Session count
                        Text("\(activeNote.sessions.count) sessions")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        
                        // Break indicator
                        if noteStore.globalTimerState == .break {
                            Text("• Break time")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        // Quick stats toggle
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSessionStats.toggle()
                            }
                        }) {
                            Image(systemName: showSessionStats ? "chevron.up" : "chart.bar")
                                .font(.system(size: 10))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // MARK: - Status Indicator
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
            .shadow(color: statusColor.opacity(0.5), radius: 2, x: 0, y: 0)
            .onAppear {
                if noteStore.globalTimerState == .running {
                    pulseAnimation = true
                }
            }
            .onChange(of: noteStore.globalTimerState) { newState in
                pulseAnimation = newState == .running
            }
    }
    
    private var statusColor: Color {
        switch noteStore.globalTimerState {
        case .running: return .green
        case .paused: return .yellow
        case .break: return .orange
        case .stopped: return .gray.opacity(0.5)
        }
    }
    
    // MARK: - Timer Display
    private var timerDisplay: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(noteStore.formatTime(noteStore.getTotalElapsedTimeForActiveTask()))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
            
            if noteStore.globalTimerState == .break {
                Text("Break: \(noteStore.formatTime(noteStore.getCurrentSessionDuration()))")
                    .font(.system(size: 9))
                    .foregroundColor(.orange.opacity(0.8))
                    .monospacedDigit()
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            if noteStore.globalTimerState == .break {
                breakModeButtons
            } else {
                regularModeButtons
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .center)))
    }
    
    private var regularModeButtons: some View {
        HStack(spacing: 8) {
            // Play/Pause button
            TimerActionButton(
                icon: noteStore.globalTimerState == .running ? "pause.circle.fill" : "play.circle.fill",
                label: noteStore.globalTimerState == .running ? "Pause" : noteStore.globalTimerState == .paused ? "Resume" : "Start",
                isHovered: hoveredButton == "playPause",
                color: .blue,
                action: toggleTimer,
                onHover: { isHovering in
                    hoveredButton = isHovering ? "playPause" : nil
                }
            )
            
            // Done button
            TimerActionButton(
                icon: "checkmark.circle.fill",
                label: "Done",
                isHovered: hoveredButton == "done",
                color: .green,
                action: completeTask,
                onHover: { isHovering in
                    hoveredButton = isHovering ? "done" : nil
                }
            )
            
            // Break button
            TimerActionButton(
                icon: "cup.and.saucer.fill",
                label: "Break",
                isHovered: hoveredButton == "break",
                color: .orange,
                action: startBreak,
                onHover: { isHovering in
                    hoveredButton = isHovering ? "break" : nil
                }
            )
            
            // Skip button
            TimerActionButton(
                icon: "forward.circle.fill",
                label: "Skip",
                isHovered: hoveredButton == "skip",
                color: .purple,
                action: skipTask,
                onHover: { isHovering in
                    hoveredButton = isHovering ? "skip" : nil
                }
            )
            
            // Stop button
            TimerActionButton(
                icon: "stop.circle.fill",
                label: "Stop",
                isHovered: hoveredButton == "stop",
                color: .red,
                action: stopTimer,
                onHover: { isHovering in
                    hoveredButton = isHovering ? "stop" : nil
                }
            )
        }
    }
    
    private var breakModeButtons: some View {
        HStack(spacing: 8) {
            // End break button
            TimerActionButton(
                icon: "play.circle.fill",
                label: "End Break",
                isHovered: hoveredButton == "endBreak",
                color: .green,
                action: endBreak,
                onHover: { isHovering in
                    hoveredButton = isHovering ? "endBreak" : nil
                }
            )
            
            // Extend break button
            TimerActionButton(
                icon: "plus.circle.fill",
                label: "+5 min",
                isHovered: hoveredButton == "extendBreak",
                color: .orange,
                action: {
                    // Implementation for extending break
                    showNotification(message: "Break extended by 5 minutes")
                },
                onHover: { isHovering in
                    hoveredButton = isHovering ? "extendBreak" : nil
                }
            )
        }
    }
    
    // MARK: - Session Stats View
    private var sessionStatsView: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                // Total work time
                StatItem(
                    icon: "clock.fill",
                    label: "Work",
                    value: noteStore.formatTime(noteStore.activeTimerNote?.totalWorkTime ?? 0),
                    color: .green
                )
                
                Spacer()
                
                // Total break time
                StatItem(
                    icon: "cup.and.saucer.fill",
                    label: "Break",
                    value: noteStore.formatTime(noteStore.activeTimerNote?.totalBreakTime ?? 0),
                    color: .orange
                )
                
                Spacer()
                
                // Session count
                StatItem(
                    icon: "number.circle.fill",
                    label: "Sessions",
                    value: "\(noteStore.activeTimerNote?.sessions.count ?? 0)",
                    color: .blue
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Background and Overlays
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: animateBackground ? "#232325" : "#1C1C1E"))
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.5), value: animateBackground)
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(borderColor, lineWidth: 1)
            .animation(.easeInOut(duration: 0.3), value: noteStore.globalTimerState)
    }
    
    private var borderColor: Color {
        switch noteStore.globalTimerState {
        case .running: return .green.opacity(0.3)
        case .paused: return .yellow.opacity(0.3)
        case .break: return .orange.opacity(0.3)
        case .stopped: return .gray.opacity(0.2)
        }
    }
    
    private var maximizeButtonOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        sidebarController.toggleSidebar()
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
        .frame(width: showSessionStats ? 350 : 300, height: showSessionStats ? 120 : 58)
    }
    
    private var notificationOverlay: some View {
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
    
    // MARK: - Helper Methods
    private func setupInitialState() {
        // Auto-start timer for first pending note if no active timer
        if noteStore.activeTimerNote == nil, let firstNote = noteStore.getFirstPendingNote() {
            noteStore.startTimer(for: firstNote)
        }
    }
    
    private func updateTimerDisplay() {
        // Check for milestone notifications (every 10 minutes)
        let totalTime = noteStore.getTotalElapsedTimeForActiveTask()
        if Int(totalTime) % 600 == 0 && totalTime > 0 && Int(totalTime) != Int(lastNotificationTime) {
            showTimeNotification()
            lastNotificationTime = totalTime
        }
        
        // Animate background every minute during work
        if noteStore.globalTimerState == .running && Int(totalTime) % 60 == 0 && totalTime > 0 {
            pulseBackground()
        }
    }
    
    private func toggleTimer() {
        switch noteStore.globalTimerState {
        case .stopped:
            if let firstNote = noteStore.getFirstPendingNote() {
                noteStore.startTimer(for: firstNote)
            }
        case .running:
            noteStore.pauseCurrentTimer()
        case .paused:
            noteStore.resumeCurrentTimer()
        case .break:
            endBreak()
        }
    }
    
    private func completeTask() {
        noteStore.completeCurrentTask()
        showNotification(message: "Task completed! 🎉")
        SoundManager.shared.playSound("complete")
    }
    
    private func startBreak() {
        noteStore.startBreakForCurrentTimer()
        showNotification(message: "Break time! Take a rest 😌")
        SoundManager.shared.playSound("break")
    }
    
    private func endBreak() {
        noteStore.endBreakForCurrentTimer()
        showNotification(message: "Break ended! Back to work 💪")
    }
    
    private func skipTask() {
        if let activeNote = noteStore.activeTimerNote {
            let nextTask = noteStore.getPendingNotes().dropFirst().first
            noteStore.stopCurrentTimer()
            
            // Move current task to end
            noteStore.moveNoteToEnd(activeNote)
            
            // Start next task if available
            if let nextTask = nextTask {
                noteStore.startTimer(for: nextTask)
            }
            
            showNotification(message: "Task skipped")
            SoundManager.shared.playSound("skip")
        }
    }
    
    private func stopTimer() {
        noteStore.stopCurrentTimer()
        showNotification(message: "Timer stopped")
    }
    
    private func showTimeNotification() {
        let minutes = Int(noteStore.getTotalElapsedTimeForActiveTask()) / 60
        notificationMessage = "\(minutes) minutes completed for \(noteStore.activeTimerNote?.title ?? "task")"
        
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
    
    private func showNotification(message: String) {
        notificationMessage = message
        withAnimation(.easeInOut(duration: 0.3)) {
            showNotification = true
        }
        
        // Hide notification after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showNotification = false
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
}

// MARK: - Timer Action Button
struct TimerActionButton: View {
    let icon: String
    let label: String
    let isHovered: Bool
    let color: Color
    let action: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(isHovered ? .white : color)
                
                if isHovered {
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .transition(.opacity)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
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
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(color.opacity(0.4), lineWidth: 0.5) :
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.clear, lineWidth: 0)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            onHover(hovering)
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .monospacedDigit()
        }
    }
}



