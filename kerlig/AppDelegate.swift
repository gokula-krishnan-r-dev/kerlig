import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    @ObservedObject var appState = kerlig.AppState()
    private var statusBarItem: NSStatusItem?
    private var contentViewController: NSHostingController<ContentView>?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
        setupMenuBarItem()
    }
    
    private func setupWindow() {
        let contentView = ContentView()
            .environmentObject(appState)
        
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = hostingController.view
        window.makeKeyAndOrderFront(nil)
        window.title = "Kerlig"
        
        // Set a minimum size for the window
        window.minSize = NSSize(width: 800, height: 500)
    }
    
    private func setupMenuBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Kerlig")
            
            // Create a menu for the status bar item
            let menu = NSMenu()
            
            // Add menu items
            menu.addItem(NSMenuItem(title: "Show Kerlig", action: #selector(showMainWindow), keyEquivalent: "s"))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Clipboard History", action: #selector(showClipboardHistory), keyEquivalent: "c"))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusBarItem?.menu = menu
        }
    }
    
    @objc func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
    
    @objc func showClipboardHistory(_ sender: Any?) {
        // First make sure the app is active
        NSApp.activate(ignoringOtherApps: true)
        
        // Post a notification that will be observed by the ContentView
        NotificationCenter.default.post(name: Notification.Name.showClipboardHistoryPopup, object: nil)
    }
}

// MARK: - Notification Extension for Clipboard History
extension Notification.Name {
    static let showClipboardHistoryPopup = Notification.Name("ShowClipboardHistoryPopup")
} 
