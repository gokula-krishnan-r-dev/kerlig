import SwiftUI
import AppKit
import Combine

// Internal struct for model option information
fileprivate struct ModelOption: Identifiable {
    let id: String
    let name: String
    let iconName: String
    let iconColor: Color
    let cost: Double
    let provider: String
    let capabilities: String
    let speed: String
    
    // Formatted cost string
    var formattedCost: String {
        return "$\(String(format: "%.5f", cost))/request"
    }
}

// Action struct for dynamic buttons
fileprivate struct AIPromptAction: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let shortcutKey: String
    let shortcutModifiers: EventModifiers
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    // Preset actions
    static let ask = AIPromptAction(id: "ask", name: "Ask", iconName: "arrow.right", shortcutKey: "p", shortcutModifiers: .command)
    static let fix = AIPromptAction(id: "fix", name: "Fix spelling and grammar", iconName: "sparkles.rectangle.stack", shortcutKey: "f", shortcutModifiers: .command)
    static let translate = AIPromptAction(id: "translate", name: "Translate", iconName: "globe", shortcutKey: "t", shortcutModifiers: .command)
    static let improve = AIPromptAction(id: "improve", name: "Improve writing", iconName: "pencil.line", shortcutKey: "i", shortcutModifiers: .command)
    static let summarize = AIPromptAction(id: "summarize", name: "Summarize", iconName: "text.redaction", shortcutKey: "s", shortcutModifiers: .command)
    static let makeShort = AIPromptAction(id: "makeShort", name: "Make shorter", iconName: "minus.forwardslash.plus", shortcutKey: "m", shortcutModifiers: .command)
    
    // All available actions
    static let allActions: [AIPromptAction] = [ask, fix, translate, improve, summarize, makeShort]
}

struct AIPromptField: View {
    @Binding var searchQuery: String
    @Binding var isProcessing: Bool
    @Binding var selectedTab: AIPromptTab
    @Binding var aiModel: String
    @EnvironmentObject var appState: AppState
    
    @State private var hasError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isHovering: Bool = false
    @State private var isModelMenuOpen: Bool = false
    @State private var selectedAction: AIPromptAction = AIPromptAction.ask
    @State private var showActionsList: Bool = false
    @State private var hoveredActionIndex: Int? = nil
    @State private var isDictating: Bool = false
    @State private var microphoneOpacity: Double = 1.0
    @State private var showDictationPulse: Bool = false
    
