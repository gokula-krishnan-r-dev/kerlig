//
//  kerligApp.swift
//  kerlig
//
//  Created by gokul on 12/05/25.
//

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




@main
struct kerligApp: App {
   @State private var statusBar: StatusBarController?
    @State private var popover = NSPopover()
     @StateObject private var appState = AppState()
    @State private var floatingPanel: FloatingPanelController?
      // Status bar controller as a state object
    @State private var statusBarController: StatusBarController?

    @StateObject private var textCaptureService = TextCaptureService()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                     if statusBarController == nil {
                        statusBarController = StatusBarController(captureService: textCaptureService)
                    }

                    textCaptureService.startMonitoring()
    
                    // Request permissions on first launch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let hotkeyManager = HotkeyManager()
                        hotkeyManager.showAccessibilityPermissionsDialog()
                    }
                    
                    // Set up popover
                    setupPopover()
                    
                    // Set up floating panel
                    setupFloatingPanel()
                    
                    // Register for panel close notifications
                    registerForPanelCloseNotifications()
            
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
             // Add keyboard commands for common actions
            CommandGroup(after: .appInfo) {
                Button("Capture Text") {
                    textCaptureService.captureSelectedText()
                }
                .keyboardShortcut("c", modifiers: [.option, .command])
            }

            
        }
        
    }
    
    private func setupPopover() {
        // Configure the popover
        popover.behavior = .transient
        popover.animates = true
         
        // Set ContentView as the popover's contentViewController
        let contentView = ContentView()
            .environmentObject(appState)
        popover.contentViewController = NSHostingController(rootView: contentView)
        
    }
    
    private func setupFloatingPanel() {
        // Initialize floating panel controller
        floatingPanel = FloatingPanelController()
        
        // Register hotkey to capture selected text and show the panel
        let hotkeyManager = HotkeyManager()
        _ = hotkeyManager.registerHotkey { selectedText in
            DispatchQueue.main.async {
                // Hide main window if it's open
                for window in NSApp.windows {
                    if window.title != "Settings" && window.title != "AI Assistant" {
                        window.orderOut(nil)
                    }
                }
                
                // Show floating panel with selected text
                if !selectedText.isEmpty {
                    self.floatingPanel?.showPanel(with: selectedText, appState: self.appState)
                } else {
                    self.floatingPanel?.showEmptySelectionPanel(appState: self.appState)
                }
            }
        }
    }
    
    private func registerForPanelCloseNotifications() {
        // Listen for panel close notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ClosePanelNotification"),
            object: nil,
            queue: .main
        ) { _ in
            // Update app state when panel is closed
            appState.isAIPanelVisible = false
            appState.emptySelectionMode = false
        }
    }
}



// Add the showSettingsWindow selector to NSApplication
extension NSApplication {
    @objc func showSettingsWindow(_ sender: Any?) {
        for window in windows {
            if window.title == "Settings" || window.frameAutosaveName == "Settings" {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
    }
}