import AppKit
import SwiftUI

class BackgroundAppManager: NSObject {
    static let shared = BackgroundAppManager()
    
    private var menuBarController: MenuBarController?
    private var floatingPanelController: FloatingPanelController?
    private var clipboardPanelController: ClipboardPanelController?
    private var hotkeyManager: HotkeyManager?
    private var textCaptureService: TextCaptureService?
    private var clipboardService: ClipboardMonitoringService?
    private var appState: AppState?
    private var customActionsStorage: CustomActionsStorage?
    
    private var isBackgroundMode: Bool = false
    
   
    
    func configure(
        appState: AppState,
        customActionsStorage: CustomActionsStorage,
        floatingPanelController: FloatingPanelController,
        textCaptureService: TextCaptureService
    ) {
        self.appState = appState
        self.customActionsStorage = customActionsStorage
        self.floatingPanelController = floatingPanelController
        self.textCaptureService = textCaptureService
        
        // Initialize clipboard service and panel
        self.clipboardService = ClipboardMonitoringService.shared
        self.clipboardPanelController = ClipboardPanelController()
        
        // Setup menu bar
        setupMenuBar()
        
        // Setup global hotkey monitoring
        setupGlobalHotkeys()
        
        // Register Whisper Mode with HotkeyManager
        if let hotkeyManager = hotkeyManager {
            WhisperModeManager.shared.registerHotkey(with: hotkeyManager)
        }
        
        // Start clipboard monitoring
        clipboardService?.startMonitoring()
        
        // Enter background mode if user preference is set
        if appState.runInBackground {
            enterBackgroundMode()
        } else {
            exitBackgroundMode()
        }
    }
    
    private func setupBackgroundMode() {
        // Initially set app to run as agent (no dock icon) - will be overridden by user preference
        NSApp.setActivationPolicy(.accessory)
        
        // Handle app termination
        NSApp.delegate = self
        
        // Monitor system events
        setupSystemEventMonitoring()
    }
    
    private func setupMenuBar() {
        guard let appState = appState,
              let customActionsStorage = customActionsStorage,
              let floatingPanelController = floatingPanelController else { return }
        
        menuBarController = MenuBarController()
        menuBarController?.setupMenuBar(
            appState: appState,
            customActionsStorage: customActionsStorage,
            floatingPanelController: floatingPanelController
        )
    }
    
    private func setupGlobalHotkeys() {
        guard let appState = appState else { return }
        
        hotkeyManager = HotkeyManager()
        
        // Register the main hotkey for text capture
        _ = hotkeyManager?.registerHotkey { [weak self] selectedText in
            DispatchQueue.main.async {
                self?.handleHotkeyActivation(selectedText: selectedText)
            }
        }
        
        // Register Whisper Mode shortcut (Command + Shift + R)
        hotkeyManager?.registerWhisperModeShortcut { [weak self] in
            DispatchQueue.main.async {
                self?.handleWhisperModeActivation()
            }
        }
        
        // Register Clipboard History shortcut (Command + Shift + V)
        hotkeyManager?.registerClipboardHistoryShortcut { [weak self] in
            DispatchQueue.main.async {
                self?.handleClipboardHistoryActivation()
            }
        }
        
        // Start text monitoring
        textCaptureService?.startMonitoring()
    }
    
    func handleHotkeyActivation(selectedText: String) {
        guard let appState = appState,
              let floatingPanelController = floatingPanelController else { return }
        
        // Ensure we're in background mode
        if !isBackgroundMode {
            enterBackgroundMode()
        }
        
        // Show floating panel
        if !selectedText.isEmpty {
            floatingPanelController.showPanel(with: selectedText, appState: appState)
        } else {
            floatingPanelController.showEmptySelectionPanel(appState: appState)
        }
    }
    
    func handleWhisperModeActivation() {
        NSLog("🎙️ Whisper Mode activated via shortcut")
        
        // Ensure we're in background mode
        if !isBackgroundMode {
            enterBackgroundMode()
        }
        
        // Activate Whisper Mode
        WhisperModeManager.shared.activateWhisperMode()
    }
    
    func handleClipboardHistoryActivation() {
        NSLog("📋 Clipboard History activated via shortcut")
        
        // Ensure we're in background mode
        if !isBackgroundMode {
            enterBackgroundMode()
        }
        
        // Show clipboard panel
        clipboardPanelController?.showPanel()
    }
    