    // Rich model options for the dropdown
    private let modelOptions: [String: [ModelOption]] = [
        "OpenAI": [
            ModelOption(id: "gpt-4o", name: "GPT-4o", iconName: "sparkle.magnifyingglass", iconColor: .green, cost: 0.01, provider: "OpenAI", capabilities: "Excellent", speed: "Fast"),
            ModelOption(id: "gpt-4o-mini", name: "GPT-4o Mini", iconName: "sparkle", iconColor: .green, cost: 0.001, provider: "OpenAI", capabilities: "Good", speed: "Very Fast")
        ],
        "Anthropic": [
            ModelOption(id: "claude-3-opus", name: "Claude 3 Opus", iconName: "wand.and.stars", iconColor: .purple, cost: 0.015, provider: "Anthropic", capabilities: "Excellent", speed: "Medium"),
            ModelOption(id: "claude-3-sonnet", name: "Claude 3 Sonnet", iconName: "wand.and.stars.inverse", iconColor: .blue, cost: 0.003, provider: "Anthropic", capabilities: "Very Good", speed: "Fast"),
            ModelOption(id: "claude-3-haiku", name: "Claude 3 Haiku", iconName: "wand.and.rays", iconColor: .teal, cost: 0.00025, provider: "Anthropic", capabilities: "Good", speed: "Very Fast")
        ],
        "Google": [
            ModelOption(id: "gemini-pro", name: "Gemini Pro", iconName: "g.circle", iconColor: .orange, cost: 0.0005, provider: "Google", capabilities: "Good", speed: "Fast")
        ],
        "Cloudflare Workers AI": [
            // Text Models
            ModelOption(id: "@cf/meta/llama-3-8b-instruct", name: "Llama 3 8B Instruct", iconName: "cloud", iconColor: .orange, cost: 0.0005, provider: "Cloudflare", capabilities: "Good", speed: "Fast"),
            ModelOption(id: "@cf/meta/llama-3-70b-instruct", name: "Llama 3 70B Instruct", iconName: "cloud.bolt", iconColor: .orange, cost: 0.0015, provider: "Cloudflare", capabilities: "Very Good", speed: "Medium"),
            ModelOption(id: "@cf/mistral/mistral-7b-instruct-v0.1", name: "Mistral 7B Instruct", iconName: "wind", iconColor: .blue, cost: 0.0005, provider: "Cloudflare", capabilities: "Good", speed: "Fast"),
            ModelOption(id: "@cf/mistral/mistral-large-latest", name: "Mistral Large", iconName: "wind.snow", iconColor: .blue, cost: 0.0015, provider: "Cloudflare", capabilities: "Very Good", speed: "Medium"),


            //@cf/deepseek-ai/deepseek-r1-distill-qwen-32b
            ModelOption(id: "@cf/deepseek-ai/deepseek-r1-distill-qwen-32b", name: "DeepSeek R1 Distill Qwen 32B", iconName: "cloud.bolt", iconColor: .orange, cost: 0.0015, provider: "Cloudflare", capabilities: "Very Good", speed: "Medium"),


            //@hf/google/gemma-7b-it
            ModelOption(id: "@hf/google/gemma-7b-it", name: "Gemma 7B IT", iconName: "cloud.bolt", iconColor: .orange, cost: 0.0015, provider: "Cloudflare", capabilities: "Very Good", speed: "Medium"),

            //@hf/google/gemma-2-9b-it
            ModelOption(id: "@hf/google/gemma-2-9b-it", name: "Gemma 2 9B IT", iconName: "cloud.bolt", iconColor: .orange, cost: 0.0015, provider: "Cloudflare", capabilities: "Very Good", speed: "Medium"),

            //@hf/google/gemma-2-9b-it
            ModelOption(id: "@hf/google/gemma-2-9b-it", name: "Gemma 2 9B IT", iconName: "cloud.bolt", iconColor: .orange, cost: 0.0015, provider: "Cloudflare", capabilities: "Very Good", speed: "Medium"),


            // Embedding Models
            ModelOption(id: "@cf/baai/bge-base-en-v1.5", name: "BGE Base English", iconName: "square.stack.3d.up", iconColor: .teal, cost: 0.0001, provider: "Cloudflare", capabilities: "Embeddings", speed: "Very Fast"),
            ModelOption(id: "@cf/baai/bge-large-en-v1.5", name: "BGE Large English", iconName: "square.stack.3d.up.fill", iconColor: .teal, cost: 0.0002, provider: "Cloudflare", capabilities: "Embeddings", speed: "Fast"),
            
            // Vision Models
            ModelOption(id: "@cf/openai/clip-vit-b-32", name: "CLIP ViT-B/32", iconName: "eye", iconColor: .purple, cost: 0.0001, provider: "Cloudflare", capabilities: "Vision", speed: "Fast"),
            ModelOption(id: "@cf/openai/clip-vit-l-14", name: "CLIP ViT-L/14", iconName: "eye.fill", iconColor: .purple, cost: 0.0002, provider: "Cloudflare", capabilities: "Vision", speed: "Medium"),
            
            // Text-to-Image Models
            ModelOption(id: "@cf/stabilityai/stable-diffusion-xl-base-1.0", name: "Stable Diffusion XL", iconName: "paintbrush", iconColor: .pink, cost: 0.002, provider: "Cloudflare", capabilities: "Image Generation", speed: "Slow"),
            ModelOption(id: "@cf/lykon/dreamshaper-8-lcm", name: "Dreamshaper 8 LCM", iconName: "sparkles", iconColor: .pink, cost: 0.001, provider: "Cloudflare", capabilities: "Image Generation", speed: "Medium"),
            
            // Translation Models
            ModelOption(id: "@cf/meta/m2m100-1.2b", name: "M2M100 1.2B", iconName: "globe", iconColor: .green, cost: 0.0002, provider: "Cloudflare", capabilities: "Translation", speed: "Fast"),
            
            // Speech Recognition Models
            ModelOption(id: "@cf/openai/whisper", name: "Whisper", iconName: "waveform", iconColor: .blue, cost: 0.0005, provider: "Cloudflare", capabilities: "Speech-to-Text", speed: "Medium")
        ]
    ]
    
