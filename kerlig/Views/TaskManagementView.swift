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
        
        let allTasks = noteStore.getNotesForRelease(selectedRelease)
        var result = [UUID: [Note]]()
        
        for (columnId, notes) in allTasks {
            let filteredNotes = notes.filter { note in
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
            
            result[columnId] = filteredNotes
        }
        
        return result
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left sidebar with projects and releases
            leftSidebar
            
            // Main content area with task columns or pages
            VStack(spacing: 0) {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    animateIn = true
                }
            }
            
            if noteStore.projects.isEmpty {
                // Auto-select first project if available
                selectedProject = noteStore.projects.first
            } else {
                selectedProject = filteredProjects.first
            }
        }
        .onChange(of: selectedProject) { _, newProject in
            if let project = newProject {
                let releases = noteStore.getReleasesForProject(project)
                selectedRelease = releases.first
            } else {
                selectedRelease = nil
            }
        }
        .sheet(isPresented: $isAddingProject) {
            addProjectSheet
        }
        .sheet(isPresented: $isAddingRelease) {
            addReleaseSheet
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
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(accentColor)
            }
            .buttonStyle(AnimatedButtonStyle())
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
                        
                        let columnCount = noteStore.getColumnsForRelease(release).count
                        Text("\(columnCount)")
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
            
            if isColumnsListExpanded {
                let columns = noteStore.getColumnsForRelease(release)
                if !columns.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(columns.sorted(by: { $0.order < $1.order })) { column in
                                ColumnRowView(column: column)
                                    .padding(.horizontal, 8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 150)
                } else {
                    Text("No columns available")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
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
                        
                        Text(project.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    if let release = selectedRelease {
                        HStack(spacing: 8) {
                            Image(systemName: release.status.iconName)
                                .foregroundColor(release.status.color)
                                .font(.system(size: 14))
                            
                            Text("Release v\(release.version)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("•")
                                .foregroundColor(.gray)
                            
                            Text(release.name)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
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
            
            // Filter controls
            HStack(spacing: 12) {
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
    
    private var taskBoard: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: isCompactMode ? 8 : 16) {
                if let release = selectedRelease {
                    let columns = noteStore.getColumnsForRelease(release)
                    
                    ForEach(Array(zip(columns.indices, columns)), id: \.1.id) { index, column in
                        NoteColumnView(
                            column: column,
                            notes: filteredTasks[column.id] ?? [],
                            noteStore: noteStore
                        )
                        .frame(width: isCompactMode ? 280 : 320)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 50)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3 + Double(index) * 0.1), value: animateIn)
                    }
                }
            }
            .padding()
        }
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
    
    // MARK: - Sheets
    
    private var addProjectSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Project")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Cancel") {
                    isAddingProject = false
                    resetProjectForm()
                }
                .foregroundColor(.gray)
            }
            .padding()
            .background(secondaryBgColor)
            
            // Form
            ScrollView {
                VStack(spacing: 24) {
                    // Logo upload section
                    VStack(alignment: .center, spacing: 12) {
                        if let logoImage = newProjectLogoImage {
                            Image(nsImage: logoImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        } else {
                            Circle()
                                .fill(newProjectColor)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.8))
                                )
                                .shadow(color: newProjectColor.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                        Button(action: {
                            isShowingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text(newProjectLogoImage == nil ? "Upload Logo" : "Change Logo")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#3C3C3E"))
                            .cornerRadius(8)
                        }
                        .buttonStyle(AnimatedButtonStyle())
                        .fileImporter(
                            isPresented: $isShowingImagePicker,
                            allowedContentTypes: [.image],
                            allowsMultipleSelection: false
                        ) { result in
                            handleImageSelection(result)
                        }
                        
                        if newProjectLogoImage != nil {
                            Button(action: {
                                newProjectLogoImage = nil
                            }) {
                                Text("Remove Logo")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red.opacity(0.8))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Title")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter project title", text: $newProjectTitle)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(cardBgColor)
                            .cornerRadius(8)
                            .onSubmit {
                                if !newProjectTitle.isEmpty && !newProjectDescription.isEmpty {
                                    createProject()
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter project description", text: $newProjectDescription, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(cardBgColor)
                            .cornerRadius(8)
                            .frame(minHeight: 80)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                            ForEach(availableColors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        ZStack {
                                            Circle()
                                                .stroke(Color.white, lineWidth: newProjectColor == color ? 3 : 0)
                                            
                                            if newProjectColor == color {
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 16, height: 16)
                                            }
                                        }
                                    )
                                    .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 2)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            newProjectColor = color
                                        }
                                    }
                            }
                        }
                    }
                    
                    Button(action: {
                        createProject()
                    }) {
                        Text("Create Project")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentGradient)
                            .cornerRadius(8)
                            .shadow(color: accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(AnimatedButtonStyle())
                    .disabled(newProjectTitle.isEmpty || newProjectDescription.isEmpty)
                    .opacity((newProjectTitle.isEmpty || newProjectDescription.isEmpty) ? 0.6 : 1)
                }
                .padding()
            }
        }
        .background(secondaryBgColor)
        .frame(width: 500, height: 650)
        .cornerRadius(12)
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
            selectedRelease = newReleases.first { $0.version == newReleaseVersion }
            
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

