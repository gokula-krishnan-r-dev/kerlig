import Foundation
import SwiftUI
import Combine

// Define OnboardingStep enum locally to avoid import issues
enum OnboardingStep: String, CaseIterable {
    case permissions = "Permissions"
    case modelSelection = "Model Selection"
    case appOverview = "App Overview"
}

class AppState: ObservableObject {
    // User settings
    @Published var hotkeyEnabled: Bool = true
    @Published var emptySelectionMode: Bool = false
    @Published var apiKey: String = ""
    @Published var aiModel: String = "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
    @Published var isDarkMode: Bool = false
    @Published var currentTheme: String = "light" // Default to light theme
    @Published var responseStyle: ResponseStyle = .balanced
    @Published var isPinned: Bool = false // Track if panel is pinned
    @Published var startWithBlank: Bool = false // Track if starting with blank content
    @Published var isFirstLaunch: Bool = false // Track if this is the first app launch
    
    // Onboarding related
    @Published var currentOnboardingStep: OnboardingStep = .permissions
    @Published var onboardingComplete: Bool = false // Track if onboarding is complete
    
    // History
    @Published var history: [ChatInteraction] = []
    
    // UI state
    @Published var isAIPanelVisible: Bool = false
    @Published var selectedText: String = ""
    @Published var aiResponse: String = ""
    @Published var isLoading: Bool = false
    @Published var isProcessing: Bool = false
    @Published var showingSettings: Bool = false
    @Published var currentAppName: String = ""
    @Published var currentAppPath: String = ""
    @Published var currentAppBundleID: String = ""
    
    // Text source tracking
    @Published var textSource: TextSource = .unknown
    @Published var lastSelectionTimestamp: Date = Date()
    @Published var textMetadata: [String: Any] = [:]
    