    var onSubmit: (String) -> Void
    var onCancel: () -> Void
    
    @FocusState private var searchQueryIsFocused: Bool
    @Binding var focusedField: FocusableField?
    
    // Enum for tabs that can be customized by parent
    public enum AIPromptTab {
        case blank
        case withContent
        case custom(String)
    }
    
    // Focus fields enum to be used by parent
    public enum FocusableField: Hashable {
        case searchField
        case actionButton(Int)
        case copyButton
        case insertButton
        case regenerateButton
        case custom(String)
    }
    
    init(
        searchQuery: Binding<String>,
        isProcessing: Binding<Bool>,
        selectedTab: Binding<AIPromptTab>,
        aiModel: Binding<String>,
        focusedField: Binding<FocusableField?>,
        onSubmit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._searchQuery = searchQuery
        self._isProcessing = isProcessing
        self._selectedTab = selectedTab
        self._aiModel = aiModel
        self._focusedField = focusedField
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }
    
    // Format input for display
    private var formattedQuery: String {
        if searchQuery.isEmpty {
            return "Type your query..."
        } else if searchQuery.count <= 20 {
            return searchQuery
        } else {
            return "\(searchQuery.prefix(20))..."
        }
    }
    
    // Get current selected model
    private var currentModel: ModelOption {
        // First try to find the model in the dictionary
        for (_, models) in modelOptions {
            if let model = models.first(where: { $0.id == appState.aiModel }) {
                return model
            }
        }
        
        // If not found, return first model from first provider as fallback
        return modelOptions.first?.value.first ?? 
               ModelOption(id: "gpt-4o", name: "GPT-4o", iconName: "sparkle.magnifyingglass", 
                           iconColor: .green, cost: 0.01, provider: "OpenAI", 
                           capabilities: "Excellent", speed: "Fast")
    }
    
