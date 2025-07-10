import Cocoa
import SwiftUI

class NotificationPanelController: NSObject {
    private var window: NSWindow?
    private var notificationDuration: TimeInterval = 5.0
    private var hideTimer: Timer?
    
    override init() {
        super.init()
        setupWindow()
    }
    
    private func setupWindow() {
        // Create window with transparent titlebar
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 80),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = true
        
        // Set SwiftUI view as content
        window.contentView = NSHostingView(rootView: NotificationPanelView(message: ""))
        
        self.window = window
    }
    
    func showNotification(withMessage message: String) {
        // Cancel any existing hide timer
        hideTimer?.invalidate()
        
        // Update the message in the SwiftUI view
        if let hostingView = window?.contentView as? NSHostingView<NotificationPanelView> {
            hostingView.rootView = NotificationPanelView(message: message)
        }
        
        // Position window at the top of the screen
        positionWindowAtTopOfScreen()
        
        // Show window with animation if not already visible
        if !(window?.isVisible ?? false) {
            window?.alphaValue = 0.0
            window?.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                window?.animator().alphaValue = 1.0
            })
        }
        
        // Set timer to hide notification
        hideTimer = Timer.scheduledTimer(withTimeInterval: notificationDuration, repeats: false) { [weak self] _ in
            self?.hideNotification()
        }
    }
    
    func hideNotification() {
        // Hide window with animation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window?.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.window?.orderOut(nil)
        })
    }
    
    private func positionWindowAtTopOfScreen() {
        guard let window = self.window, let screen = NSScreen.main else { return }
        
        // Calculate position at top center of the screen
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        let newOriginX = screenFrame.midX - windowFrame.width / 2
        let newOriginY = screenFrame.maxY - windowFrame.height - 10 // 10px from top
        
        window.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
    }
} 