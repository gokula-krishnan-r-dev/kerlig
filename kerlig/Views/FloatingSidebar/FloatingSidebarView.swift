import SwiftUI
import AppKit
import AVFoundation
import UserNotifications
import QuartzCore

// MARK: - UserDefaults Manager for Project/Release Preferences
private struct ProjectReleasePreferences {
    static let selectedProjectIdKey = "SelectedProjectId"
    static let selectedReleaseIdKey = "SelectedReleaseId"
    static let lastUsedProjectKey = "LastUsedProject"
    
    static func saveSelectedProject(_ project: Project?, release: Release?) {
        let userDefaults = UserDefaults.standard
        
        if let project = project {
            userDefaults.set(project.id.uuidString, forKey: selectedProjectIdKey)
            userDefaults.set(project.id.uuidString, forKey: lastUsedProjectKey)
            
            if let release = release {
                userDefaults.set(release.id.uuidString, forKey: selectedReleaseIdKey)
            } else {
                userDefaults.removeObject(forKey: selectedReleaseIdKey)
            }
        } else {
            userDefaults.removeObject(forKey: selectedProjectIdKey)
            userDefaults.removeObject(forKey: selectedReleaseIdKey)
        }
        
        userDefaults.synchronize()
        
        // Debug logging
        print("💾 Project Preferences Saved:")
        print("   Project: \(project?.title ?? "None")")
        print("   Release: \(release?.version ?? "None")")
    }
    
