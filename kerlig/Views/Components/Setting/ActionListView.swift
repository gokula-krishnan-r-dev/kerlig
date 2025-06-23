import SwiftUI

// MARK: - Action List View
struct ActionListView: View {
    let actions: [CustomAction]
    let storage: CustomActionsStorage
    let searchText: String
    let selectedNavigation: NavigationItem
    @State private var hoveredAction: UUID?
    let onSelectAction: (CustomAction) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            listHeader
            
            if actions.isEmpty {
                emptyStateView
            } else {
                // Actions Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
                    ], spacing: 16) {
                        ForEach(actions) { action in
                            ActionCardView(
                                action: action,
                                storage: storage,
                                isHovered: hoveredAction == action.id,
                                onSelect: { onSelectAction(action) },
                                onHover: { isHovered in
                                    hoveredAction = isHovered ? action.id : nil
                                }
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
    
    private var listHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedNavigation.rawValue)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                if !searchText.isEmpty {
                    Text("Showing \(actions.count) results for '\(searchText)'")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(actions.count) actions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Menu {
                    Button("Sort by Name") { /* TODO */ }
                    Button("Sort by Date Created") { /* TODO */ }
                    Button("Sort by Date Modified") { /* TODO */ }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .menuStyle(BorderlessButtonMenuStyle())
                
                Button(action: { /* TODO: Grid/List toggle */ }) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(NSColor.textBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedNavigation == .createNew ? "plus.circle" : "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            if selectedNavigation == .createNew || actions.isEmpty {
                Button("Create New Action") {
                    // TODO: Create new action
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var emptyStateTitle: String {
        switch selectedNavigation {
        case .allActions:
            return searchText.isEmpty ? "No Actions Yet" : "No Results Found"
        case .enabledActions:
            return "No Enabled Actions"
        case .recentlyUsed:
            return "No Recent Actions"
        case .createNew:
            return "Create Your First Action"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedNavigation {
        case .allActions:
            return searchText.isEmpty ? 
                "Create your first custom action to get started with automated AI workflows." :
                "Try adjusting your search terms or create a new action."
        case .enabledActions:
            return "Enable some actions to see them here. Go to All Actions to manage your actions."
        case .recentlyUsed:
            return "Actions you use will appear here for quick access."
        case .createNew:
            return "Custom actions let you create reusable AI workflows with specific prompts and behaviors."
        }
    }
}
