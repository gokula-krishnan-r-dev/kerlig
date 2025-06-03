import SwiftUI

struct WorkspacePanelView: View {
    @StateObject private var workspaceService = WorkspaceService()
    @State private var searchText = ""
    @State private var selectedWorkspaceIndex: Int? = nil
    @Environment(\.dismiss) private var dismiss
    
    private var filteredWorkspaces: [WorkspaceInfo] {
        if searchText.isEmpty {
            return workspaceService.workspaces
        } else {
            return workspaceService.workspaces.filter { workspace in
                workspace.name.localizedCaseInsensitiveContains(searchText) ||
                workspace.path.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search workspaces", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.body)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
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
                Text("↑↓ to navigate • Enter to open • Esc to close")
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
        
        // Create Apple Script to open Terminal, cd to path, and execute code .
        let script: String
        
        if isTerminalRunning {
            // Create a new window/tab in the existing Terminal
            script = """
            tell application "Terminal"
                activate
                do script "cd '\(path.replacingOccurrences(of: "'", with: "\\'"))' && code . && clear"
            end tell
            """
        } else {
            // Just open a new Terminal
            script = """
            tell application "Terminal"
                activate
                do script "cd '\(path.replacingOccurrences(of: "'", with: "\\'"))' && code . && clear"
            end tell
            """
        }
        
        let appleScript = NSAppleScript(source: script)
        var errorDict: NSDictionary?
        appleScript?.executeAndReturnError(&errorDict)
        
        if let error = errorDict {
            print("AppleScript error: \(error)")
            
            // Try an alternate approach if permission isn't granted
            if (error["NSAppleScriptErrorNumber"] as? NSNumber)?.intValue == -1743 ||
               (error["NSAppleScriptErrorNumber"] as? NSNumber)?.intValue == -1728 {
                // This is likely a permissions issue
                // requestAppleScriptPermission()
            }
            
            // Fallback method using Process
            fallbackTerminalOpen(path: path)
        }
    }
    
    // Request AppleScript permissions if needed
    private func requestAppleScriptPermission() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Permission Required"
            alert.informativeText = """
            Kerlig needs permission to control Terminal with AppleScript.
            
            Please grant automation permissions in System Settings:
            1. Go to Privacy & Security > Automation
            2. Enable Kerlig to control Terminal
            
            Would you like to open the settings now?
            """
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")
            
            if alert.runModal() == .alertFirstButtonReturn {
                // Try to open automation settings directly
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(url)
                } else {
                    // Fallback to general privacy settings
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
                }
            }
        }
    }
    
    // Fallback method if AppleScript fails
    private func fallbackTerminalOpen(path: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Terminal", path]
        
        do {
            try process.run()
            print("Opened Terminal at path: \(path)")

        } catch {
            print("Error opening Terminal: \(error)")
        }
    }
}

// Extension to enable double-click functionality
extension View {
    func onDoubleClick(perform action: @escaping () -> Void) -> some View {
        self.gesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    action()
                }
        )
    }
} 

