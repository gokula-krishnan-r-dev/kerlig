import Combine
import Foundation
import SwiftUI

// Define OnboardingStep enum locally to avoid import issues
enum OnboardingStep: String, CaseIterable {
  case permissions = "Permissions"
  case modelSelection = "Model Selection"
  case appOverview = "App Overview"
}

// Text source enum
enum TextSource: String, CaseIterable {
  case directSelection = "Direct Selection"
  case clipboard = "Clipboard"
  case userInput = "User Input"
  case unknown = "Unknown"
}

// Connection state for streaming
enum ConnectionState: String, CaseIterable {
  case disconnected = "Disconnected"
  case connecting = "Connecting"
  case connected = "Connected"
  case streaming = "Streaming"
  case completed = "Completed"
  case error = "Error"
  case cancelled = "Cancelled"
}

class AppState: ObservableObject {
  // User settings
  @Published var hotkeyEnabled: Bool = true
  @Published var emptySelectionMode: Bool = false
  @Published var apiKey: String = ""
  @Published var aiModel: String = "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
  @Published var isDarkMode: Bool = false
  @Published var currentTheme: String = "light"  // Default to light theme
  @Published var responseStyle: ResponseStyle = .balanced
  @Published var isPinned: Bool = false  // Track if panel is pinned
  @Published var startWithBlank: Bool = false  // Track if starting with blank content
  @Published var isFirstLaunch: Bool = false  // Track if this is the first app launch
  @Published var runInBackground: Bool = true  // Track if app should run in background
  @Published var launchAtLogin: Bool = false  // Track if app should launch at login

  // Onboarding related
  @Published var currentOnboardingStep: OnboardingStep = .permissions
  @Published var onboardingComplete: Bool = false  // Track if onboarding is complete

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

  // Streaming state management
  @Published var isStreaming: Bool = false
  @Published var streamingResponse: String = ""
  @Published var streamingError: String? = nil
  @Published var connectionState: ConnectionState = .disconnected
  @Published var streamingProgress: Double = 0.0
  @Published var estimatedTokens: Int = 0
  @Published var actualTokens: Int = 0

  // Real-time typing effect
  @Published var displayedResponse: String = ""
  @Published var isTyping: Bool = false
  private var typingTimer: Timer?

  // Text source tracking
  @Published var textSource: TextSource = .unknown
  @Published var lastSelectionTimestamp: Date = Date()
  @Published var textMetadata: [String: Any] = [:]

  // File details tracking
  @Published var selectedFile: URL? = nil
  @Published var fileDetailsCapturer = FileDetailsCapture()

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

  var savedRunInBackground: Bool {
    get {
      // Default to true if never set before
      if UserDefaults.standard.object(forKey: "runInBackground") == nil {
        return true
      }
      return UserDefaults.standard.bool(forKey: "runInBackground")
    }
    set {
      UserDefaults.standard.set(newValue, forKey: "runInBackground")
      runInBackground = newValue
    }
  }

