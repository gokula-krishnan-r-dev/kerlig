import SwiftUI
import AppKit
import Combine

struct AIPromptField: View {
    @Binding var searchQuery: String
    @Binding var isProcessing: Bool
    @Binding var selectedTab: AIPromptTab
    @Binding var aiModel: String
    @EnvironmentObject var appState: AppState
    
    @State private var hasError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isHovering: Bool = false
    
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


