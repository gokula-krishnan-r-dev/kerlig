import SwiftUI

struct TaskManagementView: View {
    @StateObject private var noteStore = NoteStore()
    
    // Project management states
    @State private var selectedProject: Project?
    @State private var selectedRelease: Release?
    @State private var isAddingProject = false
    @State private var isAddingRelease = false
    @State private var newProjectTitle = ""
    @State private var newProjectDescription = ""
    @State private var newProjectColor: Color = .blue
    @State private var newReleaseVersion = ""
    @State private var newReleaseName = ""
    @State private var newReleaseDescription = ""
    @State private var newReleaseTargetDate = Date()
    @State private var newProjectLogoImage: NSImage? = nil
    @State private var isShowingImagePicker = false
    
    // UI states
    @State private var isProjectListExpanded = true
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var isCompactMode = false
    @State private var showCompletedTasks = true
    @State private var animateIn = false
    @State private var selectedTab: TabSection = .tasks
    
    // New UI states
    @State private var isReleaseListExpanded = true
    @State private var isColumnsListExpanded = true
    @State private var showDeleteProjectConfirm = false
    @State private var projectToDelete: Project? = nil
    @State private var releaseToDelete: Release? = nil
    @State private var showDeleteReleaseConfirm = false
    
    // New state for better UI responsiveness
    @State private var isLoadingColumns = false
    @State private var taskColumns: [NoteColumn] = []
    @State private var taskColumnNotes: [UUID: [Note]] = [:]
    
    // Animation states for background effects
    @State private var backgroundAnimationPhase: CGFloat = 0
    @State private var patternOpacity: CGFloat = 0.15
    @State private var patternScale: CGFloat = 1.0
    
    // Color palette
    private let primaryBgColor = Color(hex: "#0A0A0B")
    private let secondaryBgColor = Color(hex: "#1C1C1E")
    private let cardBgColor = Color(hex: "#2C2C2E")
    private let accentColor = Color(hex: "#007AFF")
    private let successColor = Color(hex: "#34C759")
    private let warningColor = Color(hex: "#FF9F0A")
    private let errorColor = Color(hex: "#FF3B30")
    