    static func loadSelectedProject(from projects: [Project], releases: [Release]) -> (project: Project?, release: Release?) {
        let userDefaults = UserDefaults.standard
        
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
                        print("🎯 Restored saved selection: \(savedProject.title) -> v\(savedRelease.version)")
                        return (savedProject, savedRelease)
                    }
                }
                
                // If project exists but release doesn't, select first available release
                let projectReleases = releases.filter { $0.projectId == savedProject.id }
                let firstRelease = projectReleases.first
                print("🔄 Project found, selecting first release: \(savedProject.title) -> \(firstRelease?.version ?? "None")")
                return (savedProject, firstRelease)
            }
        }
        
        // Fallback: Try to use last used project if current selection is invalid
        if let lastProjectIdString = userDefaults.string(forKey: lastUsedProjectKey),
           let lastProjectId = UUID(uuidString: lastProjectIdString),
           let lastUsedProject = projects.first(where: { $0.id == lastProjectId && !$0.isArchived }) {
            
            let projectReleases = releases.filter { $0.projectId == lastUsedProject.id }
            let firstRelease = projectReleases.first
            print("🔄 Using last used project: \(lastUsedProject.title)")
            return (lastUsedProject, firstRelease)
        }
        
        // Final fallback: Select first available project
        if let firstProject = projects.first(where: { !$0.isArchived }) {
            let projectReleases = releases.filter { $0.projectId == firstProject.id }
            let firstRelease = projectReleases.first
            print("🆕 Auto-selecting first available project: \(firstProject.title)")
            return (firstProject, firstRelease)
        }
        
        print("⚠️ No projects available for selection")
        return (nil, nil)
    }
    
    static func clearPreferences() {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: selectedProjectIdKey)
        userDefaults.removeObject(forKey: selectedReleaseIdKey)
        userDefaults.synchronize()
        print("🗑️ Project preferences cleared")
    }
    
    /// Get current stored preferences for debugging
    static func getCurrentStoredPreferences() -> (projectId: String?, releaseId: String?, lastUsedProjectId: String?) {
        let userDefaults = UserDefaults.standard
        return (
            projectId: userDefaults.string(forKey: selectedProjectIdKey),
            releaseId: userDefaults.string(forKey: selectedReleaseIdKey),
            lastUsedProjectId: userDefaults.string(forKey: lastUsedProjectKey)
        )
    }
}

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
    @State private var showCompletedTasks: Bool = false
    @State private var isCompletedSectionExpanded: Bool = false
    @State private var isFullScreenButtonHovered: Bool = false
    @State private var isFullScreenButtonPressed: Bool = false
    @State private var isCompleted: Bool = false
    @State private var completedTaskTime: TimeInterval = 0
    @State private var dismissTimer: Timer?
    @State private var recentlySkippedNoteId: UUID? = nil
    
    // Project and Release Selection
    @State private var selectedProject: Project?
    @State private var selectedRelease: Release?
    @State private var showingProjectSelector = false
    @State private var showingReleaseSelector = false
    @State private var isProjectSelectorExpanded = false
    
    // Scheduled Task Properties
    @State private var selectedTaskTab: TaskTab = .regular
    @State private var scheduledDate = Date()
    @State private var scheduledTime = Date()
    @State private var taskPriority: TaskPriority = .medium
    @State private var taskDescription = ""
    @State private var reminderMinutes = 15
    @State private var selectedImage: NSImage?
    @State private var showingImagePicker = false
    
    // New unified media content
    @State private var taskMediaContent = MediaContent()
    
    // Media picker visibility toggle
    @State private var showMediaPicker = UserDefaults.standard.bool(forKey: "showMediaPicker")
    
    @StateObject private var notificationService = ScheduledTaskNotificationService.shared
    
    let controller: FloatingSidebarController
    let onClose: () -> Void
    let focusCardController = FocusCardController()
    
    enum TaskTab: String, CaseIterable {
        case regular = "Regular"
        case scheduled = "Scheduled"
        
        var iconName: String {
            switch self {
            case .regular: return "plus.circle"
            case .scheduled: return "calendar.badge.clock"
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            headerView
             if isCompleted {
                completedTaskView
            }else{
            // Project and Release Selection
            projectReleaseSelector
            
            if isAddingNote {
                addTaskView
            } else {
                addTaskButton
            }

            // Task Progress Summary
            taskProgressSummary

            }
            
            taskListView
            if !isCompleted {
            if noteStore.getFilteredPendingNotes(selectedProject: selectedProject, selectedRelease: selectedRelease).count == 0 {
                Spacer()
                emptyStateView
                Spacer()
            }
            }            
            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            
            completedTasksSection
            if (!noteStore.getFilteredPendingNotes(selectedProject: selectedProject, selectedRelease: selectedRelease).isEmpty) {
                focusModeButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundWithResizeHandle)
        .cornerRadius(20)
        .onAppear {
            isFocused = true
            initializeProjectSelection()
            firstNote = findFirstNote()
            
            // Initialize media picker preference with default value
            initializeMediaPickerPreference()
            
            // Initialize notification service
            notificationService.setNoteStore(noteStore)
            
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
        .onChange(of: noteStore.projects.count) { _ in
            // Validate selection when projects change
            validateAndRefreshSelection()
        }
        .onChange(of: noteStore.releases.count) { _ in
            // Validate selection when releases change
            validateAndRefreshSelection()
        }
        .sheet(isPresented: $notificationService.showingScheduledAlert) {
            if let task = notificationService.currentScheduledTask {
                ScheduledTaskAlertView(
                    task: task,
                    onDismiss: {
                        notificationService.dismissAlert()
                    },
                    onStartTask: {
                        notificationService.dismissAlert()
                        // Move task to top of list and start it
                        firstNote = task
                    },
                    onSnooze: { minutes in
                        // Implement snooze functionality
                        var updatedTask = task
                        updatedTask.scheduledTime = Calendar.current.date(byAdding: .minute, value: minutes, to: updatedTask.scheduledTime ?? Date()) ?? Date()
                        updatedTask.hasBeenNotified = false
                        noteStore.updateNote(updatedTask)
                        notificationService.dismissAlert()
                    }
                )
            }
        }
    }
    
    // MARK: - UI Components
    private var fullScreenModeButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isFullScreenButtonPressed = true
            }
            
            // Reset pressed state after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isFullScreenButtonPressed = false
                }
            }
            
            // Open main application window with enhanced functionality
            openMainApplicationWindow()
        }) {
            ZStack {
                // Background with dynamic effects
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isFullScreenButtonHovered ? Color(hex: "#4CAF50").opacity(0.2) : Color(hex: "#2C2C2E").opacity(0.8),
                                isFullScreenButtonHovered ? Color(hex: "#45A049").opacity(0.3) : Color(hex: "#262628").opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isFullScreenButtonHovered ? Color(hex: "#4CAF50").opacity(0.4) : Color.white.opacity(0.1),
                                        isFullScreenButtonHovered ? Color(hex: "#45A049").opacity(0.2) : Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: isFullScreenButtonHovered ? 1.5 : 0.5
                            )
                    )
                    .frame(width: 32, height: 32)
                    .scaleEffect(
                        isFullScreenButtonPressed ? 0.85 : 
                        (isFullScreenButtonHovered ? 1.1 : 1.0)
                    )
                    .shadow(
                        color: isFullScreenButtonHovered ? Color(hex: "#4CAF50").opacity(0.3) : Color.black.opacity(0.2),
                        radius: isFullScreenButtonHovered ? 8 : 4,
                        x: 0,
                        y: isFullScreenButtonHovered ? 4 : 2
                    )
                
                // Icon with dynamic rotation and scaling
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(
                        isFullScreenButtonHovered ? Color(hex: "#4CAF50") : .white.opacity(0.9)
                    )
                    .scaleEffect(
                        isFullScreenButtonPressed ? 0.8 : 
                        (isFullScreenButtonHovered ? 1.2 : 1.0)
                    )
                    .rotationEffect(.degrees(isFullScreenButtonHovered ? 5 : 0))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.25)) {
                isFullScreenButtonHovered = hovering
            }
        }
        .help("Open Full Application") // Tooltip
    }
    
    private var headerView: some View {
        HStack {
            Text("Tasks")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()

            // Dynamic Full Screen Mode Button
            fullScreenModeButton


        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Project and Release Selector
    private var projectReleaseSelector: some View {
        VStack(spacing: 0) {
            // Header with toggle button
            selectorHeader
            
            // Expandable content
            if isProjectSelectorExpanded {
                expandedSelectorContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            } else {
                compactSelectorContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                                            removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isProjectSelectorExpanded.toggle()
            }
        }
        .background(selectorContainerBackground)
        .cornerRadius(12)
        .padding(.horizontal, 4)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isProjectSelectorExpanded)
    }
    
    private var selectorHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Project & Release")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Current selection summary (when collapsed)
            if !isProjectSelectorExpanded {
                HStack(spacing: 4) {
                    if let project = selectedProject {
                        if let logoData = project.logoImageData,
                           let nsImage = NSImage(data: logoData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .frame(width: 14, height: 14)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 10))
                                .foregroundColor(project.color ?? .blue)
                        }
                        
                        Text(project.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    } else {
                        Text("All Projects")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    if let release = selectedRelease {
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text("v\(release.version)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#2C2C2E").opacity(0.6))
                )
            }
            
            // Toggle button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isProjectSelectorExpanded.toggle()
                }
            }) {
                Image(systemName: isProjectSelectorExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .rotationEffect(.degrees(isProjectSelectorExpanded ? 0 : 0))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(4)
            .background(
                Circle()
                    .fill(Color(hex: "#2C2C2E").opacity(isProjectSelectorExpanded ? 0.8 : 0.4))
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    private var compactSelectorContent: some View {
        EmptyView()
    }
    
    private var expandedSelectorContent: some View {
        VStack(spacing: 8) {
            // Labels row
            HStack {
                Text("PROJECT")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("RELEASE")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            
            // Cards row
            HStack(spacing: 8) {
                // Project Card
                projectSelectorCard
                
                // Release Card
                releaseSelectorCard
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
    
    private var projectSelectorCard: some View {
        Menu {
            Button("All Projects") {
                clearProjectSelection()
            }
            
            ForEach(noteStore.projects.filter { !$0.isArchived }) { project in
                Button(action: {
                    selectProject(project)
                }) {
                    HStack {
                        if let logoData = project.logoImageData,
                           let nsImage = NSImage(data: logoData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .frame(width: 16, height: 16)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                )
                        }
                        
                        Text(project.title)
                            .lineLimit(1)
                        
                        if selectedProject?.id == project.id {
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    // Project icon
                    if let project = selectedProject {
                        if let logoData = project.logoImageData,
                           let nsImage = NSImage(data: logoData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 16))
                                .foregroundColor(project.color ?? .blue)
                        }
                    } else {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.6))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedProject?.title ?? "All Projects")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(selectedProject != nil ? "Active Project" : "No Filter")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(selectorCardBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var releaseSelectorCard: some View {
        Menu {
            if let selectedProject = selectedProject {
                let releases = noteStore.getReleasesForProject(selectedProject)
                if releases.isEmpty {
                    Button("No Releases") { }
                        .disabled(true)
                } else {
                    ForEach(releases) { release in
                        Button(action: {
                            selectRelease(release)
                        }) {
                            HStack {
                                Image(systemName: release.status.iconName)
                                    .font(.system(size: 12))
                                    .foregroundColor(release.status.color)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("v\(release.version)")
                                        .font(.system(size: 11, weight: .semibold))
                                    if !release.name.isEmpty {
                                        Text(release.name)
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                }
                                
                                if selectedRelease?.id == release.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            } else {
                Button("Select Project First") { }
                    .disabled(true)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    // Release icon
                    if let release = selectedRelease {
                        Image(systemName: release.status.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(release.status.color)
                    } else {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 16))
                            .foregroundColor(selectedProject != nil ? .orange.opacity(0.8) : .gray.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(selectedProject != nil ? 0.6 : 0.3))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if let release = selectedRelease {
                        Text("v\(release.version)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(release.name.isEmpty ? "Release" : release.name)
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.8))
                            .lineLimit(1)
                    } else {
                        Text(selectedProject != nil ? "Select Release" : "No Project")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedProject != nil ? .white : .gray.opacity(0.6))
                            .lineLimit(1)
                        
                        Text(selectedProject != nil ? "Choose Version" : "Select project first")
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(selectedProject != nil ? 0.8 : 0.5))
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(selectorCardBackground)
            .opacity(selectedProject != nil ? 1.0 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(selectedProject == nil)
    }
    
    private var selectorContainerBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: "#1C1C1E"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.02)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
    }
    
    private var selectorCardBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(hex: "#2C2C2E"))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            )
    }
    
    private var addTaskView: some View {
        VStack(spacing: 12) {
            taskCreationHeader
            taskTabSelector
            taskFormContent
        }
        .background(taskViewBackground)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
    }
    
    private var taskCreationHeader: some View {
        HStack {
            Text("CANCEL")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .onTapGesture {
                    resetTaskForm()
                    isAddingNote = false
                }
                .keyboardShortcut(.escape)
            
            Spacer()
            
            Text("Create Task")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            confirmButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var confirmButton: some View {
        Button(action: selectedTaskTab == .regular ? createNewNote : createScheduledTask) {
            Text("Confirm")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(confirmButtonBackground)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(newNoteTitle.isEmpty)
        .opacity(newNoteTitle.isEmpty ? 0.5 : 1.0)
    }
    
    private var confirmButtonBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: "#4CAF50"), Color(hex: "#45A049")]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
    
    private var taskTabSelector: some View {
        HStack(spacing: 2) {
            ForEach(TaskTab.allCases, id: \.self) { tab in
                taskTabView(for: tab)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }
    
    private func taskTabView(for tab: TaskTab) -> some View {
        HStack(spacing: 4) {
            Image(systemName: tab.iconName)
                .font(.system(size: 11, weight: .medium))
                .symbolRenderingMode(.hierarchical)
            Text(tab.rawValue)
                .font(.system(size: 11, weight: .medium))
                .tracking(0.2)
        }
        .foregroundColor(selectedTaskTab == tab ? .white : .gray.opacity(0.7))
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .scaleEffect(selectedTaskTab == tab ? 1.02 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTaskTab = tab
            }
        }
        .animation(.easeInOut(duration: 0.1), value: selectedTaskTab)
    }
    
    private func taskTabBackground(for tab: TaskTab) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#4CAF50").opacity(0.25),
                        Color(hex: "#45A049").opacity(0.15)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) 
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        selectedTaskTab == tab ? 
                        Color(hex: "#4CAF50").opacity(0.3) : 
                        Color.clear, 
                        lineWidth: 0.8
                    )
            )
    }
    
    private var taskFormContent: some View {
        Group {
            if selectedTaskTab == .regular {
                regularTaskForm
            } else {
                scheduledTaskForm
            }
        }
    }
    
    private var taskViewBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: "#1C1C1E"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
    }
    
    private var mediaPickerSection: some View {
        VStack(spacing: 12) {
            // Toggle switch for media picker
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: showMediaPicker ? "photo.fill" : "photo")
                        .font(.system(size: 14))
                        .foregroundColor(showMediaPicker ? .blue : .gray)
                    
                    Text("Attach Media")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("(images or emojis)")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: $showMediaPicker)
                    .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                    .scaleEffect(0.8)
                    .onChange(of: showMediaPicker) { value in
                        saveMediaPickerPreference(value)
                        if !value {
                            // Clear media content when disabled
                            taskMediaContent = MediaContent()
                        }
                    }
            }
            .padding(.horizontal, 16)
            
            // Show MediaPickerView only when enabled
            if showMediaPicker {
                MediaPickerView(mediaContent: $taskMediaContent)
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showMediaPicker)
    }
    
    private func saveMediaPickerPreference(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: "showMediaPicker")
    }
    
    private func initializeMediaPickerPreference() {
        // Set default value for first-time users
        if UserDefaults.standard.object(forKey: "showMediaPicker") == nil {
            UserDefaults.standard.set(false, forKey: "showMediaPicker")
            showMediaPicker = false
        } else {
            showMediaPicker = UserDefaults.standard.bool(forKey: "showMediaPicker")
        }
    }
    
    private var regularTaskForm: some View {
        VStack(spacing: 12) {
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
            
            // Media picker toggle and content
            mediaPickerSection
            
            HStack {
                Text("Add a regular task" + (showMediaPicker ? " with optional media" : ""))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    private var scheduledTaskForm: some View {
        VStack(spacing: 16) {
            // Title and Description
            VStack(spacing: 8) {
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
                
                TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12))
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
                    .frame(minHeight: 40)
            }
            .padding(.horizontal, 16)
            
            // Date and Time Selection
            VStack(spacing: 8) {
                HStack {
                    Text("Schedule")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        DatePicker("", selection: $scheduledDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        DatePicker("", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Est. Time")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        TextField("00:00", text: $estimatedTime)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 50)
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: "#2C2C2E"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Priority and Reminder
            VStack(spacing: 8) {
                HStack {
                    // Priority Selector
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Priority")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        
                        Menu {
                            ForEach(TaskPriority.allCases) { priority in
                                Button(action: { taskPriority = priority }) {
                                    HStack {
                                        Image(systemName: priority.iconName)
                                        Text(priority.rawValue)
                                        if taskPriority == priority {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .foregroundColor(priority.color)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: taskPriority.iconName)
                                    .font(.system(size: 12))
                                Text(taskPriority.rawValue)
                                    .font(.system(size: 12))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(taskPriority.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: "#2C2C2E"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                    
                    // Reminder Selector
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remind me")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        
                        Menu {
                            Button("5 minutes before") { reminderMinutes = 5 }
                            Button("15 minutes before") { reminderMinutes = 15 }
                            Button("30 minutes before") { reminderMinutes = 30 }
                            Button("1 hour before") { reminderMinutes = 60 }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bell")
                                    .font(.system(size: 12))
                                Text("\(reminderMinutes)m before")
                                    .font(.system(size: 12))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: "#2C2C2E"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Media picker toggle and content
            mediaPickerSection
            
            HStack {
                Text("Create a scheduled task")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    // MARK: - Task Progress Summary
    private var taskProgressSummary: some View {
        let completedTasks = noteStore.getFilteredCompletedNotes(selectedProject: selectedProject, selectedRelease: selectedRelease)
        let pendingTasks = noteStore.getFilteredPendingNotes(selectedProject: selectedProject, selectedRelease: selectedRelease)
        let totalTasks = completedTasks.count + pendingTasks.count
        let progress = totalTasks > 0 ? Double(completedTasks.count) / Double(totalTasks) : 0.0
        let estimatedTimeRemaining = calculateEstimatedTimeRemaining(pendingTasks)
        
        return HStack(spacing: 10) {
            // Completed tasks
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
                
                Text("\(completedTasks.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Divider
            Text("•")
                .font(.system(size: 8))
                .foregroundColor(.gray.opacity(0.4))
            
            // Pending tasks
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.orange.opacity(0.8))
                
                Text("\(pendingTasks.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Inline progress bar
            if totalTasks > 0 {
                HStack(spacing: 6) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "#2C2C2E"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                                )
                            
                            // Progress fill
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#4CAF50"),
                                            Color(hex: "#45A049")
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress)
                                .animation(.easeInOut(duration: 0.6), value: progress)
                        }
                    }
                    .frame(width: 60, height: 4)
                    
                    // Percentage
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(minWidth: 30)
                }
            }
            
            Spacer()
            
            // Estimated time remaining
            if estimatedTimeRemaining > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "timer")
                        .font(.system(size: 10))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    Text(formatEstimatedTime(estimatedTimeRemaining))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blue.opacity(0.8))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.blue.opacity(0.15), lineWidth: 0.5)
                        )
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#1C1C1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.02)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
    }
    
    // MARK: - Helper Methods for Progress Summary
    private func calculateEstimatedTimeRemaining(_ pendingTasks: [Note]) -> TimeInterval {
        var totalSeconds: TimeInterval = 0
        
        for task in pendingTasks {
            if let estimatedTime = task.estimatedTime, !estimatedTime.isEmpty {
                // Parse time format (e.g., "01:30" or "90" minutes)
                let components = estimatedTime.components(separatedBy: ":")
                if components.count == 2 {
                    // HH:MM format
                    if let hours = Int(components[0]), let minutes = Int(components[1]) {
                        totalSeconds += TimeInterval(hours * 3600 + minutes * 60)
                    }
                } else if components.count == 1 {
                    // Minutes only format
                    if let minutes = Int(components[0]) {
                        totalSeconds += TimeInterval(minutes * 60)
                    }
                }
            } else {
                // Default estimation for tasks without specified time (15 minutes)
                totalSeconds += 15 * 60
            }
        }
        
        return totalSeconds
    }
    
    private func formatEstimatedTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m left"
            } else {
                return "\(hours)h left"
            }
        } else if minutes > 0 {
            return "\(minutes)m left"
        } else {
            return "Almost done!"
        }
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
                // Regular tasks
                ForEach(noteStore.getFilteredPendingNotes(selectedProject: selectedProject, selectedRelease: selectedRelease).filter { !$0.isScheduled }) { note in
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
                            handleTaskSkip(skippedNote)
                             //after 2s call focusOnNewNote()
                               focusOnNewNote()
            updateTaskData() // Refresh task data
                              firstNote = findFirstNote()

                              
                        }
                    )
                    .background(taskRowBackground(for: note))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: recentlySkippedNoteId == note.id)
                    .overlay(taskRowOverlay(for: note), alignment: .bottomTrailing)
                }
                
                // Scheduled tasks section
                let scheduledTasks = noteStore.getFilteredScheduledNotes(selectedProject: selectedProject, selectedRelease: selectedRelease)
                if !scheduledTasks.isEmpty {
                    scheduledTasksSection(scheduledTasks)
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(hex: "#1C1C1E"))
        .onDisappear {
            dismissTimer?.invalidate()
        }
    }
    
    private func handleTaskSkip(_ skippedNote: Note) {
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
    
    private func taskRowBackground(for note: Note) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(note.id == recentlySkippedNoteId ? 
                  Color(hex: "#9333EA").opacity(0.2) :
                  (note.isScheduled ? Color(hex: "#4CAF50").opacity(0.1) : Color(hex: "#2C2C2E")))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(note.id == recentlySkippedNoteId ?
                            Color(hex: "#9333EA").opacity(0.5) :
                            (note.isScheduled ? Color(hex: "#4CAF50").opacity(0.3) : Color.white.opacity(0.08)), 
                            lineWidth: 0.5)
            )
    }
    
    private func taskRowOverlay(for note: Note) -> some View {
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
    }
    
    private func scheduledTasksSection(_ scheduledTasks: [Note]) -> some View {
        VStack(spacing: 8) {
            // Section header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#4CAF50"))
                    
                    Text("Scheduled Tasks")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#4CAF50"))
                }
                
                Spacer()
                
                Text("\(scheduledTasks.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#4CAF50").opacity(0.2))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Scheduled tasks list
            ForEach(scheduledTasks) { note in
                ScheduledTaskRowView(
                    note: note,
                    firstNote: firstNote,
                    noteStore: noteStore,
                    onDone: { elapsedTime in
                        firstNote = findFirstNote()
                        completedTaskTime = elapsedTime
                        isCompleted = true
                    },
                    onSkip: { skippedNote in
                        handleTaskSkip(skippedNote)
                    }
                )
                .background(taskRowBackground(for: note))
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8)),
                    removal: .opacity.combined(with: .scale(scale: 0.8))
                ))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: recentlySkippedNoteId == note.id)
                .overlay(taskRowOverlay(for: note), alignment: .bottomTrailing)
            }
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
    
    // MARK: - Completed Tasks Section
    private var completedTasksSection: some View {
        let completedTasks = noteStore.getFilteredCompletedNotes(selectedProject: selectedProject, selectedRelease: selectedRelease)
        let totalTimeSpent = noteStore.getTotalTimeSpentOnFilteredCompletedNotes(selectedProject: selectedProject, selectedRelease: selectedRelease)
        
        return VStack(spacing: 0) {
            // Professional header with toggle
            completedTasksHeader(count: completedTasks.count, totalTime: totalTimeSpent)
            
            // Expandable content with smooth animation
            if isCompletedSectionExpanded {
                completedTasksContent(tasks: completedTasks)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95, anchor: .top))
                    ))
            }
        }
        .background(completedSectionBackground)
        .cornerRadius(12)
        .padding(.horizontal, 4)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isCompletedSectionExpanded)
    }
    
    private func completedTasksHeader(count: Int, totalTime: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                isCompletedSectionExpanded.toggle()
            }
        }) {
            HStack(spacing: 12) {
                // Section icon and title
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.green.opacity(0.9))
                    
                    Text("Completed Tasks")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Summary stats (when collapsed)
                if !isCompletedSectionExpanded {
                    HStack(spacing: 8) {
                        // Task count badge
                        HStack(spacing: 4) {
                            Text("\(count)")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(.green)
                            
                            Text("done")
                                .font(.system(size: 6))
                                .foregroundColor(.green.opacity(0.8))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.green.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                        
                        // Time spent badge
                        if !totalTime.isEmpty && totalTime != "0m" {
                            HStack(spacing: 3) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.blue.opacity(0.8))
                                
                                Text(totalTime)
                                    .font(.system(size: 6, weight: .medium))
                                    .foregroundColor(.blue.opacity(0.9))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.blue.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                        }
                    }
                }
                
                // Toggle chevron
                Image(systemName: isCompletedSectionExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .rotationEffect(.degrees(isCompletedSectionExpanded ? 0 : 0))
                    .scaleEffect(isCompletedSectionExpanded ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isCompletedSectionExpanded)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isCompletedSectionExpanded ? 
                        Color(hex: "#2C2C2E").opacity(0.8) : 
                        Color(hex: "#1C1C1E").opacity(0.6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isCompletedSectionExpanded ?
                                Color.white.opacity(0.08) :
                                Color.white.opacity(0.04),
                                lineWidth: 0.5
                            )
                    )
            )
            .scaleEffect(isCompletedSectionExpanded ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isCompletedSectionExpanded)
    }
    
    private func completedTasksContent(tasks: [Note]) -> some View {
        VStack(spacing: 8) {
            // Expanded header stats
            expandedStatsHeader(tasks: tasks)
            
            // Tasks list
            if tasks.isEmpty {
                emptyCompletedState
            } else {
                modernCompletedTasksList(tasks: tasks)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
    
    private func expandedStatsHeader(tasks: [Note]) -> some View {
        HStack(spacing: 4) {
            // Total completed
            VStack(alignment: .leading, spacing: 2) {
                Text("TOTAL COMPLETED")
                    .font(.system(size: 6, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.7))
                
                Text("\(tasks.count)")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            // Time spent
            VStack(alignment: .trailing, spacing: 2) {
                Text("TIME SPENT")
                    .font(.system(size: 6, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.7))
                
                Text(noteStore.getTotalTimeSpentOnFilteredCompletedNotes(selectedProject: selectedProject, selectedRelease: selectedRelease))
                    .font(.system(size: 6, weight: .bold))
                    .foregroundColor(.blue.opacity(0.9))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "#2C2C2E").opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                )
        )
    }
    
    private var emptyCompletedState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.dotted")
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No completed tasks yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("Complete your first task to see it here")
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.4))
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
    
    private func modernCompletedTasksList(tasks: [Note]) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 6) {
                ForEach(tasks) { note in
                    ModernCompletedTaskRow(note: note)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 180)
    }
    
    private var completedSectionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: "#1C1C1E"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.02)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
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

                    Text("⌘F")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            //shortcut for focus mode
            .keyboardShortcut("f", modifiers: [.command])
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
    // Enhanced Main Application Window Management
    private func openMainApplicationWindow() {
        
        controller.toggleSidebar()
        
        
        
        // Simulate Command+N shortcut to create new note
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 45, keyDown: true) // 45 is 'n' key
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 45, keyDown: false)
        
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)


    }
    
    private func createNewMainWindow() {
        // Create a new main window if none exists
        let newWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = "kerlig"
        newWindow.center()
        newWindow.setFrameAutosaveName("MainWindow")
        newWindow.isReleasedWhenClosed = false
        
        // Set up window content - you might need to adjust this based on your app structure
        // newWindow.contentView = NSHostingView(rootView: YourMainContentView())
        
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Project and Release Management
    
    /// Initialize project selection using the professional UserDefaults system
    private func initializeProjectSelection() {
        print("🚀 Initializing project selection...")
        
        // Load saved selection using the professional system
        let (savedProject, savedRelease) = ProjectReleasePreferences.loadSelectedProject(
            from: noteStore.projects,
            releases: noteStore.releases
        )
        
        // Apply the loaded selection
        selectedProject = savedProject
        selectedRelease = savedRelease
        
        // Update task data and UI
        updateTaskData()
        
        print("✅ Project selection initialized: \(savedProject?.title ?? "None") -> \(savedRelease?.version ?? "None")")
    }
    
    /// Select a project and automatically choose the best release
    private func selectProject(_ project: Project) {
        print("📁 Selecting project: \(project.title)")
        
        // Set the selected project
        selectedProject = project
        
        // Get available releases for this project
        let projectReleases = noteStore.getReleasesForProject(project)
        
        // Auto-select the first available release
        selectedRelease = projectReleases.first
        
        // Save the selection using the professional system
        ProjectReleasePreferences.saveSelectedProject(selectedProject, release: selectedRelease)
        
        // Update task data and UI
        updateTaskData()
        firstNote = findFirstNote()
        
        print("✅ Project selected successfully")
    }
    
    /// Select a specific release for the current project
    private func selectRelease(_ release: Release) {
        guard let currentProject = selectedProject else {
            print("⚠️ Cannot select release without a project")
            return
        }
        
        print("🎯 Selecting release: v\(release.version) for \(currentProject.title)")
        
        // Set the selected release
        selectedRelease = release
        
        // Save the selection using the professional system
        ProjectReleasePreferences.saveSelectedProject(selectedProject, release: selectedRelease)
        
        // Update task data and UI
        updateTaskData()
        firstNote = findFirstNote()
        
        print("✅ Release selected successfully")
    }
    
    /// Clear current project/release selection
    private func clearProjectSelection() {
        print("🗑️ Clearing project selection")
        
        selectedProject = nil
        selectedRelease = nil
        
        // Clear saved preferences
        ProjectReleasePreferences.clearPreferences()
        
        // Update task data and UI
        updateTaskData()
        firstNote = findFirstNote()
        
                 print("✅ Project selection cleared")
     }
     
     /// Validate and refresh current project/release selection
     /// This should be called when noteStore data changes
     private func validateAndRefreshSelection() {
         guard let currentProject = selectedProject else { return }
         
         // Check if current project still exists and is not archived
         if !noteStore.projects.contains(where: { $0.id == currentProject.id && !$0.isArchived }) {
            print("⚠️ Current project no longer available, reinitializing selection")
            initializeProjectSelection()
            return
         }
         
         // Check if current release still exists
         if let currentRelease = selectedRelease {
            let projectReleases = noteStore.getReleasesForProject(currentProject)
            if !projectReleases.contains(where: { $0.id == currentRelease.id }) {
                print("⚠️ Current release no longer available, selecting first available")
                selectedRelease = projectReleases.first
                ProjectReleasePreferences.saveSelectedProject(selectedProject, release: selectedRelease)
                updateTaskData()
            }
         }
     }
     
     /// Get current selection summary for debugging
     private func getCurrentSelectionSummary() -> String {
         let projectTitle = selectedProject?.title ?? "All Projects"
         let releaseVersion = selectedRelease?.version ?? "No Release"
         return "\(projectTitle) -> v\(releaseVersion)"
     }
     
     /// Public method to refresh selection state - can be called from external sources
     func refreshProjectSelection() {
         print("🔄 External refresh requested for project selection")
         validateAndRefreshSelection()
         print("📊 Current selection: \(getCurrentSelectionSummary())")
     }
    
    private func updateTaskData() {
        // This method is now simplified since filtering logic is handled by NoteStore
        // Just refresh the first note when selection changes
        firstNote = findFirstNote()
    }
    

    
    private func findFirstNote() -> Note? {
        return noteStore.getFirstPendingNote(selectedProject: selectedProject, selectedRelease: selectedRelease)
    }
    

    
    private func addTaskToAppropriateColumn(taskId: UUID) {
        // If no project/release is selected, add to default "Today" column
        if selectedProject == nil || selectedRelease == nil {
            if let todayColumn = noteStore.columns.first(where: { $0.title == "Today" }) {
                var mutableColumn = todayColumn
                mutableColumn.noteIds.append(taskId)
                noteStore.updateColumn(mutableColumn)
            }
            return
        }
        
        // Get columns for the selected release
        guard let selectedRelease = selectedRelease else { return }
        let releaseColumns = noteStore.getColumnsForRelease(selectedRelease)
        
        // Add to "Today" column of the selected release if available
        if let todayColumn = releaseColumns.first(where: { $0.title == "Today" }) {
            var mutableColumn = todayColumn
            mutableColumn.noteIds.append(taskId)
            noteStore.updateColumn(mutableColumn)
        } else if let firstColumn = releaseColumns.first {
            // If no "Today" column, add to first available column
            var mutableColumn = firstColumn
            mutableColumn.noteIds.append(taskId)
            noteStore.updateColumn(mutableColumn)
        }
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
                        .onAppear {
                            // Show confetti animation when task is completed
                            let confettiController = ConfettiWindowController()
                            confettiController.showConfetti()
                            // Custom duration
confettiController.showConfetti(duration: 5.0)
                        }
                    
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
                            if let nextNote = noteStore.getFilteredPendingNotes(selectedProject: selectedProject, selectedRelease: selectedRelease).first {
                                TickSoundService.shared.startTicking(interval: 15.0)
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
            let newId = UUID()
            let mediaToSave = (showMediaPicker && taskMediaContent.hasContent) ? taskMediaContent : nil
            
            noteStore.addNote(
                id: newId,
                title: newNoteTitle,
                content: "",
                category: .today,
                mediaContent: mediaToSave
            )
            
            // Add task to appropriate column based on selected project/release
            addTaskToAppropriateColumn(taskId: newId)
            
            resetTaskForm()
            isAddingNote = false
            focusOnNewNote()
            updateTaskData() // Refresh task data
            firstNote = findFirstNote()
        }
    }
    
    private func createScheduledTask() {
        if !newNoteTitle.isEmpty {
            let imageData = selectedImage?.tiffRepresentation
            let newId = UUID()
            let mediaToSave = (showMediaPicker && taskMediaContent.hasContent) ? taskMediaContent : nil
            
            noteStore.addScheduledNote(
                id: newId,
                title: newNoteTitle,
                description: taskDescription.isEmpty ? nil : taskDescription,
                scheduledDate: scheduledDate,
                scheduledTime: scheduledTime,
                priority: taskPriority,
                estimatedTime: estimatedTime.isEmpty ? nil : estimatedTime,
                reminderMinutes: reminderMinutes,
                imageData: imageData, // Keep for backward compatibility
                mediaContent: mediaToSave,
                category: .today
            )
            
            // Add task to appropriate column based on selected project/release
            addTaskToAppropriateColumn(taskId: newId)
            
            resetTaskForm()
            isAddingNote = false
            updateTaskData() // Refresh task data
            firstNote = findFirstNote()
        }
    }
    
    private func resetTaskForm() {
        newNoteTitle = ""
        estimatedTime = "00:00"
        taskDescription = ""
        scheduledDate = Date()
        scheduledTime = Date()
        taskPriority = .medium
        reminderMinutes = 15
        selectedImage = nil
        selectedTaskTab = .regular
        
        // Only reset media content if media picker is enabled
        if showMediaPicker {
            taskMediaContent = MediaContent()
        }
    }
    
    // Note: showImagePicker() method removed as we now use MediaPickerView
    
    private func focusOnNewNote() {
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isFocused = true
        }
        isAddingNote = true
        newNoteTitle = ""
        estimatedTime = "00:00"
    }
}

