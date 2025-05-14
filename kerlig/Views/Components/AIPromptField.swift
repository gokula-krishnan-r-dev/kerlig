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
    
    var onSubmit: () -> Void
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
        onSubmit: @escaping () -> Void,
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
            Divider()
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
                        Text("Explain circadian rhythm")
                            .foregroundColor(.secondary.opacity(0.7))
                            .font(.system(size: 15))
                    }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            
            Divider()
            
            // Action bar - conditionally displayed
            if appState.aiResponse.isEmpty && !searchQuery.isEmpty {
                HStack(spacing: 10) {
                    // Left arrow icon
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 20)
                    
                    // Dynamic prompt text with keyboard shortcut
                    HStack(spacing: 4) {
                        Text("Ask \"\(formattedQuery)\"")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 2) {
                            Text("⌘+P")
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
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: !searchQuery.isEmpty || !appState.aiResponse.isEmpty || !isProcessing)
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
        
        // Submit the prompt
        onSubmit()
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


