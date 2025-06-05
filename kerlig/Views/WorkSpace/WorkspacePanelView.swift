import SwiftUI

struct WorkspacePanelView: View {
    @StateObject private var workspaceService = WorkspaceService()
    @StateObject private var organizationService = OrganizationService()
    @State private var searchText = ""
    @State private var selectedWorkspaceIndex: Int? = nil
    @State private var activeFilter: ProjectType? = nil
    @FocusState private var isSearchFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    // Organization-related state
    @State private var isOrganizationMode = false
    @State private var selectedWorkspaces: Set<UUID> = []
    @State private var showOrganizationCreator = false
    @State private var showOrganizationManagement = false
    @State private var showOrganizationCreatedAlert = false
    @State private var lastCreatedOrganization: Organization?
    
    // First filtering step - by project type
    private var typeFilteredWorkspaces: [WorkspaceInfo] {
        guard let filter = activeFilter else {
            return workspaceService.workspaces
        }
        return workspaceService.workspaces.filter { $0.projectType == filter }
    }
    
    // Second filtering step - by search text
    private var filteredWorkspaces: [WorkspaceInfo] {
        // If search is empty, just return the type-filtered results
        if searchText.isEmpty {
            return typeFilteredWorkspaces
        }
        
        // Otherwise, filter by search text
        let searchLowercased = searchText.lowercased()
        return typeFilteredWorkspaces.filter { workspace in
            let nameMatches = workspace.name.lowercased().contains(searchLowercased)
            let pathMatches = workspace.path.lowercased().contains(searchLowercased)
            let typeMatches = workspace.projectType.displayName.lowercased().contains(searchLowercased)
            return nameMatches || pathMatches || typeMatches
        }
    }
    
    // Get selected workspace objects for organization creation
    private var selectedWorkspaceObjects: [WorkspaceInfo] {
        return filteredWorkspaces.filter { selectedWorkspaces.contains($0.id) }
    }

