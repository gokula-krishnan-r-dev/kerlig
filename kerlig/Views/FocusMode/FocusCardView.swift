import SwiftUI
import AVFoundation
import Foundation

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
    @State private var hasAppeared = false
    
    // Create an instance of the sidebar controller
    private let sidebarController = FloatingSidebarController()

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                if isHovered && noteStore.activeTimerNote != nil {
                    // Enhanced action buttons when hovered
                    actionButtonsView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                } else {
                    // Main timer display
                    mainTimerView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                }
                
                // AI-enhanced content (dynamic based on hover and content)
                if isHovered && noteStore.activeTimerNote != nil {
                    if let activeNote = noteStore.activeTimerNote, activeNote.isAIEnhanced {
                        aiEnhancedContentView(for: activeNote)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)).combined(with: .scale(scale: 0.95)),
                                removal: .opacity.combined(with: .move(edge: .bottom)).combined(with: .scale(scale: 0.95))
                            ))
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isHovered)
                    }
                }
                
                // Session statistics (optional)
                if showSessionStats {
                    sessionStatsView
                        .transition(.slide)
                }
            }
            .frame(width: calculateFrameWidth(), height: calculateFrameHeight())
            .background(backgroundView)
            .overlay(borderOverlay)
            .scaleEffect(hasAppeared ? (isHovered ? 1.02 : 1.0) : 0.85) // Entrance + hover scale effect
            .opacity(hasAppeared ? 1.0 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1), value: isHovered)
            .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.2), value: hasAppeared)
            
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
            
            // Trigger entrance animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.2)) {
                    hasAppeared = true
                }
            }

            print("🔍 [FOCUS-CARD] ==========================================")
            print("🔍 [FOCUS-CARD] Focus Card View Appeared")
            if let activeNote = noteStore.activeTimerNote {
                print("🔍 [FOCUS-CARD] Active Timer Note: '\(activeNote.title)'")
                print("🔍 [FOCUS-CARD] AI Enhanced: \(activeNote.isAIEnhanced)")
                print("🔍 [FOCUS-CARD] AI Description: '\(activeNote.aiGeneratedDescription?.prefix(100) ?? "None")...'")
                print("🔍 [FOCUS-CARD] AI Subtasks Count: \(activeNote.aiGeneratedSubtasks.count)")
                if !activeNote.aiGeneratedSubtasks.isEmpty {
                    print("🔍 [FOCUS-CARD] First Subtask: '\(activeNote.aiGeneratedSubtasks.first?.title ?? "None")'")
                }
                print("🔍 [FOCUS-CARD] Generation Date: \(activeNote.aiGenerationDate?.formatted() ?? "None")")
            } else {
                print("🔍 [FOCUS-CARD] No active timer note")
            }
            print("🔍 [FOCUS-CARD] ==========================================")
        }
        .onHover { hovering in
            // Professional hover animation with spring effect
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1)) {
                isHovered = hovering
                showMaximizeButton = hovering
            }
            
            // Update window size with smooth timing
            let delay = hovering ? 0.05 : 0.1 // Faster expansion, slower contraction
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let newSize = CGSize(width: calculateFrameWidth(), height: calculateFrameHeight())
                controller.updateSize(newSize: newSize)
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
        HStack(spacing: 10) {
            // Task status indicator
            statusIndicator
            
            // Task content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    // Task title
                    Text(noteStore.activeTimerNote?.title ?? "No active task")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
               HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#4CAF50").opacity(0.8))
            
            // Use centralized timer from noteStore
            Text(noteStore.formatTime(noteStore.getTotalElapsedTimeForActiveTask()))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#4CAF50").opacity(0.8))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#4CAF50").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#4CAF50").opacity(0.2), lineWidth: 0.5)
                )
        )       
                }
                
                // Compact info row
                HStack(spacing: 8) {
                    // AI enhancement indicator
                    if let activeNote = noteStore.activeTimerNote, activeNote.isAIEnhanced {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.cyan)
                                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                            
                            Text("AI Enhanced")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.cyan.opacity(0.9))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.cyan.opacity(0.15),
                                            Color.blue.opacity(0.08)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                        .scaleEffect(isHovered ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
                    }
                    
                    // Session count
                    if let activeNote = noteStore.activeTimerNote {
                        Text("\(activeNote.sessions.count) sessions")
                            .font(.system(size: 9))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    
                    // Break indicator
                    if noteStore.globalTimerState == .break {
                        Text("• Break")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
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
    
    // MARK: - Timer Display (Legacy - keeping for potential future use)
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
    
    // MARK: - AI Enhanced Content View
    private func aiEnhancedContentView(for note: Note) -> some View {
        VStack(spacing: 0) {
            // Only show when hovered or if there's meaningful content
            if isHovered || hasmeaningfulAIContent(note) {
               Text(note.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 16) {
                    // AI Description section
                    if let cleanDescription = getCleanDescription(from: note.aiGeneratedDescription), !cleanDescription.isEmpty {
                        aiDescriptionSection(cleanDescription)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                    }
                    
                    // Subtasks section
                    if !note.aiGeneratedSubtasks.isEmpty {
                        aiSubtasksSection(note: note)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity.combined(with: .move(edge: .bottom))
                            ))
                    } else if isHovered && note.isAIEnhanced {
                        // Show loading state or fallback message when hovered
                        aiLoadingOrFallbackSection()
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .animation(.easeInOut(duration: 0.3), value: isHovered)
            }
        }
    }
    
    // MARK: - AI Content Helper Methods
    
    private func hasmeaningfulAIContent(_ note: Note) -> Bool {
        // Show content if there are subtasks or a clean description
        return !note.aiGeneratedSubtasks.isEmpty || 
               (getCleanDescription(from: note.aiGeneratedDescription) != nil && 
                !getCleanDescription(from: note.aiGeneratedDescription)!.isEmpty)
    }
    
    private func getCleanDescription(from rawDescription: String?) -> String? {
        guard let description = rawDescription, !description.isEmpty else { return nil }
        
        // Check if it's malformed JSON and try to extract the actual description
        if description.contains("\"description\":") {
            // Try to parse as JSON first
            if let data = description.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let cleanDesc = json["description"] as? String {
                return cleanDesc
            }
            
            // Fallback: Extract description using regex
            let pattern = "\"description\":\\s*\"([^\"]*)\""
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: description, range: NSRange(description.startIndex..., in: description)) {
                if let range = Range(match.range(at: 1), in: description) {
                    return String(description[range])
                }
            }
        }
        
        // If it's not JSON-like, return as is (but clean it up)
        return description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func aiDescriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green.opacity(0.8))
                
                Text("AI Description")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green.opacity(0.8))
                
                Spacer()
                
                if isHovered {
                    Image(systemName: "eye")
                        .font(.system(size: 10))
                        .foregroundColor(.green.opacity(0.6))
                        .transition(.opacity)
                }
            }
            
            Text(description)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(isHovered ? nil : 3)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.indigo.opacity(0.12),
                                    Color.purple.opacity(0.08),
                                    Color.blue.opacity(0.06)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.indigo.opacity(0.4),
                                            Color.purple.opacity(0.25),
                                            Color.blue.opacity(0.15)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        )
                        .shadow(
                            color: Color.indigo.opacity(0.15),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                )
                .scaleEffect(isHovered ? 1.01 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        }
    }
    
    private func aiSubtasksSection(note: Note) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green.opacity(0.8))
                
                let completedCount = note.aiGeneratedSubtasks.filter(\.isCompleted).count
                let totalCount = note.aiGeneratedSubtasks.count
                
                Text("Subtasks")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green.opacity(0.9))
                
                // Progress indicator
                Text("(\(completedCount)/\(totalCount))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.15))
                    )
                
                Spacer()
                
              
            }
            
            // Subtasks list
            LazyVStack(spacing: 8) {
                ForEach(note.aiGeneratedSubtasks.sorted(by: { $0.order < $1.order }), id: \.id) { subtask in
                    ProfessionalSubtaskRowView(subtask: subtask, noteStore: noteStore, noteId: note.id)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func aiLoadingOrFallbackSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.purple.opacity(0.6))
                
                Text("AI Enhancement")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.purple.opacity(0.7))
                
                Spacer()
            }
            
            Text("AI enhancement is being processed. Detailed breakdown and subtasks will appear here once ready.")
                .font(.system(size: 10))
                .foregroundColor(.gray.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
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
        RoundedRectangle(cornerRadius: 18)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: isHovered ? "#2A2A2C" : "#1C1C1E"),
                        Color(hex: isHovered ? "#1F1F21" : "#181818"),
                        Color(hex: isHovered ? "#1A1A1C" : "#151515")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(isHovered ? 0.15 : 0.08),
                                Color.cyan.opacity(isHovered ? 0.1 : 0.05),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovered ? 1.5 : 1
                    )
            )
            .shadow(
                color: isHovered ? Color.cyan.opacity(0.2) : Color.black.opacity(0.2),
                radius: isHovered ? 12 : 6,
                x: 0,
                y: isHovered ? 6 : 3
            )
            .shadow(
                color: Color.black.opacity(isHovered ? 0.4 : 0.3),
                radius: isHovered ? 4 : 2,
                x: 0,
                y: isHovered ? 2 : 1
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        borderColor.opacity(isHovered ? 0.8 : 0.5),
                        borderColor.opacity(isHovered ? 0.4 : 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isHovered ? 1.5 : 1
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
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
        .frame(width: calculateFrameWidth(), height: calculateFrameHeight())
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
    
    /// Calculate the appropriate frame width based on content
    private func calculateFrameWidth() -> CGFloat {
        // Base width - compact by default
        var width: CGFloat = 280
        
        if isHovered {
            // Expand significantly on hover for better content visibility
            width = 420
            
            // Extra width for AI-enhanced content
            if let activeNote = noteStore.activeTimerNote, activeNote.isAIEnhanced {
                // Check if we have longer descriptions or many subtasks
                let hasLongDescription = getCleanDescription(from: activeNote.aiGeneratedDescription)?.count ?? 0 > 100
                let hasMultipleSubtasks = activeNote.aiGeneratedSubtasks.count > 3
                
                if hasLongDescription || hasMultipleSubtasks {
                    width = 460
                }
            }
        }
        
        // Expand for session stats
        if showSessionStats {
            width = max(width, width + 40)
        }
        
        return width
    }
    
    /// Calculate the appropriate frame height based on content
    private func calculateFrameHeight() -> CGFloat {
        // Base height - very compact by default
        var height: CGFloat = 50
        
        if isHovered {
            // Base expanded height for hovered state
            height = 90 // Room for action buttons
            
            // Add height for AI-enhanced content if active note has AI content
            if let activeNote = noteStore.activeTimerNote, activeNote.isAIEnhanced {
                var aiContentHeight: CGFloat = 60 // Base AI content height with divider and headers
                
                // Add height for description
                if let cleanDescription = getCleanDescription(from: activeNote.aiGeneratedDescription), !cleanDescription.isEmpty {
                    let characterCount = cleanDescription.count
                    let estimatedLines = max(1, min(6, characterCount / 70)) // More generous line estimation
                    aiContentHeight += CGFloat(estimatedLines * 20) + 35 // Line height + padding
                }
                
                // Add height for subtasks
                let subtaskCount = activeNote.aiGeneratedSubtasks.count
                if subtaskCount > 0 {
                    // Dynamic height based on subtask count and content
                    let baseSubtaskHeight: CGFloat = 50
                    let additionalHeight = subtaskCount > 3 ? 5 : 0 // Extra space for more subtasks
                    aiContentHeight += CGFloat(subtaskCount * Int(baseSubtaskHeight + CGFloat(additionalHeight))) + 25
                }
                
                height += aiContentHeight
            }
        }
        
        // Add height for session stats
        if showSessionStats {
            height += 70 // Height for session stats section
        }
        
        // Dynamic maximum height based on content
        let maxHeight: CGFloat = isHovered ? 500 : 60
        return min(height, maxHeight)
    }
    
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
    var borderColor: Color? = nil
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(isHovered ? borderColor ?? color : .gray)

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
                RoundedRectangle(cornerRadius: 55)
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
                            RoundedRectangle(cornerRadius:55)
                                .stroke(color.opacity(0.3), lineWidth: 0.5) :
                            RoundedRectangle(cornerRadius: 55)
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
// MARK: - Professional Subtask Row View
struct ProfessionalSubtaskRowView: View {
    let subtask: Subtask
    @ObservedObject var noteStore: NoteStore
    let noteId: UUID
    @State private var isHovered = false
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            mainSubtaskRow
            
            // Show details when hovered or expanded
            if (isHovered || showingDetails) && hasDetails {
                subtaskDetailsView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(subtaskBackground)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            if hasDetails {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingDetails.toggle()
                }
            }
        }
    }
    
    // MARK: - Sub-views
    private var mainSubtaskRow: some View {
        HStack(spacing: 12) {
            checkboxButton
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    titleText
                    Spacer()
                    HStack(spacing: 6) {
                        priorityIndicator
                        durationBadge
                        if hasDetails {
                            expandIndicator
                        }
                    }
                }
            }
        }
    }
    
    private var checkboxButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.1)) {
                toggleSubtaskCompletion()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        subtask.isCompleted ? 
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.25),
                                Color.mint.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 18, height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        subtask.isCompleted ? Color.green.opacity(0.8) : Color.cyan.opacity(isHovered ? 0.6 : 0.3),
                                        subtask.isCompleted ? Color.mint.opacity(0.6) : Color.blue.opacity(isHovered ? 0.4 : 0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: subtask.isCompleted ? 2 : 1.5
                            )
                    )
                
                if subtask.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                        .scaleEffect(1.1)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .shadow(
                color: subtask.isCompleted ? Color.green.opacity(0.3) : Color.cyan.opacity(isHovered ? 0.2 : 0.1),
                radius: subtask.isCompleted ? 4 : (isHovered ? 3 : 2),
                x: 0,
                y: subtask.isCompleted ? 2 : (isHovered ? 1 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHovered ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1), value: isHovered)
        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2), value: subtask.isCompleted)
    }
    
    private var titleText: some View {
        Text(subtask.title)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(subtask.isCompleted ? .gray.opacity(0.7) : .white.opacity(0.9))
            .strikethrough(subtask.isCompleted)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
    
    @ViewBuilder
    private var priorityIndicator: some View {
        if subtask.priority != .medium {
            HStack(spacing: 3) {
                Image(systemName: subtask.priority.iconName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(priorityAccentColor)
                
                Text(subtask.priority.rawValue.capitalized)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(priorityAccentColor)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                priorityBackgroundColor.opacity(0.2),
                                priorityBackgroundColor.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(priorityAccentColor.opacity(0.3), lineWidth: 0.5)
                    )
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        }
    }
    
    private var priorityAccentColor: Color {
        switch subtask.priority {
        case .low: return .cyan
        case .medium: return .blue
        case .high: return .orange
        }
    }
    
    private var priorityBackgroundColor: Color {
        switch subtask.priority {
        case .low: return .mint
        case .medium: return .blue
        case .high: return .red
        }
    }
    
    @ViewBuilder
    private var durationBadge: some View {
        if let duration = subtask.estimatedDuration {
            HStack(spacing: 2) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.indigo.opacity(0.8))
                
                Text(formatDuration(duration))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.indigo.opacity(0.9))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.indigo.opacity(0.15),
                                Color.purple.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.indigo.opacity(0.25), lineWidth: 0.5)
                    )
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        }
    }
    
    @ViewBuilder
    private var expandIndicator: some View {
        Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
            .font(.system(size: 8))
            .foregroundColor(.gray.opacity(0.6))
            .rotationEffect(.degrees(isHovered ? (showingDetails ? 180 : 0) : (showingDetails ? 180 : 0)))
            .animation(.easeInOut(duration: 0.2), value: showingDetails)
    }
    
    private var subtaskDetailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let description = subtask.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.purple.opacity(0.8))
                    
                    Text(description)
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.8))
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                }
            }
            
            if let duration = subtask.estimatedDuration {
                HStack(spacing: 8) {
                    Text("Estimated Time:")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.purple.opacity(0.8))
                    
                    Text(formatDuration(duration))
                        .font(.system(size: 9))
                        .foregroundColor(.gray.opacity(0.8))
                    
                    Spacer()
                }
            }
            
            if let completionDate = subtask.completionDate {
                HStack(spacing: 8) {
                    Text("Completed:")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.green.opacity(0.8))
                    
                    Text(completionDate.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 9))
                        .foregroundColor(.green.opacity(0.8))
                    
                    Spacer()
                }
            }
        }
        .padding(.top, 6)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.indigo.opacity(0.08),
                            Color.purple.opacity(0.05),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.indigo.opacity(0.2),
                                    Color.purple.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                )
                .shadow(
                    color: Color.indigo.opacity(0.1),
                    radius: 2,
                    x: 0,
                    y: 1
                )
        )
    }
    
    private var subtaskBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(backgroundFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderStrokeColor, lineWidth: isHovered ? 1.5 : 1)
            )
            .shadow(
                color: shadowColor,
                radius: isHovered ? 6 : 3,
                x: 0,
                y: isHovered ? 3 : 1
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1), value: isHovered)
    }
    
    // MARK: - Computed Properties
    private var hasDetails: Bool {
        return (subtask.description != nil && !subtask.description!.isEmpty) ||
               subtask.estimatedDuration != nil ||
               subtask.completionDate != nil
    }
    
    private var backgroundFillColor: some ShapeStyle {
        if subtask.isCompleted {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.15),
                    Color.green.opacity(0.08),
                    Color.mint.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isHovered {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.cyan.opacity(0.12),
                    Color.blue.opacity(0.08),
                    Color.indigo.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.08),
                    Color.gray.opacity(0.04),
                    Color.clear
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
   
    private var borderStrokeColor: Color {
        if subtask.isCompleted {
            return Color.green.opacity(0.4)
        } else if isHovered {
            return Color.cyan.opacity(0.3)
        } else {
            return Color.white.opacity(0.15)
        }
    }
    
    private var shadowColor: Color {
        if subtask.isCompleted {
            return Color.green.opacity(0.25)
        } else if isHovered {
            return Color.cyan.opacity(0.2)
        } else {
            return Color.black.opacity(0.12)
        }
    }
    
    private func toggleSubtaskCompletion() {
        // Find and update the note with the modified subtask
        guard var note = noteStore.notes.first(where: { $0.id == noteId }) else { return }
        
        // Find the subtask and toggle its completion
        if let index = note.aiGeneratedSubtasks.firstIndex(where: { $0.id == subtask.id }) {
            note.aiGeneratedSubtasks[index].isCompleted.toggle()
            
            if note.aiGeneratedSubtasks[index].isCompleted {
                note.aiGeneratedSubtasks[index].completionDate = Date()
            } else {
                note.aiGeneratedSubtasks[index].completionDate = nil
            }
            
            // Update the note in the store
            noteStore.updateNote(note)
            
            print("✅ [SUBTASK] Toggled subtask completion: \(subtask.title) - \(note.aiGeneratedSubtasks[index].isCompleted ? "completed" : "incomplete")")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

// MARK: - Enhanced Subtask Row View (Legacy)
struct EnhancedSubtaskRowView: View {
    let subtask: Subtask
    @ObservedObject var noteStore: NoteStore
    let noteId: UUID
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            mainSubtaskRow
            
            if let description = subtask.description, !description.isEmpty {
                descriptionView(description)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(subtaskBackground)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    // MARK: - Sub-views
    private var mainSubtaskRow: some View {
        HStack(spacing: 10) {
            checkboxButton
            subtaskContentView
        }
    }
    
    private var checkboxButton: some View {
        Button(action: {
            toggleSubtaskCompletion()
        }) {
            Image(systemName: subtask.isCompleted ? "checkmark.square.fill" : "square")
                .font(.system(size: 14))
                .foregroundColor(subtask.isCompleted ? .green : .gray.opacity(0.6))
                .animation(.easeInOut(duration: 0.2), value: subtask.isCompleted)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var subtaskContentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                titleText
                Spacer()
                priorityIndicator
                durationBadge
            }
        }
    }
    
    private var titleText: some View {
        Text(subtask.title)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(subtask.isCompleted ? .gray.opacity(0.7) : .white.opacity(0.9))
            .strikethrough(subtask.isCompleted)
            .lineLimit(2)
    }
    
    @ViewBuilder
    private var priorityIndicator: some View {
        if subtask.priority != .medium {
            Image(systemName: subtask.priority.iconName)
                .font(.system(size: 10))
                .foregroundColor(subtask.priority.color.opacity(0.8))
        }
    }
    
    @ViewBuilder
    private var durationBadge: some View {
        if let duration = subtask.estimatedDuration {
            Text(formatDuration(duration))
                .font(.system(size: 9))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(durationBackground)
        }
    }
    
    private var durationBackground: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.1))
    }
    
    private func descriptionView(_ description: String) -> some View {
        Text(description)
            .font(.system(size: 10))
            .foregroundColor(.gray.opacity(0.8))
            .lineLimit(isHovered ? 10 : 2)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(descriptionBackground)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    
    private var descriptionBackground: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
            )
    }
    
    private var subtaskBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderStrokeColor, lineWidth: 0.5)
            )
    }
    
    // MARK: - Computed Properties
    private var backgroundFillColor: some ShapeStyle {
        if subtask.isCompleted {
            return Color.green.opacity(0.1)
        } else if isHovered {
            return Color.white.opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    private var borderStrokeColor: Color {
        if subtask.isCompleted {
            return Color.green.opacity(0.3)
        } else if isHovered {
            return Color.white.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private func toggleSubtaskCompletion() {
        // Find and update the note with the modified subtask
        guard var note = noteStore.notes.first(where: { $0.id == noteId }) else { return }
        
        // Find the subtask and toggle its completion
        if let index = note.aiGeneratedSubtasks.firstIndex(where: { $0.id == subtask.id }) {
            note.aiGeneratedSubtasks[index].isCompleted.toggle()
            
            if note.aiGeneratedSubtasks[index].isCompleted {
                note.aiGeneratedSubtasks[index].completionDate = Date()
            } else {
                note.aiGeneratedSubtasks[index].completionDate = nil
            }
            
            // Update the note in the store
            noteStore.updateNote(note)
            
            print("✅ [SUBTASK] Toggled subtask completion: \(subtask.title) - \(note.aiGeneratedSubtasks[index].isCompleted ? "completed" : "incomplete")")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

// MARK: - Subtask Row View (Legacy)
struct SubtaskRowView: View {
    let subtask: Subtask
    @ObservedObject var noteStore: NoteStore
    let noteId: UUID
    @State private var isHovered = false
    
    var body: some View {
        EnhancedSubtaskRowView(subtask: subtask, noteStore: noteStore, noteId: noteId)
    }
}

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
        .frame(width: 700 , height: 700)
}