  var savedLaunchAtLogin: Bool {
    get {
      return UserDefaults.standard.bool(forKey: "launchAtLogin")
    }
    set {
      UserDefaults.standard.set(newValue, forKey: "launchAtLogin")
      launchAtLogin = newValue
      LaunchAtLoginManager.shared.isEnabled = newValue
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

  // Task Timer Notification Settings
  @Published var taskTimerEnabled: Bool = true
  @Published var defaultTaskDuration: Double = 10.0 // in minutes
  @Published var showTaskCompletionNotification: Bool = true

  init() {
    // Load saved settings
    apiKey = savedAPIKey
    aiModel = savedModel
    currentTheme = "light"  // Force light theme

    // Check if this is first launch
    isFirstLaunch = true

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

    // Load background mode preference
    runInBackground = savedRunInBackground

    // Load launch at login preference
    launchAtLogin = savedLaunchAtLogin

    // Load history
    loadHistory()

    // Load response style
    if let rawStyle = UserDefaults.standard.object(forKey: "responseStyle") as? Int,
      let style = ResponseStyle(rawValue: rawStyle)
    {
      responseStyle = style
    }

    // Set app theme to light
    isDarkMode = false

    // Set up notification observer for panel closing
    setupNotificationObservers()

    // Initialize task timer settings from UserDefaults
    loadTaskTimerSettings()
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
      let decodedHistory = try? JSONDecoder().decode([ChatInteraction].self, from: historyData)
    {
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

  // Toggle background mode
  func toggleBackgroundMode() {
    savedRunInBackground = !runInBackground
    
    // Notify the background app manager of the change
    NotificationCenter.default.post(
      name: NSNotification.Name("BackgroundModeChanged"),
      object: runInBackground
    )
  }

  // Toggle launch at login
  func toggleLaunchAtLogin() {
    savedLaunchAtLogin = !launchAtLogin
  }

  // Save settings
  func saveSettings() {
    UserDefaults.standard.set(apiKey, forKey: "apiKey")
    UserDefaults.standard.set(aiModel, forKey: "aiModel")
    UserDefaults.standard.set("light", forKey: "theme")  // Always save light theme
    UserDefaults.standard.set(hotkeyEnabled, forKey: "hotkeyEnabled")
    UserDefaults.standard.set(responseStyle.rawValue, forKey: "responseStyle")
    UserDefaults.standard.set(isPinned, forKey: "isPinned")
    UserDefaults.standard.set(startWithBlank, forKey: "startWithBlank")
    UserDefaults.standard.set(runInBackground, forKey: "runInBackground")
    UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
  }

  // Mark first launch as completed
  func completeFirstLaunch() {
    savedIsFirstLaunch = false
  }

  // Move to the next onboarding step
  func nextOnboardingStep() {
    guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentOnboardingStep) else {
      return
    }

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

  // Update file details in the metadata
  func updateFileDetails(_ details: [String: Any]) {
    textMetadata["fileDetails"] = details

    // Set some common properties for easier access
    if let name = details["name"] as? String {
      textMetadata["fileName"] = name
    }

    if let path = details["path"] as? String {
      textMetadata["filePath"] = path
      currentAppPath = path  // Reuse the app path property
    }

    if let type = details["type"] as? String {
      textMetadata["fileType"] = type
    }
  }

  // MARK: - Streaming Management
  
  // Start streaming session
  func startStreaming() {
    print("🎬 [APPSTATE] Starting streaming session")
    connectionState = .connecting
    isStreaming = true
    streamingResponse = ""
    displayedResponse = ""
    streamingError = nil
    streamingProgress = 0.0
    actualTokens = 0
    isTyping = false
    
    // Clear previous response
    aiResponse = ""
    print("🎬 [APPSTATE] Streaming session initialized")
  }
  
  // Update streaming response with new chunk
  func updateStreamingResponse(_ chunk: String) {
    print("📝 [APPSTATE] Received chunk: '\(chunk.prefix(20))...' (length: \(chunk.count))")
    streamingResponse += chunk
    actualTokens += chunk.split(separator: " ").count
    
    print("📝 [APPSTATE] Total response length: \(streamingResponse.count), tokens: \(actualTokens)")
    
    // Update progress estimation
    if estimatedTokens > 0 {
      streamingProgress = min(Double(actualTokens) / Double(estimatedTokens), 1.0)
      print("📝 [APPSTATE] Progress updated: \(Int(streamingProgress * 100))%")
    }
    
    // Trigger typing effect for display
    if !isTyping {
      print("📝 [APPSTATE] Starting typing effect")
      startTypingEffect()
    }
  }
  
  // Complete streaming session
  func completeStreaming() {
    print("✅ [APPSTATE] Completing streaming session")
    print("✅ [APPSTATE] Final response length: \(streamingResponse.count) characters")
    connectionState = .completed
    isStreaming = false
    aiResponse = streamingResponse
    streamingProgress = 1.0
    
    // Ensure typing effect completes
    print("✅ [APPSTATE] Completing typing effect")
    completeTypingEffect()
  }
  
  // Handle streaming error
  func handleStreamingError(_ error: String) {
    print("❌ [APPSTATE] Handling streaming error: \(error)")
    connectionState = .error
    streamingError = error
    isStreaming = false
    isTyping = false
    
    // Cancel typing timer
    typingTimer?.invalidate()
    typingTimer = nil
    print("❌ [APPSTATE] Streaming error handled")
  }
  
  // Cancel streaming
  func cancelStreaming() {
    connectionState = .cancelled
    isStreaming = false
    isTyping = false
    
    // Cancel typing timer
    typingTimer?.invalidate()
    typingTimer = nil
  }
  
  // MARK: - Typing Effect
  
  private func startTypingEffect() {
    isTyping = true
    typingTimer?.invalidate()
    
    typingTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      
      DispatchQueue.main.async {
        if self.displayedResponse.count < self.streamingResponse.count {
          let nextIndex = self.streamingResponse.index(
            self.streamingResponse.startIndex,
            offsetBy: self.displayedResponse.count + 1
          )
          self.displayedResponse = String(self.streamingResponse[..<nextIndex])
        } else {
          self.isTyping = false
          self.typingTimer?.invalidate()
          self.typingTimer = nil
        }
      }
    }
  }
  
  private func completeTypingEffect() {
    typingTimer?.invalidate()
    typingTimer = nil
    isTyping = false
    displayedResponse = streamingResponse
  }
  
  // Reset streaming state
  func resetStreamingState() {
    connectionState = .disconnected
    isStreaming = false
    streamingResponse = ""
    displayedResponse = ""
    streamingError = nil
    streamingProgress = 0.0
    estimatedTokens = 0
    actualTokens = 0
    isTyping = false
    
    typingTimer?.invalidate()
    typingTimer = nil
  }

  // Initialize task timer settings from UserDefaults
  private func loadTaskTimerSettings() {
      taskTimerEnabled = UserDefaults.standard.bool(forKey: "taskTimerEnabled")
      defaultTaskDuration = UserDefaults.standard.double(forKey: "defaultTaskDuration")
      if defaultTaskDuration == 0 {
          defaultTaskDuration = 10.0 // Default to 10 minutes if not set
      }
      showTaskCompletionNotification = UserDefaults.standard.bool(forKey: "showTaskCompletionNotification")
      if (UserDefaults.standard.object(forKey: "showTaskCompletionNotification").map({ _ in true }) == nil) ?? false {
          showTaskCompletionNotification = true // Default to true if not set
      }
  }
  
  // Save task timer settings to UserDefaults
  func saveTaskTimerSettings() {
      UserDefaults.standard.set(taskTimerEnabled, forKey: "taskTimerEnabled")
      UserDefaults.standard.set(defaultTaskDuration, forKey: "defaultTaskDuration")
      UserDefaults.standard.set(showTaskCompletionNotification, forKey: "showTaskCompletionNotification")
  }
}
