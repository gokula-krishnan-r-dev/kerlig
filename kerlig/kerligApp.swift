//
//  kerligApp.swift
//  kerlig
//
//  Created by gokul on 12/05/25.
//

import SwiftUI

@main
struct kerligApp: App {
  @StateObject private var appState = AppState()
  @StateObject private var textCaptureService = TextCaptureService()
  @StateObject private var customActionsStorage = CustomActionsStorage()
  
  @State private var floatingPanel: FloatingPanelController?
  @State private var backgroundAppManager = BackgroundAppManager.shared
  @State private var hasConfiguredBackgroundMode = false

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
              setupBackgroundMode()
            }
        } else if appState.isFirstLaunch {
          // Show welcome screen on first launch
          WelcomeView()
            .environmentObject(appState)
            .environmentObject(customActionsStorage)
            .frame(minWidth: 800, minHeight: 600)
            .onAppear {
              setupBackgroundMode()
            }
        } else {
          // Show onboarding screens after welcome but before main app
          OnboardingView()
            .environmentObject(appState)
            .environmentObject(customActionsStorage)
            .frame(minWidth: 800, minHeight: 600)
            .onAppear {
              setupBackgroundMode()
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
          let selectedText = textCaptureService.getTextFromSelection()
          if !selectedText.isEmpty {
            floatingPanel?.showPanel(with: selectedText, appState: appState)
          } else {
            floatingPanel?.showEmptySelectionPanel(appState: appState)
          }
        }
        .keyboardShortcut("c", modifiers: [.option, .command])

        Divider()

        Button("Show Port Monitor") {
          showPortMonitorWindow()
        }
        .keyboardShortcut("p", modifiers: [.option, .command])
        
        Button("Show Main Window") {
          backgroundAppManager.showMainWindow()
        }
        .keyboardShortcut("m", modifiers: [.option, .command])
      }
    }
  }

  private func setupBackgroundMode() {
    // Only configure once
    guard !hasConfiguredBackgroundMode else { return }
    hasConfiguredBackgroundMode = true
    
    // Initialize floating panel controller
    floatingPanel = FloatingPanelController()
    
    // Configure the background app manager
    guard let floatingPanelController = floatingPanel else {
      NSLog("❌ Error: FloatingPanelController is nil")
      return
    }
    
    backgroundAppManager.configure(
      appState: appState,
      customActionsStorage: customActionsStorage,
      floatingPanelController: floatingPanelController,
      textCaptureService: textCaptureService
    )
    
    // Request permissions on first setup
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      let hotkeyManager = HotkeyManager()
      hotkeyManager.showAccessibilityPermissionsDialog()
    }
    
    // Register for panel close notifications
    registerForPanelCloseNotifications()
    
    // Check if we should start in background mode
    if appState.runInBackground && appState.onboardingComplete {
      // Start in background mode after a short delay
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        self.backgroundAppManager.enterBackgroundMode()
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
      self.appState.isAIPanelVisible = false
      self.appState.emptySelectionMode = false
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
