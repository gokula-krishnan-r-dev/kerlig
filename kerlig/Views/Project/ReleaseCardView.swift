import SwiftUI

struct ReleaseCard: View {
    let release: Release
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: release.status.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(release.status.color)
                    
                    Spacer()
                    
                    Text(release.status.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(release.status.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(release.status.color.opacity(0.2))
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("v\(release.version)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(release.name)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                if !release.description.isEmpty {
                    Text(release.description)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .hoverEffect(.lift)
    }
}

