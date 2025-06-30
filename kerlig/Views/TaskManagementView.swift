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
        HStack(spacing: 0) {
            // Left sidebar with projects and releases
            leftSidebar
            
            // Main content area with task columns or pages
            VStack(spacing: 0) {

                headerView
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                if selectedTab == .tasks {
                    mainContent
                } else {
                    ProjectPagesView(
                        noteStore: noteStore,
                        selectedProject: $selectedProject
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(primaryBgColor)
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
    
    // MARK: - Setup and Data Management
    private func setupInitialState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) {
                animateIn = true
            }
        }
        
        // Auto-select first project if available
        if selectedProject == nil {
            selectedProject = filteredProjects.first
        }
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


    private var headerView: some View {

    
    func showFloatingSidebar() {


        //before toggle close already existing window close
        if let existingWindow = NSApp.windows.first(where: { $0.isVisible }) {
            existingWindow.close()
        }
        floatingSidebarController.toggleSidebar()
    }
        
    let floatingSidebarController = FloatingSidebarController()
        return VStack(spacing: 0) {
        HStack {
            // Title and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text("Task Management")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let project = selectedProject {
                    Text(project.title)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text("Select a project to get started")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {

                // Add task button
                Button(action: {showFloatingSidebar()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                        Text("Mac Write")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(selectedRelease == nil)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(primaryBgColor)
        
        // Divider
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 1)
    }
    }
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
    
    // MARK: - Left Sidebar
    
    private var leftSidebar: some View {
        VStack(spacing: 0) {
            // Header
            sidebarHeader
            
            // Search bar
            searchBar
            
            // Projects list
            projectsList
            
            // Releases section
            if selectedProject != nil {
                releasesSection
            }
        }
        .frame(width: 350)
        .background(secondaryBgColor)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.gray.opacity(0.2))
                .offset(x: 1),
            alignment: .trailing
        )
    }
    
    private var sidebarHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Task Management")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(filteredProjects.count) projects")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                isAddingProject = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("New Project")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor)
                        .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(AnimatedButtonStyle())
            .scaleEffect(animateIn ? 1 : 0.8)
            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: animateIn)
        }
        .padding()
        .background(Color(hex: "#1C1C1E"))
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -20)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 14))
            
            TextField("Search projects and tasks...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(10)
        .background(cardBgColor)
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -10)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)
    }
    
    private var projectsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Projects header
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isProjectListExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isProjectListExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("PROJECTS")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(filteredProjects.count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Projects list
            if isProjectListExpanded {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(zip(filteredProjects.indices, filteredProjects)), id: \.1.id) { index, project in
                            ProjectRowView(
                                project: project,
                                isSelected: selectedProject?.id == project.id,
                                onSelect: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedProject = project
                                    }
                                },
                                onDelete: {
                                    deleteProject(project)
                                }
                            )
                            .opacity(animateIn ? 1 : 0)
                            .offset(x: animateIn ? 0 : -20)
                            .animation(.easeOut(duration: 0.4).delay(0.3 + Double(index) * 0.05), value: animateIn)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            
            // All releases list (not filtered by project)
            allReleasesList
        }
    }
    
    private var allReleasesList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Releases header
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isReleaseListExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isReleaseListExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("ALL RELEASES")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(noteStore.releases.count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.05))
            
            if isReleaseListExpanded && !noteStore.releases.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(noteStore.releases.sorted(by: { $0.creationDate > $1.creationDate })) { release in
                            let project = noteStore.projects.first(where: { $0.id == release.projectId })
                            ReleaseRowView(
                                release: release,
                                projectTitle: getProjectTitle(for: release),
                                isSelected: selectedRelease?.id == release.id,
                                onSelect: {
                                    // Find and select the project first
                                    if let project = noteStore.projects.first(where: { $0.id == release.projectId }) {
                                        selectedProject = project
                                        // Then select the release
                                        selectedRelease = release
                                    }
                                },
                                onDelete: {
                                    deleteRelease(release)
                                },
                                projectLogoData: project?.logoImageData
                            )
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 200)
            }
            
            // Task columns list (for selected release)
            if let release = selectedRelease {
                taskColumnsList(for: release)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.5), value: animateIn)
    }
    
    private func taskColumnsList(for release: Release) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Columns header
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isColumnsListExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isColumnsListExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("TASK COLUMNS")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if isLoadingColumns {
                            ProgressView()
                                .scaleEffect(0.7)
                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        } else {
                            Text("\(taskColumns.count)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.05))
            
            if isColumnsListExpanded {
                if isLoadingColumns {
                    HStack {
                        Spacer()
                        ProgressView("Loading columns...")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding()
                } else if !taskColumns.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(taskColumns.sorted(by: { $0.order < $1.order })) { column in
                                EnhancedColumnRowView(
                                    column: column,
                                    taskCount: taskColumnNotes[column.id]?.count ?? 0
                                )
                                .padding(.horizontal, 8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 200)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.3.group")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No columns available")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            createDefaultColumnsForRelease(release)
                            loadTaskDataForRelease(release)
                        }) {
                            Text("Create Default Columns")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(accentColor)
                                .cornerRadius(12)
                        }
                        .buttonStyle(AnimatedButtonStyle())
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.6), value: animateIn)
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
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Main header
            mainHeader
            
            // Task board
            if selectedRelease != nil {
                taskBoard
            } else {
                emptyStateView
            }
        }
    }
    
    private var mainHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let project = selectedProject {
                    HStack(spacing: 12) {
                        // Project logo
                        if let logoData = project.logoImageData, let nsImage = NSImage(data: logoData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        } else {
                            Circle()
                                .fill(project.color ?? .blue)
                                .frame(width: 32, height: 32)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            if let release = selectedRelease {
                                HStack(spacing: 8) {
                                    Image(systemName: release.status.iconName)
                                        .foregroundColor(release.status.color)
                                        .font(.system(size: 12))
                                    
                                    Text("v\(release.version)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(release.status.color)
                                    
                                    Text("•")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 10))
                                    
                                    Text(release.name)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    
                                    if !taskColumns.isEmpty {
                                        Text("•")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 10))
                                        
                                        Text("\(taskColumns.count) columns")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                            } else {
                                Text("No release selected")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                } else {
                    Text("Select a Project")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Action buttons and controls
            HStack(spacing: 12) {
                // Quick add task button
                if selectedRelease != nil && !taskColumns.isEmpty {
                    Button(action: {
                        addQuickTask()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("Quick Task")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(accentGradient)
                        .cornerRadius(8)
                    }
                    .buttonStyle(AnimatedButtonStyle())
                }
                
                // Refresh button
                Button(action: {
                    refreshTaskData()
                }) {
                    Image(systemName: isLoadingColumns ? "arrow.clockwise" : "arrow.clockwise")
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(cardBgColor)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Refresh task data")
                .disabled(isLoadingColumns)
                
                // Filter menu
                Menu {
                    Button(action: { selectedFilter = .all }) {
                        HStack {
                            Text("All Tasks")
                            if selectedFilter == .all {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button(action: { selectedFilter = .completed }) {
                        HStack {
                            Text("Completed Tasks")
                            if selectedFilter == .completed {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button(action: { selectedFilter = .incomplete }) {
                        HStack {
                            Text("Incomplete Tasks")
                            if selectedFilter == .incomplete {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        withAnimation {
                            showCompletedTasks.toggle()
                        }
                    }) {
                        HStack {
                            Text("Show Completed Tasks")
                            Spacer()
                            Image(systemName: showCompletedTasks ? "checkmark.square" : "square")
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 14))
                        Text(selectedFilter.rawValue)
                            .font(.system(size: 14))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(cardBgColor)
                    .cornerRadius(8)
                }
                
                // Compact mode toggle
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isCompactMode.toggle()
                    }
                }) {
                    Image(systemName: isCompactMode ? "arrow.left.and.right.square" : "arrow.up.and.down.square")
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(cardBgColor)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .help(isCompactMode ? "Expand columns" : "Compact columns")
            }
        }
        .padding()
        .background(secondaryBgColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2))
                .offset(y: 1),
            alignment: .bottom
        )
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -10)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)
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
    
    private var taskBoard: some View {
        Group {
            if isLoadingColumns {
                loadingView
            } else if taskColumns.isEmpty {
                emptyColumnsView
            } else {
                taskColumnsView
            }
        }
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
        .background(primaryBgColor)
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
                
                Text("Create your first release to start organizing tasks")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            if selectedProject != nil && selectedRelease == nil {
                Button(action: {
                    isAddingRelease = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create First Release")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(accentGradient)
                    .cornerRadius(24)
                    .shadow(color: accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(AnimatedButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
    }
    
    private var taskColumnsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: isCompactMode ? 8 : 16) {
                ForEach(Array(zip(taskColumns.indices, taskColumns)), id: \.1.id) { index, column in
                    NoteColumnView(
                        column: column,
                        notes: filteredTasks[column.id] ?? [],
                        noteStore: noteStore,
                        refresh: refreshTaskData,
                    )
                    .frame(width: isCompactMode ? 280 : 320)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 50)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3 + Double(index) * 0.1), value: animateIn)
                }
                
                // Add column button
                addColumnButton
            }
            .padding()
        }
        .refreshable {
            // Refresh task data when user pulls to refresh
            if let release = selectedRelease {
                loadTaskDataForRelease(release)
            }
        }
    }
    
    private var addColumnButton: some View {
        VStack(spacing: 16) {
            Button(action: {
                addNewColumn()
            }) {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.dashed")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("Add Column")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray.opacity(0.8))
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                        .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: isCompactMode ? 280 : 320)
        .opacity(animateIn ? 0.6 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.8), value: animateIn)
    }
    
    private func addNewColumn() {
        guard let release = selectedRelease else { return }
        
        let newColumnTitle = "New Column"
        let newColumn = NoteColumn(
            title: newColumnTitle,
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
        
        // Refresh local data
        loadTaskDataForRelease(release)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Release Selected")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Select a project and release to start managing tasks")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            if selectedProject != nil {
                Button(action: {
                    isAddingRelease = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Release")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(accentGradient)
                    .cornerRadius(24)
                }
                .buttonStyle(AnimatedButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
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
                            .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? accentColor : Color.clear)
                            .frame(height: 2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .background(secondaryBgColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2))
                .offset(y: 1),
            alignment: .bottom
        )
    }
    
    private var releasesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Releases header
            HStack {
                Text("RELEASES")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(filteredReleases.count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Button(action: {
                    isAddingRelease = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundColor(accentColor)
                }
                .buttonStyle(AnimatedButtonStyle())
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.05))
            
            // Release dropdown/selector
            if !filteredReleases.isEmpty {
                Menu {
                    ForEach(filteredReleases, id: \.id) { release in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
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
                                        .foregroundColor(accentColor)
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        if let release = selectedRelease {
                            HStack(spacing: 8) {
                                Image(systemName: release.status.iconName)
                                    .foregroundColor(release.status.color)
                                    .font(.system(size: 14))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("v\(release.version)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(release.name)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        } else {
                            HStack {
                                Text("Select Release")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(cardBgColor)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            } else {
                // No releases message
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No releases yet")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        isAddingRelease = true
                    }) {
                        Text("Create First Release")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(accentGradient)
                            .cornerRadius(16)
                    }
                    .buttonStyle(AnimatedButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
    }
}







#Preview {
    TaskManagementView()
} 
