import SwiftUI

// MARK: - Action Editor View
struct ActionEditorView: View {
    let storage: CustomActionsStorage
    let action: CustomAction?
    let onSave: (CustomAction) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var systemPrompt: String = ""
    @State private var selectedIcon: String = "wand.and.stars"
    @State private var shortcutKey: String = ""
    @State private var isEnabled: Bool = true
    
    // Available icons
    private let availableIcons = [
        "wand.and.stars", "sparkles", "text.cursor", "doc.text",
        "pencil.line", "checkmark.seal", "arrow.triangle.2.circlepath",
        "magnifyingglass", "globe", "translate", "scissors",
        "textformat", "bold", "italic", "underline",
        "list.bullet", "checklist", "doc.text.magnifyingglass"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Basic Information
                    basicInfoSection
                    
                    // Icon Selection
                    iconSelectionSection
                    
                    // System Prompt
                    systemPromptSection
                    
                    // Advanced Settings
                    advancedSettingsSection
                }
            }
            .padding(16)
            .navigationTitle(action == nil ? "New Action" : "Edit Action")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAction()
                    }
                    .disabled(name.isEmpty || systemPrompt.isEmpty)
                }
            }
        }
        .frame(width: 600, height: 600)
        .onAppear {
            if let action = action {
                name = action.name
                description = action.description
                systemPrompt = action.systemPrompt
                selectedIcon = action.icon
                shortcutKey = action.shortcutKey ?? ""
                isEnabled = action.isEnabled
            }
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    TextField("Enter action name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    TextField("Brief description of what this action does", text: $description)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }
    
    private var iconSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Icon")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(availableIcons, id: \.self) { icon in
                    Button(action: { selectedIcon = icon }) {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(selectedIcon == icon ? .white : .blue)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIcon == icon ? Color.blue : Color.blue.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var systemPromptSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Prompt")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("This prompt will be sent to the AI along with the user's input")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $systemPrompt)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced Settings")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Keyboard Shortcut")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        TextField("Single letter (e.g., E)", text: $shortcutKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    
                    Spacer()
                    
                    Toggle("Enabled", isOn: $isEnabled)
                        .toggleStyle(SwitchToggleStyle())
                }
                
                Text("Shortcut will be ⌘+[letter]. Leave empty for no shortcut.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func saveAction() {
        let newAction: CustomAction
        
        if let existingAction = action {
            var updatedAction = existingAction
            updatedAction.update(
                name: name,
                description: description,
                systemPrompt: systemPrompt,
                icon: selectedIcon,
                shortcutKey: shortcutKey.isEmpty ? nil : shortcutKey.uppercased()
            )
            newAction = updatedAction
        } else {
            newAction = CustomAction(
                id:UUID(),
                name: name,
                description: description,
                systemPrompt: systemPrompt,
                icon: selectedIcon,
                shortcutKey: shortcutKey.isEmpty ? nil : shortcutKey.uppercased(),
                isEnabled: isEnabled
            )
        }
        
        onSave(newAction)
        dismiss()
    }
}