// MARK: - Modern Completed Task Row
struct ModernCompletedTaskRow: View {
    let note: Note
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion status indicator
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.green.opacity(isHovered ? 1.0 : 0.8))
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                
                // Task content
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(isHovered ? 0.9 : 0.7))
                        .lineLimit(2)
                        .strikethrough(true, color: .green.opacity(0.6))
                    

                }
            }
            
            Spacer()
            
            // Time and media indicators
            HStack(spacing: 6) {
                // Media indicator
                if note.mediaContent.hasContent {
                    mediaIndicator
                } else if note.imageData != nil {
                    // Backward compatibility
                    Image(systemName: "photo.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.blue.opacity(0.6))
                        .padding(3)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                
                // Time badge
                if let actualTime = note.actualTime {
                    modernTimeLabel(actualTime)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(modernRowBackground)
        .cornerRadius(8)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    
    private var mediaIndicator: some View {
        Group {
            switch note.mediaContent.type {
            case .image:
                Image(systemName: "photo.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.blue.opacity(0.6))
            case .emoji:
                if let emoji = note.mediaContent.emoji {
                    Text(emoji)
                        .font(.system(size: 10))
                }
            case .none:
                EmptyView()
            }
        }
        .padding(3)
        .background(
            Circle()
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    private var modernRowBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                isHovered ?
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#2C2C2E").opacity(0.8),
                        Color(hex: "#262628").opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#232325").opacity(0.6),
                        Color(hex: "#1E1E20").opacity(0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isHovered ?
                        Color.green.opacity(0.2) :
                        Color.white.opacity(0.03),
                        lineWidth: 0.5
                    )
            )
    }
    
    private func modernTimeLabel(_ actualTime: TimeInterval) -> some View {
        let seconds = Int(actualTime)
        let minutes = seconds / 60
        let hours = minutes / 60
        
        let displayText: String
        if hours > 0 {
            displayText = "\(hours)h \(minutes % 60)m"
        } else if minutes > 0 {
            displayText = "\(minutes)m"
        } else {
            displayText = "\(seconds)s"
        }
        
        return HStack(spacing: 3) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: 8))
                .foregroundColor(.blue.opacity(0.7))
            
            Text(displayText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.blue.opacity(0.8))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 0.5)
                )
        )
    }
    
    private func formatCompletedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Legacy Completed Task Row (for backward compatibility)
