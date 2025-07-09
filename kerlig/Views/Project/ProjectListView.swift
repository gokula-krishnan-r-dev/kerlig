import SwiftUI

struct ProjectListView: View {
    @EnvironmentObject private var noteStore: NoteStore
    @State private var searchText = ""
    @State private var selectedProjectId: UUID?
    @State private var showDeleteConfirmation = false
    @State private var projectToDelete: Project?
    @State private var sortOption: SortOption = .lastModified
    @State private var isAscending = false
    @State private var animateIn = false
    @State private var showArchived = false
    @State private var selectedProjects = Set<UUID>()
    @State private var isBulkSelectMode = false
    @State private var showBulkActionMenu = false
    
    // Edit project states
    @State private var showEditProjectSheet = false
    @State private var projectToEdit: Project?
    @State private var editedProjectTitle = ""
    @State private var editedProjectDescription = ""
    @State private var editedProjectColor: Color = .blue
    @State private var editedProjectLogo: NSImage?
    
    // Action callbacks
    var onSelectProject: (Project) -> Void
    var onAddProject: () -> Void
    
    enum SortOption: String, CaseIterable {
        case title = "Name"
        case lastModified = "Last Modified"
        case creationDate = "Created Date"
    }
    
    // Computed properties
    private var filteredProjects: [Project] {
        let filtered = noteStore.projects.filter { project in
            // Filter by archive status
            if !showArchived && project.isArchived {
                return false
            }
            
            // Filter by search text
            if !searchText.isEmpty {
                return project.title.localizedCaseInsensitiveContains(searchText) || 
                       project.description.localizedCaseInsensitiveContains(searchText)
            }
            
            return true
        }
        
        return sortedProjects(filtered)
    }
    
    private func sortedProjects(_ projects: [Project]) -> [Project] {
        switch sortOption {
        case .title:
            return projects.sorted { 
                isAscending ? $0.title < $1.title : $0.title > $1.title 
            }
        case .lastModified:
            return projects.sorted { 
                isAscending ? $0.lastModified < $1.lastModified : $0.lastModified > $1.lastModified 
            }
        case .creationDate:
            return projects.sorted { 
                isAscending ? $0.creationDate < $1.creationDate : $0.creationDate > $1.creationDate 
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and controls header
            VStack(spacing: 16) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search projects...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.07))
                .cornerRadius(8)
                
                // Sort and filter controls
                HStack {
                    Text("Sort by:")
                        .foregroundColor(.gray)
                    
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                    
                    Button(action: { isAscending.toggle() }) {
                        Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                    }
                    .buttonStyle(.plain)
                    
                    Toggle(isOn: $showArchived) {
                        HStack(spacing: 4) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 12))
                            Text("Show Archived")
                                .font(.system(size: 13))
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    Text("\(filteredProjects.count) projects")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .padding(.trailing, 16)
                    
                    // Bulk selection toggle
                    Button(action: {
                        isBulkSelectMode.toggle()
                        if !isBulkSelectMode {
                            selectedProjects.removeAll()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isBulkSelectMode ? "checkmark.square.fill" : "square")
                            Text(isBulkSelectMode ? "Cancel" : "Select")
                                .font(.system(size: 13))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isBulkSelectMode ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.2))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                    
                    // Bulk actions menu (only shown when items are selected)
                    if isBulkSelectMode && !selectedProjects.isEmpty {
                        Menu {
                            Button(action: {
                                // Archive selected projects
                                for projectId in selectedProjects {
                                    if let project = noteStore.projects.first(where: { $0.id == projectId }) {
                                        var updatedProject = project
                                        updatedProject.isArchived = true
                                        noteStore.updateProject(updatedProject)
                                    }
                                }
                                selectedProjects.removeAll()
                            }) {
                                Label("Archive Selected", systemImage: "archivebox")
                            }
                            
                            Button(action: {
                                // Delete selected projects
                                for projectId in selectedProjects {
                                    if let project = noteStore.projects.first(where: { $0.id == projectId }) {
                                        noteStore.deleteProject(project)
                                    }
                                }
                                selectedProjects.removeAll()
                            }) {
                                Label("Delete Selected", systemImage: "trash")
                            }
                        } label: {
                            Text("Actions (\(selectedProjects.count))")
                                .font(.system(size: 13))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.accentColor)
                                .cornerRadius(6)
                        }
                        .menuStyle(.borderlessButton)
                        .padding(.trailing, 8)
                    }
                    
