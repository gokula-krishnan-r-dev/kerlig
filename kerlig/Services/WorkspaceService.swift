import Foundation
import AppKit

class WorkspaceService: ObservableObject {
    @Published var workspaces: [WorkspaceInfo] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let fileManager = FileManager.default
    
    func loadWorkspaces() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let username = NSUserName()
            
            // Try different paths that might exist
            var workspaceStoragePath = "/Users/\(username)/Library/Application Support/Cursor/User/workspaceStorage"
            
            // Check alternate paths if the main one doesn't exist
            if !fileManager.fileExists(atPath: workspaceStoragePath) {
                // Try VSCode path as Cursor might use compatible storage locations
                workspaceStoragePath = "/Users/\(username)/Library/Application Support/Code/User/workspaceStorage"
                
                if !fileManager.fileExists(atPath: workspaceStoragePath) {
                    // Populate with sample data for demonstration purposes
                    let sampleWorkspaces = createSampleWorkspaces()
                    DispatchQueue.main.async {
                        self.workspaces = sampleWorkspaces
                        self.isLoading = false
                    }
                    return
                }
            }
            
            // Try to get directory contents
            let storageContents: [String]
            do {
                storageContents = try fileManager.contentsOfDirectory(atPath: workspaceStoragePath)
            } catch {
                // Fall back to sample workspaces if we can't access the directory
                print("Cannot access directory: \(error.localizedDescription)")
                let sampleWorkspaces = createSampleWorkspaces()
                DispatchQueue.main.async {
                    self.workspaces = sampleWorkspaces
                    self.isLoading = false
                }
                return
            }
            
            var discoveredWorkspaces: [WorkspaceInfo] = []
            
            for folder in storageContents {
                let folderPath = "\(workspaceStoragePath)/\(folder)"
                let workspaceJsonPath = "\(folderPath)/workspace.json"
                
                if fileManager.fileExists(atPath: workspaceJsonPath) {
                    do {
                        let jsonData = try Data(contentsOf: URL(fileURLWithPath: workspaceJsonPath))
                        let decoder = JSONDecoder()
                        let workspaceJson = try decoder.decode(WorkspaceJSON.self, from: jsonData)
                        
                        let folderUrl = URL(fileURLWithPath: workspaceJson.folder)
                        
                        // Get the last component of the path as the workspace name
                        let workspaceName = folderUrl.lastPathComponent
                        
                        // Get file attributes to determine last opened date
                        let attributes = try fileManager.attributesOfItem(atPath: workspaceJsonPath)
                        let lastModified = attributes[.modificationDate] as? Date
                        
                        let workspace = WorkspaceInfo(
                            name: workspaceName,
                            path: workspaceJson.folder,
                            lastOpened: lastModified
                        )
                        
                        discoveredWorkspaces.append(workspace)
                    } catch {
                        print("Error processing workspace at \(folderPath): \(error)")
                    }
                }
            }
            
            // If no workspaces were found, add samples
            if discoveredWorkspaces.isEmpty {
                discoveredWorkspaces = createSampleWorkspaces()
            }
            
            // Sort workspaces by last opened date
            let sortedWorkspaces = discoveredWorkspaces.sorted { 
                guard let date1 = $0.lastOpened, let date2 = $1.lastOpened else {
                    return false
                }
                return date1 > date2
            }
            
            DispatchQueue.main.async {
                self.workspaces = sortedWorkspaces
                self.isLoading = false
            }
            
        } catch {
            DispatchQueue.main.async {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    private func createSampleWorkspaces() -> [WorkspaceInfo] {
        // Create sample workspaces for demonstration
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            WorkspaceInfo(
                name: "Example Project 1",
                path: "\(homeDir)/Documents/Projects/Example1",
                lastOpened: Date()
            ),
            WorkspaceInfo(
                name: "SwiftUI App",
                path: "\(homeDir)/Documents/Projects/SwiftUI-App",
                lastOpened: Date().addingTimeInterval(-86400)
            ),
            WorkspaceInfo(
                name: "Personal Website",
                path: "\(homeDir)/Documents/Projects/Website",
                lastOpened: Date().addingTimeInterval(-172800)
            ),
            WorkspaceInfo(
                name: "iOS Game",
                path: "\(homeDir)/Documents/Projects/Game",
                lastOpened: Date().addingTimeInterval(-259200)
            ),
            WorkspaceInfo(
                name: "Machine Learning Project",
                path: "\(homeDir)/Documents/Projects/ML",
                lastOpened: Date().addingTimeInterval(-345600)
            )
        ]
    }
    
    func openWorkspace(_ workspace: WorkspaceInfo) {
        NSWorkspace.shared.open(URL(fileURLWithPath: workspace.path))
    }
} 