struct CompletedTaskRow: View {
    let note: Note
    
    var body: some View {
        ModernCompletedTaskRow(note: note)
    }
}

/*
 * SYNCHRONIZED TIMER SYSTEM IMPLEMENTATION
 * 
 * 🎯 Overview:
 * This TaskRowView now uses a centralized timer system through noteStore instead of local timers.
 * This ensures perfect synchronization between FloatingSidebarView and FocusCardView.
 * 
 * 🔄 Key Changes:
 * - Removed local @State timer and elapsedTime variables
 * - All timer operations go through noteStore centralized system
 * - Timer display reads from noteStore.getTotalElapsedTimeForActiveTask()
 * - Break times use noteStore.getCurrentSessionDuration()
 * - Task completion uses noteStore.completeCurrentTask()
 * 
 * 📊 Synchronization Benefits:
 * - FloatingSidebarView and FocusCardView show identical timer values
 * - Timer state is preserved when switching between views
 * - Professional logging for debugging timer operations
 * - Consistent timer behavior across the entire application
 * 
 * 🔧 Technical Implementation:
 * - Timer starts automatically for first note if no active timer
 * - Centralized break/resume operations through noteStore
 * - Proper timer cleanup when tasks are skipped/deleted
 * - Real-time updates across all UI components
 */

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
    @State private var isHovered = false
    @State private var editableTitle: String = ""
    @State private var hoveredButton: String? = nil
    @State private var tickCounter: Int = 0
    
    // Use centralized noteStore timer system - no local timer needed
    
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


            // Start centralized timer for first note if not already running
            if firstNote?.id == note.id && noteStore.activeTimerNote?.id != note.id {
                print("▶️ [Sidebar] Starting centralized timer for: \(note.title)")
                noteStore.startTimer(for: note)
            }
            
            // Start tick sound for first note
            if firstNote?.id == note.id {
                TickSoundService.shared.startTicking(interval: 15.0)
            }
        }
        .onDisappear {
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
            VStack{

            
            Text(note.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
HStack{


            if !isBreak {
                // Done button
                TaskActionButton(
                    icon: "checkmark.circle.fill",
                    label: "Done",
                    isHovered: hoveredButton == "done",
                    color: Color(hex: "#4CAF50"),
                    action: {
                        // Use centralized timer system
                        let elapsedTime = noteStore.getTotalElapsedTimeForActiveTask()
                        
                        // Complete the task using centralized system
                        noteStore.completeCurrentTask()
                        
                        // Stop the tick sound when marking a task as done
                        if firstNote?.id == note.id {
                            TickSoundService.shared.stopTicking()
                        }
                        
                        onDone(elapsedTime)
                        
                        // Show confetti animation
                        let confettiController = ConfettiWindowController()
                        confettiController.showConfetti()
                        
                        print("✅ [Sidebar] Task completed: \(note.title) in \(formatTime(elapsedTime))")
                    },
                    onHover: { isHovering in
                        hoveredButton = isHovering ? "done" : nil
                    }
                )
                // .tooltip("Mark task as completed", arrowPosition: .bottom)
                
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
                        // Use centralized break system
                        noteStore.startBreakForCurrentTimer()
                        isBreak = true
                        
                        // Stop the tick sound during break
                        if firstNote?.id == note.id {
                            TickSoundService.shared.stopTicking()
                        }
                        
                        print("☕ [Sidebar] Break started for: \(note.title)")
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
                        print("⏭️ [Sidebar] Task skipped: \(note.title)")
                        
                        // Only handle skip if this is the first note (active timer)
                        if let firstNote = firstNote, note.id == firstNote.id {
                            // Stop current timer
                            noteStore.stopCurrentTimer()
                            
                            // Trigger skip animation
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isSkipping = true
                            }
 
                            // Delay the actual reordering to allow animation to complete
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                noteStore.moveNoteToEnd(note)

                                // Reset the animation state
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isSkipping = false
                                }
                            }
                            
                            // Call onSkip with the skipped note
                            onSkip(note)
                        } else {
                            // For non-first notes, just move to end without animation
                            noteStore.moveNoteToEnd(note)
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
                        print("🗑️ [Sidebar] Task deleted: \(note.title)")
                        
                        // Stop timer if this is the active task
                        if firstNote?.id == note.id {
                            noteStore.stopCurrentTimer()
                        }
                        
                        noteStore.deleteNote(id: note.id)
                        onSkip(note)
                    },
                    onHover: { isHovering in
                        hoveredButton = isHovering ? "delete" : nil
                    }
                )
            } else {
                breakModeView
            }
}
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
            
            // Use centralized break timer from noteStore
            Text(formatTime(noteStore.getCurrentSessionDuration()))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            
            TaskActionButton(
                icon: "arrow.right.circle",
                label: "Resume",
                isHovered: hoveredButton == "resume",
                color: Color(hex: "#4CAF50"),
                action: {
                    // Use centralized break system
                    noteStore.endBreakForCurrentTimer()
                    isBreak = false
                    
                    // Resume the tick sound when returning from break
                    if firstNote?.id == note.id {
                        TickSoundService.shared.startTicking(interval: 15.0)
                    }
                    
                    print("▶️ [Sidebar] Break ended, resuming: \(note.title)")
                },
                onHover: { isHovering in
                    hoveredButton = isHovering ? "resume" : nil
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
            // Media indicator (small)
            if note.mediaContent.hasContent {
                VStack {
                    switch note.mediaContent.type {
                    case .image:
                        if let imageData = note.mediaContent.imageData, let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                        }
                    case .emoji:
                        if let emoji = note.mediaContent.emoji {
                            Text(emoji)
                                .font(.system(size: 16))
                                .frame(width: 24, height: 24)
                        }
                    case .none:
                        EmptyView()
                    }
                }
            } else if let imageData = note.imageData, let nsImage = NSImage(data: imageData) {
                // Backward compatibility
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            }
            
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
        .tooltip(note.title, arrowPosition: .bottom)
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
            
            // Use centralized timer from noteStore
            Text(formatTime(noteStore.getTotalElapsedTimeForActiveTask()))
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
        .cornerRadius(55)
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

// MARK: - Scheduled Task Row View
struct ScheduledTaskRowView: View {
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
    
    var body: some View {
        VStack {
            if !isNotes && isHovered && firstNote?.id == note.id {
                actionButtonsView
            } else {
                if isBreak {
                    breakModeView
                } else {
                    scheduledTaskView
                }
            }

            if isNotes {
                NotePadTextEditorView(noteStore: noteStore, isNoteIcon: $isNotes)
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
                } else {
                    breakTime += 1
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .offset(x: isSkipping ? -NSScreen.main!.frame.width : 0)
        .opacity(isSkipping ? 0 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSkipping)
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            Text(note.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
                .lineLimit(3)
                .tooltip(note.title, arrowPosition: .bottom)
HStack{


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
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isSkipping = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            noteStore.moveNoteToEnd(note)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isSkipping = false
                            }
                        }
                        
                        onSkip(note)
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
                isHovered: hoveredButton == "resume",
                color: Color(hex: "#4CAF50"),
                action: {
                    isBreak = false
                    breakTime = 0
                },
                onHover: { isHovering in
                    hoveredButton = isHovering ? "resume" : nil
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
    
    private var scheduledTaskView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Priority indicator
                VStack {
                    Image(systemName: note.priority.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(note.priority.color)
                    
                    Text(note.priority.rawValue)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(note.priority.color)
                }
                .frame(width: 40)
                
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
                    
                    if let description = note.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 8) {
                        if let scheduledDate = note.scheduledDate,
                           let scheduledTime = note.scheduledTime {
                            Label(formatScheduledDateTime(date: scheduledDate, time: scheduledTime), systemImage: "calendar")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        if let estimatedTime = note.estimatedTime, !estimatedTime.isEmpty {
                            Label("Est: \(estimatedTime)", systemImage: "clock")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer(minLength: 4)
                
                VStack(spacing: 4) {
                    if firstNote?.id == note.id {
                        timerView
                    }
                    
                    // Task media thumbnail
                    if note.mediaContent.hasContent {
                        switch note.mediaContent.type {
                        case .image:
                            if let imageData = note.mediaContent.imageData, let nsImage = NSImage(data: imageData) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                    )
                            }
                        case .emoji:
                            if let emoji = note.mediaContent.emoji {
                                Text(emoji)
                                    .font(.system(size: 24))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(hex: "#2C2C2E"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                            )
                                    )
                            }
                        case .none:
                            EmptyView()
                        }
                    } else if let imageData = note.imageData, let nsImage = NSImage(data: imageData) {
                        // Backward compatibility for old image data
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    }
                }
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
                            firstNote?.id == note.id ? Color(hex: "#2A4A2D") : Color(hex: "#2C2C2E"),
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
                                    gradient: Gradient(colors: [Color(hex: "#4CAF50").opacity(0.4), Color(hex: "#45A049").opacity(0.3)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ) : 
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#4CAF50").opacity(0.2), Color(hex: "#45A049").opacity(0.1)]),
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
    
    private func formatScheduledDateTime(date: Date, time: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let dateFormatter = DateFormatter()
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        if calendar.isDateInToday(date) {
            return "Today \(timeFormatter.string(from: time))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow \(timeFormatter.string(from: time))"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            dateFormatter.dateFormat = "EEE"
            return "\(dateFormatter.string(from: date)) \(timeFormatter.string(from: time))"
        } else {
            dateFormatter.dateStyle = .short
            return "\(dateFormatter.string(from: date)) \(timeFormatter.string(from: time))"
        }
    }
    
    private func saveTitle() {
        if editableTitle != note.title {
            var updatedNote = note
            updatedNote.title = editableTitle
            noteStore.updateNote(updatedNote)
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


#Preview {
    FloatingSidebarView(controller: FloatingSidebarController(), onClose: {})
}
