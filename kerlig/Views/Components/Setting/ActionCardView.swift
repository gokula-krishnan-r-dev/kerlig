import SwiftUI

// MARK: - Action Card View
struct ActionCardView: View {
    let action: CustomAction
    let storage: CustomActionsStorage
    let isHovered: Bool
    let onSelect: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: action.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        if let shortcut = action.shortcutKey {
                            Text("⌘+\(shortcut)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.secondary.opacity(0.1)))
                        }
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    Circle()
                        .fill(action.isEnabled ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                }
                
                // Description
                Text(action.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                // System prompt preview
                Text(action.systemPrompt)
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.05)))
                
                // Footer
                HStack {
                    Text("Updated \(RelativeDateTimeFormatter().localizedString(for: action.updatedAt, relativeTo: Date()))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { storage.toggleAction(action) }) {
                        Image(systemName: action.isEnabled ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(action.isEnabled ? .green : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isHovered ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2),
                                lineWidth: isHovered ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isHovered ? Color.black.opacity(0.1) : Color.clear,
                        radius: isHovered ? 8 : 0,
                        x: 0,
                        y: isHovered ? 4 : 0
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover(perform: onHover)
    }
}