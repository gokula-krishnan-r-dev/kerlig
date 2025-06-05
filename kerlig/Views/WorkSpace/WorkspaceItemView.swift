import SwiftUI

struct WorkspaceItemView: View {
    let workspace: WorkspaceInfo
    let isSelected: Bool
    var isOrganizationMode: Bool = false
    var isWorkspaceSelected: Bool = false
    var onWorkspaceToggle: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator for organization mode
            if isOrganizationMode {
                Button(action: {
                    onWorkspaceToggle?()
                }) {
                    ZStack {
                        Circle()
                            .stroke(isWorkspaceSelected ? Color.purple : Color.secondary.opacity(0.5), lineWidth: 2)
                            .frame(width: 20, height: 20)
                        
                        if isWorkspaceSelected {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Project type icon
            ZStack {
                Circle()
                    .fill(workspace.projectType.color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: workspace.projectType.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(workspace.projectType.color)
            }
            .padding(.trailing, 4)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(workspace.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    // Framework/language badge
                    Text(workspace.projectType.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(workspace.projectType.color.opacity(0.1))
                        .foregroundColor(workspace.projectType.color)
                        .cornerRadius(4)
                }
                
                Text(workspace.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            // Right side info
            VStack(alignment: .trailing, spacing: 2) {
                // Last opened date
                if let lastOpened = workspace.lastOpened {
                    Text(lastOpened, style: .relative)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                // Organization mode indicator
                if isOrganizationMode && isWorkspaceSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.system(size: 10))
                        Text("Selected")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.purple)
                }
                
                // Favorite indicator
                if workspace.isFavorite && !isOrganizationMode {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColorForState)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColorForState, lineWidth: borderWidthForState)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isWorkspaceSelected)
    }
    
    // Computed properties for styling based on state
    private var backgroundColorForState: Color {
        if isOrganizationMode && isWorkspaceSelected {
            return Color.purple.opacity(0.1)
        } else if isSelected {
            return Color.accentColor.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var borderColorForState: Color {
        if isOrganizationMode && isWorkspaceSelected {
            return Color.purple.opacity(0.3)
        } else if isSelected {
            return Color.accentColor
        } else {
            return Color.clear
        }
    }
    
    private var borderWidthForState: CGFloat {
        if (isOrganizationMode && isWorkspaceSelected) || isSelected {
            return 1
        } else {
            return 0
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        // Normal mode
        WorkspaceItemView(
            workspace: WorkspaceInfo(
                name: "Sample Project",
                path: "/Users/example/Projects/SampleProject",
                lastOpened: Date(),
                projectType: .react,
                isFavorite: true
            ),
            isSelected: false
        )
        
        // Organization mode - not selected
        WorkspaceItemView(
            workspace: WorkspaceInfo(
                name: "Another Project",
                path: "/Users/example/Projects/AnotherProject",
                lastOpened: Date().addingTimeInterval(-86400),
                projectType: .swift
            ),
            isSelected: false,
            isOrganizationMode: true,
            isWorkspaceSelected: false,
            onWorkspaceToggle: {}
        )
        
        // Organization mode - selected
        WorkspaceItemView(
            workspace: WorkspaceInfo(
                name: "Selected Project",
                path: "/Users/example/Projects/SelectedProject",
                lastOpened: Date().addingTimeInterval(-172800),
                projectType: .python
            ),
            isSelected: false,
            isOrganizationMode: true,
            isWorkspaceSelected: true,
            onWorkspaceToggle: {}
        )
    }
    .padding()
} 