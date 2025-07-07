import AppKit
import SwiftUI
import Combine

// MARK: - Screenshot Panel Controller
class ScreenshotPanelController: NSObject, ObservableObject {
    static let shared = ScreenshotPanelController()
    
    private var window: NSWindow?
    private var screenshotView: ScreenshotAnalysisView?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isVisible = false
    @Published var currentScreenshot: NSImage?
    @Published var userQuery: String = ""
    @Published var aiResponse: String = ""
    @Published var isAnalyzing = false
    @Published var analysisError: String?
    @Published var isCapturingScreenshot = false
    @Published var captureProgress: String = ""
    
    private let screenshotService = ScreenshotCaptureService.shared
    private let geminiService = GeminiVisionService()
    
    override init() {
        super.init()
        setupObservers()
    }
    
    // MARK: - Setup Methods
    
    private func setupObservers() {
        // Monitor screenshot service
        screenshotService.$lastScreenshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] screenshot in
                if let screenshot = screenshot {
                    self?.showPanel(with: screenshot)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Panel Management
    
    /// Show the screenshot analysis panel with captured image
    func showPanel(with screenshot: NSImage) {
        currentScreenshot = screenshot
        userQuery = ""
        aiResponse = ""
        isAnalyzing = false
        analysisError = nil
        
        if window == nil {
            createWindow()
        }
        
        DispatchQueue.main.async {
            // Ensure window is at the highest level
            self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
            
            // Make the window key and order front
            self.window?.makeKeyAndOrderFront(nil)
            
            // Bring app to front to ensure the window is visible
            NSApp.activate(ignoringOtherApps: true)
            
            // Set visibility state
            self.isVisible = true
            
            // Center the window on the screen with the cursor
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let windowSize = self.window?.frame.size ?? NSSize(width: 600, height: 700)
                
                // Get current mouse location
                let mouseLocation = NSEvent.mouseLocation
                
                // Calculate window position centered around mouse, but ensure it's fully visible
                var windowX = mouseLocation.x - windowSize.width / 2
                var windowY = mouseLocation.y - windowSize.height / 2
                
                // Ensure window stays within screen bounds
                windowX = max(screenRect.minX, min(windowX, screenRect.maxX - windowSize.width))
                windowY = max(screenRect.minY, min(windowY, screenRect.maxY - windowSize.height))
                
                self.window?.setFrameOrigin(NSPoint(x: windowX, y: windowY))
            }
            
            // Auto-copy screenshot to clipboard
            self.screenshotService.copyToClipboard(screenshot)
            
            // Add a subtle notification sound
            NSSound.beep()
        }
    }
    
    /// Hide the panel
    func hidePanel() {
        DispatchQueue.main.async {
            self.window?.orderOut(nil)
            self.isVisible = false
            self.currentScreenshot = nil
            self.userQuery = ""
            self.aiResponse = ""
            self.isAnalyzing = false
            self.analysisError = nil
        }
    }
    
    /// Toggle panel visibility
    func togglePanel() {
        if isVisible {
            hidePanel()
        } else {
            // Ensure the app can be activated from any state
            activateAppFromBackground()
            
            // Trigger new screenshot capture
            captureScreenshot()
        }
    }
    
    /// Activate the app from background when triggered globally
    private func activateAppFromBackground() {
        // Check if app is in background
        if !NSApp.isActive {
            // Activate the app but don't bring all windows to front
            NSApp.activate(ignoringOtherApps: true)
        }
        
        // Ensure the app is in the dock (in case it's running as menu bar only)
        NSApp.setActivationPolicy(.regular)
        
        // Post notification that the app has been activated by global hotkey
        NotificationCenter.default.post(
            name: NSNotification.Name("ScreenshotPanelActivated"),
            object: nil,
            userInfo: ["source": "global_hotkey"]
        )
    }
    
    // MARK: - Screenshot Capture
    
