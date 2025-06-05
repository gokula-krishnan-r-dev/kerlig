import SwiftUI
import AppKit

class URLManagerPanelController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private var hotkeyManager = HotkeyManager()
    private var urlManagerService = URLManagerService()
    
    override init() {
        super.init()
        setupCommandDHotkey()
    }
    
    deinit {
        panel?.close()
        hotkeyManager.removeKeyPressCallbacks()
    }
    
    // MARK: - Hotkey Setup
    
    private func setupCommandDHotkey() {
        // Set up Command + D hotkey detection
        hotkeyManager.simulateKeyPressWithCallback(
            keyCode: CGKeyCode(2), // D key
            withCommand: true,
            withOption: false
        ) { [weak self] in
            DispatchQueue.main.async {
                self?.togglePanel()
            }
        }
        
        NSLog("✅ URL Manager: Set up Command+D hotkey detection")
    }
    
    // MARK: - Panel Management
    
    func togglePanel() {
        if let panel = panel, panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }
    
    func showPanel() {
        if panel == nil {
            createPanel()
        }
        
        guard let panel = panel else { return }
        
        // Position panel in center of screen
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect.zero
        let panelSize = NSSize(width: 600, height: 500)
        let panelOrigin = NSPoint(
            x: screenFrame.midX - panelSize.width / 2,
            y: screenFrame.midY - panelSize.height / 2
        )
        
        panel.setFrame(NSRect(origin: panelOrigin, size: panelSize), display: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        
        NSLog("✅ URL Manager Panel shown")
    }
    
    func closePanel() {
        panel?.orderOut(nil)
        NSLog("📤 URL Manager Panel closed")
    }
    
    private func createPanel() {
        // Create the panel
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        guard let panel = panel else { return }
        
        // Configure panel properties
        panel.title = "URL Manager"
        panel.delegate = self
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isRestorable = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Add visual effect background
        let visualEffectView = NSVisualEffectView()
        visualEffectView.state = .active
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        panel.contentView = visualEffectView
        
        // Create and set up the SwiftUI content
        let contentView = URLManagerPanelView(
            urlManagerService: urlManagerService,
            onClose: { [weak self] in
                self?.closePanel()
            }
        )
        
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        visualEffectView.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor)
        ])
        
        NSLog("✅ URL Manager Panel created")
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        NSLog("📤 URL Manager Panel will close")
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        NSLog("🔑 URL Manager Panel became key")
    }
    
    func windowDidResignKey(_ notification: Notification) {
        NSLog("🔓 URL Manager Panel resigned key")
    }
} 