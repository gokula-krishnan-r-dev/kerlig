//
//  ContentView.swift
//  Streamline
//
//  Created by gokul on 17/04/25.
//

import SwiftUI
import AppKit
import Combine
import OSLog


struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings: Bool = false
    @State private var isFirstLaunch: Bool = false
    @State private var showPermissionsNeeded: Bool = false
    @State private var permissionGranted: Bool = false
    @State private var selectedSidebarItem: SidebarItem? = .dashboard
    @State private var showClipboardPermissionAlert = false
    @State private var clipboardPollingTimer: Timer?

    @StateObject private var textCaptureService = TextCaptureService()
    
    private let hotkeyManager = HotkeyManager()
    private let floatingPanel = FloatingPanelController()
    
    // Add TextCapture to the sidebar items
    enum SidebarItem: String, CaseIterable {
        case dashboard = "Dashboard"
        case textCapture = "Text Capture"
        case history = "History"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .dashboard: return "house"
            case .textCapture: return "text.cursor"
            case .history: return "clock"
            case .settings: return "gear"
            }
        }
    }
    
    var body: some View {
        HStack {
            Text("SonicMemory")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.accentColor)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .onAppear {
            textCaptureService.startMonitoring()
            print("Last captured text: \(textCaptureService.lastCapturedText)")
            
            // Check for permissions with enhanced methods
            checkPermissionsWithRetry()
            
            // Register hotkey to handle Option+Space
            registerHotkey()
            
            setupClipboardPolling()
        }
        .alert(isPresented: $showPermissionsNeeded) {
            Alert(
                title: Text("Accessibility Permission Required"),
                message: Text("Streamline needs accessibility permissions to capture text selections."),
                primaryButton: .default(Text("Open Settings")) {
                    openAccessibilitySettings()
                },
                secondaryButton: .cancel(Text("Later"))
            )
        }
        .alert(isPresented: $showClipboardPermissionAlert) {
            Alert(
                title: Text("Permission Required"),
                message: Text("To monitor clipboard changes, please allow Streamline to access your clipboard in System Settings > Privacy & Security > Accessibility."),
                primaryButton: .default(Text("Open Settings")) {
                    openAccessibilityPermissionSettings()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func checkPermissionsWithRetry() {
        // First try a basic check
        if hotkeyManager.hasAccessibilityPermission() {
            permissionGranted = true
            return
        }
        
        // Check if permissions may have been granted but cache not updated
        if hotkeyManager.examineProcessPrivileges() {
            permissionGranted = true
            return
        }
        
        // Advanced verification method with multiple retries
        hotkeyManager.verifyAccessibilityPermissions { granted in
            DispatchQueue.main.async {
                self.permissionGranted = granted
                
                // If permissions were detected on delayed verification,
                // the UI will automatically update due to state change
                if granted {
                    print("Accessibility permissions verified after advanced checks")
                } else {
                    // If still not granted after advanced checks, attempt one final restart of relevant services
                    self.performFinalPermissionRefresh()
                }
            }
        }
    }
    
    // Final attempt at refreshing permissions by restarting accessibility services
    private func performFinalPermissionRefresh() {
        // Create a task to restart accessibility services
        let task = Process()
        task.launchPath = "/usr/bin/killall"
        task.arguments = ["SystemUIServer"]
        
        do {
            try task.run()
            
            // Wait a bit for the service to restart
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Check permissions again after restart
                if self.hotkeyManager.hasAccessibilityPermission() || 
                   self.hotkeyManager.examineProcessPrivileges() {
                    self.permissionGranted = true
                }
            }
        } catch {
            print("Failed to restart accessibility services: \(error)")
        }
    }
    
    private func openAccessibilitySettings() {
        if #available(macOS 13.0, *) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        } else {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
        }
    }
    
    private func registerHotkey() {
        if appState.hotkeyEnabled {
            let success = hotkeyManager.registerHotkey { selectedText in
                handleSelectedText(selectedText)
            }
            
            if !success {
                // Alert the user if hotkey registration failed
                let alert = NSAlert()
                alert.messageText = "Hotkey Registration Failed"
                alert.informativeText = "Could not register Option+Space shortcut. Please check if another application is using this key combination."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
    
    // Handle the text when the hotkey is pressed
    private func handleSelectedText(_ text: String) {
        if !text.isEmpty {
            // Determine the source based on context clues
            let source: TextSource = text == NSPasteboard.general.string(forType: .string) ? 
                .clipboard : .directSelection
            
            // Update app state with the text and its source
            appState.updateSelectedText(text, source: source)
            
            // Show the floating panel with the selected text
            DispatchQueue.main.async {
                // If permission not granted, show the dialog instead
                if !hotkeyManager.hasAccessibilityPermission() {
                    showPermissionsNeeded = true
                } else {
                    floatingPanel.showPanel(with: text, appState: appState)
                }
            }
        } else {
            // Show the empty selection panel
            DispatchQueue.main.async {
                if !hotkeyManager.hasAccessibilityPermission() {
                    showPermissionsNeeded = true
                } else {
                    floatingPanel.showEmptySelectionPanel(appState: appState)
                }
            }
        }
    }
    
    private func refreshPermissions() {
        // Display temporary feedback
        let alert = NSAlert()
        alert.messageText = "Checking Permissions..."
        alert.informativeText = "If you've already enabled permissions, we'll verify the system status."
        alert.alertStyle = .informational
        
        // Show alert without blocking
        let alertWindow = alert.window
        alert.beginSheetModal(for: alertWindow) { _ in }
        
        // Check on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Try the enhanced permission checking process
            let hasAccessPermission = self.hotkeyManager.refreshAndCheckPermissions()
            let hasAutomationPermission = self.hotkeyManager.hasAutomationPermission()
            let hasAllPermissions = hasAccessPermission && hasAutomationPermission
            
            // If that fails, try advanced verification
            if !hasAllPermissions {
                // Try manual permission fixing
                self.hotkeyManager.showAllPermissionsDialog()
                
                // Dismiss any shown alert
                DispatchQueue.main.async {
                    alertWindow.sheetParent?.endSheet(alertWindow)
                }
            } else {
                DispatchQueue.main.async {
                    // Dismiss any shown alert
                    alertWindow.sheetParent?.endSheet(alertWindow)
                    
                    // Success from the first attempt
                    let successAlert = NSAlert()
                    successAlert.messageText = "Permissions Verified"
                    successAlert.informativeText = "All required permissions are now confirmed. You're all set!"
                    successAlert.alertStyle = .informational
                    successAlert.runModal()
                    
                    // Update state to trigger UI refresh
                    self.permissionGranted = true
                }
            }
        }
    }
    
    
    
    private func setupClipboardPolling() {
        // Initialize timer to check clipboard periodically
        clipboardPollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Get permission status
            let hasPermission = hotkeyManager.hasAccessibilityPermission()
            
            // If we don't have permission, we'll prompt once
            if !hasPermission && !showClipboardPermissionAlert {
                showClipboardPermissionAlert = true
                clipboardPollingTimer?.invalidate()
            }
        }
    }
    
    private func openAccessibilityPermissionSettings() {
        if #available(macOS 13.0, *) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        } else {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
        }
    }
    
}

