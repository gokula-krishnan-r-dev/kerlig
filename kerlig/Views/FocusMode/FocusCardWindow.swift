import SwiftUI
import AppKit

class FocusCardWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties
        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Set title bar appearance
        self.appearance = NSAppearance(named: .darkAqua)
        self.titleVisibility = .hidden
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

class FocusCardController {
    private var window: FocusCardWindow?
    private var isVisible = false
    
    func toggleFocusCard() {
        if let window = self.window {
            hideFocusCard()
        } else {
            showFocusCard()
        }
    }
    
    private func showFocusCard() {
        // Get the main screen's frame
        guard let screen = NSScreen.main else { return }
        
        // Calculate window position (top center of screen)
        let windowWidth: CGFloat = 200
        let windowHeight: CGFloat = 80  // Increased height to accommodate action buttons
        let xPosition = (screen.frame.width - windowWidth) / 2
        let yPosition = screen.frame.height - windowHeight - 10 // 10px from top
        
        // Create and configure window
        let contentRect = NSRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight)
        let window = FocusCardWindow(contentRect: contentRect)
        
        // Set the window's content view
        let contentView = FocusCardView(controller: self)
        window.contentView = NSHostingView(rootView: contentView)
        
        // Show the window with animation
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }
        
        self.window = window
        isVisible = true
    }
    
    func hideFocusCard() {
        guard let window = self.window else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        }) {
            window.close()
            self.window = nil
            self.isVisible = false
        }
    }
} 