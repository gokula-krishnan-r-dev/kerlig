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
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Modern header with dropdowns (only show when project is selected)
                if selectedProject != nil {
                    modernHeader
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            )
                        )
                        .zIndex(1)
                }
                
                // Main content area with responsive layout
                ZStack {
                    // Content based on selection state
                    if selectedProject == nil {
                        // Project selection view
                        projectSelectionView
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.9, anchor: .center)
                                        .combined(with: .opacity)
                                        .combined(with: .move(edge: .bottom)),
                                    removal: .scale(scale: 1.1, anchor: .center)
                                        .combined(with: .opacity)
                                        .combined(with: .move(edge: .top))
                                )
                            )
                    } else {
                        // Task management view
                        taskManagementView
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.95, anchor: .top)
                                        .combined(with: .opacity)
                                        .combined(with: .move(edge: .bottom)),
                                    removal: .scale(scale: 0.9, anchor: .center)
                                        .combined(with: .opacity)
                                        .combined(with: .move(edge: .bottom))
                                )
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            setupInitialState()
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

    private var modernHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 20) {
                // Back button with improved styling
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        selectedProject = nil
                        selectedRelease = nil
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.12))
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .hoverEffect(.lift)
                
                // Project and Release dropdowns with better spacing
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Project")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        projectDropdown
                            .frame(minWidth: 200)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Release")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        releaseDropdown
                            .frame(minWidth: 180)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Action buttons with proper backgrounds and improved styling
                HStack(spacing: 12) {
                    Button(action: { isAddingRelease = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("New Release")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [accentColor, accentColor.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .hoverEffect(.lift)
                    
                    Button(action: { showFloatingSidebar() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 16))
                            Text("Mac Write")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [successColor, successColor.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: successColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .hoverEffect(.lift)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
            .background(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 1)
                    .offset(y: 1),
                alignment: .bottom
            )
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
        ProjectDropdown(
            selectedProject: Binding(
                get: { selectedProject?.toDropdownItem() },
                set: { dropdownItem in
                    selectedProject = dropdownItem?.toProject(from: filteredProjects)
                }
            ),
            projects: filteredProjects.map { $0.toDropdownItem() },
            accentColor: accentColor,
            placeholder: "Select Project"
        )
    }
    
    private var releaseDropdown: some View {
        ReleaseDropdown(
            selectedRelease: Binding(
                get: { selectedRelease?.toDropdownItem() },
                set: { dropdownItem in
                    selectedRelease = dropdownItem?.toRelease(from: filteredReleases)
                }
            ),
            releases: filteredReleases.map { $0.toDropdownItem() },
            accentColor: accentColor,
            placeholder: "Select Release"
        )
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

                    
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 40)
            .padding(.bottom, 32)
            
            // Projects table view
            ProjectListView(
                onSelectProject: { project in
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        selectedProject = project
                    }
                },
                onAddProject: {
                    isAddingProject = true
                }
            )
            .environmentObject(noteStore)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
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
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: isCompactMode ? 16 : 24) {
                    ForEach(Array(taskColumns.enumerated()), id: \.element.id) { index, column in
                        ModernColumnView(
                            column: column,
                            notes: filteredTasks[column.id] ?? [],
                            noteStore: noteStore,
                            onRefresh: refreshTaskData
                        )
                        .frame(width: dynamicColumnWidth(for: geometry))
                        .scaleEffect(animateIn ? 1 : 0.95)
                        .opacity(animateIn ? 1 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(index) * 0.08),
                            value: animateIn
                        )
                    }
                    
                    // Add column button with improved styling
                    AddColumnButton(onAdd: addNewColumn)
                        .frame(width: dynamicColumnWidth(for: geometry))
                        .opacity(animateIn ? 0.8 : 0)
                        .animation(
                            .easeOut(duration: 0.5)
                            .delay(Double(taskColumns.count) * 0.08 + 0.2),
                            value: animateIn
                        )
                }
                .padding(.horizontal, adaptivePadding(for: geometry))
                .padding(.vertical, 20)
            }
        }
        .background(Color.clear)
    }
    
    // MARK: - Responsive Layout Helpers
    
    private func dynamicColumnWidth(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let availableWidth = screenWidth - (adaptivePadding(for: geometry) * 2)
        let numberOfColumns = taskColumns.count + 1 // +1 for add button
        
        if isCompactMode {
            return min(280, max(240, availableWidth / CGFloat(min(numberOfColumns, 4))))
        } else {
            let idealWidth: CGFloat = 340
            let minWidth: CGFloat = 300
            let maxColumnsVisible = Int(availableWidth / minWidth)
            
            if numberOfColumns <= maxColumnsVisible {
                return min(idealWidth, availableWidth / CGFloat(numberOfColumns))
            } else {
                return max(minWidth, idealWidth)
            }
        }
    }
    
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        if screenWidth < 1200 {
            return 20
        } else if screenWidth < 1600 {
            return 28
        } else {
            return 36
        }
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

// MARK: - Extensions for Dropdown Integration

extension Project {
    func toDropdownItem() -> ProjectDropdownItem {
        return ProjectDropdownItem(
            id: self.id.uuidString,
            title: self.title,
            description: self.description,
            logoImageData: self.logoImageData,
            color: self.color
        )
    }
}

extension ProjectDropdownItem {
    func toProject(from projects: [Project]) -> Project? {
        return projects.first { $0.id.uuidString == self.id }
    }
}

extension Release {
    func toDropdownItem() -> ReleaseDropdownItem {
        return ReleaseDropdownItem(
            id: self.id.uuidString,
            version: self.version,
            name: self.name,
            status: self.status.toDropdownStatus()
        )
    }
}

extension ReleaseDropdownItem {
    func toRelease(from releases: [Release]) -> Release? {
        return releases.first { $0.id.uuidString == self.id }
    }
}

extension ReleaseStatus {
    func toDropdownStatus() -> DropdownReleaseStatus {
        return DropdownReleaseStatus(iconName: self.iconName, color: self.color)
    }
} 

