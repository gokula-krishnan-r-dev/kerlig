import SwiftUI

struct WorkspacePanelView: View {
    @StateObject private var workspaceService = WorkspaceService()
    @State private var searchText = ""
    @State private var selectedWorkspaceIndex: Int? = nil
    @State private var activeFilter: ProjectType? = nil
    @FocusState private var isSearchFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
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
    
    var body: some View {
        VStack {
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
            
            // Project type filters
            ProjectTypeFilterBar(activeFilter: $activeFilter)
                .padding(.horizontal)
                .padding(.vertical, 4)
            
            // Workspaces list
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
                            isSelected: selectedWorkspaceIndex == index
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedWorkspaceIndex = index
                            openSelectedWorkspace()
                        }
                        .onDoubleClick {
                            openSelectedWorkspace()
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.clear)
            }
            // Footer with hint
            HStack {
                Text("↑↓ to navigate • Enter to open • Esc to close • ⌘F to search")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(width: 600, height: 400)
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
            moveSelection(direction: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(direction: 1)
            return .handled
        }
        .onKeyPress(.return) {
            openSelectedWorkspace()
            return .handled
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        // Add shortcut for focusing the search field
//        .onKeyPress("f") { event in
//            if event.modifiers.contains(.command) {
//                isSearchFieldFocused = true
//                return .handled
//            }
//            return .ignored
//        }
    }
    
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
