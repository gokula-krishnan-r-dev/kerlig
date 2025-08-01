import SwiftUI
import AppKit

class FloatingSidebarWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .fullSizeContentView],
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
        
        // Apply enhanced visual styling
        setupVisualStyling()
    }
    
    private func setupVisualStyling() {
        guard let contentView = self.contentView else { return }
        
        // Enable layer for the content view
        contentView.wantsLayer = true
        
        // Apply modern corner radius
        contentView.layer?.cornerRadius = 20
        contentView.layer?.masksToBounds = true
        
        // Add glass-like background effect
        let visualEffect = NSVisualEffectView(frame: contentView.bounds)
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 20
        
        // Add gradient border layer
        let borderLayer = CAGradientLayer()
        borderLayer.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.height)
        borderLayer.cornerRadius = 20
        
        // Create gradient with modern colors
        borderLayer.colors = [
            NSColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 0.6).cgColor,
            NSColor(red: 0.6, green: 0.4, blue: 1.0, alpha: 0.6).cgColor,
            NSColor(red: 1.0, green: 0.4, blue: 0.8, alpha: 0.6).cgColor
        ]
        
        borderLayer.startPoint = CGPoint(x: 0, y: 0)
        borderLayer.endPoint = CGPoint(x: 1, y: 1)
        borderLayer.type = .conic
        
        // Create mask for border-only effect
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        let inset: CGFloat = 1.0 // Border width
        
        path.addRect(contentView.bounds)
        path.addRect(contentView.bounds.insetBy(dx: inset, dy: inset))
        
        maskLayer.path = path
        maskLayer.fillRule = .evenOdd
        
        borderLayer.mask = maskLayer
        
        // Add layers to the view
        contentView.layer?.addSublayer(borderLayer)
        
        // Enhanced shadow effect
        contentView.layer?.shadowOpacity = 0.25
        contentView.layer?.shadowRadius = 20
        contentView.layer?.shadowOffset = CGSize(width: 0, height: 8)
        contentView.layer?.shadowColor = NSColor.black.cgColor
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

class FloatingSidebarController {
    private var window: FloatingSidebarWindow?
    private var isVisible = false
    private var isClosing = false
    private var windowWidth: CGFloat = 320
    
    // Store the window position for persistence
    private var lastPosition: NSPoint?
    
    func toggleSidebar() {
        if isVisible && !isClosing {
            hideSidebar()
        } else if !isVisible && !isClosing {
            showSidebar()
        }
    }
    
    private func showSidebar() {
        // Get the main screen's frame
        guard let screen = NSScreen.main else { return }
        
        // Calculate window position (right side of screen)
        let windowHeight = screen.frame.height * 0.87
        
        // Use last position if available, otherwise calculate default position
        let xPosition: CGFloat
        let yPosition: CGFloat
        
        if let lastPos = lastPosition {
            xPosition = lastPos.x
            yPosition = lastPos.y
        } else {
            xPosition = screen.frame.maxX - windowWidth - 20
            yPosition = (screen.frame.height - windowHeight) / 2
        }
        
        // Create and configure window
        let contentRect = NSRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight)
        let window = FloatingSidebarWindow(contentRect: contentRect)
        
        // Set the window's content view
        let contentView = FloatingSidebarView(
            controller: self,
            onClose: { [weak self] in
                self?.hideSidebar()
            }
        )
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
    
    func hideSidebar() {
        guard let window = self.window, !isClosing else { return }
        
        // Mark as closing to prevent multiple close attempts
        isClosing = true
        
        // Store the current position before closing
        lastPosition = window.frame.origin
        
        // Create a weak reference to self to avoid retain cycles
        weak var weakSelf = self
        
        // Store a local reference to the window
        let windowToClose = window
        
        // Clear the reference before animation starts
        self.window = nil
        
        DispatchQueue.main.async {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
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
    
    func resizeWindow(width: CGFloat? = nil) {
        guard let window = self.window else { return }
        
        if let newWidth = width {
            windowWidth = newWidth
        }
        
        var frame = window.frame
        frame.size.width = windowWidth
        window.setFrame(frame, display: true, animate: true)
    }
} 



