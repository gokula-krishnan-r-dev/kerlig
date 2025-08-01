import AppKit
import Combine
import SwiftUI

// Note: ModelOption is now imported from AIModelManager

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
  @EnvironmentObject var customActionsStorage: CustomActionsStorage
  @State private var pastedContent: String? = nil
  @State private var showPasteCard: Bool = false
  @State private var hasError: Bool = false
  @State private var errorMessage: String = ""
  @State private var isHovering: Bool = false
  @State private var isModelMenuOpen: Bool = false
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
        ActionsBarView(aiModel: $aiModel , formattedQuery: formattedQuery , showActionsList: $showActionsList , submitPrompt: submitPrompt)
          .transition(.opacity)
          .animation(
            .easeInOut(duration: 0.2),
            value: !searchQuery.isEmpty || !appState.aiResponse.isEmpty || !isProcessing)
      }

      // Actions dropdown list - conditionally displayed
      if showActionsList && !searchQuery.isEmpty {
        ActionsListView(
          selectedActionId: $customActionsStorage.selectedActionId,
          hoveredActionIndex: $hoveredActionIndex,
          onSelectAction: { action in
            selectAndSubmitAction(action)
          }
        )
        .environmentObject(customActionsStorage)
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
        if showPasteCard, let content = pastedContent {
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

      // Listen for keyboard shortcuts
      setupKeyboardShortcuts()
    }
    .onAppear {

      customActionsStorage.loadSelectedAction()

      customActionsStorage.updateActions()
      setupKeyboardShortcuts()
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        searchQueryIsFocused = true
        focusedField = .searchField
      }
      
      // Set default action if none selected
      if customActionsStorage.selectedActionId == nil && !customActionsStorage.actions.isEmpty {
        customActionsStorage.selectedActionId = customActionsStorage.actions.first?.id.uuidString
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
        index >= 0 && index < customActionsStorage.actions.count
      {
        let enabledActions = customActionsStorage.actions.filter { $0.isEnabled }
        if index < enabledActions.count {
          selectAndSubmitAction(enabledActions[index])
          return .handled
        }
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

  // Setup keyboard shortcuts for custom actions
  private func setupKeyboardShortcuts() {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
      if event.modifierFlags.contains(.command) {
        if let key = event.charactersIgnoringModifiers {
          if let action = customActionsStorage.actions.first(where: { $0.shortcutKey == key && $0.isEnabled }) {
            selectAndSubmitAction(action)
            return nil
          }
        }
      }
      return event
    }
  }



  // Navigate through actions with arrow keys
  private func navigateActions(direction: Int) {
    let enabledActions = customActionsStorage.actions.filter { $0.isEnabled }
    guard !enabledActions.isEmpty else { return }

    if let currentIndex = hoveredActionIndex {
      let newIndex = (currentIndex + direction) % enabledActions.count
      hoveredActionIndex = newIndex < 0 ? enabledActions.count - 1 : newIndex
    } else {
      hoveredActionIndex = direction > 0 ? 0 : enabledActions.count - 1
    }
  }

  // Select and use an action
  private func selectAndSubmitAction(_ action: CustomAction) {
    customActionsStorage.selectedActionId = action.id.uuidString
    customActionsStorage.selectedAction = action
    UserDefaults.standard.set(action.id.uuidString, forKey: "selectedActionId")
    showActionsList = false

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

    // if let action = selectedAction {
    //   actionPrompt = "\(action.systemPrompt): \(searchQuery)"
    // }

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
        .environmentObject(CustomActionsStorage())
        
        // Example of PasteContentCard
        PasteContentCard(
          content: "This is an example of pasted content that can be used in the prompt.",
          onRemove: { },
          onExpand: { }
        )
        .padding()
      }
    }
  }
  
  return PreviewWrapper()
}
