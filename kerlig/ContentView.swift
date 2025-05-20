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

// Import the models explicitly to resolve ambiguity
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

    @StateObject private var textCaptureService = TextCaptureService()
    
    private let hotkeyManager = HotkeyManager()
    private let floatingPanel = FloatingPanelController()
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
        ZStack {
            NavigationView {
                // Sidebar
                VStack(spacing: 0) {
                    // App Logo
                    HStack {
                        AppIconImage()
                            .frame(width: 32, height: 32)
                            .padding(.trailing, 8)
                        
                        Text("Kerlig")
                            .font(.headline)
                            .foregroundColor(Color(hex: "333333"))
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                showSidebar.toggle()
                            }
                        }) {
                            Image(systemName: "sidebar.left")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "666666"))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    
                    Divider()
                    
                    // Sidebar items
                    List {
                        ForEach(SidebarItem.allCases, id: \.self) { item in
                            SidebarItemView(
                                item: item,
                                isSelected: selectedSidebarItem == item,
                                onSelect: {
                                    withAnimation {
                                        selectedSidebarItem = item
                                    }
                                }
                            )
                        }
                        
                        Spacer()
                    }
                    .listStyle(SidebarListStyle())
                    .frame(width: sidebarWidth)
                }
                
                // Main Content
                ZStack {
                    switch selectedSidebarItem {
                    case .dashboard:
                        DashboardView()
                            .environmentObject(appState)
                    case .textCapture:
                        TextCaptureCOPYView()
                            .environmentObject(appState)
//                    case .clipboardHistory:
//                        ClipboardHistoryView()
//                            .environmentObject(appState)
                    case .history:
                        HistoryView()
                            .environmentObject(appState)
                    case .settings:
                        SettingsView()
                            .environmentObject(appState)
                    case .clipboardHistory:
                        Text("demo")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        withAnimation {
                            showSidebar.toggle()
                        }
                    }) {
                        Image(systemName: "sidebar.left")
                    }
                }
            }
            
            // Clipboard History Popup
            if showClipboardPopup {
                ZStack {
                    // Background overlay
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                showClipboardPopup = false
                            }
                        }
                    
//                    // Popup content
//                    ClipboardHistoryPopup(isVisible: $showClipboardPopup, onDismiss: {
//                        showClipboardPopup = false
//                    })
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
//                    .transition(.opacity.combined(with: .scale))
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            textCaptureService.startMonitoring()
            print("Last captured text: \(textCaptureService.lastCapturedText)")
            
            // Check for permissions with enhanced methods
            checkPermissionsWithRetry()
            
            // Register hotkey to handle Option+Space
            registerHotkey()
            
            setupClipboardPolling()
            
//            // Setup clipboard shortcut monitor
//            clipboardShortcutMonitor = ClipboardShortcutMonitor(showPopupAction: {
//                DispatchQueue.main.async {
//                    withAnimation(.spring()) {
//                        self.showClipboardPopup = true
//                    }
//                }
//            })
//            
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
}

// Sidebar Item View
struct SidebarItemView: View {
    let item: ContentView.SidebarItem
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 18))
                .foregroundColor(isSelected ? Color(hex: "845CEF") : Color(hex: "666666"))
            
            Text(item.rawValue)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Color(hex: "333333") : Color(hex: "666666"))
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color(hex: "845CEF").opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

// Dashboard View (placeholder)
struct DashboardView: View {
    @EnvironmentObject var appState: kerlig.AppState
    
    var body: some View {
        VStack {
            Text("Dashboard")
                .font(.largeTitle)
                .padding()
            
            Text("Welcome to Kerlig")
                .font(.title2)
            
            Spacer()
        }
    }
}

// Text Capture View (placeholder)
struct TextCaptureCOPYView: View {
    @EnvironmentObject var appState: kerlig.AppState
    @State private var selectedText: String = ""
    @State private var isProcessing: Bool = false
    @State private var animateCapture: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Text("Text Capture")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.top, 20)
                
                Text("Capture and process text from anywhere on your screen")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "666666"))
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            
            Divider()
            
            // Capture Area
            VStack(spacing: 25) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color(hex: "845CEF").opacity(0.3), radius: 10, x: 0, y: 5)
                        .scaleEffect(animateCapture ? 1.1 : 1.0)
                    
                    Image(systemName: "text.cursor")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                .padding(.top, 30)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        animateCapture = true
                    }
                }
                
                // Instructions
                VStack(spacing: 15) {
                    Text("How to capture text:")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "333333"))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InstructionRow(
                            number: "1",
                            text: "Select text in any application",
                            icon: "hand.tap"
                        )
                        
                        InstructionRow(
                            number: "2",
                            text: "Press Command+Space to activate Kerlig",
                            icon: "command"
                        )
                        
                        InstructionRow(
                            number: "3",
                            text: "The selected text will appear in a floating panel",
                            icon: "rectangle.on.rectangle"
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxWidth: 500)
                .padding(.vertical, 30)
                .background(Color(hex: "f5f7fa"))
                .cornerRadius(16)
                
                // Recent captures
                VStack(alignment: .leading, spacing: 15) {
                    Text("Recent Captures")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "333333"))
                        .padding(.horizontal, 20)
                    
                    
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Instruction Row
struct InstructionRow: View {
    let number: String
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color(hex: "845CEF").opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Text(number)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "845CEF"))
            }
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "333333"))
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "845CEF"))
        }
        .padding(.vertical, 8)
    }
}

// // Capture Item Row
// struct CaptureItemRow: View {
//     let capture: TextCapture
//     @State private var isHovering: Bool = false
    
//     var body: some View {
//         VStack(alignment: .leading, spacing: 8) {
//             // Header with timestamp
//             HStack {
//                 Text(capture.timestamp, style: .time)
//                     .font(.system(size: 12))
//                     .foregroundColor(Color(hex: "999999"))
                
//                 Spacer()
                
//                 Text(capture.source.rawValue)
//                     .font(.system(size: 12))
//                     .foregroundColor(Color(hex: "999999"))
//                     .padding(.horizontal, 8)
//                     .padding(.vertical, 3)
//                     .background(Color(hex: "f0f0f0"))
//                     .cornerRadius(4)
//             }
            
//             Divider()
            
//             // Content
//             Text(capture.text)
//                 .font(.system(size: 14))
//                 .foregroundColor(Color(hex: "333333"))
//                 .lineLimit(3)
//                 .padding(.vertical, 5)
//         }
//         .padding(12)
//         .background(Color.white)
//         .cornerRadius(8)
//         .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
//         .overlay(
//             RoundedRectangle(cornerRadius: 8)
//                 .stroke(isHovering ? Color(hex: "845CEF").opacity(0.3) : Color.clear, lineWidth: 1)
//         )
//         .onHover { hovering in
//             withAnimation(.easeInOut(duration: 0.2)) {
//                 isHovering = hovering
//             }
//         }
//     }
// }

// History View (placeholder)
struct HistoryView: View {
    @EnvironmentObject var appState: kerlig.AppState
    
    var body: some View {
        VStack {
            Text("History")
                .font(.largeTitle)
                .padding()
            
            Text("View your past interactions")
                .font(.title2)
            
            Spacer()
        }
    }
}
