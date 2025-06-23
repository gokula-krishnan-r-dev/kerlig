import SwiftUI

struct ActionsListView: View {
    @EnvironmentObject private var customActionsStorage: CustomActionsStorage
    @Binding var selectedActionId: String?
    @Binding var hoveredActionIndex: Int?
    var onSelectAction: (CustomAction) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(customActionsStorage.actions.enumerated()), id: \.element.id) { index, action in
                if action.isEnabled {
                    ActionRowView(
                        action: action,
                        isSelected: action.id.uuidString == selectedActionId,
                        isHovered: hoveredActionIndex == index,
                        index: index,
                        onSelect: { onSelectAction(action) },
                        onHover: { isHovered in
                            if isHovered {
                                hoveredActionIndex = index
                            } else if hoveredActionIndex == index {
                                hoveredActionIndex = nil
                            }
                        }
                    )
                    
                    if index < customActionsStorage.actions.filter({ $0.isEnabled }).count - 1 {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private struct ActionRowView: View {
        let action: CustomAction
        let isSelected: Bool
        let isHovered: Bool
        let index: Int
        let onSelect: () -> Void
        let onHover: (Bool) -> Void
        
        var body: some View {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    // Action icon
                    Image(systemName: action.icon)
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? .blue : .primary)
                        .frame(width: 20)
                        
                    // Action name
                    Text(action.name)
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? .blue : .primary)
                        
                    Spacer()
                        
                    // Keyboard shortcut (if available)
                    if let shortcutKey = action.shortcutKey {
                        Text("⌘+\(shortcutKey.uppercased())")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(3)
                    }
                        
                    // Execute arrow
                    Image(systemName: "return")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .background(isHovered ? Color.blue.opacity(0.1) : Color.clear)
            }
            .buttonStyle(PlainButtonStyle())
            .if(action.shortcutKey != nil) { view in
                view.keyboardShortcut(KeyEquivalent(Character(action.shortcutKey!)), modifiers: .command)
            }
            .onHover(perform: onHover)
        }
    }
}

// Helper extension for conditional modifiers
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}


