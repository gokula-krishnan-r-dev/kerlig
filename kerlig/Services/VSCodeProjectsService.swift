import Foundation
import AppKit

struct VSCodeProject: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let lastOpened: Date?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(path)
    }
    
    static func == (lhs: VSCodeProject, rhs: VSCodeProject) -> Bool {
        return lhs.id == rhs.id && lhs.path == rhs.path
    }
}

class VSCodeProjectsService {
    private let fileManager = FileManager.default
    private let vscodeStoragePath = "~/Library/Application Support/Code/User/workspaceStorage"
    
    // Loads VS Code projects from the workspace storage
    func loadProjects() -> [VSCodeProject] {
        let expandedPath = NSString(string: vscodeStoragePath).expandingTildeInPath
        
        guard let storageContents = try? fileManager.contentsOfDirectory(atPath: expandedPath) else {
            NSLog("❌ Failed to access VS Code workspace storage at: \(expandedPath)")
            return []
        }
        
        var projects: [VSCodeProject] = []
        
        // Process each workspace storage folder
        for storageFolder in storageContents {
            let storageFolderPath = "\(expandedPath)/\(storageFolder)"
            
            // Check if it's a directory
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: storageFolderPath, isDirectory: &isDir), isDir.boolValue {
                // Look for workspace.json in each storage folder
                let workspaceJsonPath = "\(storageFolderPath)/workspace.json"
                
                if fileManager.fileExists(atPath: workspaceJsonPath) {
                    if let workspaceData = try? Data(contentsOf: URL(fileURLWithPath: workspaceJsonPath)),
                       let workspaceInfo = try? JSONSerialization.jsonObject(with: workspaceData) as? [String: Any],
                       let folderUri = workspaceInfo["folder"] as? String {
                        
                        // Convert VS Code URI to file path
                        if let projectPath = convertVSCodeUriToFilePath(folderUri) {
                            // Get the folder name as the project name
                            let projectName = URL(fileURLWithPath: projectPath).lastPathComponent
                            
                            // Get file attributes to determine last opened date
                            let fileAttributes = try? fileManager.attributesOfItem(atPath: workspaceJsonPath)
                            let modificationDate = fileAttributes?[.modificationDate] as? Date
                            
                            let project = VSCodeProject(
                                name: projectName,
                                path: projectPath,
                                lastOpened: modificationDate
                            )
                            
                            projects.append(project)
                        }
                    }
                }
            }
        }
        
        // Add recent projects from state.json
        let recentProjects = loadRecentProjects()
        
        // Merge lists and remove duplicates
        let allProjects = (projects + recentProjects).reduce(into: [String: VSCodeProject]()) { dict, project in
            // If duplicate exists, keep the one with most recent date
            if let existing = dict[project.path] {
                if let projectDate = project.lastOpened, 
                   let existingDate = existing.lastOpened, 
                   projectDate > existingDate {
                    dict[project.path] = project
                }
            } else {
                dict[project.path] = project
            }
        }
        
        // Sort by last opened date, most recent first
        return Array(allProjects.values).sorted { 
            if let date1 = $0.lastOpened, let date2 = $1.lastOpened {
                return date1 > date2
            } else if $0.lastOpened != nil {
                return true
            } else if $1.lastOpened != nil {
                return false
            } else {
                return $0.name < $1.name
            }
        }
    }
    
    // Load recent projects from VS Code's state.json file
    private func loadRecentProjects() -> [VSCodeProject] {
        let statePath = "~/Library/Application Support/Code/User/globalStorage/state.json"
        let expandedPath = NSString(string: statePath).expandingTildeInPath
        
        guard fileManager.fileExists(atPath: expandedPath),
              let stateData = try? Data(contentsOf: URL(fileURLWithPath: expandedPath)),
              let stateInfo = try? JSONSerialization.jsonObject(with: stateData) as? [String: Any],
              let recentPaths = stateInfo["openedPathsList"] as? [String: Any],
              let entries = recentPaths["entries"] as? [[String: Any]] else {
            return []
        }
        
        var projects: [VSCodeProject] = []
        
        for entry in entries {
            if let folderUri = entry["folderUri"] as? String,
               let projectPath = convertVSCodeUriToFilePath(folderUri) {
                
                let projectName = URL(fileURLWithPath: projectPath).lastPathComponent
                
                // Try to determine when it was last opened
                let lastOpenedTimestamp = (entry["timestamp"] as? Double) ?? 0
                let lastOpenedDate = lastOpenedTimestamp > 0 
                    ? Date(timeIntervalSince1970: lastOpenedTimestamp / 1000) 
                    : Date()
                
                let project = VSCodeProject(
                    name: projectName,
                    path: projectPath,
                    lastOpened: lastOpenedDate
                )
                
                projects.append(project)
            }
        }
        
        return projects
    }
    
    // Convert VS Code URI to a file path
    private func convertVSCodeUriToFilePath(_ uri: String) -> String? {
        guard uri.hasPrefix("file://") else { return nil }
        
        // Remove the file:// prefix and decode URL components
        var path = String(uri.dropFirst(7))
        
        // Handle percent encoding
        if let decodedPath = path.removingPercentEncoding {
            path = decodedPath
        }
        
        return path
    }
    
    // Open a VS Code project
    func openProject(at path: String) -> Bool {
        guard fileManager.fileExists(atPath: path) else {
            NSLog("❌ Project path does not exist: \(path)")
            return false
        }
        
        let url = URL(fileURLWithPath: path)
        
        // First try using the vscode URL scheme
        if let vscodeUrl = URL(string: "vscode://file\(url.path)") {
            if NSWorkspace.shared.open(vscodeUrl) {
                return true
            }
        }
        
        // Fall back to opening with VS Code app
        let workspace = NSWorkspace.shared
        let vscodeAppURL = URL(fileURLWithPath: "/Applications/Visual Studio Code.app")
        
        do {
            try workspace.open(
                [url],
                withApplicationAt: vscodeAppURL,
                options: [],
                configuration: [:]
            )
            return true
        } catch {
            NSLog("❌ Failed to open project with VS Code: \(error.localizedDescription)")
            
            // Last resort: try with open command
            let process = Process()
            process.launchPath = "/usr/bin/open"
            process.arguments = ["-a", "Visual Studio Code", path]
            
            do {
                try process.run()
                return true
            } catch {
                NSLog("❌ Failed to open project with open command: \(error.localizedDescription)")
                return false
            }
        }
    }
} 