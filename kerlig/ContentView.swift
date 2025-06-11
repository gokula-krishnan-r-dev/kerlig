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
    @EnvironmentObject var appState: kerlig.AppState
    @State private var showSettings: Bool = false
    @State private var isFirstLaunch: Bool = false
    @State private var showPermissionsNeeded: Bool = false
    @State private var permissionGranted: Bool = false
    @State private var selectedSidebarItem: SidebarItem = .dashboard
    @State private var showClipboardPermissionAlert = false
    @State private var clipboardPollingTimer: Timer?
    @State private var sidebarWidth: CGFloat = 240
    @State private var showSidebar: Bool = true
    @State private var showClipboardPopup: Bool = false
    @State private var animateLogo = false
    @State private var animateTitle = false
    @State private var animateCard = false
    @State private var animateContent = false
    @State private var animateFeatures = false
    @State private var animatePulse = false
    @State private var isButtonPressed = false

    @StateObject private var textCaptureService = TextCaptureService()
    
    private let hotkeyManager = HotkeyManager()
    private let floatingPanel = FloatingPanelController()
    private let projectsPanel = ProjectsPanelController()
//    private var clipboardShortcutMonitor: ClipboardShortcutMonitor?
    
    // Add ClipboardHistory to the sidebar items
    enum SidebarItem: String, CaseIterable {
        case dashboard = "Dashboard"
        case textCapture = "Text Capture"
        case clipboardHistory = "Clipboard History"
        case history = "History"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .dashboard: return "house"
            case .textCapture: return "text.cursor"
            case .clipboardHistory: return "clipboard"
            case .history: return "clock"
            case .settings: return "gear"
            }
        }
    }
    
    var body: some View {
        VStack {
            // Add a gradient background with animation
            NoteUIView()
        }
        .onAppear {
            // Start animations when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateLogo = true
                animateTitle = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateCard = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateContent = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                animateFeatures = true
            }
            
            // Start pulse animation after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                startPulseAnimation()
            }
            
            // Continue with existing onAppear code
            textCaptureService.startMonitoring()
            print("Last captured text: \(textCaptureService.lastCapturedText)")
            
            // Check for permissions with enhanced methods
            checkPermissionsWithRetry()
            
            // Register hotkey to handle Option+Space
            setupHotkeyManager()
            
            setupClipboardPolling()
            
            // Create menu bar item for clipboard history
            setupClipboardMenuItem()
        }
        .alert(isPresented: $showPermissionsNeeded) {
            Alert(
                title: Text("Accessibility Permission Required"),
                message: Text("Kerlig needs accessibility permissions to capture text selections."),
                primaryButton: .default(Text("Open Settings")) {
                    openAccessibilitySettings()
                },
                secondaryButton: .cancel(Text("Later"))
            )
        }
        .alert(isPresented: $showClipboardPermissionAlert) {
            Alert(
                title: Text("Permission Required"),
                message: Text("To monitor clipboard changes, please allow Kerlig to access your clipboard in System Settings > Privacy & Security > Accessibility."),
                primaryButton: .default(Text("Open Settings")) {
                    openAccessibilityPermissionSettings()
                },
                secondaryButton: .cancel()
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.showClipboardHistoryPopup)) { _ in
            withAnimation(.spring()) {
                self.showClipboardPopup = true
            }
        }
    }
    
    private func setupClipboardMenuItem() {
        // Get the application menu
        guard let mainMenu = NSApplication.shared.mainMenu else { return }
        
        // Create a new menu item
        let clipboardMenuItem = NSMenuItem(title: "Clipboard History", action: #selector(AppDelegate.showClipboardHistory(_:)), keyEquivalent: "c")
        clipboardMenuItem.keyEquivalentModifierMask = [.control]
        
        // Create a menu for File if it doesn't exist
        if mainMenu.items.first(where: { $0.title == "File" }) == nil {
            let fileMenu = NSMenu(title: "File")
            let fileMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
            fileMenuItem.submenu = fileMenu
            mainMenu.insertItem(fileMenuItem, at: 1) // Insert after the application menu
        }
        
        // Get the File menu
        if let fileMenuItem = mainMenu.items.first(where: { $0.title == "File" }),
           let fileMenu = fileMenuItem.submenu {
            // Add the clipboard history item
            fileMenu.insertItem(clipboardMenuItem, at: 0)
            
            // Add a separator
            fileMenu.insertItem(NSMenuItem.separator(), at: 1)
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
    
    private func setupHotkeyManager() {
        // Check for permission to register hotkeys
        if !hotkeyManager.hasAccessibilityPermission() {
            self.showPermissionsNeeded = true
        } else {
            // Register the standard Option+Space hotkey if enabled
            if appState.hotkeyEnabled {
                registerHotkey()
            }
            
            // Register Command+P for projects panel separately
            projectsPanel.registerHotkey(appState: appState)
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
            let source: kerlig.TextSource = text == NSPasteboard.general.string(forType: .string) ? 
                .clipboard : .directSelection
            
            // Update app state with the text and its source
            appState.updateSelectedText(text, source: source)
            
            // Show the floating panel with the selected text
            DispatchQueue.main.async {
                // If permission not granted, show the dialog instead
                if !hotkeyManager.hasAccessibilityPermission() {
                    self.showPermissionsNeeded = true
                } else {
                    floatingPanel.showPanel(with: text, appState: appState)
                }
            }
        } else {
            // Show the empty selection panel
            DispatchQueue.main.async {
                if !hotkeyManager.hasAccessibilityPermission() {
                    self.showPermissionsNeeded = true
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
            let hasPermission = self.hotkeyManager.hasAccessibilityPermission()
            
            // If we don't have permission, we'll prompt once
            if !hasPermission && !self.showClipboardPermissionAlert {
                self.showClipboardPermissionAlert = true
                self.clipboardPollingTimer?.invalidate()
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
    
    // Helper function for pulse animation
    private func startPulseAnimation() {
        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            animatePulse.toggle()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(isHovered ? 0.08 : 0.02))
                .shadow(color: Color.black.opacity(isHovered ? 0.1 : 0.0), radius: 5, x: 0, y: 2)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct KeyCapsuleView: View {
    let text: String
    @State private var isPressed = false
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.blue.opacity(isPressed ? 0.6 : 0.3), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2), value: isPressed)
            .onTapGesture {
                withAnimation {
                    isPressed = true
                    
                    // Reset after short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isPressed = false
                    }
                }
            }
    }
}

//preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