    func enterBackgroundMode() {
        guard !isBackgroundMode else {
            NSLog("🔄 [BACKGROUND] Already in background mode, skipping...")
            return
        }
        
        NSLog("🔄 [BACKGROUND] Entering background mode...")
        isBackgroundMode = true
        
        // Hide all windows except floating panels and specific system windows
        let windowsToHide = NSApp.windows.filter { window in
            window.title != "AI Assistant" && 
            window.title != "Settings" &&
            !window.title.contains("Panel") &&
            !window.title.isEmpty // Don't hide system windows
        }
        
        NSLog("🔄 [BACKGROUND] Hiding \(windowsToHide.count) windows")
        for window in windowsToHide {
            window.orderOut(nil)
        }
        
        // Set activation policy to accessory (no dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Update app state
        appState?.isAIPanelVisible = false
        
        NSLog("✅ [BACKGROUND] Successfully entered background mode - app hidden from dock")
    }
    
    func exitBackgroundMode() {
        guard isBackgroundMode else {
            NSLog("🔄 [BACKGROUND] Already in regular mode, skipping...")
            return
        }
        
        NSLog("🔄 [BACKGROUND] Exiting background mode...")
        isBackgroundMode = false
        
        // Show app in dock
        NSApp.setActivationPolicy(.regular)
        
        // Activate the app with a small delay to ensure proper window management
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
        }
        
        NSLog("✅ [BACKGROUND] Successfully exited background mode - app visible in dock")
    }
    
    private func setupSystemEventMonitoring() {
        // Monitor for system sleep/wake events
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
        // Monitor for user session changes
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(userSessionDidBecomeActive),
            name: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil
        )
        
        // Monitor for background mode changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackgroundModeChange),
            name: NSNotification.Name("BackgroundModeChanged"),
            object: nil
        )
    }
    
    @objc private func systemWillSleep() {
        // Pause monitoring when system sleeps
        textCaptureService?.stopMonitoring()
    }
    
    @objc private func systemDidWake() {
        // Resume monitoring when system wakes
        textCaptureService?.startMonitoring()
        
        // Refresh hotkey registration
        setupGlobalHotkeys()
        
        // Re-register Whisper Mode
        if let hotkeyManager = hotkeyManager {
            WhisperModeManager.shared.registerHotkey(with: hotkeyManager)
        }
    }
    
    @objc private func userSessionDidBecomeActive() {
        // Ensure hotkeys are still working after user session changes
        setupGlobalHotkeys()
        
        // Re-register Whisper Mode
        if let hotkeyManager = hotkeyManager {
            WhisperModeManager.shared.registerHotkey(with: hotkeyManager)
        }
    }
    
    @objc private func handleBackgroundModeChange(_ notification: Notification) {
        guard let runInBackground = notification.object as? Bool else { 
            NSLog("⚠️ [BACKGROUND] Invalid notification object for background mode change")
            return 
        }
        
        NSLog("🔄 [BACKGROUND] Handling background mode change to: \(runInBackground)")
        
        // Add a small delay to ensure UI state is consistent
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if runInBackground {
                // Switch to background mode only if onboarding is complete
                if self.appState?.onboardingComplete == true {
                    NSLog("🔄 [BACKGROUND] Switching to background mode")
                    self.enterBackgroundMode()
                } else {
                    NSLog("⚠️ [BACKGROUND] Cannot enter background mode - onboarding not complete")
                }
            } else {
                // Switch to regular mode
                NSLog("🔄 [BACKGROUND] Switching to regular mode")
                self.exitBackgroundMode()
            }
        }
    }
    
    // MARK: - Public Interface
    
    func showMainWindow() {
        exitBackgroundMode()
        
        // Find or create main window
        if let window = NSApp.windows.first(where: { $0.title == "Kerlig" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            createMainWindow()
        }
    }
    
    private func createMainWindow() {
        guard let appState = appState,
              let customActionsStorage = customActionsStorage else { return }
        
        let contentView = ContentView()
            .environmentObject(appState)
            .environmentObject(customActionsStorage)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Kerlig"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // Set up window delegate to handle closing
        window.delegate = BackgroundWindowDelegate()
    }
    
    func terminateApp() {
        // Clean up resources
        textCaptureService?.stopMonitoring()
        clipboardService?.stopMonitoring()
        menuBarController = nil
        floatingPanelController = nil
        clipboardPanelController = nil
        hotkeyManager = nil
        
        // Clean up Whisper Mode resources
        ToastManager.shared.dismissAllToasts()
        
        // Quit the app
        NSApp.terminate(nil)
    }
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}

// MARK: - NSApplicationDelegate

extension BackgroundAppManager: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // App finished launching in background mode
        NSLog("Kerlig started in background mode")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up before termination
        textCaptureService?.stopMonitoring()
        NSLog("Kerlig terminating")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Handle dock icon click or app reopen
        if !flag {
            showMainWindow()
        }
        return true
    }
}

// MARK: - Background Window Delegate

class BackgroundWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Return to background mode when main window closes
        BackgroundAppManager.shared.enterBackgroundMode()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Ensure app is visible when window becomes key
        NSApp.setActivationPolicy(.regular)
    }
} 
