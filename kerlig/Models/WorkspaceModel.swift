import Foundation

struct WorkspaceInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let lastOpened: Date?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
}

struct WorkspaceJSON: Codable {
    let folder: String
    
    enum CodingKeys: String, CodingKey {
        case folder
    }
}