    /// Capture a new screenshot
    func captureScreenshot() {
        // Check for screen recording permission first
        if !screenshotService.checkScreenRecordingPermission() {
            screenshotService.requestScreenRecordingPermission()
            showPermissionAlert()
            return
        }
        
        // Set capturing state
        isCapturingScreenshot = true
        captureProgress = "Preparing to capture..."
        analysisError = nil
        
        // Hide panel if visible during capture
        if isVisible {
            hidePanel()
        }
        
        // Capture screenshot with a slight delay to ensure panel is hidden
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.captureProgress = "Capturing screenshot..."
            
            self.screenshotService.captureFullScreen { [weak self] result in
                DispatchQueue.main.async {
                    self?.isCapturingScreenshot = false
                    self?.captureProgress = ""
                    
                    switch result {
                    case .success(let image):
                        self?.captureProgress = "Screenshot captured successfully!"
                        self?.showPanel(with: image)
                        
                        // Clear success message after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self?.captureProgress = ""
                        }
                    case .failure(let error):
                        self?.showError("Failed to capture screenshot: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Capture screenshot area interactively
    func captureScreenshotArea() {
        // Check for screen recording permission first
        if !screenshotService.checkScreenRecordingPermission() {
            screenshotService.requestScreenRecordingPermission()
            showPermissionAlert()
            return
        }
        
        // Set capturing state
        isCapturingScreenshot = true
        captureProgress = "Preparing area selection..."
        analysisError = nil
        
        // Hide panel if visible during capture
        if isVisible {
            hidePanel()
        }
        
        // Capture screenshot area with a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.captureProgress = "Select area to capture..."
            
            self.screenshotService.captureScreenArea { [weak self] result in
                DispatchQueue.main.async {
                    self?.isCapturingScreenshot = false
                    self?.captureProgress = ""
                    
                    switch result {
                    case .success(let image):
                        self?.captureProgress = "Area captured successfully!"
                        self?.showPanel(with: image)
                        
                        // Clear success message after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self?.captureProgress = ""
                        }
                    case .failure(let error):
                        if case .userCancelled = error {
                            // User cancelled, just clear the capturing state
                            self?.captureProgress = "Capture cancelled"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self?.captureProgress = ""
                            }
                            return
                        }
                        self?.showError("Failed to capture area: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - AI Analysis
    
    /// Analyze screenshot with user query
    func analyzeScreenshot() {
        guard let screenshot = currentScreenshot,
              !userQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            analysisError = "Please enter a question about the screenshot"
            return
        }
        
        isAnalyzing = true
        analysisError = nil
        
        // Convert screenshot to data for AI processing
        guard let imageData = screenshotService.getScreenshotData(screenshot) else {
            isAnalyzing = false
            analysisError = "Failed to process screenshot for analysis"
            return
        }
        
        // Create file details for Gemini Vision
        let base64String = imageData.base64EncodedString()
        let fileDetails = FileDetailsCapture.FileDetails(
            name: "screenshot_\(Date().timeIntervalSince1970).png",
            path: "",
            size: UInt64(imageData.count),
            type: "image/png",
            creationDate: Date(),
            modificationDate: Date(),
            base64: base64String,
            dimensions: (width: Int(screenshot.size.width), height: Int(screenshot.size.height)),
            additionalMetadata: [:]
        )
        
        // Send to Gemini Vision
        geminiService.processFileDetails(fileDetails: fileDetails, prompt: userQuery) { [weak self] result in
            DispatchQueue.main.async {
                self?.isAnalyzing = false
                
                switch result {
                case .success(let response):
                    self?.aiResponse = response
                    self?.analysisError = nil
                case .failure(let error):
                    self?.analysisError = "Analysis failed: \(error.localizedDescription)"
                    self?.aiResponse = ""
                }
            }
        }
    }
    
    // MARK: - Window Management
    
    private func createWindow() {
        let windowRect = NSRect(x: 0, y: 0, width: 600, height: 700)
        
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window?.title = "Screenshot Analysis"
        window?.titlebarAppearsTransparent = true
        window?.isMovableByWindowBackground = true
        window?.backgroundColor = NSColor.clear
        window?.isOpaque = false
        window?.hasShadow = true
        
        // Enhanced global floating behavior
        window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
        window?.collectionBehavior = [
            .canJoinAllSpaces,           // Available on all spaces
            .fullScreenAuxiliary,        // Can appear over full screen apps
            .ignoresCycle,               // Don't appear in Cmd+Tab
            .participatesInCycle,        // Actually DO participate in window cycling for accessibility
            .stationary                  // Stay in place when spaces change
        ]
        
        // Make window appear over all other applications
        window?.hidesOnDeactivate = false  // Don't hide when another app is activated
        // Note: canBecomeKey and canBecomeMain are read-only properties in modern macOS
        
        // Set up the SwiftUI view
        screenshotView = ScreenshotAnalysisView(controller: self)
        let hostingView = NSHostingView(rootView: screenshotView!)
        window?.contentView = hostingView
        
        // Handle window close
        window?.delegate = self
        
        // Set up window constraints
        window?.minSize = NSSize(width: 400, height: 500)
        window?.maxSize = NSSize(width: 1000, height: 1000)
        
        // Add escape key handler
        setupKeyboardShortcuts()
    }
    
    private func setupKeyboardShortcuts() {
        // Handle escape key to close panel
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 && self?.isVisible == true { // Escape key
                self?.hidePanel()
                return nil // Consume the event
            }
            return event
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            // Set the error in the controller for UI display
            self.analysisError = message
            
            // Also show a native alert for critical errors
            let alert = NSAlert()
            alert.messageText = "Screenshot Error"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Try Again")
            
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                // User wants to try again
                self.captureScreenshot()
            }
        }
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "This app needs screen recording permission to capture screenshots. Please grant permission in System Settings > Privacy & Security > Screen Recording."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings
            if #available(macOS 13.0, *) {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
            } else {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Save current screenshot to file
    func saveScreenshot() {
        guard let screenshot = currentScreenshot else { return }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Save Screenshot"
        savePanel.showsHiddenFiles = false
        savePanel.allowedContentTypes = [.png, .jpeg]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "screenshot_\(Date().timeIntervalSince1970).png"
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                do {
                    try screenshotService.saveToFile(screenshot, url: url)
                } catch {
                    showError("Failed to save screenshot: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Copy AI response to clipboard
    func copyResponseToClipboard() {
        if !aiResponse.isEmpty {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(aiResponse, forType: .string)
        }
    }
    
    /// Copy screenshot to clipboard
    func copyScreenshotToClipboard() {
        if let screenshot = currentScreenshot {
            screenshotService.copyToClipboard(screenshot)
        }
    }
}

// MARK: - NSWindowDelegate
extension ScreenshotPanelController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        isVisible = false
        currentScreenshot = nil
        userQuery = ""
        aiResponse = ""
        isAnalyzing = false
        analysisError = nil
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // Keep window visible even when it loses focus
        // This allows users to interact with other apps while keeping the panel visible
    }
} 