//
//  kerligApp.swift
//  kerlig
//
//  Created by gokul on 12/05/25.
//

import SwiftUI

@main
struct kerligApp: App {
  @State private var popover = NSPopover()
  @StateObject private var appState = AppState()
  @State private var floatingPanel: FloatingPanelController?
  @State private var statusBarController: StatusBarController?
  
  // Add global hotkey manager
  @State private var globalHotkeyManager: HotkeyManager?

  @StateObject private var textCaptureService = TextCaptureService()
  @StateObject private var customActionsStorage = CustomActionsStorage()

  var body: some Scene {
    WindowGroup {
      ZStack {
        // Show main content if not first launch and onboarding complete
        if !appState.isFirstLaunch && appState.onboardingComplete {
          ContentView()
            .environmentObject(appState)
            .environmentObject(customActionsStorage)
            .frame(minWidth: 800)
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
              
              // Initialize global hotkeys when the main view appears
              initializeGlobalHotkeys()
            }
        } else if appState.isFirstLaunch {
          // Show welcome screen on first launch
          WelcomeView()
            .environmentObject(appState)
            .environmentObject(customActionsStorage)
            .frame(minWidth: 800, minHeight: 600)
            .onAppear {
              // Initialize global hotkeys even during first launch
              if globalHotkeyManager == nil {
                initializeGlobalHotkeys()
              }
            }
        } else {
          // Show onboarding screens after welcome but before main app
          OnboardingView()
            .environmentObject(appState)
            .environmentObject(customActionsStorage)
            .frame(minWidth: 800, minHeight: 600)
            .onAppear {
              // Initialize global hotkeys even during onboarding
              if globalHotkeyManager == nil {
                initializeGlobalHotkeys()
              }
            }
        }
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

        Divider()

        Button("Show Port Monitor") {
          showPortMonitorWindow()
        }
        .keyboardShortcut("p", modifiers: [.option, .command])
        
        Button("Screenshot Analysis") {
          ScreenshotPanelController.shared.togglePanel()
        }
        .keyboardShortcut("k", modifiers: [.option, .command])
      }
    }
  }
  
  // MARK: - Global Hotkey Initialization
  
  private func initializeGlobalHotkeys() {
    // Prevent multiple initializations
    guard globalHotkeyManager == nil else {
      print("🔄 Global hotkey manager already initialized")
      return
    }
    
    // Create the global hotkey manager
    globalHotkeyManager = HotkeyManager()
    
    // Register text capture hotkey (Option + Space)
    _ = globalHotkeyManager?.registerHotkey { selectedText in
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
    
    // Register screenshot hotkey (Command + ~) - this is the key change
    let screenshotRegistered = globalHotkeyManager?.registerScreenshotHotkey()
    
    if screenshotRegistered == true {
      print("✅ Global screenshot hotkey (Command + ~) registered successfully")
    } else {
      print("❌ Failed to register global screenshot hotkey")
    }
    
    // Ensure the hotkey manager stays alive for the lifetime of the app
    print("🌐 Global hotkey manager initialized - hotkeys will work system-wide")
  }

  private func setupPopover() {
    // Configure the popover
    popover.behavior = .transient
    popover.animates = true

    // Set ContentView as the popover's contentViewController
    let contentView = ContentView()
      .environmentObject(appState)
      .environmentObject(customActionsStorage)
    popover.contentViewController = NSHostingController(rootView: contentView)

  }

  private func setupFloatingPanel() {
    // Initialize floating panel controller
    floatingPanel = FloatingPanelController()

    // Initialize global hotkeys here as well to ensure they work 
    // even if the main window never appears (e.g., menu bar app mode)
    if globalHotkeyManager == nil {
      initializeGlobalHotkeys()
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

  // Function to show the port monitor window
  private func showPortMonitorWindow() {
    PortMonitorWindow.open()
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
