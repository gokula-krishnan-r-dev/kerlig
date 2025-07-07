import SwiftUI

struct EnhancedProjectRowView: View {
    let project: Project
    let isSelected: Bool
    
    // Callbacks for actions
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onArchive: () -> Void
    let onExport: () -> Void
    
    @State private var isHovered = false
    @State private var showContextMenu = false
    @State private var contextMenuPosition: CGPoint = .zero
    
    var body: some View {
        HStack(spacing: 16) {
            // Project icon and name
            HStack(spacing: 12) {
                // Project logo
                if let logoData = project.logoImageData, let nsImage = NSImage(data: logoData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    Circle()
                        .fill(project.color ?? .blue)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(project.title.prefix(1)))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(1)
                    
                    // Status badges
                    HStack(spacing: 6) {
                        if project.isArchived {
                            StatusBadge(text: "Archived", color: .gray)
                        }
                        
                        // Get release count
                        let releaseCount = project.releaseIds.count
                        if releaseCount > 0 {
                            StatusBadge(text: "\(releaseCount) \(releaseCount == 1 ? "Release" : "Releases")", color: .blue)
                        }
                    }
                }
            }
            .frame(width: 250, alignment: .leading)
            
            // Description
            Text(project.description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            // Last modified date
            Text(project.lastModified, style: .relative)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .leading)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(isHovered ? .white : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Edit project")
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(isHovered ? 1.0 : 0.7))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Delete project")
                
                Button(action: {
                    showContextMenu.toggle()
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(isHovered ? .white : .gray)
                        .rotationEffect(.degrees(90))
                }
                .buttonStyle(PlainButtonStyle())
                .help("More options")
                .overlay(
                    ZStack {
                        if showContextMenu {
                            ContextMenuView(
                                onDuplicate: onDuplicate,
                                onArchive: onArchive,
                                onExport: onExport,
                                isArchived: project.isArchived
                            )
                            .offset(x: -100, y: 30)
                            .zIndex(100)
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.2), value: showContextMenu)
                )
            }
            .frame(width: 120)
            .opacity(isHovered || isSelected ? 1 : 0.7)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onSelect()
            if showContextMenu {
                showContextMenu = false
            }
        }
        .onChange(of: isSelected) { _, newValue in
            if !newValue && showContextMenu {
                showContextMenu = false
            }
        }
    }
}

// Status badge component
struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}

// Context menu component
struct ContextMenuView: View {
    let onDuplicate: () -> Void
    let onArchive: () -> Void
    let onExport: () -> Void
    let isArchived: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ContextMenuItem(
                icon: "doc.on.doc",
                title: "Duplicate",
                action: onDuplicate
            )
            
            Divider()
                .opacity(0.3)
            
            ContextMenuItem(
                icon: isArchived ? "tray.and.arrow.up" : "archivebox",
                title: isArchived ? "Unarchive" : "Archive",
                action: onArchive
            )
            
            Divider()
                .opacity(0.3)
            
                            ContextMenuItem(
                    icon: "square.and.arrow.up",
                    title: "Export as JSON",
                    action: onExport
                )
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// Context menu item component
struct ContextMenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(isHovered ? Color.gray.opacity(0.15) : Color.clear)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}

// Preview provider
struct EnhancedProjectRowView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedProjectRowView(
            project: Project(
                title: "Sample Project",
                description: "This is a sample project description",
                releaseIds: [UUID(), UUID()]
            ),
            isSelected: false,
            onSelect: {},
            onDelete: {},
            onEdit: {},
            onDuplicate: {},
            onArchive: {},
            onExport: {}
        )
        .frame(width: 800)
        .preferredColorScheme(.dark)
    }
} 