import SwiftUI

// MARK: - Component Views
struct ProjectCard: View {
    let project: Project
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // Project logo
                    if let logoData = project.logoImageData, let nsImage = NSImage(data: logoData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                    } else {
                        Circle()
                            .fill(project.color ?? .blue)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(String(project.title.prefix(1)))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(project.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(project.description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                HStack {
                    Text("Last updated")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(project.lastModified, style: .relative)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .padding(20)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .hoverEffect(.lift)
    }
}