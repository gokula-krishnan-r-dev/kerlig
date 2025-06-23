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
        let windowWidth: CGFloat = 320
        let windowHeight = screen.frame.height * 0.8
        let xPosition = screen.frame.maxX - windowWidth - 20
        let yPosition = (screen.frame.height - windowHeight) / 2
        
        // Create and configure window
        let contentRect = NSRect(x: xPosition, y: yPosition, width: windowWidth, height: windowHeight)
        let window = FloatingSidebarWindow(contentRect: contentRect)
        
        // Set the window's content view
        let contentView = FloatingSidebarView(
            controller: self,
            onClose: { [weak self] in
//                self?.close()
            }
        )
        window.contentView = NSHostingView(rootView: contentView)
        
        // Show the window
        window.makeKeyAndOrderFront(nil)
        self.window = window
        isVisible = true
    }
    
    func hideSidebar() {
        window?.close()
        window = nil
        isVisible = false
    }
} 
