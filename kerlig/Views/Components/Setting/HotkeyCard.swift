import SwiftUI

struct HotkeyCard: View {
    let configuration: HotkeyConfiguration
    let isRecording: Bool
    let onToggle: () -> Void
    let onRecord: () -> Void
    let onClear: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Action Icon
            actionIcon
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Header
                HStack {
                    Text(configuration.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if configuration.isSystemDefault {
                        SystemDefaultBadge()
                    }
                    
                    Spacer()
                    
                    // Enable/Disable Toggle
                    Toggle("", isOn: .constant(configuration.isEnabled))
                        .onChange(of: configuration.isEnabled) { _ in
                            onToggle()
                        }
                        .toggleStyle(SwitchToggleStyle(tint: configuration.action.color))
                        .scaleEffect(0.8)
                        .help(configuration.isEnabled ? "Disable hotkey" : "Enable hotkey")
                }
                
                Text(configuration.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Shortcut Section
                HStack(spacing: 8) {
                    shortcutDisplay
                    
                    Spacer()
                    
                    // Action Buttons
                    actionButtons
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        )
        .opacity(configuration.isEnabled ? 1.0 : 0.6)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - Action Icon
    
    private var actionIcon: some View {
        ZStack {
            Circle()
                .fill(configuration.action.color.opacity(0.1))
                .frame(width: 40, height: 40)
            
            Image(systemName: configuration.action.icon)
                .foregroundColor(configuration.action.color)
                .font(.system(size: 18, weight: .medium))
        }
    }
    
    // MARK: - Shortcut Display
    
    private var shortcutDisplay: some View {
        HStack(spacing: 6) {
            if isRecording {
                recordingIndicator
            } else if configuration.isConfigured {
                configuredShortcut
            } else {
                notConfiguredIndicator
            }
        }
    }
    
    private var recordingIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "record.circle")
                .foregroundColor(.red)
                .font(.system(size: 12))
            
            Text("Recording...")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var configuredShortcut: some View {
        Text(configuration.displayShortcut)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
    }
    
    private var notConfiguredIndicator: some View {
        Text("Not Set")
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 6) {
            if isRecording {
                recordingButtons
            } else {
                normalButtons
            }
        }
    }
    
    private var recordingButtons: some View {
        HStack(spacing: 4) {
            Button("Cancel") {
                // Cancel recording logic would be handled by parent
            }
            .buttonStyle(SecondaryButtonStyle())
            .font(.system(size: 10))
            
            Text("Press keys...")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .italic()
        }
    }
    
    private var normalButtons: some View {
        HStack(spacing: 6) {
            // Record/Edit Button
            Button(action: onRecord) {
                HStack(spacing: 4) {
                    Image(systemName: configuration.isConfigured ? "pencil" : "plus")
                        .font(.system(size: 10))
                    Text(configuration.isConfigured ? "Edit" : "Set")
                        .font(.system(size: 10, weight: .medium))
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: configuration.action.color))
            .help(configuration.isConfigured ? "Edit shortcut" : "Set shortcut")
            
            // Clear Button (only show if configured)
            if configuration.isConfigured {
                Button(action: onClear) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                }
                .buttonStyle(SecondaryButtonStyle())
                .help("Clear shortcut")
            }
        }
    }
    
    // MARK: - Background and Border
    
    private var backgroundColor: Color {
        if isRecording {
            return Color.blue.opacity(0.05)
        } else if isHovered {
            return Color.primary.opacity(0.03)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isRecording {
            return Color.blue.opacity(0.3)
        } else if isHovered {
            return Color.primary.opacity(0.2)
        } else {
            return Color.primary.opacity(0.1)
        }
    }
    
    private var borderWidth: CGFloat {
        isRecording ? 1.5 : 1.0
    }
}

// MARK: - Supporting Views

struct SystemDefaultBadge: View {
    var body: some View {
        Text("System")
            .font(.system(size: 8, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray)
            )
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.1 : 0.05))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Compact Hotkey Card

struct CompactHotkeyCard: View {
    let configuration: HotkeyConfiguration
    let isRecording: Bool
    let onToggle: () -> Void
    let onRecord: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Action Icon
            ZStack {
                Circle()
                    .fill(configuration.action.color.opacity(0.1))
                    .frame(width: 24, height: 24)
                
                Image(systemName: configuration.action.icon)
                    .foregroundColor(configuration.action.color)
                    .font(.system(size: 12, weight: .medium))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(configuration.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Shortcut Display
                    if isRecording {
                        Text("Recording...")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.red)
                    } else if configuration.isConfigured {
                        Text(configuration.displayShortcut)
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(.blue)
                    } else {
                        Text("Not Set")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text(configuration.action.category.rawValue)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Enable Toggle
                    Toggle("", isOn: .constant(configuration.isEnabled))
                        .onChange(of: configuration.isEnabled) { _ in
                            onToggle()
                        }
                        .toggleStyle(SwitchToggleStyle(tint: configuration.action.color))
                        .scaleEffect(0.6)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 0.5)
                )
        )
        .opacity(configuration.isEnabled ? 1.0 : 0.6)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if !isRecording {
                onRecord()
            }
        }
    }
    
    private var backgroundColor: Color {
        if isRecording {
            return Color.blue.opacity(0.05)
        } else if isHovered {
            return Color.primary.opacity(0.03)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isRecording {
            return Color.blue.opacity(0.3)
        } else if isHovered {
            return Color.primary.opacity(0.2)
        } else {
            return Color.primary.opacity(0.1)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        HotkeyCard(
            configuration: HotkeyConfiguration(
                name: "Text Capture & AI",
                description: "Capture selected text and process with AI",
                shortcut: .optionSpace,
                action: .textCapture,
                isSystemDefault: true
            ),
            isRecording: false,
            onToggle: {},
            onRecord: {},
            onClear: {}
        )
        
        HotkeyCard(
            configuration: HotkeyConfiguration(
                name: "Voice Recording",
                description: "Start/stop voice recording",
                action: .voiceRecording
            ),
            isRecording: true,
            onToggle: {},
            onRecord: {},
            onClear: {}
        )
        
        CompactHotkeyCard(
            configuration: HotkeyConfiguration(
                name: "AI Panel",
                description: "Open AI interaction panel",
                action: .aiPanel
            ),
            isRecording: false,
            onToggle: {},
            onRecord: {}
        )
    }
    .padding()
    .frame(width: 400)
}