    var body: some View {
        ZStack {
            // Main workspace panel
            VStack(spacing: 0) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search by name, path, or project type", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .focused($isSearchFieldFocused)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            isSearchFieldFocused = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(8)
                .background(Color(.textBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top)
                
                // Project type filters with organization button
                HStack {
                    ProjectTypeFilterBar(
                        activeFilter: $activeFilter,
                        onOrganizationTapped: {
                            if !isOrganizationMode {
                                toggleOrganizationMode()
                            } else {
                                showOrganizationManagement = true
                            }
                        }
                    )
                    
                    Spacer()
                    
                    // Organization management button (when not in org mode)
                    if !isOrganizationMode && !organizationService.organizations.isEmpty {
                        Button(action: {
                            showOrganizationManagement = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2.crop.circle")
                                    .font(.system(size: 12))
                                Text("Manage")
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Manage existing organizations")
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                
                // Organization mode interface
                if isOrganizationMode {
                    VStack(spacing: 0) {
                        // Organization mode header
                        OrganizationModeHeader(
                            selectedCount: selectedWorkspaces.count,
                            onCancel: { exitOrganizationMode() },
                            onCreateOrganization: {
                                if selectedWorkspaces.count >= 2 {
                                    withAnimation(.spring(response: 0.5)) {
                                        showOrganizationCreator = true
                                    }
                                }
                            },
                            onManageOrganizations: {
                                showOrganizationManagement = true
                            }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        // Inline organization creator
                        if showOrganizationCreator {
                            InlineOrganizationCreator(
                                selectedWorkspaces: selectedWorkspaceObjects,
                                onCreateOrganization: { organization in
                                    organizationService.addOrganization(organization)
                                    lastCreatedOrganization = organization
                                    exitOrganizationMode()
                                    showOrganizationCreatedAlert = true
                                },
                                onCancel: {
                                    withAnimation(.spring(response: 0.5)) {
                                        showOrganizationCreator = false
                                    }
                                }
                            )
                            .padding(.horizontal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                        }
                    }
                }
                
                // Workspaces list with flexible frame
                if workspaceService.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                    Spacer()
                } else if let error = workspaceService.error {
                    Spacer()
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("Error loading workspaces")
                            .font(.headline)
                        
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Try Again") {
                            Task {
                                await workspaceService.loadWorkspaces()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                    .padding()
                    Spacer() 
                } else if filteredWorkspaces.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                            .padding()
                        
                        if searchText.isEmpty {
                            Text("No workspaces found")
                                .font(.headline)
                        } else {
                            Text("No matching workspaces")
                                .font(.headline)
                        }
                    }
                    .padding()
                    Spacer()
                } else {
                    List(selection: $selectedWorkspaceIndex) {
                        ForEach(Array(filteredWorkspaces.enumerated()), id: \.element.id) { index, workspace in
                            WorkspaceItemView(
                                workspace: workspace,
                                isSelected: selectedWorkspaceIndex == index,
                                isOrganizationMode: isOrganizationMode,
                                isWorkspaceSelected: selectedWorkspaces.contains(workspace.id),
                                onWorkspaceToggle: {
                                    toggleWorkspaceSelection(workspace.id)
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isOrganizationMode {
                                    toggleWorkspaceSelection(workspace.id)
                                } else {
                                    selectedWorkspaceIndex = index
                                    openSelectedWorkspace()
                                }
                            }
                            .onDoubleClick {
                                if !isOrganizationMode {
                                    openSelectedWorkspace()
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.clear)
                    .frame(minHeight: 0, maxHeight: .infinity)
                }
                
                // Footer with hint
                HStack {
                    if isOrganizationMode {
                        if showOrganizationCreator {
                            Text("Creating organization • Esc to cancel")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Select workspaces • Create organization • Esc to cancel")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("↑↓ to navigate • Enter to open • Esc to close • ⌘F to search")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .frame(minHeight: 400, maxHeight: showOrganizationCreator ? .infinity : 400)
            .clipped()
            .blur(radius: showOrganizationManagement ? 3 : 0)
            
            // Organization management overlay
            if showOrganizationManagement {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showOrganizationManagement = false
                        }
                    }
                
                OrganizationManagementView(
                    organizationService: organizationService,
                    allWorkspaces: workspaceService.workspaces,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showOrganizationManagement = false
                        }
                    },
                    onOpenWorkspace: { workspace in
                        openWorkspace(workspace)
                        withAnimation(.easeOut(duration: 0.3)) {
                            showOrganizationManagement = false
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            Task {
                await workspaceService.loadWorkspaces()
            }
            
            // Focus the search field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFieldFocused = true
            }
        }
        .onKeyPress(.upArrow) {
            if !isOrganizationMode {
                moveSelection(direction: -1)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.downArrow) {
            if !isOrganizationMode {
                moveSelection(direction: 1)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.return) {
            if !isOrganizationMode {
                openSelectedWorkspace()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.escape) {
            if showOrganizationManagement {
                withAnimation(.easeOut(duration: 0.3)) {
                    showOrganizationManagement = false
                }
                return .handled
            } else if showOrganizationCreator {
                withAnimation(.spring(response: 0.5)) {
                    showOrganizationCreator = false
                }
                return .handled
            } else if isOrganizationMode {
                exitOrganizationMode()
                return .handled
            } else {
                dismiss()
                return .handled
            }
        }
        .alert("Organization Created", isPresented: $showOrganizationCreatedAlert) {
            Button("OK") {}
        } message: {
            if let org = lastCreatedOrganization {
                Text("'\(org.name)' has been created with \(org.workspaceIds.count) workspaces.")
            }
        }
    }
    
    // MARK: - Organization Mode Functions
    
    private func toggleOrganizationMode() {
        if isOrganizationMode {
            exitOrganizationMode()
        } else {
            enterOrganizationMode()
        }
    }
    
    private func enterOrganizationMode() {
        withAnimation(.spring(response: 0.4)) {
            isOrganizationMode = true
            selectedWorkspaces.removeAll()
            selectedWorkspaceIndex = nil
            showOrganizationCreator = false
        }
    }
    
    private func exitOrganizationMode() {
        withAnimation(.spring(response: 0.4)) {
            isOrganizationMode = false
            selectedWorkspaces.removeAll()
            showOrganizationCreator = false
        }
    }
    
    private func toggleWorkspaceSelection(_ workspaceId: UUID) {
        if selectedWorkspaces.contains(workspaceId) {
            selectedWorkspaces.remove(workspaceId)
        } else {
            selectedWorkspaces.insert(workspaceId)
        }
    }
    
    // MARK: - Navigation Functions
    
    private func moveSelection(direction: Int) {
        guard !filteredWorkspaces.isEmpty else { return }
        
        if selectedWorkspaceIndex == nil {
            selectedWorkspaceIndex = 0
        } else {
            let newIndex = (selectedWorkspaceIndex! + direction) % filteredWorkspaces.count
            selectedWorkspaceIndex = newIndex < 0 ? filteredWorkspaces.count - 1 : newIndex
        }
    }
    
    private func openSelectedWorkspace() {
        guard let index = selectedWorkspaceIndex, index < filteredWorkspaces.count else { return }
        let workspace = filteredWorkspaces[index]
        openWorkspace(workspace)
    }
    
    private func openWorkspace(_ workspace: WorkspaceInfo) {
        // Create a more robust and dynamic approach for opening workspaces
        Task {
            // First try to open in Cursor
            openInCursor(path: workspace.path)
            
            // Also open terminal with VS Code
            openTerminalWithVSCode(path: workspace.path)
            
            // Update last opened timestamp
            workspaceService.openWorkspace(workspace)

            //after open in cursor, terminal run that code like is it is nextjs then use yarn run like this way 
            
            // Close the panel
            DispatchQueue.main.async {
                self.dismiss()
            }
        }
    }
    
    // Open workspace in Cursor
    private func openInCursor(path: String) {
        // First check if Cursor is already running
        let isCursorRunning = NSWorkspace.shared.runningApplications.contains { app in
            return app.bundleIdentifier == "com.cursor.Cursor" || app.bundleIdentifier == "com.cursor"
        }
        
        let cursorPaths = [
            "/Applications/Cursor.app",
            "/Applications/Cursor/Cursor.app",
            // Add potential additional Cursor locations
        ]
        
        // If Cursor is running, use AppleScript to bring it to front and open the workspace
        if isCursorRunning {
            let script = """
            tell application "Cursor"
                activate
                open "\(path.replacingOccurrences(of: "\"", with: "\\\""))"
            end tell
            """
            
            let appleScript = NSAppleScript(source: script)
            var errorDict: NSDictionary?
            appleScript?.executeAndReturnError(&errorDict)
            
            if errorDict == nil {
                print("Successfully opened path in Cursor: \(path)")
                return
            }
            
            print("AppleScript error with Cursor: \(String(describing: errorDict))")
            // Fall through to standard open method if AppleScript fails
        }
        
        // Standard method to open using the 'open' command
        for cursorPath in cursorPaths {
            if FileManager.default.fileExists(atPath: cursorPath) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                process.arguments = ["-a", cursorPath, path]
                
                do {
                    try process.run()
                    print("Opening workspace in Cursor: \(path)")
                    return // Successfully opened
                } catch {
                    print("Error opening Cursor: \(error)")
                    // Continue to next path
                }
            }
        }
        
        // Fallback to opening with VS Code directly if Cursor not found
        let codeProcess = Process()
        codeProcess.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        codeProcess.arguments = ["-a", "Visual Studio Code", path]
        
        do {
            try codeProcess.run()
            print("Fallback: Opening with VS Code: \(path)")
        } catch {
            print("Error opening VS Code: \(error)")
            
            // Last resort - just open in Finder
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }
    
    // Open terminal and execute VS Code command
    private func openTerminalWithVSCode(path: String) {
        // Check if Terminal is already running
        let isTerminalRunning = NSWorkspace.shared.runningApplications.contains { app in
            return app.bundleIdentifier == "com.apple.Terminal"
        }
        
        // Get the workspace info to determine project type
        let workspace = filteredWorkspaces.first { $0.path == path } ?? 
                        workspaceService.workspaces.first { $0.path == path }
        
        // Determine appropriate project command based on project type
        let projectCommand = getProjectCommand(for: workspace?.projectType ?? .unknown)
        
        // Create Apple Script to open Terminal, cd to path, and execute commands
        let script: String
        
        if isTerminalRunning {
            // Create a new window/tab in the existing Terminal
            script = """
            tell application "Terminal"
                activate
                do script "cd '\(path.replacingOccurrences(of: "'", with: "\\'"))' && code . && \(projectCommand) && clear"
            end tell
            """
        } else {
            // Just open a new Terminal
            script = """
            tell application "Terminal"
                activate
                do script "cd '\(path.replacingOccurrences(of: "'", with: "\\'"))' && code . && \(projectCommand) && clear"
            end tell
            """
        }
        
        let appleScript = NSAppleScript(source: script)
        var errorDict: NSDictionary?
        appleScript?.executeAndReturnError(&errorDict)
    }
    
    // Get appropriate command based on project type
    private func getProjectCommand(for projectType: ProjectType) -> String {
        switch projectType {
        case .nextjs, .react:
            // Check for yarn.lock or package-lock.json to determine package manager
            let workspace = filteredWorkspaces.first { $0.projectType == projectType }
            if let path = workspace?.path {
                if FileManager.default.fileExists(atPath: "\(path)/yarn.lock") {
                    return "echo 'Running Next.js/React project with Yarn' && yarn dev"
                } else if FileManager.default.fileExists(atPath: "\(path)/package-lock.json") {
                    return "echo 'Running Next.js/React project with NPM' && npm run dev"
                } else if FileManager.default.fileExists(atPath: "\(path)/pnpm-lock.yaml") {
                    return "echo 'Running Next.js/React project with PNPM' && pnpm dev"
                }
            }
            return "echo 'Next.js/React project detected - use npm run dev or yarn dev to start'"
            
        case .vue:
            return "echo 'Vue project detected - use npm run serve to start'"
            
        case .angular:
            return "echo 'Angular project detected - use ng serve to start'"
            
        case .swift:
            return "echo 'Swift project detected - use swift build to compile'"
            
        case .flutter:
            return "echo 'Flutter project detected - use flutter run to start'"
            
        case .node:
            return "echo 'Node.js project detected - use node index.js or npm start to run'"
            
        case .python:
            // Check for specific Python frameworks
            let workspace = filteredWorkspaces.first { $0.projectType == projectType }
            if let path = workspace?.path {
                if FileManager.default.fileExists(atPath: "\(path)/manage.py") {
                    return "echo 'Django project detected - use python manage.py runserver to start'"
                } else if FileManager.default.fileExists(atPath: "\(path)/app.py") || 
                          FileManager.default.fileExists(atPath: "\(path)/main.py") {
                    return "echo 'Flask/Python project detected - use python app.py or python main.py to start'"
                }
            }
            return "echo 'Python project detected'"
            
        case .ruby, .rails:
            return "echo 'Ruby/Rails project detected - use rails server to start'"
            
        case .go:
            return "echo 'Go project detected - use go run . to start'"
            
        case .rust:
            return "echo 'Rust project detected - use cargo run to start'"
            
        case .dotnet:
            return "echo '.NET project detected - use dotnet run to start'"
            
        case .java:
            return "echo 'Java project detected - use mvn spring-boot:run or gradle bootRun for Spring projects'"
            
        case .kotlin:
            return "echo 'Kotlin project detected'"
            
        case .php, .laravel:
            if projectType == .laravel {
                return "echo 'Laravel project detected - use php artisan serve to start'"
            }
            return "echo 'PHP project detected'"
            
        case .django:
            return "echo 'Django project detected - use python manage.py runserver to start'"
            
        case .unknown:
            return "echo 'Project type not detected'"
        }
    }
}

// Enhanced organization mode header component
struct OrganizationModeHeader: View {
    let selectedCount: Int
    let onCancel: () -> Void
    let onCreateOrganization: () -> Void
    let onManageOrganizations: () -> Void
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "building.2")
                    .foregroundColor(.purple)
                
                Text("Organization Mode")
                    .font(.headline)
                    .foregroundColor(.purple)
                
                Text("(\(selectedCount) selected)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("Manage") {
                    onManageOrganizations()
                }
                .buttonStyle(.bordered)
                .help("View and manage existing organizations")
                
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Button("Create Organization") {
                    onCreateOrganization()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCount < 2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
}
