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
    
    // Handle background mode initialization dynamically
    handleBackgroundModeInitialization()
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
  
  // MARK: - Background Mode Management
  
  /// Handles background mode initialization dynamically based on app state conditions
  private func handleBackgroundModeInitialization() {
    NSLog("🔄 [APP] Evaluating background mode initialization...")
    NSLog("🔄 [APP] State - isFirstLaunch: \(appState.isFirstLaunch), onboardingComplete: \(appState.onboardingComplete), runInBackground: \(appState.runInBackground)")
    
    // Determine the appropriate mode based on current state
    let shouldEnterBackgroundMode = determineShouldEnterBackgroundMode()
    
    if shouldEnterBackgroundMode {
      // Schedule background mode entry with appropriate delay
      let delay = appState.isFirstLaunch ? 2.0 : 1.0 // Longer delay for first launch
      
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        NSLog("🔄 [APP] Entering background mode...")
        self.backgroundAppManager.enterBackgroundMode()
        
        // Mark first launch as completed if this was the first launch
        if self.appState.isFirstLaunch && self.appState.onboardingComplete {
          NSLog("🔄 [APP] Completing first launch sequence...")
          self.appState.completeFirstLaunch()
        }
      }
    } else {
      NSLog("🔄 [APP] Staying in regular mode - conditions not met for background mode")
      
      // Ensure we're in regular mode
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.backgroundAppManager.exitBackgroundMode()
      }
    }
  }
  
  /// Determines whether the app should enter background mode based on current conditions
  private func determineShouldEnterBackgroundMode() -> Bool {
    // Use the centralized logic from AppState
    let shouldEnterBG = appState.shouldRunInBackgroundMode()
    
    // Additional logic for first launch scenario
    if appState.isFirstLaunch {
      NSLog("🔄 [APP] First launch scenario - should enter background: \(shouldEnterBG)")
      return shouldEnterBG
    }
    
    // For subsequent launches, use the standard check
    NSLog("🔄 [APP] Regular launch scenario - should enter background: \(shouldEnterBG)")
    return shouldEnterBG
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
