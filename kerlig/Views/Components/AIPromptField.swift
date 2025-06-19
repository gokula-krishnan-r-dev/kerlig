import AppKit
import Combine
import SwiftUI

// Internal struct for model option information
private struct ModelOption: Identifiable {
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
private struct AIPromptAction: Identifiable, Hashable {
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
  static let ask = AIPromptAction(
    id: "ask", name: "Ask", iconName: "arrow.right", shortcutKey: "p", shortcutModifiers: .command)
  static let fix = AIPromptAction(
    id: "fix", name: "Fix spelling and grammar", iconName: "sparkles.rectangle.stack",
    shortcutKey: "f", shortcutModifiers: .command)
  static let translate = AIPromptAction(
    id: "translate", name: "Translate", iconName: "globe", shortcutKey: "t",
    shortcutModifiers: .command)
  static let improve = AIPromptAction(
    id: "improve", name: "Improve writing", iconName: "pencil.line", shortcutKey: "i",
    shortcutModifiers: .command)
  static let summarize = AIPromptAction(
    id: "summarize", name: "Summarize", iconName: "text.redaction", shortcutKey: "s",
    shortcutModifiers: .command)
  static let makeShort = AIPromptAction(
    id: "makeShort", name: "Make shorter", iconName: "minus.forwardslash.plus", shortcutKey: "m",
    shortcutModifiers: .command)
  static let analyzeImage = AIPromptAction(
    id: "analyzeImage", name: "Analyze image with Gemini Vision", iconName: "photo.on.rectangle",
    shortcutKey: "a", shortcutModifiers: .command)

  // All available actions
  static let allActions: [AIPromptAction] = [
    ask, fix, translate, improve, summarize, makeShort, analyzeImage,
  ]
}
// MARK: - Paste Content Card Component
struct PasteContentCard: View {
    let content: String
    let onRemove: () -> Void
    let onExpand: () -> Void
    
    @State private var isExpanded: Bool = false
    @State private var contentHeight: CGFloat = 0
    @State private var isHovering: Bool = false
    
    private let maxPreviewLength = 200
    private let maxPreviewLines = 6
    
    private var previewText: String {
        if content.count <= maxPreviewLength {
            return content
        }
        let truncated = String(content.prefix(maxPreviewLength))
        return truncated + "..."
    }
    
    private var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }
    
    private var characterCount: Int {
        content.count
    }
    
    var body: some View {
        HStack() {

            

            // Main card content
            VStack(alignment: .leading, spacing: 6) {
                
                // Content preview/full text
                VStack(alignment: .leading, spacing: 6) {
                    Text(isExpanded ? content : previewText)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(isExpanded ? nil : maxPreviewLines)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                  
                }
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
            
        }
        .frame(width: isExpanded ? nil : 300 )
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onExpand()
        }
        .overlay(alignment: .topTrailing) {

             if isHovering {
                    // Remove button
                    Button(action: {
                        onRemove()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 20, height: 20)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Remove pasted content")
                    .offset(x: -2, y: -10)
            }
        }
    }
}
struct AIPromptField: View {
  @Binding var searchQuery: String
  @Binding var isProcessing: Bool
  @Binding var selectedTab: AIPromptTab
  @Binding var aiModel: String
  @EnvironmentObject var appState: AppState
  @State private var pastedContent: String? = nil
    @State private var showPasteCard: Bool = false
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

   // Paste detection threshold
    private let pasteThreshold = 100 // characters

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
          .lineLimit(4)
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

        if !searchQuery.isEmpty {
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

 // Error message display
            if hasError {
                errorMessageView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: hasError)
            }


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
          .animation(
            .easeInOut(duration: 0.2),
            value: !searchQuery.isEmpty || !appState.aiResponse.isEmpty || !isProcessing)
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

       HStack(spacing: 0) {

          // Paste content card - shown when large content is pasted
            if  showPasteCard, let content = pastedContent {
                PasteContentCard(
                    content: content,
                    onRemove: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showPasteCard = false
                            pastedContent = nil
                            searchQuery = ""
                        }
                    },
                    onExpand: {
                        // Optional: Add haptic feedback or other interactions
                        NSHapticFeedbackManager.defaultPerformer.perform(
                            .levelChange,
                            performanceTime: .now
                        )
                    }
                )
            }
            Spacer()
        }
    }
    .onChange(of: searchQuery) { oldValue, newValue in
            detectPasteOperation(oldValue: oldValue, newValue: newValue)
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
          clearContent()
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
      if showActionsList, let index = hoveredActionIndex,
        index >= 0 && index < AIPromptAction.allActions.count
      {
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

      //show the model name
      Text(aiModel)
        .font(.system(size: 12))
        .foregroundColor(.white)

     

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

    searchQuery = searchQuery + (pastedContent ?? "")

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

    showPasteCard = false


    pastedContent = nil

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

   private func clearContent() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            searchQuery = ""
            pastedContent = nil
            showPasteCard = false
            hasError = false
        }
    }

    // MARK: - Helper Functions
    private func detectPasteOperation(oldValue: String, newValue: String) {
        let lengthDifference = newValue.count - oldValue.count
        
        // Detect if this looks like a paste operation (large text addition)
        if lengthDifference > pasteThreshold {
            let pastedText = String(newValue.suffix(lengthDifference))
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                pastedContent = newValue + "\n\n"
                showPasteCard = true
                searchQuery = ""
            }
            
        }
    }

// Error message view
    private var errorMessageView: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(errorMessage)
                .font(.system(size: 12))
                .foregroundColor(.red)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
        )
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
    @ViewBuilder placeholder: () -> Content
  ) -> some View {

    ZStack(alignment: alignment) {
      placeholder().opacity(shouldShow ? 1 : 0)
      self
    }
  }
}

// MARK: - Keyboard Shortcut Extension
extension View {
  func keyboardShortcut(
    _ key: KeyEquivalent, modifiers: EventModifiers = .command, action: @escaping () -> Void
  ) -> some View {
    self.onTapGesture {
      // This is just a placeholder - the actual keyboard shortcut is handled by the system
    }
  }
}


#Preview {
    struct PreviewWrapper: View {
        @State private var searchQuery = "Text"
        @State private var isProcessing = false
        @State private var selectedTab: AIPromptField.AIPromptTab = .blank
        @State private var aiModel = "GPT-4"
        @State private var focusedField: AIPromptField.FocusableField? = nil
        
        var body: some View {
            VStack {
                AIPromptField(
                    searchQuery: $searchQuery,
                    isProcessing: $isProcessing,
                    selectedTab: $selectedTab,
                    aiModel: $aiModel,
                    focusedField: $focusedField,
                    onSubmit: { _ in isProcessing.toggle() },
                    onCancel: { isProcessing = false }
                )
                .environmentObject(AppState())
                
                // Example of PasteContentCard
                PasteContentCard(
                    content: "This is an example asdjfhksdfjkdsfjkdhfjdshfldshfkds sdj ksdjfkldj fsdj kldslfkjsd lkfjdskl fjdsfk jsdkfj dsfj dsfjdsfjds fdsk fkdsfj klasdjfklsdf s ks   dj fkdsjfkldsjfkldjsfkldjsf asdjf sdfkdsjfj of pasted content that can be used in the prompt.",
                    onRemove: { },
                    onExpand: { }
                )
                .padding()
            }
        }
    }
    
    return PreviewWrapper()
}
