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
        
        // Add visual effect for better aesthetics
        self.isOpaque = false
        self.backgroundColor = .clear
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
    private var isClosing = false
    
    func toggleFocusCard() {
        if isVisible && !isClosing {
            hideFocusCard()
        } else if !isVisible && !isClosing {
            showFocusCard()
        }
    }
    
    private func showFocusCard() {
        // Get the main screen's frame
        guard let screen = NSScreen.main else { return }
        
        // Calculate window position (top center of screen)
        let windowWidth: CGFloat = 300
        let windowHeight: CGFloat = 80  // Adjusted height for modern design
        let xPosition = (screen.frame.width - windowWidth) / 2
        let yPosition = screen.frame.height - windowHeight - 10 // 10px from top
        
        // Create and configure window
        let contentRect = NSRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight)
        let window = FocusCardWindow(contentRect: contentRect)
        let noteStore = NoteStore()
        
        // Set the window's content view
        let contentView = FocusCardView(controller: self, noteStore: noteStore)
        window.contentView = NSHostingView(rootView: contentView)
        
        // Show the window with animation
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }
        
        self.window = window
        isVisible = true
        isClosing = false
    }
    
    func hideFocusCard() {
        guard let window = self.window, !isClosing else { return }
        
        // Mark as closing to prevent multiple close attempts
        isClosing = true
        
        // Create a weak reference to self to avoid retain cycles
        weak var weakSelf = self
        
        // Store a local reference to the window
        let windowToClose = window
        
        // Clear the reference before animation starts
        self.window = nil
        
        DispatchQueue.main.async {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                windowToClose.animator().alphaValue = 0
            }) {
                // Only access properties through the weak reference
                windowToClose.orderOut(nil)
                
                // Update state on main thread after animation completes
                DispatchQueue.main.async {
                    weakSelf?.isVisible = false
                    weakSelf?.isClosing = false
                }
            }
        }
    }
} 
