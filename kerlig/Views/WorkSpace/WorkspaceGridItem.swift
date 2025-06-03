import SwiftUI

struct WorkspaceGridItem: View {
    let workspace: WorkspaceInfo
    let isSelected: Bool
    let onSelect: () -> Void
    let onOpen: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with project icon
            HStack(spacing: 8) {
                // Project type icon
                ZStack {
                    Circle()
                        .fill(workspace.projectType.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: workspace.projectType.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(workspace.projectType.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    // Workspace name
                    Text(workspace.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    // Project type badge
                    Text(workspace.projectType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(workspace.projectType.color.opacity(0.1))
                        .foregroundColor(workspace.projectType.color)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // Favorite icon if applicable
                if workspace.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 14))
                }
            }
            
            // Path
            Text(workspace.path)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            // Last opened date
            if let lastOpened = workspace.lastOpened {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    
                    Text(lastOpened, style: .relative)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(height: 130)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
