import SwiftUI
import AppKit

class FloatingPanelController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private var hotkeyManager = HotkeyManager()
    private var cachedSelectedText: String = ""
    private var isAttemptingTextCapture = false
    private var appStateRef: AppState? = nil
    private var visualEffectView: NSVisualEffectView? = nil
    
    // MARK: - Panel Toggling
    func togglePanel(appState: AppState) {
        // Store reference to appState for later use
        self.appStateRef = appState
        
        if appState.isAIPanelVisible {
            closePanel()
            appState.isAIPanelVisible = false
            appState.emptySelectionMode = false
        } else {
            // Immediately try to capture text using our enhanced methods
            let selectedText = captureSelectedText()
            
            if !selectedText.isEmpty {
                // We have text, show the panel with it
                self.cachedSelectedText = selectedText
                self.showUnifiedPanelWithText(selectedText: selectedText, appState: appState)
            } else {
                // If text is empty, retry once after a short delay
                self.isAttemptingTextCapture = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Try again after a delay to allow for selection events to complete
                    let secondAttemptText = self.captureSelectedText()
                    
                    if !secondAttemptText.isEmpty {
                        self.cachedSelectedText = secondAttemptText
                        self.showUnifiedPanelWithText(selectedText: secondAttemptText, appState: appState)
                    } else {
                        // No text found after retry, show empty selection panel
                        self.showEmptySelectionPanel(appState: appState)
                    }
                    self.isAttemptingTextCapture = false
                }
            }
        }
    }
    
    // Reliable text capture using our enhanced HotkeyManager
    private func captureSelectedText() -> String {
        return hotkeyManager.getTextFromSelectionOrClipboard()
    }
    
    // Show panel with selected text context
    func showPanel(with selectedText: String, appState: AppState) {
        // Enhanced permissions verification before showing panel
        checkAndRefreshPermissions { permissionGranted in
            if permissionGranted {
                DispatchQueue.main.async {
                    var textToShow = selectedText
                    
                    // Ensure we have text to display
                    if textToShow.isEmpty {
                        // Try one more capture attempt with clipboard prioritized
                        textToShow = self.captureSelectedText()
                        NSLog("📋 Attempted recapture, got text of length: \(textToShow.count)")
                    }
                    
                    if !textToShow.isEmpty {
                        // Cache the text and show the panel
                        self.cachedSelectedText = textToShow
                        self.showUnifiedPanelWithText(selectedText: textToShow, appState: appState)
                        
                        // Log for debugging
                        NSLog("✅ Showing panel with text: \(String(textToShow.prefix(20)))...")
                    } else {
                        // No text found - show empty panel with message
                        appState.selectedText = "No text selected. Please select or copy text and try again."
                        appState.textSource = .userInput
                        self.showEmptySelectionPanel(appState: appState)
                        
                        // Log for debugging
                        NSLog("⚠️ No text found to display")
                    }
                    
                    // Prevent main window from opening
                    NSApp.windows.forEach { window in
                        if window != self.panel && window.title != "Settings" {
                            window.orderOut(nil)
                        }
                    }
                }
            } else {
                // If permissions are still not granted, show the permissions dialog
                DispatchQueue.main.async {
//                    self.hotkeyManager.showAccessibilityPermissionsDialog()
                }
            }
        }
    }
    
    // Show empty selection panel when no text is selected
    func showEmptySelectionPanel(appState: AppState) {
        // Store reference to the app state
        self.appStateRef = appState
        
        // Enhanced permissions verification before showing panel
        checkAndRefreshPermissions { permissionGranted in
            if permissionGranted {
                DispatchQueue.main.async {
                    self.showUnifiedPanelWithContext(appState: appState)
                    appState.emptySelectionMode = true
                    
                    // Prevent main window from opening
                    NSApp.windows.forEach { window in
                        if window != self.panel && window.title != "Settings" {
                            window.orderOut(nil)
                        }
                    }
                }
            } else {
                // If permissions are still not granted, show the permissions dialog
                DispatchQueue.main.async {
//                    self.hotkeyManager.showAccessibilityPermissionsDialog()
                }
            }
        }
    }
    
    // Comprehensive permission check with refresh attempts
    private func checkAndRefreshPermissions(completion: @escaping (Bool) -> Void) {
        // First check if we already have permissions
        if hotkeyManager.hasAccessibilityPermission() {
            completion(true)
            return
        }
        
        // Try refreshing permissions
        if hotkeyManager.refreshAndCheckPermissions() {
            completion(true)
            return
        }
        
        // Advanced verification with dynamic subsystem restart
        hotkeyManager.verifyAccessibilityPermissions { granted in
            if granted {
                completion(true)
            } else {
                // Final attempt - restart the accessibility service
                self.restartAccessibilityService { success in
                    completion(success)
                }
            }
        }
    }
    
    // Final attempt to restart accessibility services
    private func restartAccessibilityService(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Try to restart SystemUIServer which can help refresh permissions
            let task = Process()
            task.launchPath = "/usr/bin/killall"
            task.arguments = ["SystemUIServer"]
            try? task.run()
            
            // Wait for the service to restart
            Thread.sleep(forTimeInterval: 0.5)
            
            // Check permissions after restart
            let hasPermission = self.hotkeyManager.hasAccessibilityPermission() || 
                               self.hotkeyManager.examineProcessPrivileges()
            
            DispatchQueue.main.async {
                completion(hasPermission)
            }
        }
    }
    
    // Core method to show panel with text
    private func showUnifiedPanelWithText(selectedText: String, appState: AppState) {
        // Update the app state with the selected text
        appState.selectedText = selectedText
        appState.isAIPanelVisible = true
        appState.emptySelectionMode = false
        
        // Save reference to the app state
        self.appStateRef = appState
        
        // Track the text source
        appState.updateSelectedText(selectedText, source: .directSelection)
        
        showUnifiedPanelWithContext(appState: appState)
        
        // Additional refresh after panel is visible for reliability
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.refreshPanelContent(appState: appState)
        }
    }
    
    // Core method to display the panel
    private func showUnifiedPanelWithContext(appState: AppState) {
        if panel == nil {
            // Create panel if it doesn't exist
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 640, height: 520),
                styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .borderless],
                backing: .buffered,
                defer: false,
            )
            
            // Remove title and make panel fully transparent
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = .clear
            panel.hasShadow = true
            
            // Hide all standard window buttons
            panel.standardWindowButton(.closeButton)?.isHidden = true
            panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
            panel.standardWindowButton(.zoomButton)?.isHidden = true
            
            // Create a visual effect view for the backdrop
            let visualEffectView = NSVisualEffectView()
            visualEffectView.translatesAutoresizingMaskIntoConstraints = false
            visualEffectView.material = .hudWindow
            visualEffectView.blendingMode = .behindWindow
            visualEffectView.state = .active
            visualEffectView.wantsLayer = true
            
            // Add rounded corners to the visual effect view
            visualEffectView.layer?.cornerRadius = 20
            visualEffectView.layer?.masksToBounds = true
            
            if let contentView = panel.contentView {
                contentView.addSubview(visualEffectView)
                
                // Make visual effect view fill the content view
                NSLayoutConstraint.activate([
                    visualEffectView.topAnchor.constraint(equalTo: contentView.topAnchor),
                    visualEffectView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    visualEffectView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    visualEffectView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                ])
                
                // Store reference to the visual effect view
                self.visualEffectView = visualEffectView
            }
            
            // Set up the content view with SwiftUI
            let hostingController = NSHostingController(
                rootView: KerligStylePanelView()
                    .environmentObject(appState)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            )
            
            // Add the hosting view to the visual effect view
            let hostView = hostingController.view
            hostView.translatesAutoresizingMaskIntoConstraints = false
            visualEffectView.addSubview(hostView)
            
            // Constrain the hosting view to fill the visual effect view
            NSLayoutConstraint.activate([
                hostView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
                hostView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
                hostView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
                hostView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor)
            ])
            
            // Set background to clear for transparency
            hostView.wantsLayer = true
            hostView.layer?.backgroundColor = NSColor.clear.cgColor
            
            // Position panel in a good default location - center of screen
            if let mainScreen = NSScreen.main {
                let screenRect = mainScreen.visibleFrame
                panel.center()
            }
            
            // Add a custom close button through SwiftUI
            
            // Make panel close when clicking outside by default
            panel.hidesOnDeactivate = true
            
            // Listen for pin state changes
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handlePinStateChange),
                name: NSNotification.Name("PanelPinStateChanged"),
                object: nil
            )
            
            self.panel = panel
        }
        
        // Set the window delegate for additional control
        panel?.delegate = self
        
        // Show and activate the panel
        panel?.orderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Add global monitor for outside clicks
        setupGlobalMonitor()
        
        // Add entrance animation
        if let panel = self.panel {
            panel.alphaValue = 0.0
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().alphaValue = 1.0
            }
        }
    }
    
    // Set up global monitor to detect clicks outside the panel
    private func setupGlobalMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else { return }
            
            // Get the mouse location in screen coordinates
            let mouseLocation = event.locationInWindow
            let screenLocation = NSEvent.mouseLocation
            
            // Check if the click is inside the panel's frame
            let panelFrame = panel.frame
            
            // If click is outside the panel and not pinned, close it
            // Use the stored AppState reference to check pin state
            let isPinned = self.appStateRef?.isPinned ?? false
            
            if !NSPointInRect(screenLocation, panelFrame) && !self.isAttemptingTextCapture && !isPinned {
                DispatchQueue.main.async {
                    self.closePanel()
                    // Notify AppState that panel is closed
                    NotificationCenter.default.post(name: NSNotification.Name("ClosePanelNotification"), object: nil)
                }
            }
        }
    }
    
    // Method to refresh content after panel is displayed
    private func refreshPanelContent(appState: AppState) {
        if !self.cachedSelectedText.isEmpty && appState.selectedText.isEmpty {
            // If we have cached text but the state doesn't, update it
            appState.selectedText = self.cachedSelectedText
            // Also update the text source
            appState.updateSelectedText(self.cachedSelectedText, source: .directSelection)
        }
    }
    
    func closePanel() {
        // Fade out animation
        if let panel = self.panel {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().alphaValue = 0.0
            }, completionHandler: {
                panel.orderOut(nil)
                
                // Update app state
                NotificationCenter.default.post(name: NSNotification.Name("ClosePanelNotification"), object: nil)
            })
        } else {
            panel?.orderOut(nil)
            // Update app state
            NotificationCenter.default.post(name: NSNotification.Name("ClosePanelNotification"), object: nil)
        }
    }
    
    @objc private func closeButtonClicked() {
        closePanel()
    }
    
    // Window delegate methods
    func windowDidResignKey(_ notification: Notification) {
        // Use the stored AppState reference to check pin state
        let isPinned = self.appStateRef?.isPinned ?? false
        
        // Close panel when it loses focus only if not pinned
        if !isPinned {
            closePanel()
        }
    }
    
    // Add this method to handle pin state changes
    @objc private func handlePinStateChange(_ notification: Notification) {
        if let isPinned = notification.object as? Bool {
            // Update panel behavior based on pin state
            panel?.hidesOnDeactivate = !isPinned
            
            // Also update our reference to the AppState
            if appStateRef != nil {
                appStateRef?.isPinned = isPinned
            }
        }
    }
} 
