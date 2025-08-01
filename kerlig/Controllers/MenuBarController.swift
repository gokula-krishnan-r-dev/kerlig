import AppKit
import SwiftUI

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var floatingPanelController: FloatingPanelController?
    private var appState: AppState?
    private var customActionsStorage: CustomActionsStorage?
    // Hotkey manager to handle global shortcuts
    private let hotkeyManager = HotkeyManager()
      private var panelController: WhisperModePanelController?
    // About window controller
    private let aboutWindowController = AboutWindowController()
    // Project workspace panel controller
    private let projectsPanelController = ProjectsPanelController()
    
    func setupMenuBar(appState: AppState, customActionsStorage: CustomActionsStorage, floatingPanelController: FloatingPanelController) {
        self.appState = appState
        self.customActionsStorage = customActionsStorage
        self.floatingPanelController = floatingPanelController
        
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let statusButton = statusItem?.button {
            // Set the menu bar icon
            statusButton.image = createMenuBarIcon()
            statusButton.imagePosition = .imageOnly
            statusButton.action = #selector(statusBarButtonClicked)
            statusButton.target = self
            statusButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Create the menu
        setupMenu()

        // Register global Command+M shortcut for Mac Write
        registerMacWriteHotkey()
        
        // Initialize and register hotkeys for projects panel controller
        setupProjectsPanelController(appState: appState)
    }
    
    private func createMenuBarIcon() -> NSImage {
        // Use the system command key icon (⌘) for the menu bar
        if let commandIcon = NSImage(systemSymbolName: "command", accessibilityDescription: "Kerlig Clipboard Manager") {
            // Create a new image with the desired size
            let image = NSImage(size: NSSize(width: 18, height: 18))
            image.lockFocus()
            
            // Draw the command icon centered in the image
            let drawRect = NSRect(x: 1, y: 1, width: 16, height: 15)
            commandIcon.draw(in: drawRect)
            
            image.unlockFocus()
            image.isTemplate = true
            return image
        }
        
        // Fallback to a simple command symbol if system icon fails
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        
        // Draw command symbol manually as fallback
        let font = NSFont.systemFont(ofSize: 14, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]
        let commandString = NSAttributedString(string: "⌘", attributes: attributes)
        let stringSize = commandString.size()
        let stringRect = NSRect(
            x: (18 - stringSize.width) / 2,
            y: (18 - stringSize.height) / 2,
            width: stringSize.width,
            height: stringSize.height
        )
        commandString.draw(in: stringRect)
        
        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    private func setupMenu() {
        let menu = NSMenu()
        
        // Quick Capture item
        let captureItem = NSMenuItem(
            title: "Quick Capture",
            action: #selector(quickCapture),
            keyEquivalent: ""
        )
        captureItem.target = self
        menu.addItem(captureItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Show Main Window
        let showMainItem = NSMenuItem(
            title: "Show Main Window",
            action: #selector(showMainWindow),
            keyEquivalent: ""
        )
        showMainItem.target = self
        menu.addItem(showMainItem)
        
        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)


        //add one more for mac write
        let macWriteItem = NSMenuItem(
            title: "Mac Write",
            action: #selector(showMacWrite),
            keyEquivalent: "m"
        )
        macWriteItem.keyEquivalentModifierMask = [.command]
        macWriteItem.target = self
        menu.addItem(macWriteItem)
        // Launch at Login
        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
        menu.addItem(launchAtLoginItem)
        
        menu.addItem(NSMenuItem.separator())


        // Project Workspace
        let projectWorkspaceItem = NSMenuItem(
            title: "Project Workspace",
            action: #selector(showProjectWorkspace),
            keyEquivalent: "p"
        )
        projectWorkspaceItem.keyEquivalentModifierMask = [.command]
        projectWorkspaceItem.target = self
        menu.addItem(projectWorkspaceItem)

        //add a button for whisper mode
        let whisperModeItem = NSMenuItem(
            title: "Whisper Mode",
            action: #selector(showWhisperMode),
            keyEquivalent: "w"
        )
        whisperModeItem.target = self
        menu.addItem(whisperModeItem)


        
        menu.addItem(NSMenuItem.separator())
        
        // About
        let aboutItem = NSMenuItem(
            title: "About Kerlig",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)


        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Kerlig",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func statusBarButtonClicked() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .leftMouseUp {
            // Left click - show quick capture
            quickCapture()
        } else if event.type == .rightMouseUp {
            // Right click - show menu (handled automatically)
        }
    }
    
    @objc private func quickCapture() {
        guard let appState = appState else { return }
        
        // Use the floating panel controller to show quick capture
        floatingPanelController?.togglePanel(appState: appState)
    }
    
    @objc private func showMainWindow() {
        // Show the main application window
        NSApp.setActivationPolicy(.regular)
        
        // Find or create main window
        if let window = NSApp.windows.first(where: { $0.title != "Settings" && $0.title != "AI Assistant" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Create new main window if none exists
            createMainWindow()
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func createMainWindow() {
        guard let appState = appState, let customActionsStorage = customActionsStorage else { return }
        
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
        
        // Hide back to background when window is closed
        window.delegate = WindowDelegate()
    }
    
    @objc private func showSettings() {
        // Show settings window
        let settingsWindow = SettingsWindow()
        settingsWindow.show()
    }

    @objc private func showMacWrite() {
     
         //before toggle close already existing window close
        if let existingWindow = NSApp.windows.first(where: { $0.isVisible }) {
            existingWindow.close()
        }

          let floatingSidebarController = FloatingSidebarController()
        floatingSidebarController.toggleSidebar()
    }
    
    @objc private func toggleLaunchAtLogin() {
        LaunchAtLoginManager.shared.isEnabled.toggle()
        appState?.toggleLaunchAtLogin()
        
        // Update the menu item state
        setupMenu()
    }
    
    /// Displays the project workspace panel for browsing and opening VS Code projects
    /// This method is triggered from the menu bar or Command+P hotkey
    @objc private func showProjectWorkspace() {
        guard let appState = appState else {
            NSLog("⚠️ [MenuBarController] AppState not available for project workspace")
            return
        }
        
        // Show the project workspace panel with proper state management
        projectsPanelController.showProjectsPanel(appState: appState)
        NSLog("✅ [MenuBarController] Project workspace panel displayed")
    }

    @objc private func showWhisperMode() {
        //show the whisper mode panel
        panelController!.showPanel(
                completion:{
                    print("demo")
                }
            )
    }

    @objc private func showAbout() {
        aboutWindowController.showAboutWindow()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Global Shortcut (⌘+M) Registration

    /// Registers a system-wide Command + M shortcut that triggers `showMacWrite()`.
    /// Uses the shared `HotkeyManager` utility which relies on accessibility
    /// permissions and NSEvent monitors to listen for key presses even when the
    /// application is not in the foreground.
    private func registerMacWriteHotkey() {
        // Ensure we have the required accessibility permission first
        guard hotkeyManager.hasAccessibilityPermission() else {
            hotkeyManager.showAccessibilityPermissionsDialog()
            return
        }

        // Key code for the "M" key on ANSI keyboards is 0x2E (46)
        hotkeyManager.simulateKeyPressWithCallback(
            keyCode: CGKeyCode(46),
            withCommand: true
        ) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.showMacWrite()
            }
        }
    }
    
    // MARK: - Projects Panel Setup
    
    /// Sets up the projects panel controller with proper initialization and hotkey registration
    private func setupProjectsPanelController(appState: AppState) {
        // Register the Command+P hotkey for the projects panel
        projectsPanelController.registerHotkey(appState: appState)
        NSLog("✅ [MenuBarController] Projects panel controller initialized with hotkeys")
    }
    
    deinit {
        statusItem = nil
        // Remove any global key-press monitors we installed
        hotkeyManager.removeKeyPressCallbacks()
        // Note: projectsPanelController will clean up itself in its own deinit
        NSLog("🧹 [MenuBarController] Cleaned up menu bar controller resources")
    }
}

// Window delegate to handle main window closing
class WindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Hide the app from dock when main window closes
        NSApp.setActivationPolicy(.accessory)
    }
}

// Settings window controller
class SettingsWindow: NSObject {
    private var window: NSWindow?
    
    func show() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        let settingsView = SettingsView()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        self.window = window
        window.delegate = self
    }
}

extension SettingsWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        window = nil
    }
} 
