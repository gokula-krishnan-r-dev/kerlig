import SwiftUI

// Class to handle status bar functionality
class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var captureService: TextCaptureService
    
    init(captureService: TextCaptureService) {
        self.captureService = captureService
        super.init()
        setupStatusBarItem()
    }
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "text.append", accessibilityDescription: "Text Capture")
            
            // Create the menu
            let menu = NSMenu()
            
            menu.addItem(NSMenuItem(title: "Capture Text (Option+Space)", action: #selector(captureText), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Open App", action: #selector(openApp), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusItem?.menu = menu
        }
    }
    
    @objc func captureText() {
        captureService.captureSelectedText()
    }
    
    @objc func openApp() {
        NSApp.activate(ignoringOtherApps: true)
    }
}
