import SwiftUI
struct ProjectRowTaskView: View {
    let project: Project
    let isSelected: Bool
    let onSelect: () -> Void
    var onDelete: (() -> Void)? = nil
    
    @State private var isHovered = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Project logo or color circle
                if let logoData = project.logoImageData, let nsImage = NSImage(data: logoData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                } else {
                    Circle()
                        .fill(project.color ?? .blue)
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .white : .gray)
                        .lineLimit(1)
                    
                    Text(project.description)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Color(hex: "#007AFF"))
                        .frame(width: 8, height: 8)
                }
                
                if isHovered || isSelected {
                    Button(action: {
                        showDeleteConfirm = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(6)
                            .background(Color(hex: "#3C3C3E"))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Delete project")
                    .confirmationDialog("Delete Project", isPresented: $showDeleteConfirm) {
                        Button("Delete", role: .destructive) {
                            if let onDelete = onDelete {
                                onDelete()
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to delete '\(project.title)'? This will delete all associated releases and tasks.")
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#2C2C2E") : (isHovered ? Color(hex: "#1C1C1E") : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "#007AFF").opacity(0.3) : Color.clear, lineWidth: 1)
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
// MARK: - Supporting Types

enum FilterOption: String {
    case all = "All Tasks"
    case completed = "Completed"
    case incomplete = "Incomplete"
}