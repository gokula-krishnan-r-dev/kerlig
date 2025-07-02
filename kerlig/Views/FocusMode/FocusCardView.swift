import SwiftUI
import AVFoundation

/*
 * FOCUS CARD VIEW - Professional Task Timer Management
 * 
 * 🎯 Features:
 * - Dynamic project/release selection with persistent storage
 * - Professional UserDefaults management with fallback logic
 * - Automatic task selection based on current project context
 * - Real-time state updates when data changes
 * - Comprehensive logging for debugging
 * 
 * 🔄 Auto-refresh triggers:
 * - When projects are added/removed/archived
 * - When releases are created/deleted
 * - When focus card is initialized
 * 
 * 📱 Integration:
 * - Syncs with FloatingSidebarView selection
 * - Maintains consistent state across app components
 * - Provides external refresh methods for manual updates
 * 
 * ⏱️ Synchronized Timer System:
 * - Uses centralized noteStore timer system for perfect sync
 * - Timer values match exactly with FloatingSidebarView
 * - Real-time updates when timer state changes from other views
 * - Professional logging for debugging timer operations
 */

// MARK: - UserDefaults Manager for Project/Release Preferences (Shared)
private struct ProjectReleasePreferences {
    static let selectedProjectIdKey = "SelectedProjectId"
    static let selectedReleaseIdKey = "SelectedReleaseId"
    static let lastUsedProjectKey = "LastUsedProject"
    
