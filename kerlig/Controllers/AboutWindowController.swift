import AppKit
import SwiftUI

class AboutWindowController: NSObject {
    private var window: NSWindow?
    
    func showAboutWindow() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let aboutView = AboutView()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = "About Kerlig"
        window.contentView = NSHostingView(rootView: aboutView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // Set minimum and maximum sizes
        window.minSize = NSSize(width: 600, height: 500)
        window.maxSize = NSSize(width: 800, height: 700)
        
        // Configure window appearance
        window.titlebarAppearsTransparent = false
        window.backgroundColor = NSColor.windowBackgroundColor
        
        // Set window delegate
        window.delegate = self
        
        self.window = window
        
        // Bring app to front
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension AboutWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        window = nil
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
} 