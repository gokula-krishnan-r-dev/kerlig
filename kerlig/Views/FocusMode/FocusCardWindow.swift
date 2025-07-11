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
        
        // Ensure window appears above other windows but below alerts
        self.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
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

    func updateSize(newSize: CGSize) {
        guard let window = self.window else { return }

        var newFrame = window.frame
        let oldFrame = window.frame
        let oldSize = oldFrame.size
        
        // Keep top edge stationary while adjusting for new size
        newFrame.origin.y += (oldSize.height - newSize.height)
        newFrame.origin.x += (oldSize.width - newSize.width) / 2
        newFrame.size = newSize

        // Professional spring animation for smooth resizing
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.2, 1.0) // Custom easing
            context.allowsImplicitAnimation = true
            window.animator().setFrame(newFrame, display: true)
        }
    }
    
    private func showFocusCard() {
        // Get the main screen's frame
        guard let screen = NSScreen.main else { return }
        
               // Calculate window position (top center of screen)
        let windowWidth: CGFloat = 280
        let windowHeight: CGFloat = 50  // Much more compact for modern design
        let xPosition = (screen.frame.width - windowWidth) / 2
        let yPosition = screen.frame.height - windowHeight - 10 // 10px from top
        
        // Create and configure window
        let contentRect = NSRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight)
        let window = FocusCardWindow(contentRect: contentRect)
        
        // Create a note store instance
        let noteStore = NoteStore()
        
        // Set the window's content view with proper styling
        let contentView = FocusCardView(controller: self, noteStore: noteStore)
            .environment(\.colorScheme, .dark) // Ensure dark mode appearance
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.appearance = NSAppearance(named: .darkAqua)
        window.contentView = hostingView
        
        // Show the window with animation
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        
        // Add a subtle spring animation for a more polished appearance
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            
            // Add a subtle scale animation
            if let contentView = window.contentView {
                let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
                scaleAnimation.fromValue = 0.95
                scaleAnimation.toValue = 1.0
                scaleAnimation.duration = 0.4
                scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
                contentView.layer?.add(scaleAnimation, forKey: "scale")
            }
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
