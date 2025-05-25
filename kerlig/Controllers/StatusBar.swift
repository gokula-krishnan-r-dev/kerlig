import SwiftUI

// Class to handle status bar functionality
class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var captureService: TextCaptureService
    private let logger = AppLogger.statusBar
    
    // Menu items configuration for easy maintenance
    private struct MenuItems {
        static let openApp = MenuItem(title: "Open App", action: #selector(StatusBarController.openApp), keyEquivalent: "o")
        static let requestChange = MenuItem(title: "Request Change", action: #selector(StatusBarController.requestChange), keyEquivalent: "r")
        static let writeReview = MenuItem(title: "Write a Review", action: #selector(StatusBarController.writeReview), keyEquivalent: "w")
        static let reportBug = MenuItem(title: "Report a Bug", action: #selector(StatusBarController.reportBug), keyEquivalent: "b")
        static let checkForUpdates = MenuItem(title: "Check for Updates", action: #selector(StatusBarController.checkForUpdates), keyEquivalent: "u")
        static let version = MenuItem(title: "Version \(AppConfiguration.appVersion)", action: #selector(StatusBarController.version), keyEquivalent: "v")
        static let settings = MenuItem(title: "Settings", action: #selector(StatusBarController.settings), keyEquivalent: "s")
        static let launchAtStartup = MenuItem(title: "Launch at Startup", action: #selector(StatusBarController.launchAtStartup), keyEquivalent: "l")
        static let quit = MenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }
    
    // Helper struct to define menu items
    private struct MenuItem {
        let title: String
        let action: Selector
        let keyEquivalent: String
    }
    
    init(captureService: TextCaptureService) {
        self.captureService = captureService
        super.init()
        setupStatusBarItem()
        logger.log("StatusBarController initialized", level: .info)
    }
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "text.append", accessibilityDescription: "Text Capture")
            
            // Create the menu
            let menu = createMenu()
            statusItem?.menu = menu
            logger.log("Status bar item setup complete", level: .debug)
        } else {
            logger.log("Failed to create status bar button", level: .error)
        }
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Add main action items
        addMenuItem(to: menu, with: MenuItems.openApp)
        menu.addItem(NSMenuItem.separator())
        
        // Add feedback section
        addMenuItem(to: menu, with: MenuItems.requestChange)
        addMenuItem(to: menu, with: MenuItems.writeReview)
        addMenuItem(to: menu, with: MenuItems.reportBug)
        menu.addItem(NSMenuItem.separator())
        
        // Add version and updates section
        addMenuItem(to: menu, with: MenuItems.checkForUpdates)
        addMenuItem(to: menu, with: MenuItems.version)
        menu.addItem(NSMenuItem.separator())
        
        // Add settings section
        addMenuItem(to: menu, with: MenuItems.settings)
        addMenuItem(to: menu, with: MenuItems.launchAtStartup)
        menu.addItem(NSMenuItem.separator())
        
        // Add quit item
        addMenuItem(to: menu, with: MenuItems.quit)
        
        logger.log("Menu created with \(menu.items.count) items", level: .debug)
        return menu
    }
    
    private func addMenuItem(to menu: NSMenu, with item: MenuItem) {
        menu.addItem(NSMenuItem(title: item.title, action: item.action, keyEquivalent: item.keyEquivalent))
    }
    
    @objc func captureText() {
        logger.log("Capture text action triggered", level: .debug)
        captureService.captureSelectedText()
    }
    
    @objc func openApp() {
        logger.log("Open app action triggered", level: .debug)
        NSApp.activate(ignoringOtherApps: true)
    }

    // Open URL helper method to handle errors and logging
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            logger.log("Failed to create URL from string: \(urlString)", level: .error)
            return
        }
        
        logger.log("Opening URL: \(url.absoluteString)", level: .debug)
        NSWorkspace.shared.open(url)
    }

    @objc func requestChange() {
        logger.log("Request change action triggered", level: .debug)
        openURL(AppConfiguration.URLs.requestChange)
    }

    @objc func writeReview() {
        logger.log("Write review action triggered", level: .debug)
        openURL(AppConfiguration.URLs.writeReview)
    }

    @objc func reportBug() {
        logger.log("Report bug action triggered", level: .debug)
        openURL(AppConfiguration.URLs.reportBug)
    }

    @objc func checkForUpdates() {
        logger.log("Check for updates action triggered", level: .debug)
        openURL(AppConfiguration.URLs.checkForUpdates)
    }

    @objc func launchAtStartup() {
        logger.log("Launch at startup action triggered", level: .debug)
        openURL(AppConfiguration.URLs.launchAtStartup)
    }

    @objc func settings() {
        logger.log("Settings action triggered", level: .debug)
        openURL(AppConfiguration.URLs.settings)
    }

    @objc func version() {
        logger.log("Version action triggered", level: .debug)
        openURL(AppConfiguration.URLs.version)
    }

    @objc func about() {
        logger.log("About action triggered", level: .debug)
        openURL(AppConfiguration.URLs.about)
    }

    @objc func support() {
        logger.log("Support action triggered", level: .debug)
        openURL(AppConfiguration.URLs.support)
    }
}