    // Get all models as a flattened array
    private var allModels: [ModelOption] {
        var result: [ModelOption] = []
        for (_, models) in modelOptions {
            result.append(contentsOf: models)
        }
        return result
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Input field section
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16))
                    .foregroundColor(.purple)
                
                TextField("", text: $searchQuery)
                    .font(.system(size: 15))
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.primary)
                    .focused($searchQueryIsFocused)
                    .onSubmit {
                        submitPrompt()
                    }
                    .placeholder(when: searchQuery.isEmpty) {
                        Text("Type your query...")
                            .foregroundColor(.secondary.opacity(0.7))
                            .font(.system(size: 15))
                    }
                
                Spacer()
                
                // Dictation button with animation
                Button(action: {
                    toggleDictation()
                }) {
                    ZStack {
                        // Pulse animation for active dictation
                        if showDictationPulse {
                            Circle()
                                .fill(Color.red.opacity(0.3))
                                .frame(width: 30, height: 30)
                                .scaleEffect(showDictationPulse ? 1.5 : 1.0)
                                .opacity(showDictationPulse ? 0 : 0.3)
                                .animation(
                                    Animation.easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: false),
                                    value: showDictationPulse
                                )
                        }
                        
                        // Microphone icon
                        Image(systemName: isDictating ? "mic.fill" : "mic")
                            .font(.system(size: 14))
                            .foregroundColor(isDictating ? .red : .secondary)
                            .opacity(microphoneOpacity)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color(.controlBackgroundColor))
                                    .shadow(color: isDictating ? .red.opacity(0.3) : .clear, radius: 4, x: 0, y: 0)
                            )
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut("d", modifiers: [.function])
                .help("Start dictation (fn + D) or use your system dictation shortcut")
                .padding(.trailing, 4)
                
                if (!searchQuery.isEmpty) {
                    Button(action: {
                        searchQuery = ""
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            
            // Dictation helper text - shown when dictation is active
            if isDictating {
                HStack(spacing: 8) {
                    // Audio visualization
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { index in
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: 3, height: CGFloat.random(in: 5...15))
                                .animation(
                                    Animation.easeInOut(duration: 0.2)
                                        .repeatForever()
                                        .delay(Double(index) * 0.05),
                                    value: isDictating
                                )
                        }
                    }
                    .frame(width: 20)
                    
                    Text("Speak your prompt... Press fn+D or Esc to stop dictation")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        stopDictation()
                    }) {
                        Text("Stop")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.controlBackgroundColor).opacity(0.8))
                .cornerRadius(6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Action bar - conditionally displayed
            if appState.aiResponse.isEmpty && !searchQuery.isEmpty {
                actionsBar
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: !searchQuery.isEmpty || !appState.aiResponse.isEmpty || !isProcessing)
            }
            
            // Actions dropdown list - conditionally displayed
            if showActionsList && !searchQuery.isEmpty {
                actionsListView
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.2), value: showActionsList)
            }
            
            // Error message display
            if hasError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.3), value: hasError)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                searchQueryIsFocused = true
                focusedField = .searchField
            }
        }
        .overlay(
            Button("") {
                if isProcessing {
                    onCancel()
                } else if !searchQuery.isEmpty {
                    searchQuery = ""
                    hasError = false
                }
            }
            .keyboardShortcut(.escape, modifiers: [])
            .opacity(0)
        )
        // Add keyboard shortcuts for navigation
        .onKeyPress(.upArrow) {
            if showActionsList {
                navigateActions(direction: -1)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.downArrow) {
            if showActionsList {
                navigateActions(direction: 1)
                return .handled
            } else if !searchQuery.isEmpty {
                showActionsList = true
                hoveredActionIndex = 0
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.return) {
            if showActionsList, let index = hoveredActionIndex, index >= 0 && index < AIPromptAction.allActions.count {
                selectAndSubmitAction(AIPromptAction.allActions[index])
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.tab) {
            if !searchQuery.isEmpty {
                isModelMenuOpen = !isModelMenuOpen
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.escape) {
            if isDictating {
                stopDictation()
                return .handled
            }
            return .ignored
        }
//        // Function key + D shortcut for dictation
//        .onKeyPress(.init("d")) { event in
//            if event.modifiers.contains(.function) {
//                toggleDictation()
//                return .handled
//            }
//            return .ignored
//        }
    }
    
    // Action bar UI
    private var actionsBar: some View {
        HStack(spacing: 10) {
            // Action icon
            Image(systemName: selectedAction.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 20)
            
            // Dynamic action text with keyboard shortcut
            HStack(spacing: 4) {
                Text("\(selectedAction.name) \"\(formattedQuery)\"")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                
                HStack(spacing: 2) {
                    Text("⌘+\(selectedAction.shortcutKey.uppercased())")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(3)
                }
            }
            
            Spacer()
            
            // Model selector dropdown
            Menu {
                ForEach(Array(modelOptions.keys.sorted()), id: \.self) { provider in
                    Section(header: Text(provider)) {
                        ForEach(modelOptions[provider] ?? []) { model in
                            Button(action: {
                                appState.aiModel = model.id
                                isModelMenuOpen = false
                            }) {
                                HStack {
                                    Image(systemName: model.iconName)
                                        .foregroundColor(model.iconColor)
                                    
                                    VStack(alignment: .leading) {
                                        Text(model.name)
                                            .font(.system(size: 12))
                                        
                                        Text(model.formattedCost)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if appState.aiModel == model.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(currentModel.name)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    
                    // TAB indicator
                    Text("TAB")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(4)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.15))
                .cornerRadius(4)
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .menuIndicator(.hidden)
            .fixedSize()
            
            // Actions selector button (dropdown indicator)
            Button(action: {
                showActionsList.toggle()
                if showActionsList {
                    hoveredActionIndex = AIPromptAction.allActions.firstIndex(of: selectedAction)
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(4)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Run button
            Button(action: {
                submitPrompt()
            }) {
                HStack(spacing: 6) {
                    Text("Run")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.15))
                .cornerRadius(4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.blue)
        .cornerRadius(8)
    }
    
    // Actions list dropdown
    private var actionsListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(AIPromptAction.allActions.enumerated()), id: \.element.id) { index, action in
                Button(action: {
                    selectAndSubmitAction(action)
                }) {
                    HStack(spacing: 12) {
                        // Action icon
                        Image(systemName: action.iconName)
                            .font(.system(size: 14))
                            .foregroundColor(action.id == selectedAction.id ? .blue : .primary)
                            .frame(width: 20)
                        
                        // Action name
                        Text(action.name)
                            .font(.system(size: 13))
                            .foregroundColor(action.id == selectedAction.id ? .blue : .primary)
                        
                        Spacer()
                        
                        // Keyboard shortcut
                        Text("⌘+\(action.shortcutKey.uppercased())")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(3)
                        
                        // Execute arrow
                        Image(systemName: "return")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .background(hoveredActionIndex == index ? Color.blue.opacity(0.1) : Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { isHovered in
                    if isHovered {
                        hoveredActionIndex = index
                    } else if hoveredActionIndex == index {
                        hoveredActionIndex = nil
                    }
                }
                
                if index < AIPromptAction.allActions.count - 1 {
                    Divider()
                        .padding(.leading, 48)
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
    
    // Navigate through actions with arrow keys
    private func navigateActions(direction: Int) {
        guard !AIPromptAction.allActions.isEmpty else { return }
        
        if let currentIndex = hoveredActionIndex {
            let newIndex = (currentIndex + direction) % AIPromptAction.allActions.count
            hoveredActionIndex = newIndex < 0 ? AIPromptAction.allActions.count - 1 : newIndex
        } else {
            hoveredActionIndex = direction > 0 ? 0 : AIPromptAction.allActions.count - 1
        }
    }
    
    // Select and use an action
    private func selectAndSubmitAction(_ action: AIPromptAction) {
        selectedAction = action
        showActionsList = false
        submitPrompt()
    }
    
    // Function to validate and submit prompt
    private func submitPrompt() {
        // Validate input
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            withAnimation {
                hasError = true
                errorMessage = "Please enter a valid prompt"
            }
            return
        }
        
        // Clear any previous errors
        hasError = false
        errorMessage = ""
        
        // Create the appropriate prompt based on the selected action
        var actionPrompt = searchQuery
        
        switch selectedAction.id {
        case "fix":
            actionPrompt = "Fix spelling and grammar: \(searchQuery)"
        case "translate":
            actionPrompt = "Translate to English: \(searchQuery)"
        case "improve":
            actionPrompt = "Improve this writing: \(searchQuery)"
        case "summarize":
            actionPrompt = "Summarize this: \(searchQuery)"
        case "makeShort":
            actionPrompt = "Make this text shorter while preserving meaning: \(searchQuery)"
        default:
            // Default "ask" action uses the query as is
            break
        }
        
        // Submit the prompt with the action context
        onSubmit(actionPrompt)
    }
    
    // Toggle dictation on/off
    private func toggleDictation() {
        if isDictating {
            stopDictation()
        } else {
            startDictation()
        }
    }
    
    // Start dictation with animation
    private func startDictation() {
        isDictating = true
        showDictationPulse = true
        
        // Trigger native macOS dictation (using system shortcut)
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Note: This simulates pressing the dictation shortcut.
        // Users should have dictation enabled and configured in System Settings
        let fnKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x3F, keyDown: true)
        let fnKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x3F, keyDown: false)
        
        fnKeyDown?.flags = .maskSecondaryFn
        fnKeyUp?.flags = .maskSecondaryFn
        
        fnKeyDown?.post(tap: .cghidEventTap)
        fnKeyUp?.post(tap: .cghidEventTap)
        
        // Microphone "breathing" animation
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
            microphoneOpacity = 0.6
        }
    }
    
    // Stop dictation
    private func stopDictation() {
        isDictating = false
        showDictationPulse = false
        
        // Reset microphone opacity
        withAnimation {
            microphoneOpacity = 1.0
        }
        
        // Simulate Esc key to stop native dictation
        let source = CGEventSource(stateID: .combinedSessionState)
        let escKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x35, keyDown: true)
        let escKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x35, keyDown: false)
        
        escKeyDown?.post(tap: .cghidEventTap)
        escKeyUp?.post(tap: .cghidEventTap)
    }
}

// MARK: - Placeholder Extension for TextField
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Keyboard Shortcut Extension
extension View {
    func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers = .command, action: @escaping () -> Void) -> some View {
        self.onTapGesture { 
            // This is just a placeholder - the actual keyboard shortcut is handled by the system
        }
    }
}