    // Saved settings
    var savedAPIKey: String {
        get {
            UserDefaults.standard.string(forKey: "apiKey") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "apiKey")
            apiKey = newValue
        }
    }
    
    var savedModel: String {
        get {
            UserDefaults.standard.string(forKey: "aiModel") ?? "gpt-4o"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "aiModel")
            aiModel = newValue
        }
    }
    
    var savedTheme: String {
        get {
            UserDefaults.standard.string(forKey: "theme") ?? "light"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "theme")
            currentTheme = newValue
            updateTheme()
        }
    }
    
    var savedHotkeyEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "hotkeyEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hotkeyEnabled")
            hotkeyEnabled = newValue
        }
    }
    
    var savedIsPinned: Bool {
        get {
            UserDefaults.standard.bool(forKey: "isPinned")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isPinned")
            isPinned = newValue
            
            // Notify panel controller about pin state change
            NotificationCenter.default.post(
                name: NSNotification.Name("PanelPinStateChanged"),
                object: isPinned
            )
        }
    }
    
    var savedStartWithBlank: Bool {
        get {
            UserDefaults.standard.bool(forKey: "startWithBlank")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "startWithBlank")
            startWithBlank = newValue
        }
    }
    
    var savedIsFirstLaunch: Bool {
        get {
            // Return true if the key doesn't exist yet (first launch)
            !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        }
        set {
            // When setting to false, it means app has been launched
            UserDefaults.standard.set(!newValue, forKey: "hasLaunchedBefore")
            isFirstLaunch = newValue
        }
    }
    
    var savedOnboardingComplete: Bool {
        get {
            UserDefaults.standard.bool(forKey: "onboardingComplete")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "onboardingComplete")
            onboardingComplete = newValue
        }
    }
    
    init() {
        // Load saved settings
        apiKey = savedAPIKey
        aiModel = savedModel
        currentTheme = "light" // Force light theme
        
        // Check if this is first launch
        isFirstLaunch = false
        
        // Load onboarding status
        onboardingComplete = savedOnboardingComplete
        
        // Default to true if never set before
        if UserDefaults.standard.object(forKey: "hotkeyEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "hotkeyEnabled")
        }

        hotkeyEnabled = savedHotkeyEnabled
        
        // Load pin state
        if UserDefaults.standard.object(forKey: "isPinned") != nil {
            isPinned = UserDefaults.standard.bool(forKey: "isPinned")
        }
        
        // Load start with blank preference
        if UserDefaults.standard.object(forKey: "startWithBlank") != nil {
            startWithBlank = UserDefaults.standard.bool(forKey: "startWithBlank")
        }
        
        // Load history
        loadHistory()
        
        // Load response style
        if let rawStyle = UserDefaults.standard.object(forKey: "responseStyle") as? Int,
           let style = ResponseStyle(rawValue: rawStyle) {
            responseStyle = style
        }
        
        // Set app theme to light
        isDarkMode = false
        
        // Set up notification observer for panel closing
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotificationObservers() {
        // Listen for panel close notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePanelClose),
            name: NSNotification.Name("ClosePanelNotification"),
            object: nil
        )
    }
    
    @objc private func handlePanelClose() {
        DispatchQueue.main.async {
            self.isAIPanelVisible = false
            self.emptySelectionMode = false
        }
    }
    
    private func updateTheme() {
        // Force light theme regardless of system setting
        isDarkMode = false
    }
    
    // Update selected text and track its source
    func updateSelectedText(_ text: String, source: TextSource) {
        self.selectedText = text
        self.textSource = source
        self.lastSelectionTimestamp = Date()
        
        // Get additional metadata based on source
        switch source {
        case .clipboard:
            if let app = NSWorkspace.shared.frontmostApplication {
                textMetadata["sourceApp"] = app.localizedName
                textMetadata["appBundleId"] = app.bundleIdentifier
                currentAppName = app.localizedName ?? ""
                currentAppBundleID = app.bundleIdentifier ?? ""
                if let appURL = app.bundleURL {
                    currentAppPath = appURL.path
                }
            }
        case .directSelection:
            if let app = NSWorkspace.shared.frontmostApplication {
                textMetadata["sourceApp"] = app.localizedName
                textMetadata["appBundleId"] = app.bundleIdentifier
                currentAppName = app.localizedName ?? ""
                currentAppBundleID = app.bundleIdentifier ?? ""
                if let appURL = app.bundleURL {
                    currentAppPath = appURL.path
                }
            }
        case .userInput:
            textMetadata["source"] = "manual input"
        case .unknown:
            textMetadata.removeAll()
        }
    }
    
    // Clear the current text and response
    func clearCurrentSession() {
        selectedText = ""
        aiResponse = ""
        textSource = .unknown
        textMetadata.removeAll()
    }
    
    // Save the current interaction to history
    func saveInteraction() {
        if !selectedText.isEmpty && !aiResponse.isEmpty {
            let interaction = ChatInteraction(
                prompt: selectedText,
                response: aiResponse,
                responseStyle: responseStyle,
                timestamp: Date()
            )
            history.append(interaction)
            saveHistory()
        }
    }
    
    // Clear all history
    func clearHistory() {
        history = []
        saveHistory()
    }
    
    // Delete a specific history item
    func deleteHistoryItem(at index: Int) {
        if index >= 0 && index < history.count {
            history.remove(at: index)
            saveHistory()
        }
    }
    
    // Load history from UserDefaults
    private func loadHistory() {
        if let historyData = UserDefaults.standard.data(forKey: "chatHistory"),
           let decodedHistory = try? JSONDecoder().decode([ChatInteraction].self, from: historyData) {
            history = decodedHistory
        }
    }
    
    // Save history to UserDefaults
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "chatHistory")
        }
    }
    
    // Toggle pin state
    func togglePinState() {
        savedIsPinned = !isPinned
    }
    
    // Toggle start with blank
    func toggleStartWithBlank() {
        savedStartWithBlank = !startWithBlank
    }
    
    // Save settings
    func saveSettings() {
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
        UserDefaults.standard.set(aiModel, forKey: "aiModel")
        UserDefaults.standard.set("light", forKey: "theme") // Always save light theme
        UserDefaults.standard.set(hotkeyEnabled, forKey: "hotkeyEnabled")
        UserDefaults.standard.set(responseStyle.rawValue, forKey: "responseStyle")
        UserDefaults.standard.set(isPinned, forKey: "isPinned")
        UserDefaults.standard.set(startWithBlank, forKey: "startWithBlank")
    }
    
    // Mark first launch as completed
    func completeFirstLaunch() {
        savedIsFirstLaunch = false
    }
    
    // Move to the next onboarding step
    func nextOnboardingStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentOnboardingStep) else { return }
        
        if currentIndex < OnboardingStep.allCases.count - 1 {
            currentOnboardingStep = OnboardingStep.allCases[currentIndex + 1]
        } else {
            // Last step - complete onboarding
            completeFirstLaunch()
            completeOnboarding()
        }
    }
    
    // Skip onboarding and go straight to the app
    func skipOnboarding() {
        completeFirstLaunch()
        savedOnboardingComplete = true
    }
    
    // Mark onboarding as complete
    func completeOnboarding() {
        savedOnboardingComplete = true
    }
}

// Enum to track where text came from
enum TextSource {
    case clipboard
    case directSelection
    case userInput
    case unknown
} 