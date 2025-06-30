import SwiftUI

// New supporting views
struct ReleaseRowView: View {
    let release: Release
    let projectTitle: String
    let isSelected: Bool
    let onSelect: () -> Void
    var onDelete: (() -> Void)? = nil
    var projectLogoData: Data? = nil
    
    @State private var isHovered = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Project logo or status icon
                if let logoData = projectLogoData, let nsImage = NSImage(data: logoData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                } else {
                    Image(systemName: release.status.iconName)
                        .foregroundColor(release.status.color)
                        .font(.system(size: 14))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("v\(release.version) - \(release.name)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? .white : .gray)
                    
                    Text(projectTitle)
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Color(hex: "#007AFF"))
                        .frame(width: 6, height: 6)
                }
                
                if isHovered || isSelected {
                    Button(action: {
                        showDeleteConfirm = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(5)
                            .background(Color(hex: "#3C3C3E"))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Delete release")
                    .confirmationDialog("Delete Release", isPresented: $showDeleteConfirm) {
                        Button("Delete", role: .destructive) {
                            if let onDelete = onDelete {
                                onDelete()
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to delete release '\(release.name)'? This will delete all associated tasks.")
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color(hex: "#2C2C2E") : (isHovered ? Color(hex: "#1C1C1E") : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? release.status.color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