    private let accentGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#007AFF"), Color(hex: "#0056CC")]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    private let availableColors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink,
        Color(hex: "#00BCD4"), Color(hex: "#FF5722"), Color(hex: "#9C27B0")
    ]
    
    // Tab section enum
    enum TabSection: String, CaseIterable {
        case tasks = "Tasks"
        case pages = "Pages"
    }
    
    var filteredProjects: [Project] {
        let filtered = noteStore.projects.filter { !$0.isArchived }
        
        if searchText.isEmpty {
            return filtered.sorted(by: { $0.lastModified > $1.lastModified })
        }
        
        return filtered.filter { project in
            project.title.lowercased().contains(searchText.lowercased()) ||
            project.description.lowercased().contains(searchText.lowercased())
        }.sorted(by: { $0.lastModified > $1.lastModified })
    }
    
    var filteredReleases: [Release] {
        guard let selectedProject = selectedProject else { return [] }
        
        return noteStore.getReleasesForProject(selectedProject)
            .sorted(by: { $0.creationDate > $1.creationDate })
    }
    
    var filteredTasks: [UUID: [Note]] {
        guard let selectedRelease = selectedRelease else { return [:] }
        
        var result = [UUID: [Note]]()
        
        // Use the local taskColumns state for better performance
        for column in taskColumns {
            let columnNotes = taskColumnNotes[column.id] ?? []
            let filteredNotes = columnNotes.filter { note in
                let matchesSearch = searchText.isEmpty ||
                    note.title.lowercased().contains(searchText.lowercased()) ||
                    note.content.lowercased().contains(searchText.lowercased())
                
                let matchesFilter: Bool
                switch selectedFilter {
                case .all:
                    matchesFilter = true
                case .completed:
                    matchesFilter = note.isCompleted
                case .incomplete:
                    matchesFilter = !note.isCompleted
                }
                
                let matchesCompleted = showCompletedTasks || !note.isCompleted
                
                return matchesSearch && matchesFilter && matchesCompleted
            }
            
            result[column.id] = filteredNotes
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern header with dropdowns (only show when project is selected)
            if selectedProject != nil {
                modernHeader
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Main content area
            ZStack {
                // Background with animated pattern
                backgroundView
                
                // Content based on selection state
                if selectedProject == nil {
                    // Project selection view
                    projectSelectionView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Task management view
                    taskManagementView
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(primaryBgColor)
        .onAppear {
            setupInitialState()
            startBackgroundAnimation()
        }
        .onChange(of: selectedProject) { _, newProject in
            handleProjectSelection(newProject)
        }
        .onChange(of: selectedRelease) { _, newRelease in
            handleReleaseSelection(newRelease)
        }
        .sheet(isPresented: $isAddingProject) {
            AddProjectSheetView(
                isAddingProject: $isAddingProject,
                newProjectTitle: $newProjectTitle,
                newProjectDescription: $newProjectDescription,
                newProjectLogoImage: $newProjectLogoImage,
                isShowingImagePicker: $isShowingImagePicker,
                newProjectColor: $newProjectColor,
                availableColors: availableColors,
                resetProjectForm: resetProjectForm,
                createProject: createProject,
                secondaryBgColor: secondaryBgColor,
                handleImageSelection: handleImageSelection,
                cardBgColor: cardBgColor,
                accentColor: accentColor,
                accentGradient: accentGradient
            )
        }
        .sheet(isPresented: $isAddingRelease) {
            addReleaseSheet
        }
    }
    
    // MARK: - Background and Visual Components
    
    private var backgroundView: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#0A0B12"),
                    Color(hex: "#1A1B2E"),
                    Color(hex: "#16213E")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Dynamic pattern overlay
            PatternBackground(phase: backgroundAnimationPhase, scale: patternScale)
                .opacity(patternOpacity)
                .blendMode(.overlay)
        }
        .ignoresSafeArea()
    }
    
    private var modernHeader: some View {
        VStack(spacing: 0) {
            HStack {
                // Back button
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        selectedProject = nil
                        selectedRelease = nil
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Projects")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .hoverEffect(.lift)
                
                Spacer()
                
                // Project and Release dropdowns
                HStack(spacing: 16) {
                    projectDropdown
                    releaseDropdown
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: { isAddingRelease = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14))
                            Text("New Release")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(accentGradient)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showFloatingSidebar() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14))
                            Text("Mac Write")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(successColor)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            
            // Header divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
        }
    }
    
    private func startBackgroundAnimation() {
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: true)) {
            backgroundAnimationPhase = 1.0
        }
        
        withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
            patternScale = 1.2
        }
        
        withAnimation(.easeInOut(duration: 15).repeatForever(autoreverses: true)) {
            patternOpacity = 0.3
        }
    }
    
    // MARK: - Dropdown Components
    
    private var projectDropdown: some View {
        Menu {
            ForEach(filteredProjects, id: \.id) { project in
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        selectedProject = project
                    }
                }) {
                    HStack(spacing: 12) {
                        // Enhanced circular project image
                        if let logoData = project.logoImageData, let nsImage = NSImage(data: logoData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            (project.color ?? .blue).opacity(0.8),
                                            (project.color ?? .blue)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(String(project.title.prefix(1)).uppercased())
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text(project.description)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if selectedProject?.id == project.id {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } label: {
            HStack(spacing: 12) {
                if let project = selectedProject {
                    // Enhanced circular project image for dropdown label
                    if let logoData = project.logoImageData, let nsImage = NSImage(data: logoData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        (project.color ?? .blue).opacity(0.9),
                                        (project.color ?? .blue)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(String(project.title.prefix(1)).uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    
                    Text(project.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "folder")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        )
                    
                    Text("Select Project")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .disabled(filteredProjects.isEmpty)
    }
    
    private var releaseDropdown: some View {
        Menu {
            ForEach(filteredReleases, id: \.id) { release in
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        selectedRelease = release
                    }
                }) {
                    HStack {
                        Image(systemName: release.status.iconName)
                            .foregroundColor(release.status.color)
                        
                        VStack(alignment: .leading) {
                            Text("v\(release.version)")
                                .font(.system(size: 14, weight: .semibold))
                            Text(release.name)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        if selectedRelease?.id == release.id {
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                                .foregroundColor(accentColor)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                if let release = selectedRelease {
                    Image(systemName: release.status.iconName)
                        .foregroundColor(release.status.color)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("v\(release.version)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text(release.name)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                } else {
                    Text("Select Release")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            )
        }
        .disabled(filteredReleases.isEmpty)
    }
    
    // MARK: - Project Selection View
    
    private var projectSelectionView: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Management")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Select a project to get started")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: { isAddingProject = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 16))
                            Text("New Project")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(accentGradient)
                        .cornerRadius(12)
                        .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .hoverEffect(.lift)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 40)
            .padding(.bottom, 32)
            
            // Projects grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 24), count: 3), spacing: 24) {
                    ForEach(Array(filteredProjects.enumerated()), id: \.element.id) { index, project in
                        ProjectCard(
                            project: project,
                            onSelect: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    selectedProject = project
                                }
                            }
                        )
                        .scaleEffect(animateIn ? 1 : 0.8)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateIn)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .clipped()
        }
    }
    
    // MARK: - Setup and Data Management
    private func setupInitialState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) {
                animateIn = true
            }
        }
        
        // Don't auto-select first project anymore - let user choose
        // selectedProject = filteredProjects.first
    }
    
    private func handleProjectSelection(_ project: Project?) {
        guard let project = project else {
            selectedRelease = nil
            clearTaskData()
            return
        }
        
        let releases = noteStore.getReleasesForProject(project)
        selectedRelease = releases.first
    }
    
    private func handleReleaseSelection(_ release: Release?) {
        guard let release = release else {
            clearTaskData()
            return
        }
        
        loadTaskDataForRelease(release)
    }
    
    private func loadTaskDataForRelease(_ release: Release) {
        isLoadingColumns = true
        
        DispatchQueue.main.async {
            // Get columns for the release
            self.taskColumns = self.noteStore.getColumnsForRelease(release)
            
            // If no columns exist, create default ones
            if self.taskColumns.isEmpty {
                self.createDefaultColumnsForRelease(release)
                self.taskColumns = self.noteStore.getColumnsForRelease(release)
            }
            
            // Load notes for each column
            self.taskColumnNotes.removeAll()
            for column in self.taskColumns {
                let columnNotes = self.noteStore.getNotesForColumn(column)
                self.taskColumnNotes[column.id] = columnNotes
            }
            
            self.isLoadingColumns = false
        }
    }
    
    private func clearTaskData() {
        taskColumns.removeAll()
        taskColumnNotes.removeAll()
    }
    
    // MARK: - Task Management View
    private var taskManagementView: some View {
        VStack(spacing: 0) {
            // Tab selector
            tabSelector
            
            // Content based on selected tab
            if selectedTab == .tasks {
                modernTaskBoard
            } else {
                ProjectPagesView(
                    noteStore: noteStore,
                    selectedProject: $selectedProject
                )
            }
        }
    }
    
    private var modernTaskBoard: some View {
        Group {
            if selectedRelease == nil {
                releaseSelectionView
            } else if isLoadingColumns {
                loadingView
            } else if taskColumns.isEmpty {
                emptyColumnsView
            } else {
                modernTaskColumnsView
            }
        }
    }
    
    private var releaseSelectionView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "rocket.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [accentColor, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 8) {
                    Text("Select a Release")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Choose a release version to view and manage tasks")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 16) {
                if !filteredReleases.isEmpty {
                    Text("Available Releases")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        ForEach(filteredReleases, id: \.id) { release in
                            ReleaseCard(
                                release: release,
                                onSelect: {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        selectedRelease = release
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                } else {
                    Button(action: { isAddingRelease = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                            Text("Create First Release")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(accentGradient)
                        .cornerRadius(12)
                        .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .hoverEffect(.lift)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateIn)
    }
    
    private var modernTaskColumnsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 20) {
                ForEach(Array(taskColumns.enumerated()), id: \.element.id) { index, column in
                    ModernColumnView(
                        column: column,
                        notes: filteredTasks[column.id] ?? [],
                        noteStore: noteStore,
                        onRefresh: refreshTaskData
                    )
                    .frame(width: isCompactMode ? 300 : 350)
                    .scaleEffect(animateIn ? 1 : 0.9)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateIn)
                }
                
                // Add column button
                AddColumnButton(onAdd: addNewColumn)
                    .frame(width: isCompactMode ? 300 : 350)
                    .opacity(animateIn ? 0.7 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: animateIn)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
        .background(Color.clear)
    }


    // MARK: - Helper Functions
    func showFloatingSidebar() {
        //before toggle close already existing window close
        if let existingWindow = NSApp.windows.first(where: { $0.isVisible }) {
            existingWindow.close()
        }
        floatingSidebarController.toggleSidebar()
    }
    
    let floatingSidebarController = FloatingSidebarController()
    private func createDefaultColumnsForRelease(_ release: Release) {
        let defaultColumnTitles = ["Backlog", "In Progress", "Today", "Review", "Done", "Cancelled"]
        let defaultColors: [Color] = [.blue, .orange, .purple, .green, .red, .gray]
        
        var newColumnIds: [UUID] = []
        
        for (index, title) in defaultColumnTitles.enumerated() {
            let newColumn = NoteColumn(
                title: title,
                order: index,
                color: defaultColors[index]
            )
            noteStore.columns.append(newColumn)
            newColumnIds.append(newColumn.id)
        }
        
        // Update release with column IDs
        if let releaseIndex = noteStore.releases.firstIndex(where: { $0.id == release.id }) {
            var updatedRelease = release
            updatedRelease.columnIds = newColumnIds
            noteStore.releases[releaseIndex] = updatedRelease
            noteStore.updateRelease(updatedRelease)
        }
        
        // Save columns
        for column in noteStore.columns {
            noteStore.updateColumn(column)
        }
    }
    



    
    // Helper function to get project title for a release
    private func getProjectTitle(for release: Release) -> String {
        if let project = noteStore.projects.first(where: { $0.id == release.projectId }) {
            return project.title
        }
        return "Unknown Project"
    }
    
    // Delete project function
    private func deleteProject(_ project: Project) {
        // First delete all releases associated with this project
        let projectReleases = noteStore.getReleasesForProject(project)
        for release in projectReleases {
            noteStore.deleteRelease(release)
        }
        
        // Then delete the project itself
        noteStore.deleteProject(project)
        
        // Update selection if needed
        if selectedProject?.id == project.id {
            selectedProject = noteStore.projects.first
            selectedRelease = nil
        }
    }
    
    // Delete release function
    private func deleteRelease(_ release: Release) {
        noteStore.deleteRelease(release)
        
        // Update selection if needed
        if selectedRelease?.id == release.id {
            if let project = selectedProject {
                let releases = noteStore.getReleasesForProject(project)
                selectedRelease = releases.first
            }
        }
    }
    
    private func addQuickTask() {
        guard let release = selectedRelease,
              let firstColumn = taskColumns.first else { return }
        
        let newNote = Note(
            title: "New Task",
            content: "Task description",
            category: .today
        )
        
        // Add note to store
        noteStore.notes.append(newNote)
        
        // Add note to first column
        if let columnIndex = noteStore.columns.firstIndex(where: { $0.id == firstColumn.id }) {
            var updatedColumn = noteStore.columns[columnIndex]
            updatedColumn.noteIds.append(newNote.id)
            noteStore.columns[columnIndex] = updatedColumn
            noteStore.updateColumn(updatedColumn)
        }
        
        noteStore.saveNotes()
        
        // Refresh task data
        loadTaskDataForRelease(release)
    }
    
    private func refreshTaskData() {
        guard let release = selectedRelease else { return }
        loadTaskDataForRelease(release)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
            
            Text("Loading task columns...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
    
    private var emptyColumnsView: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Task Columns")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Create default columns to start organizing tasks")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                if let release = selectedRelease {
                    createDefaultColumnsForRelease(release)
                    loadTaskDataForRelease(release)
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Default Columns")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(accentGradient)
                .cornerRadius(24)
                .shadow(color: accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .hoverEffect(.lift)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
    }
    
    private func addNewColumn() {
        guard let release = selectedRelease else { return }
        
        // Create a simple dialog for column creation
        let alert = NSAlert()
        alert.messageText = "Create New Column"
        alert.informativeText = "Enter a name for your new task column:"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputTextField.placeholderString = "Column name"
        alert.accessoryView = inputTextField
        
        // Show the alert
        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    let columnTitle = inputTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !columnTitle.isEmpty {
                        self.createNewColumn(title: columnTitle)
                    }
                }
            }
        } else {
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let columnTitle = inputTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if !columnTitle.isEmpty {
                    createNewColumn(title: columnTitle)
                }
            }
        }
    }
    
    private func createNewColumn(title: String) {
        guard let release = selectedRelease else { return }
        
        let newColumn = NoteColumn(
            title: title,
            order: taskColumns.count,
            color: availableColors.randomElement() ?? .blue
        )
        
        // Add to noteStore
        noteStore.columns.append(newColumn)
        noteStore.updateColumn(newColumn)
        
        // Update release with new column ID
        if let releaseIndex = noteStore.releases.firstIndex(where: { $0.id == release.id }) {
            var updatedRelease = release
            updatedRelease.columnIds.append(newColumn.id)
            noteStore.releases[releaseIndex] = updatedRelease
            noteStore.updateRelease(updatedRelease)
        }
        
        // Refresh local data with animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            loadTaskDataForRelease(release)
        }
    }
    

    private var addReleaseSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Release")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Cancel") {
                    isAddingRelease = false
                    resetReleaseForm()
                }
                .foregroundColor(.gray)
            }
            .padding()
            .background(secondaryBgColor)
            
            // Form
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Version")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("1.0.0", text: $newReleaseVersion)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(cardBgColor)
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Release Name")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Beta Release", text: $newReleaseName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(cardBgColor)
                            .cornerRadius(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Enter release description", text: $newReleaseDescription, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .background(cardBgColor)
                        .cornerRadius(8)
                        .frame(minHeight: 80)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Date (Optional)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    DatePicker("", selection: $newReleaseTargetDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .colorScheme(.dark)
                        .padding()
                        .background(cardBgColor)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    createRelease()
                }) {
                    Text("Create Release")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentGradient)
                        .cornerRadius(8)
                        .shadow(color: accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(AnimatedButtonStyle())
                .disabled(newReleaseVersion.isEmpty || newReleaseName.isEmpty)
                .opacity((newReleaseVersion.isEmpty || newReleaseName.isEmpty) ? 0.6 : 1)
            }
            .padding()
        }
        .background(secondaryBgColor)
        .frame(width: 500)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func handleImageSelection(_ result: Result<[URL], Error>) {
        do {
            let selectedFiles = try result.get()
            if let selectedFile = selectedFiles.first {
                if let image = NSImage(contentsOf: selectedFile) {
                    newProjectLogoImage = image
                }
            }
        } catch {
            print("Error selecting image: \(error.localizedDescription)")
        }
    }
    
    private func createProject() {
        guard !newProjectTitle.isEmpty && !newProjectDescription.isEmpty else { return }
        
        // Convert NSImage to Data if available
        var logoImageData: Data? = nil
        if let logoImage = newProjectLogoImage {
            logoImageData = logoImage.tiffRepresentation
        }
        
        let newProject = Project(
            title: newProjectTitle,
            description: newProjectDescription,
            color: newProjectColor,
            logoImageData: logoImageData
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            noteStore.addProject(title: newProjectTitle, description: newProjectDescription)
            
            // Update the project with color and logo
            if let index = noteStore.projects.firstIndex(where: { $0.title == newProjectTitle }) {
                var project = noteStore.projects[index]
                project.color = newProjectColor
                project.logoImageData = logoImageData
                noteStore.updateProject(project)
                selectedProject = project
                
                // Create default page for the project
                noteStore.createDefaultPageForProject(project)
            }
            
            isAddingProject = false
            resetProjectForm()

            //reload the data
            refreshTaskData()
        }
    }
    
    private func createRelease() {
        guard let selectedProject = selectedProject,
              !newReleaseVersion.isEmpty && !newReleaseName.isEmpty else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            noteStore.addRelease(
                projectId: selectedProject.id,
                version: newReleaseVersion,
                name: newReleaseName,
                description: newReleaseDescription,
                targetDate: newReleaseTargetDate
            )
            
            // Auto-select the new release
            let newReleases = noteStore.getReleasesForProject(selectedProject)
            if let newRelease = newReleases.first(where: { $0.version == newReleaseVersion }) {
                selectedRelease = newRelease
                // This will trigger handleReleaseSelection and load task data
            }
            
            isAddingRelease = false
            resetReleaseForm()

        }
    }
    
    private func resetProjectForm() {
        newProjectTitle = ""
        newProjectDescription = ""
        newProjectColor = .blue
        newProjectLogoImage = nil
    }
    
    private func resetReleaseForm() {
        newReleaseVersion = ""
        newReleaseName = ""
        newReleaseDescription = ""
        newReleaseTargetDate = Date()
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(TabSection.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? accentColor : Color.clear)
                            .frame(height: 3)
                            .animation(.easeInOut(duration: 0.3), value: selectedTab)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                .hoverEffect(.lift)
            }
            
                        Spacer()
        }
        .background(.ultraThinMaterial)

        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.1))
                .offset(y: 1),
            alignment: .bottom
        )
    }
}

#Preview {
    TaskManagementView()
    .environmentObject(AppState())
} 

