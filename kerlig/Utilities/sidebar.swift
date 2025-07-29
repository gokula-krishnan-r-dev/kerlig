enum SidebarItem: String, Identifiable, CaseIterable {
    case dashboard = "Dashboard"
    case taskManagement = "Task Management"
    case clipboardHistory = "Clipboard History"
    case history = "History"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .taskManagement: return "checklist"
        case .clipboardHistory: return "doc.on.clipboard"
        case .history: return "clock"
        }
    }
}
