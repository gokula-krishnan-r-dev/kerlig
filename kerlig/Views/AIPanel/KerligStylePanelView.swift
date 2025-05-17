import SwiftUI
import AppKit
import Combine
import UserNotifications



struct KerligStylePanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText: String = ""
    @State private var selectedAction: AIAction? = nil
    @State private var isGeneratingSuggestion: Bool = false
    @State private var displayedText: String = ""
    @State private var selectedTab: ActionTab = .blank
    @State private var searchQuery: String = ""
    @State private var isPanelPinned: Bool = false
    @State private var aiModel: String =  UserDefaults.standard.string(forKey: "aiModel") ?? "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
    @State private var generatedResponse: String = ""
    @State private var isProcessing: Bool = false
    @State private var insertionStatus: InsertionStatus = .none

    // Focus states for keyboard navigation
    enum FocusableField: Hashable {
        case searchField
        case actionButton(Int)
        case copyButton
        case insertButton
        case regenerateButton
    }
    @FocusState private var focusedField: FocusableField?

    @State private var cancellables = Set<AnyCancellable>()
    @State private var shouldFocusTextField: Bool = true
    @State private var animatePanel: Bool = false
    @State private var isAnimating: Bool = false
    @FocusState private var searchQueryIsFocused: Bool
    
    // New states for insert functionality
    @State var isInserting: Bool = false
    @State var insertAttempts: Int = 0
    @State var showInsertionHelp: Bool = false
    @State var textToInsert: String = ""
    @State private var textInsertionService = TextInsertionService(delegate: nil)
    @State var shouldInsertAfterClose: Bool = false

    
    // Services
    private let aiService = AIService()
    private let hotkeyManager = HotkeyManager()
    
    // Enum to track insertion status
    enum InsertionStatus {
        case none
        case inserting
        case success
        case failed
        case preparing
    }
    
    // Predefined actions
    private let quickActions: [AIAction] = [
        .fixSpellingGrammar,
        .improveWriting,
        .translate,
        .makeShorter
    ]
    
    // Update ActionTab to match the AIPromptField.AIPromptTab type
    private enum ActionTab: Hashable {
        case blank
        case withContent
    }
    

    
    var body: some View {
        VStack(spacing: 0) {
            // Header with app info
            HeaderPanelView()
            
            // Main content area with prompt and actions
            mainContentView
        }
        .frame(width: 640, height: 520)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
        .onAppear {
            // Initialize the coordinator if needed
            // if coordinator == nil {
            //     coordinator = TextInsertionCoordinator(parentView: self)
            // }
            
            // Initialize displayed text from appState
            displayedText = appState.selectedText
            
            
            // Set correct tab based on whether text is selected
            selectedTab = displayedText.isEmpty ? .blank : .withContent
            
            // Auto-select first action if text is available
            if !displayedText.isEmpty && selectedAction == nil {
                selectedAction = quickActions.first
            }
            
            // Set initial focus on search field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = .searchField
                searchQueryIsFocused = true
            }
            
            // Animate panel appearance
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                animatePanel = true
            }
            
            // Request notification permission
            requestNotificationPermission()
            
            // Create a new TextInsertionService with the coordinator as delegate
            // if let coordinator = coordinator {
            //     textInsertionService = TextInsertionService(delegate: coordinator)
            // }
        }
        .onChange(of: appState.isAIPanelVisible) { oldValue, newValue in
            if newValue {
                // Ensure text field gets focus when panel becomes visible
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.focusedField = .searchField
                    self.searchQueryIsFocused = true
                }
                
                // Animate panel in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    self.animatePanel = true
                }
            } else {
                // Animate panel out
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    self.animatePanel = false
                }
                self.searchQueryIsFocused = false
                
                // Check if we need to insert text after panel closure
                if self.shouldInsertAfterClose {
                    self.shouldInsertAfterClose = false
                    // Allow time for panel to fully close before inserting
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.textInsertionService.insertText(self.textToInsert)
                    }
                }
            }
        }
        .onChange(of: appState.selectedText) { oldValue, newValue in
            // Update displayed text when selectedText changes
            self.displayedText = newValue
            
            // Update tab selection
            if !newValue.isEmpty {
                self.selectedTab = .withContent
            }
            
            // Clear previous response when text changes
            self.generatedResponse = ""
        }
        .scaleEffect(animatePanel ? 1.0 : 0.95)
        .opacity(animatePanel ? 1.0 : 0.0)
    }
    
    
    
    // Handle text insertion using the service
    private func handleInsertText(_ text: String) {
        // Save text for potential help dialog
        textToInsert = text
        
        print("⏺️ [INSERT] Starting insertion process for text: \(text.prefix(20))...")
        
        // Update UI state
        insertionStatus = .inserting
        isInserting = true
        
        // Copy to clipboard first to ensure text is available for pasting
        copyToClipboard(text)
        print("⏺️ [INSERT] Text copied to clipboard")
        
        // Show notification that text is ready
        showNotification(title: "Preparing to Insert", 
                         message: "Text copied, preparing to insert...", 
                         isError: false)
        
        // Use a sequence for proper timing
        DispatchQueue.main.async {
            print("⏺️ [INSERT] Closing panel...")
            // First close the panel
            
            
            // Wait for panel to fully close before attempting to insert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("⏺️ [INSERT] Panel closed, activating target app...")
                
                // Activate frontmost app before insertion
                if self.activateFrontmostApp() {
                    print("⏺️ [INSERT] Starting text insertion...")
                    // Now perform the actual insertion
                    self.textInsertionService.insertText(text)
                    
                    // Track insertion status
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if self.insertionStatus != .success {
                            print("⏺️ [INSERT] No success confirmation received, insertion may have failed")
                            self.showNotification(title: "Insertion Status", 
                                               message: "Text insertion may not have completed successfully", 
                                               isError: true)
                        }
                    }
                }
            }
        }
    }
    

    
    // Notification helper
    private func showNotification(title: String, message: String, isError: Bool = false) {
        // Use newer UNUserNotificationCenter API for macOS 10.14+
        if #available(macOS 10.14, *) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.sound = isError ? UNNotificationSound.default : nil
            
            // Create a request with the content
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil // deliver immediately
            )
            
            // Add the request to the notification center
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error showing notification: \(error.localizedDescription)")
                }
            }
        } else {
            // Fallback for older macOS versions
            let notification = NSUserNotification()
            notification.title = title
            notification.informativeText = message
            notification.soundName = isError ? NSUserNotificationDefaultSoundName : nil
            
            let center = NSUserNotificationCenter.default
            center.deliver(notification)
        }
    }
    
    // Add a method to request notification permissions
    private func requestNotificationPermission() {
        if #available(macOS 10.14, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("Error requesting notification permission: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func selectAction(_ action: AIAction) {
        selectedAction = action
        
        // Prepare to process with the selected action
        processText(with: action)
    }
    
    private func processText(with action: AIAction) {
        // Check if we have text to process
        let textToProcess = selectedTab == .withContent ? displayedText : searchQuery
        
        guard !textToProcess.isEmpty else { return }
        
        isProcessing = true

        aiService.processWithAction(text: textToProcess, action: AIService.ActionType(rawValue: action.rawValue) ?? .summarize, apiKey: appState.apiKey, model: "@cf/meta/llama-3.3-70b-instruct-fp8-fast")
            .sink { completion in
                self.isProcessing = false
                if case .failure(let error) = completion {
                    self.generatedResponse = "Error: \(error.localizedDescription)"
                }
            } receiveValue: { response in
                self.generatedResponse = response
                self.isProcessing = false
                
                // Save to app state
                self.appState.aiResponse = response
                self.appState.saveInteraction()
            }
            .store(in: &cancellables)
    }
    
    private func processCustomPrompt() {
        guard !searchQuery.isEmpty else { 
            // Give visual feedback for empty query
            withAnimation {
                self.searchQueryIsFocused = true
            }
            return 
        }
        
        // Set loading state
        self.isProcessing = true
        self.isAnimating = true
        
        // Clear previous response to show loading state properly
        self.generatedResponse = ""
        
        // Check if user has selected text or is making a direct query
        let hasSelectedText = !displayedText.isEmpty && selectedTab == .withContent
        
        // Use the PromptManager to generate a well-structured prompt
        let promptManager = PromptManager()
        let (systemPrompt, promptContent) = promptManager.generatePrompt(
            for: searchQuery,
            selectedText: hasSelectedText ? displayedText : nil
        )
        
        // Add response format directive
        let formattedPrompt = promptManager.addResponseFormat(to: promptContent)
        
        // Log the request for debugging
        print("System prompt: \(systemPrompt)")
        print("Content prompt: \(formattedPrompt)")
        
        // Cancel any existing requests
        self.cancellables.removeAll()
        
        // Use API key if available with enhanced error handling
        let requestPublisher = self.aiService.generateResponse(
            prompt: formattedPrompt,
            systemPrompt: systemPrompt,
            model: "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
        )
        
        // Add retry logic with better error handling
        requestPublisher
            .retry(2) // Retry up to 2 times before failing
            .timeout(.seconds(45), scheduler: DispatchQueue.main, customError: { URLError(.timedOut) })
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.isAnimating = false
                        
                        if case .failure(let error) = completion {
                            // Provide user-friendly error messages based on error type
                            if let urlError = error as? URLError {
                                switch urlError.code {
                                case .notConnectedToInternet:
                                    self.generatedResponse = "No internet connection. Please check your connection and try again."
                                case .timedOut:
                                    self.generatedResponse = "Request timed out. The server might be busy, please try again."
                                case .cancelled:
                                    self.generatedResponse = "Request was cancelled."
                                default:
                                    self.generatedResponse = "Network error: \(urlError.localizedDescription)"
                                }
                            } else {
                                self.generatedResponse = "Error: \(error.localizedDescription)"
                            }
                        }
                    }
                },
                receiveValue: { response in
                    DispatchQueue.main.async {
                        self.generatedResponse = response
                        self.isProcessing = false
                        self.isAnimating = false
                        // self.appState.selectedText = self.searchQuery
                        self.appState.aiResponse = response
                        self.appState.saveInteraction()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Copy to clipboard (still needed for certain operations)
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    // Main content view
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Main content area
            ZStack {
                // Content when blank tab is selected
                if selectedTab == .blank {
                    ScrollView {
                        VStack(spacing: 0) {
                             // actionButtonsView
                            if !appState.aiResponse.isEmpty {
                                responseView
                            }

                            
                            // Search/prompt field
                            promptField

                            // Quick action buttons
                            if appState.aiResponse.isEmpty {
                            actionButtonsView
                            }
                           
                        }
                        .padding(.bottom, 20)
                    }
                    .backgroundGradient()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(8)
                } else {
                    // Content when "with content" tab is selected
                    ScrollView {
                        VStack(spacing: 0) {

                             if !appState.aiResponse.isEmpty {
                                responseView
                            }
                            // Selected text display
                            if !appState.selectedText.isEmpty {
                                selectedTextView
                            }
                            
                            // Search/prompt field
                            promptField

                            
                            // Quick action buttons
                                     if appState.aiResponse.isEmpty {
                         actionButtonsView
                                     }
                            
                           
                        }
                        .padding(.bottom, 20)
                    }
                    .backgroundGradient()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(8)
                }
            }
        }
        .backgroundGradient()
    }
    
    private var selectedTextView: some View {
        SelectedTextView(displayedText: displayedText, isVisible: selectedTab == .withContent)
            .padding(.bottom, 8)  // Add some padding to separate from the prompt field
            .environmentObject(appState)  // Make sure to pass the AppState to the SelectedTextView
    }
    
    // Replace the old promptField implementation with our new component
    private var promptField: some View {
        AIPromptField(
            searchQuery: $searchQuery,
            isProcessing: $isProcessing,
            selectedTab: Binding<AIPromptField.AIPromptTab>(
                get: {
                    switch selectedTab {
                    case .blank: return .blank
                    case .withContent: return .withContent
                    }
                },
                set: { newValue in
                    switch newValue {
                    case .blank: selectedTab = .blank
                    case .withContent: selectedTab = .withContent
                    case .custom: selectedTab = .withContent // Fallback option
                    }
                }
            ),
            aiModel: $aiModel,
            focusedField: Binding<AIPromptField.FocusableField?>(
                get: {
                    if let focus = focusedField {
                        switch focus {
                        case .searchField:
                            return .searchField
                        case .actionButton(let index):
                            return .actionButton(index)
                        case .copyButton:
                            return .copyButton
                        case .insertButton:
                            return .insertButton
                        case .regenerateButton:
                            return .regenerateButton
                        }
                    }
                    return nil
                },
                set: { newValue in
                    if let newFocus = newValue {
                        switch newFocus {
                        case .searchField:
                            focusedField = .searchField
                        case .actionButton(let index):
                            focusedField = .actionButton(index)
                        case .copyButton:
                            focusedField = .copyButton
                        case .insertButton:
                            focusedField = .insertButton
                        case .regenerateButton:
                            focusedField = .regenerateButton
                        case .custom:
                            break // Ignore custom fields from AIPromptField
                        }
                    } else {
                        focusedField = nil
                    }
                }
            ),
            onSubmit: {_ in 
                self.processCustomPrompt()
            },
            onCancel: {
                self.cancellables.removeAll()
                self.isProcessing = false
                self.generatedResponse = "Request canceled."
            }
        )
    }
    
    private var actionButtonsView: some View {
        ActionButtonsView(
            selectedAction: $selectedAction,
            isProcessing: $isProcessing,
            focusedField: _focusedField,
            animateEntrance: $animatePanel,
            onActionSelected: { action in
                selectAction(action)
            }
        )
    }
    
    private var responseView: some View {
        AIResponseView(
            isProcessing: $isProcessing,
            isAnimating: $isAnimating,
            insertionStatus: $insertionStatus,
            isInserting: $isInserting,
            insertAttempts: $insertAttempts,
            selectedAction: $selectedAction,
            onCopy: { text in
                copyToClipboard(text)
            },
            onInsert: { text in
                handleInsertText(text)
            },
            onRegenerate: {
                if let action = self.selectedAction {
                    self.processText(with: action)
                } else {
                    self.processCustomPrompt()
                }
            }
        )
    }
    
    // Update the app activate calls to use the non-deprecated API
    private func activateFrontmostApp() -> Bool {
        print("🔄 [SERVICE] Attempting to activate frontmost application")
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("🔄 [SERVICE] ⚠️ No frontmost application found")
            return false
        }
        
        print("🔄 [SERVICE] Activating app: \(frontmostApp.localizedName ?? "Unknown")")
        // Use the API without the deprecated parameter
        frontmostApp.activate(options: [])
        return true
    }
}



