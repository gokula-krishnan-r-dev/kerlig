import Foundation
import SwiftUI

// Enum to represent different project types
enum ProjectType: String, CaseIterable {
    case nextjs
    case react
    case vue
    case angular
    case swift
    case kotlin
    case flutter
    case node
    case python
    case ruby
    case rails
    case go
    case rust
    case dotnet
    case java
    case php
    case laravel
    case django
    case unknown
    
    // Associated icon for each project type
    var iconName: String {
        switch self {
        case .nextjs: return "n.square.fill"
        case .react: return "atom"
        case .vue: return "v.square.fill"
        case .angular: return "a.square.fill"
        case .swift: return "swift"
        case .kotlin: return "k.square.fill"
        case .flutter: return "f.square.fill"
        case .node: return "server.rack"
        case .python: return "p.square.fill"
        case .ruby: return "r.square.fill"
        case .rails: return "r.square.fill"
        case .go: return "g.square.fill"
        case .rust: return "r.square.fill"
        case .dotnet: return "network"
        case .java: return "j.square.fill"
        case .php: return "p.square.fill"
        case .laravel: return "l.square.fill"
        case .django: return "d.square.fill"
        case .unknown: return "folder.fill"
        }
    }
    
    // Color associated with each project type
    var color: Color {
        switch self {
        case .nextjs: return .black
        case .react: return .blue
        case .vue: return .green
        case .angular: return .red
        case .swift: return .orange
        case .kotlin: return .purple
        case .flutter: return .blue
        case .node: return .green
        case .python: return .blue
        case .ruby: return .red
        case .rails: return .red
        case .go: return .blue
        case .rust: return .orange
        case .dotnet: return .purple
        case .java: return .orange
        case .php: return .purple
        case .laravel: return .red
        case .django: return .green
        case .unknown: return .gray
        }
    }
    
    // Display name for UI
    var displayName: String {
        switch self {
        case .nextjs: return "Next.js"
        case .react: return "React"
        case .vue: return "Vue"
        case .angular: return "Angular"
        case .swift: return "Swift"
        case .kotlin: return "Kotlin"
        case .flutter: return "Flutter"
        case .node: return "Node.js"
        case .python: return "Python"
        case .ruby: return "Ruby"
        case .rails: return "Rails"
        case .go: return "Go"
        case .rust: return "Rust"
        case .dotnet: return ".NET"
        case .java: return "Java"
        case .php: return "PHP"
        case .laravel: return "Laravel"
        case .django: return "Django"
        case .unknown: return "Unknown"
        }
    }
}

// Main workspace info model
struct WorkspaceInfo: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let path: String
    let lastOpened: Date?
    var projectType: ProjectType
    var isFavorite: Bool = false
    var lastActivity: Date?
    var tags: [String] = []
    
    init(name: String, path: String, lastOpened: Date?, projectType: ProjectType? = nil, isFavorite: Bool = false) {
        self.name = name
        self.path = path
        self.lastOpened = lastOpened
        self.isFavorite = isFavorite
        
        // Detect project type if not provided
        if let type = projectType {
            self.projectType = type
        } else {
            self.projectType = Self.detectProjectType(from: path)
        }
    }
    
    static func == (lhs: WorkspaceInfo, rhs: WorkspaceInfo) -> Bool {
        return lhs.path == rhs.path
    }
    
    // Method to detect project type based on files in directory
    static func detectProjectType(from path: String) -> ProjectType {
        let fileManager = FileManager.default
        
        // Check for project files that would indicate specific frameworks
        let projectIndicators: [(file: String, type: ProjectType)] = [
            ("next.config.js", .nextjs),
            ("package.json", .node), // Check for React or Node after
            ("angular.json", .angular),
            ("vue.config.js", .vue),
            ("pubspec.yaml", .flutter),
            ("Cargo.toml", .rust),
            ("go.mod", .go),
            ("pom.xml", .java),
            ("build.gradle", .kotlin),
            ("composer.json", .php),
            ("requirements.txt", .python),
            ("Gemfile", .ruby),
            ("config/routes.rb", .rails),
            ("manage.py", .django),
            ("artisan", .laravel),
            ("*.csproj", .dotnet),
            ("Package.swift", .swift)
        ]
        
        // First check the root directory for indicator files
        if fileManager.fileExists(atPath: path) {
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: path)
                
                // Check for package.json to distinguish between React and regular Node
                if contents.contains("package.json") {
                    let packageJsonPath = "\(path)/package.json"
                    if fileManager.fileExists(atPath: packageJsonPath) {
                        do {
                            let packageJsonData = try Data(contentsOf: URL(fileURLWithPath: packageJsonPath))
                            let packageJson = try JSONSerialization.jsonObject(with: packageJsonData) as? [String: Any]
                            
                            if let dependencies = packageJson?["dependencies"] as? [String: Any] {
                                if dependencies["react"] != nil {
                                    return .react
                                }
                                if dependencies["next"] != nil {
                                    return .nextjs
                                }
                                if dependencies["vue"] != nil {
                                    return .vue
                                }
                                if dependencies["@angular/core"] != nil {
                                    return .angular
                                }
                            }
                            return .node
                        } catch {
                            // Just continue with other detection methods
                        }
                    }
                }
                
                // Check for other project indicators
                for (file, type) in projectIndicators {
                    if file.contains("*") {
                        // Handle glob patterns
                        let pattern = file.replacingOccurrences(of: "*", with: "")
                        if contents.contains(where: { $0.hasSuffix(pattern) }) {
                            return type
                        }
                    } else if contents.contains(file) {
                        return type
                    }
                }
                
                // Check file extensions to make a guess based on predominant language
                var extensionCounts: [String: Int] = [:]
                for file in contents {
                    let ext = (file as NSString).pathExtension.lowercased()
                    if !ext.isEmpty {
                        extensionCounts[ext, default: 0] += 1
                    }
                }
                
                let languageMap: [String: ProjectType] = [
                    "swift": .swift,
                    "kt": .kotlin,
                    "java": .java,
                    "py": .python,
                    "rb": .ruby,
                    "go": .go,
                    "rs": .rust,
                    "php": .php,
                    "cs": .dotnet,
                    "ts": .node,
                    "tsx": .react,
                    "jsx": .react,
                    "vue": .vue
                ]
                
                // Find most common extension
                if let mostCommon = extensionCounts.max(by: { $0.value < $1.value }) {
                    if let type = languageMap[mostCommon.key] {
                        return type
                    }
                }
            } catch {
                // If we can't read the directory, return unknown
                return .unknown
            }
        }
        
        return .unknown
    }
}

// Helper struct for JSON parsing
struct WorkspaceJSON: Codable {
    let folder: String
    
    enum CodingKeys: String, CodingKey {
        case folder
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var folderPath = try container.decode(String.self, forKey: .folder)
        
        // Remove 'file://' prefix if present
        if folderPath.hasPrefix("file://") {
            folderPath = String(folderPath.dropFirst(7))
        }
        
        self.folder = folderPath
    }
}