    static func loadSelectedProject(from projects: [Project], releases: [Release]) -> (project: Project?, release: Release?) {
        let userDefaults = UserDefaults.standard
        
        print("🔍 [FocusCard] Loading project selection...")
        
        // Try to load previously selected project
        if let projectIdString = userDefaults.string(forKey: selectedProjectIdKey),
           let projectId = UUID(uuidString: projectIdString) {
            
            // Find the project in current available projects
            if let savedProject = projects.first(where: { $0.id == projectId && !$0.isArchived }) {
                
                // Try to load previously selected release for this project
                if let releaseIdString = userDefaults.string(forKey: selectedReleaseIdKey),
                   let releaseId = UUID(uuidString: releaseIdString) {
                    
                    // Find the release in current available releases for this project
                    let projectReleases = releases.filter { $0.projectId == savedProject.id }
                    if let savedRelease = projectReleases.first(where: { $0.id == releaseId }) {
                        print("🎯 [FocusCard] Restored saved selection: \(savedProject.title) -> v\(savedRelease.version)")
                        return (savedProject, savedRelease)
                    }
                }
                
                // If project exists but release doesn't, select first available release
                let projectReleases = releases.filter { $0.projectId == savedProject.id }
                let firstRelease = projectReleases.first
                print("🔄 [FocusCard] Project found, selecting first release: \(savedProject.title) -> \(firstRelease?.version ?? "None")")
                return (savedProject, firstRelease)
            }
        }
        
        // Fallback: Try to use last used project if current selection is invalid
        if let lastProjectIdString = userDefaults.string(forKey: lastUsedProjectKey),
           let lastProjectId = UUID(uuidString: lastProjectIdString),
           let lastUsedProject = projects.first(where: { $0.id == lastProjectId && !$0.isArchived }) {
            
            let projectReleases = releases.filter { $0.projectId == lastUsedProject.id }
            let firstRelease = projectReleases.first
            print("🔄 [FocusCard] Using last used project: \(lastUsedProject.title)")
            return (lastUsedProject, firstRelease)
        }
        
        // Final fallback: Select first available project
        if let firstProject = projects.first(where: { !$0.isArchived }) {
            let projectReleases = releases.filter { $0.projectId == firstProject.id }
            let firstRelease = projectReleases.first
            print("🆕 [FocusCard] Auto-selecting first available project: \(firstProject.title)")
            return (firstProject, firstRelease)
        }
        
        print("⚠️ [FocusCard] No projects available for selection")
        return (nil, nil)
    }
}

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
        .onChange(of: noteStore.projects.count) { _ in
            // Refresh focus card state when projects change
            refreshFocusCardState()
        }
        .onChange(of: noteStore.releases.count) { _ in
            // Refresh focus card state when releases change
            refreshFocusCardState()
        }
        .onChange(of: noteStore.globalTimerState) { newState in
            // Update UI when timer state changes from other views
            print("🔄 [FocusCard] Timer state changed to: \(newState)")
        }
        .onChange(of: noteStore.activeTimerNote?.id) { _ in
            // Update UI when active timer note changes
            if let activeNote = noteStore.activeTimerNote {
                print("🎯 [FocusCard] Active timer note changed to: \(activeNote.title)")
            } else {
                print("⏹️ [FocusCard] No active timer note")
            }
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
    
    /// Professional initialization of the focus card with proper project/release selection
    private func setupInitialState() {
        print("🚀 [FocusCard] Setting up initial state...")
        
        // Load the current project and release selection using the professional system
        let (selectedProject, selectedRelease) = ProjectReleasePreferences.loadSelectedProject(
            from: noteStore.projects,
            releases: noteStore.releases
        )
        
        // Get the first pending note for the selected project and release
        let firstNote = noteStore.getFirstPendingNote(
            selectedProject: selectedProject,
            selectedRelease: selectedRelease
        )
        
        // Start timer for the first available task if no timer is currently active
        if noteStore.activeTimerNote == nil {
            if let firstNote = firstNote {
                print("▶️ [FocusCard] Starting timer for: \(firstNote.title)")
                noteStore.startTimer(for: firstNote)
            } else {
                print("⚠️ [FocusCard] No pending tasks found for current selection")
                print("   Project: \(selectedProject?.title ?? "None")")
                print("   Release: \(selectedRelease?.version ?? "None")")
            }
        } else {
            print("ℹ️ [FocusCard] Timer already active for: \(noteStore.activeTimerNote?.title ?? "Unknown")")
        }
        
        print("✅ [FocusCard] Initial state setup completed")
    }
    
    /// Get current project/release selection summary for debugging
    private func getCurrentSelectionSummary() -> String {
        let (selectedProject, selectedRelease) = ProjectReleasePreferences.loadSelectedProject(
            from: noteStore.projects,
            releases: noteStore.releases
        )
        
        let projectTitle = selectedProject?.title ?? "All Projects"
        let releaseVersion = selectedRelease?.version ?? "No Release"
        return "\(projectTitle) -> v\(releaseVersion)"
    }
    
    /// Refresh the focus card state when projects/releases change
    private func refreshFocusCardState() {
        print("🔄 [FocusCard] Refreshing focus card state")
        
        // If no timer is active, try to start one with the current selection
        if noteStore.activeTimerNote == nil {
            let (selectedProject, selectedRelease) = ProjectReleasePreferences.loadSelectedProject(
                from: noteStore.projects,
                releases: noteStore.releases
            )
            
            if let firstNote = noteStore.getFirstPendingNote(selectedProject: selectedProject, selectedRelease: selectedRelease) {
                print("▶️ [FocusCard] Starting timer for new first task: \(firstNote.title)")
                noteStore.startTimer(for: firstNote)
            }
        }
        
                 print("📊 [FocusCard] Current selection: \(getCurrentSelectionSummary())")
     }
     
     /// Public method to refresh focus card state - can be called from external sources
     func refreshProjectSelectionState() {
         print("🔄 [FocusCard] External refresh requested for project selection")
         refreshFocusCardState()
         print("📊 [FocusCard] Current selection: \(getCurrentSelectionSummary())")
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
            // Start timer for first available task using current project/release selection
            let (selectedProject, selectedRelease) = ProjectReleasePreferences.loadSelectedProject(
                from: noteStore.projects,
                releases: noteStore.releases
            )
            
            if let firstNote = noteStore.getFirstPendingNote(selectedProject: selectedProject, selectedRelease: selectedRelease) {
                print("▶️ [FocusCard] Starting timer from stopped state: \(firstNote.title)")
                noteStore.startTimer(for: firstNote)
                showNotification(message: "Timer started: \(firstNote.title)")
            } else {
                print("⚠️ [FocusCard] No tasks available to start timer")
                showNotification(message: "No tasks available")
            }
        case .running:
            noteStore.pauseCurrentTimer()
            showNotification(message: "Timer paused")
        case .paused:
            noteStore.resumeCurrentTimer()
            showNotification(message: "Timer resumed")
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
            print("⏭️ [FocusCard] Skipping task: \(activeNote.title)")
            
            // Stop current timer
            noteStore.stopCurrentTimer()
            
            // Move current task to end of the list
            noteStore.moveNoteToEnd(activeNote)
            
            // Get the next task based on current project/release selection
            let (selectedProject, selectedRelease) = ProjectReleasePreferences.loadSelectedProject(
                from: noteStore.projects,
                releases: noteStore.releases
            )
            
            // Get next available task
            if let nextTask = noteStore.getFirstPendingNote(selectedProject: selectedProject, selectedRelease: selectedRelease) {
                print("▶️ [FocusCard] Starting next task: \(nextTask.title)")
                noteStore.startTimer(for: nextTask)
                showNotification(message: "Task skipped. Started: \(nextTask.title)")
            } else {
                print("⚠️ [FocusCard] No more tasks available for current selection")
                showNotification(message: "Task skipped. No more tasks available.")
            }
            
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






#Preview {
    FocusCardView(controller: FocusCardController(), noteStore: NoteStore())
}
