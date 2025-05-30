import SwiftUI
import AppKit
import Carbon

class ProjectsPanelController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private var hotkeyManager = HotkeyManager()
    private var appStateRef: AppState? = nil
    private var visualEffectView: NSVisualEffectView? = nil
    private var projectsService = VSCodeProjectsService()
    private var hotKeyRef: EventHotKeyRef?
    
    // Register Command+P hotkey
    func registerHotkey(appState: AppState) {
        // Store reference to appState for later use
        self.appStateRef = appState
        
        // Initialize the hotkey manager to use its helpers
        if !hotkeyManager.hasAccessibilityPermission() {
            hotkeyManager.showAccessibilityPermissionsDialog()
            return
        }
        
        // Using a simpler approach through the hotkeyManager helper methods
        hotkeyManager.simulateKeyPressWithCallback(
            keyCode: CGKeyCode(35), // P key
            withCommand: true,
            callback: { [weak self] in
                // This will be called when Command+P is pressed
                if let self = self, let appState = self.appStateRef {
                    DispatchQueue.main.async {
                        self.togglePanel(appState: appState)
                    }
                }
            }
        )
    }
    
    // Toggle panel visibility
    func togglePanel(appState: AppState) {
        // Store reference to appState for later use
        self.appStateRef = appState
        
        if panel != nil && panel!.isVisible {
            closePanel()
        } else {
            showProjectsPanel(appState: appState)
        }
    }
    
    // Show the projects panel
    func showProjectsPanel(appState: AppState) {
        // Store reference to the app state
        self.appStateRef = appState
        
        // Enhanced permissions verification before showing panel
        hotkeyManager.checkAndRefreshPermissions { permissionGranted in
            if permissionGranted {
                DispatchQueue.main.async {
                    self.createAndShowPanel(appState: appState)
                    
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
                    self.hotkeyManager.showAccessibilityPermissionsDialog()
                }
            }
        }
    }
    
    // Core method to display the panel
    private func createAndShowPanel(appState: AppState) {
        if panel == nil {
            // Create panel if it doesn't exist
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 540, height: 400),
                styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .borderless],
                backing: .buffered,
                defer: false
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
                rootView: ProjectsPanelView(
                    projectsService: projectsService,
                    onClose: { [weak self] in
                        self?.closePanel()
                    }
                )
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
            
            // Make panel close when clicking outside by default
            panel.hidesOnDeactivate = true
            
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
            let screenLocation = NSEvent.mouseLocation
            
            // Check if the click is inside the panel's frame
            let panelFrame = panel.frame
            
            // If click is outside the panel, close it
            if !NSPointInRect(screenLocation, panelFrame) {
                DispatchQueue.main.async {
                    self.closePanel()
                }
            }
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
            })
        } else {
            panel?.orderOut(nil)
        }
    }
    
    // Window delegate methods
    func windowDidResignKey(_ notification: Notification) {
        closePanel()
    }
    
    // Clean up resources when controller is deallocated
    deinit {
        hotkeyManager.removeKeyPressCallbacks()
        if let panel = panel {
            panel.close()
        }
    }
} 