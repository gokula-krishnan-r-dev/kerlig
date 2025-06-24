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
        
        // Apply corner radius to the window
        self.contentView?.wantsLayer = true
        self.contentView?.layer?.cornerRadius = 16
        self.contentView?.layer?.masksToBounds = true
        
        // Add subtle border
        self.contentView?.layer?.borderWidth = 0.5
        self.contentView?.layer?.borderColor = NSColor.white.withAlphaComponent(0.1).cgColor
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
    private var windowWidth: CGFloat = 320
    
    // Store the window position for persistence
    private var lastPosition: NSPoint?
    
    func toggleSidebar() {
        if let window = self.window {
            window.close()
            self.window = nil
            isVisible = false
        } else {
            showSidebar()
        }
    }
    
    private func showSidebar() {
        // Get the main screen's frame
        guard let screen = NSScreen.main else { return }
        
        // Calculate window position (right side of screen)
        let windowHeight = screen.frame.height * 0.75
        
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
        
        // Add shadow effect
        window.contentView?.layer?.shadowOpacity = 0.3
        window.contentView?.layer?.shadowRadius = 15
        window.contentView?.layer?.shadowOffset = CGSize(width: 0, height: 5)
        window.contentView?.layer?.shadowColor = NSColor.black.cgColor
        
        // Show the window with animation
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }
        
        self.window = window
        isVisible = true
    }
    
    func hideSidebar() {
        guard let window = self.window else { return }
        
        // Store the current position before closing
        lastPosition = window.frame.origin
        
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
