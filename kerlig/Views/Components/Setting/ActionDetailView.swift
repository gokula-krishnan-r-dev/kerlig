import SwiftUI
import Carbon.HIToolbox

// MARK: - Action Detail View
struct ActionDetailView: View {
    let action: CustomAction
    let storage: CustomActionsStorage
    let onEdit: (CustomAction) -> Void
    let onDelete: (CustomAction) -> Void
        
    @State private var showingDeleteAlert = false
    @State private var actionName: String = ""
    @State private var systemPrompt: String = ""
    @State private var isAiEnhancePrompt = false
    //description
    @State private var description: String = ""


    //AIService
    @State private var aiService = AIService()
    
    // Professional shortcut recording
    @StateObject private var shortcutRecorder = ShortcutRecorderService()
    @State private var showingShortcutConflict = false
    @State private var conflictingAction: String = ""
    @State private var pendingShortcut: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                detailHeader

                defaultEditor

                //edit short cut
                editShortCut
                
                // System prompt
                systemPromptSection

                detailContent

                // Metadata
                metadataSection
            }
            .padding(24)
        }
        .onAppear {
            actionName = action.name
            systemPrompt = action.systemPrompt
            description = action.description
        }
        .background(Color(NSColor.textBackgroundColor))
        .alert("Delete Action", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete(action)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(action.name)'? This action cannot be undone.")
        }
        .alert("Shortcut Conflict", isPresented: $showingShortcutConflict) {
            Button("Replace") {
                saveShortcutDespiteConflict()
            }
            Button("Cancel", role: .cancel) {
                pendingShortcut = nil
                shortcutRecorder.cancelRecording()
            }
        } message: {
            Text("The shortcut '⌘+\(pendingShortcut ?? "")' is already used by '\(conflictingAction)'. Do you want to replace it?")
        }
    }
    
    private var detailHeader: some View {
        HStack {
            Image(systemName: action.icon)
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Color.blue.opacity(0.1)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(action.name)
                    .font(.title.bold())
                    .foregroundColor(.primary)
                
                HStack {
                    if let shortcut = action.shortcutKey {
                        Text("⌘+\(shortcut)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.secondary.opacity(0.1)))
                    }
                    
                    Circle()
                        .fill(action.isEnabled ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(action.isEnabled ? "Enabled" : "Disabled")
                        .font(.subheadline)
                        .foregroundColor(action.isEnabled ? .green : .gray)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Edit") {
                    onEdit(action)
                }
                .buttonStyle(.bordered)
                
                Menu {
                    Button(action: { storage.toggleAction(action) }) {
                        Label(action.isEnabled ? "Disable" : "Enable", systemImage: action.isEnabled ? "pause.circle" : "play.circle")
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .menuStyle(BorderlessButtonMenuStyle())
            }
        }
    }

    private var defaultEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    TextField("Action name", text: $actionName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: actionName) { oldValue, newValue in
                            updateActionProperty(\.name, value: newValue)
                        }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    TextField("Action description", text: $description)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: description) { oldValue, newValue in
                            updateActionProperty(\.description, value: newValue)
                        }
                }
            }
        }
    }

    private func updateActionProperty<T>(_ keyPath: WritableKeyPath<CustomAction, T>, value: T) {
        var updatedAction = action
        updatedAction[keyPath: keyPath] = value
        updatedAction.updatedAt = Date()
        storage.updateAction(updatedAction)
    }
    
    private var detailContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Status")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Toggle("Enabled", isOn: .constant(action.isEnabled))
                        .toggleStyle(SwitchToggleStyle())
                        .onChange(of: action.isEnabled) { oldValue, newValue in
                            storage.toggleAction(action)
                        }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(action.isEnabled ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        
                        Text(action.isEnabled ? "Active" : "Inactive")
                            .font(.subheadline)
                            .foregroundColor(action.isEnabled ? .green : .gray)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))
            }
        }
    }

    //editShortCut
    private var editShortCut: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Keyboard Shortcut")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if shortcutRecorder.isRecording {
                    Button("Cancel") {
                        shortcutRecorder.cancelRecording()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    if shortcutRecorder.isRecording {
                        shortcutRecorder.stopRecording()
                    } else {
                        shortcutRecorder.startRecording()
                    }
                }) {
                    HStack(spacing: 8) {
                        if shortcutRecorder.isRecording {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text("Recording... Press any key")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.blue)
                        } else {
                            Image(systemName: "keyboard")
                                .font(.system(size: 14))
                            
                            Text(pendingShortcut ?? "Click to Record")
                                .font(.system(size: 13, weight: .medium))
                        }
                        
                        Spacer()
                        
                        if !shortcutRecorder.isRecording {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(shortcutRecorder.isRecording ? 
                                  LinearGradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)], 
                                                startPoint: .topLeading, endPoint: .bottomTrailing) :
                                  LinearGradient(colors: [Color(NSColor.controlBackgroundColor), Color(NSColor.controlBackgroundColor).opacity(0.8)],
                                                startPoint: .top, endPoint: .bottom))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(shortcutRecorder.isRecording ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2), 
                                           lineWidth: shortcutRecorder.isRecording ? 2 : 1)
                            )
                    )
                    .scaleEffect(shortcutRecorder.isRecording ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: shortcutRecorder.isRecording)
                }
                .buttonStyle(.plain)
                .disabled(shortcutRecorder.isRecording)
                
                if action.shortcutKey != nil && !shortcutRecorder.isRecording {
                    Button(action: clearShortcut) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.1))
                    )
                    .help("Remove shortcut")
                }
            }
            
            // Current shortcut display
            if let shortcutKey = action.shortcutKey {
                HStack {
                    Text("Current:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("⌘+\(shortcutKey)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], 
                                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                }
            }
            
            // Help text
            Text(shortcutRecorder.isRecording ? 
                 "Press any key combination to create a shortcut. Escape to cancel." :
                 "Click the button above to record a new keyboard shortcut for this action.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
        )
        .onChange(of: shortcutRecorder.recordedShortcut) { oldValue, newValue in
            if let recorded = newValue {
                handleRecordedShortcut(recorded)
            }
        }
    }
    
    // MARK: - Shortcut Recording Functions
    
    private func getShortcutDisplayText() -> String {
        if let shortcut = action.shortcutKey {
            return shortcut
        } else {
            return "Click to Record"
        }
    }
    
    private func clearShortcut() {
        var updatedAction = action
        updatedAction.shortcutKey = nil
        updatedAction.updatedAt = Date()
        storage.updateAction(updatedAction)
        
        // Provide haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
    
    private func handleRecordedShortcut(_ shortcut: ShortcutRecorderService.KeyboardShortcut) {
        let shortcutString = shortcut.storageString
        
        // Check for conflicts
        if let conflictingAction = storage.actions.first(where: { $0.shortcutKey == shortcutString && $0.id != action.id }) {
            self.conflictingAction = conflictingAction.name
            self.pendingShortcut = shortcutString
            showingShortcutConflict = true
        } else {
            saveShortcut(shortcutString)
        }
    }
    
    private func saveShortcut(_ shortcut: String) {
        var updatedAction = action
        updatedAction.shortcutKey = shortcut
        updatedAction.updatedAt = Date()
        storage.updateAction(updatedAction)
        
        // Show success feedback with animation
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
            // Update any relevant UI state
        }
        
        // Provide haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        
        // Reset pending shortcut
        pendingShortcut = nil
    }
    
    private func saveShortcutDespiteConflict() {
        guard let shortcut = pendingShortcut else { return }
        
        // Remove shortcut from conflicting action
        if let conflictingActionIndex = storage.actions.firstIndex(where: { $0.shortcutKey == shortcut && $0.id != action.id }) {
            var conflictingAction = storage.actions[conflictingActionIndex]
            conflictingAction.shortcutKey = nil
            conflictingAction.updatedAt = Date()
            storage.updateAction(conflictingAction)
        }
        
        saveShortcut(shortcut)
    }
    
    private var systemPromptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("System Prompt")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    //open ai enhance prompt
                    let aiEnhancePrompt = aiService.aiEnhancePrompt(systemPrompt)
                    systemPrompt = aiEnhancePrompt

                    //update action
                    updateActionProperty(\.systemPrompt, value: aiEnhancePrompt)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("AI Enhance")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.purple.opacity(0.1)))
                    .foregroundColor(.purple)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView {
                TextEditor(text: Binding(
                    get: { systemPrompt },
                    set: { 
                        systemPrompt = $0
                        updateActionProperty(\.systemPrompt, value: $0)
                    }
                ))
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .frame(maxHeight: 300)
            
            Text("This prompt will be sent to the AI along with the user's input")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetadataCard(
                    title: "Created",
                    value: DateFormatter.localizedString(from: action.createdAt, dateStyle: .medium, timeStyle: .short),
                    icon: "calendar.badge.plus"
                )
                
                MetadataCard(
                    title: "Last Updated",
                    value: DateFormatter.localizedString(from: action.updatedAt, dateStyle: .medium, timeStyle: .short),
                    icon: "clock"
                )
            }
        }
    }
}



#Preview {
    ActionDetailView(
        action: CustomAction(
            id: UUID(),
            name: "Test Action",
            description: "Test description",
            systemPrompt: "Test system prompt",
            icon: "wand.and.stars",
            shortcutKey: "T"
        ),
        storage: CustomActionsStorage(),
        onEdit: { _ in },
        onDelete: { _ in }
    )
    .frame(width: 600, height: 800)
}