                    Button(action: onAddProject) {
                        HStack {
                            Image(systemName: "plus")
                            Text("New Project")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color.black.opacity(0.2))
            
            // Table header
            HStack(spacing: 16) {
                if isBulkSelectMode {
                    Button(action: {
                        if selectedProjects.count == filteredProjects.count {
                            // Deselect all
                            selectedProjects.removeAll()
                        } else {
                            // Select all
                            selectedProjects = Set(filteredProjects.map { $0.id })
                        }
                    }) {
                        Image(systemName: selectedProjects.count == filteredProjects.count && !filteredProjects.isEmpty ? 
                              "checkmark.square.fill" : "square")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 30)
                    .help(selectedProjects.count == filteredProjects.count ? "Deselect all" : "Select all")
                }
                
                Text("Project")
                    .frame(width: isBulkSelectMode ? 220 : 250, alignment: .leading)
                    .font(.system(size: 14, weight: .medium))
                
                Text("Description")
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 14, weight: .medium))
                
                Text("Last Modified")
                    .frame(width: 150, alignment: .leading)
                    .font(.system(size: 14, weight: .medium))
                
                Text("Actions")
                    .frame(width: 120, alignment: .center)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.15))
            
            // Table content
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredProjects.enumerated()), id: \.element.id) { index, project in
                        HStack(spacing: 0) {
                            // Checkbox for bulk selection (only visible in bulk select mode)
                            if isBulkSelectMode {
                                Button(action: {
                                    if selectedProjects.contains(project.id) {
                                        selectedProjects.remove(project.id)
                                    } else {
                                        selectedProjects.insert(project.id)
                                    }
                                }) {
                                    Image(systemName: selectedProjects.contains(project.id) ? 
                                          "checkmark.square.fill" : "square")
                                        .foregroundColor(.accentColor)
                                        .padding(.trailing, 8)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 30)
                                .contentShape(Rectangle())
                            }
                            
                            // Project row
                            EnhancedProjectRowView(
                                project: project,
                                isSelected: selectedProjectId == project.id,
                                onSelect: {
                                    if isBulkSelectMode {
                                        if selectedProjects.contains(project.id) {
                                            selectedProjects.remove(project.id)
                                        } else {
                                            selectedProjects.insert(project.id)
                                        }
                                    } else {
                                        withAnimation {
                                            selectedProjectId = project.id
                                            onSelectProject(project)
                                        }
                                    }
                                },
                                onDelete: {
                                    projectToDelete = project
                                    showDeleteConfirmation = true
                                },
                                onEdit: {
                                    projectToEdit = project
                                    editedProjectTitle = project.title
                                    editedProjectDescription = project.description
                                    editedProjectColor = project.color ?? .blue
                                    if let logoData = project.logoImageData {
                                        editedProjectLogo = NSImage(data: logoData)
                                    } else {
                                        editedProjectLogo = nil
                                    }
                                    showEditProjectSheet = true
                                },
                                onDuplicate: {
                                    let newProject = noteStore.duplicateProject(project)
                                    // Optionally select the new project
                                    withAnimation {
                                        selectedProjectId = newProject.id
                                        onSelectProject(newProject)
                                    }
                                },
                                onArchive: {
                                    // Archive functionality to be implemented
                                    var updatedProject = project
                                    updatedProject.isArchived.toggle()
                                    noteStore.updateProject(updatedProject)
                                },
                                onExport: {
                                    if let jsonData = noteStore.exportProjectToJSON(project) {
                                        let savePanel = NSSavePanel()
                                        savePanel.allowedContentTypes = [.json]
                                        savePanel.nameFieldStringValue = "\(project.title.replacingOccurrences(of: " ", with: "_")).json"
                                        savePanel.message = "Export project data"
                                        savePanel.prompt = "Export"
                                        
                                        if savePanel.runModal() == .OK, let url = savePanel.url {
                                            do {
                                                try jsonData.write(to: url)
                                            } catch {
                                                print("Error saving project export: \(error)")
                                            }
                                        }
                                    }
                                }
                            )
                        }
                        .background(
                            ZStack {
                                // Alternate row background
                                Rectangle()
                                    .fill(index % 2 == 0 ? Color.clear : Color.black.opacity(0.05))
                                
                                // Selection highlight
                                if isBulkSelectMode && selectedProjects.contains(project.id) {
                                    Rectangle()
                                        .fill(Color.accentColor.opacity(0.1))
                                }
                            }
                        )
                        .contentShape(Rectangle())
                        .scaleEffect(animateIn ? 1 : 0.95)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: animateIn)
                        
                        Divider()
                            .opacity(0.3)
                    }
                }
            }
            
            // Empty state
            if filteredProjects.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No projects found")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    if !searchText.isEmpty {
                        Text("Try adjusting your search")
                            .foregroundColor(.gray.opacity(0.8))
                    } else {
                        Button(action: onAddProject) {
                            Text("Create your first project")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.accentColor)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .background(Color.clear)
        .alert("Delete Project", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let project = projectToDelete {
                    withAnimation {
                        noteStore.deleteProject(project)
                        if selectedProjectId == project.id {
                            selectedProjectId = nil
                        }
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(projectToDelete?.title ?? "")\"? This action cannot be undone.")
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    animateIn = true
                }
            }
        }
        .sheet(isPresented: $showEditProjectSheet) {
            // Edit project sheet
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Edit Project")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { showEditProjectSheet = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                
                // Project logo
                VStack(spacing: 12) {
                    if let logo = editedProjectLogo {
                        Image(nsImage: logo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                    } else {
                        Circle()
                            .fill(editedProjectColor)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(editedProjectTitle.prefix(1)))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Button("Change Logo") {
                        // Open image picker (simplified)
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        panel.canChooseFiles = true
                        panel.allowedContentTypes = [.image]
                        
                        if panel.runModal() == .OK, let url = panel.url {
                            editedProjectLogo = NSImage(contentsOf: url)
                        }
                    }
                    .font(.system(size: 14))
                }
                
                // Project title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Title")
                        .font(.headline)
                    
                    TextField("Enter project title", text: $editedProjectTitle)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Project description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    TextEditor(text: $editedProjectDescription)
                        .frame(height: 100)
                        .padding(4)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Project color
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach([Color.blue, Color.purple, Color.green, Color.orange, Color.red, Color.pink], id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: editedProjectColor == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    editedProjectColor = color
                                }
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack {
                    Button(action: { showEditProjectSheet = false }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        guard let project = projectToEdit else { return }
                        
                        // Update project
                        var updatedProject = project
                        updatedProject.title = editedProjectTitle
                        updatedProject.description = editedProjectDescription
                        updatedProject.color = editedProjectColor
                        updatedProject.lastModified = Date()
                        
                        // Update logo if changed
                        if let logo = editedProjectLogo {
                            updatedProject.logoImageData = logo.tiffRepresentation
                        }
                        
                        // Save changes
                        noteStore.updateProject(updatedProject)
                        showEditProjectSheet = false
                    }) {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(editedProjectTitle.isEmpty)
                }
            }
            .padding(24)
            .frame(width: 500, height: 600)
        }
    }
}



// Preview provider
struct ProjectListView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectListView(
            onSelectProject: { _ in },
            onAddProject: {}
        )
        .environmentObject(NoteStore())
        .frame(width: 800, height: 600)
        .preferredColorScheme(.dark)
    }
} 