import Foundation
import SwiftUI
// MARK: - Models
struct CustomAction: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var description: String
    var systemPrompt: String
    var icon: String
    var shortcutKey: String?
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID, name: String, description: String, systemPrompt: String, icon: String, shortcutKey: String? = nil, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.systemPrompt = systemPrompt
        self.icon = icon
        self.shortcutKey = shortcutKey
        self.isEnabled = isEnabled
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    mutating func update(name: String, description: String, systemPrompt: String, icon: String, shortcutKey: String?) {
        self.name = name
        self.description = description
        self.systemPrompt = systemPrompt
        self.icon = icon
        self.shortcutKey = shortcutKey
        self.updatedAt = Date()
    }
}



// MARK: - Navigation Items
enum NavigationItem: String, CaseIterable, Identifiable {
    case allActions = "All Actions"
    case enabledActions = "Enabled Actions"
    case recentlyUsed = "Recently Used"
    case createNew = "Create New"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .allActions: return "list.bullet"
        case .enabledActions: return "checkmark.circle"
        case .recentlyUsed: return "clock"
        case .createNew: return "plus.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .allActions: return .blue
        case .enabledActions: return .green
        case .recentlyUsed: return .orange
        case .createNew: return .purple
        }
    }
}