// MARK: - Supporting Views

struct ProjectRowView: View {
    let project: Project
    let isSelected: Bool
    let onSelect: () -> Void
    var onDelete: (() -> Void)? = nil
    
    @State private var isHovered = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Project logo or color circle
                if let logoData = project.logoImageData, let nsImage = NSImage(data: logoData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                } else {
                    Circle()
                        .fill(project.color ?? .blue)
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .white : .gray)
                        .lineLimit(1)
                    
                    Text(project.description)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Color(hex: "#007AFF"))
                        .frame(width: 8, height: 8)
                }
                
                if isHovered || isSelected {
                    Button(action: {
                        showDeleteConfirm = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(6)
                            .background(Color(hex: "#3C3C3E"))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Delete project")
                    .confirmationDialog("Delete Project", isPresented: $showDeleteConfirm) {
                        Button("Delete", role: .destructive) {
                            if let onDelete = onDelete {
                                onDelete()
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to delete '\(project.title)'? This will delete all associated releases and tasks.")
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#2C2C2E") : (isHovered ? Color(hex: "#1C1C1E") : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "#007AFF").opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Supporting Types

enum FilterOption: String {
    case all = "All Tasks"
    case completed = "Completed"
    case incomplete = "Incomplete"
}

// New supporting views
struct ReleaseRowView: View {
    let release: Release
    let projectTitle: String
    let isSelected: Bool
    let onSelect: () -> Void
    var onDelete: (() -> Void)? = nil
    var projectLogoData: Data? = nil
    
    @State private var isHovered = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Project logo or status icon
                if let logoData = projectLogoData, let nsImage = NSImage(data: logoData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                } else {
                    Image(systemName: release.status.iconName)
                        .foregroundColor(release.status.color)
                        .font(.system(size: 14))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("v\(release.version) - \(release.name)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? .white : .gray)
                    
                    Text(projectTitle)
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Color(hex: "#007AFF"))
                        .frame(width: 6, height: 6)
                }
                
                if isHovered || isSelected {
                    Button(action: {
                        showDeleteConfirm = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(5)
                            .background(Color(hex: "#3C3C3E"))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Delete release")
                    .confirmationDialog("Delete Release", isPresented: $showDeleteConfirm) {
                        Button("Delete", role: .destructive) {
                            if let onDelete = onDelete {
                                onDelete()
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to delete release '\(release.name)'? This will delete all associated tasks.")
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color(hex: "#2C2C2E") : (isHovered ? Color(hex: "#1C1C1E") : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? release.status.color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct ColumnRowView: View {
    let column: NoteColumn
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(column.color ?? .gray)
                .frame(width: 10, height: 10)
            
            Text(column.title)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text("\(column.noteIds.count)")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(hex: "#2C2C2E"))
                .cornerRadius(8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color(hex: "#1C1C1E") : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    TaskManagementView()
} 