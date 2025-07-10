import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: kerlig.AppState
    @State private var selectedTab = "General"
    
    var body: some View {
        VStack {
            // Tab selection
            HStack {
                TabButton(title: "General", selectedTab: $selectedTab)
                TabButton(title: "Notifications", selectedTab: $selectedTab)
                TabButton(title: "Actions", selectedTab: $selectedTab)
                TabButton(title: "About", selectedTab: $selectedTab)
            }
            .padding(.horizontal)
            
            Divider()
            
            // Tab content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case "General":
                        GeneralSettingsView()
                    case "Notifications":
                        NotificationSettingsView()
                    case "Actions":
                        ActionSettingsView()
                    case "About":
                        AboutSettingsView()
                    default:
                        GeneralSettingsView()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// Tab button component
struct TabButton: View {
    let title: String
    @Binding var selectedTab: String
    
    var body: some View {
        Button(action: {
            selectedTab = title
        }) {
            Text(title)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    selectedTab == title ?
                    Color.blue.opacity(0.2) :
                    Color.clear
                )
                .cornerRadius(8)
                .foregroundColor(selectedTab == title ? .blue : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// General settings tab
struct GeneralSettingsView: View {
    @EnvironmentObject var appState: kerlig.AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            // Add general settings here
            Toggle("Enable hotkey (Option+Space)", isOn: $appState.hotkeyEnabled)
        }
    }
}

// Notification settings tab
struct NotificationSettingsView: View {
    @EnvironmentObject var appState: kerlig.AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Notification Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            // Task timer notification settings
            GroupBox(label: Text("Task Timer Notifications").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable task timer notifications", isOn: $appState.taskTimerEnabled)
                        .onChange(of: appState.taskTimerEnabled) { _ in
                            appState.saveTaskTimerSettings()
                        }
                    
                    Toggle("Show completion notification", isOn: $appState.showTaskCompletionNotification)
                        .onChange(of: appState.showTaskCompletionNotification) { _ in
                            appState.saveTaskTimerSettings()
                        }
                    
                    HStack {
                        Text("Default task duration:")
                        Slider(value: $appState.defaultTaskDuration, in: 1...60, step: 1) { _ in
                            appState.saveTaskTimerSettings()
                        }
                        Text("\(Int(appState.defaultTaskDuration)) min")
                            .frame(width: 60, alignment: .trailing)
                    }
                    
                    Button("Test Notification") {
                        let message = "Test notification — This is how your task timer notifications will appear."
                        TickSoundService.shared.showNotificationWithMessage(message: message)
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, 8)
            }
            .padding(.bottom, 16)
        }
    }
}

// Action settings tab
struct ActionSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Action Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            // Add action settings here
            TabFeature()
        }
    }
}

// About settings tab
struct AboutSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About Kerlig")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Version: 1.0.0")
                Text("© 2023 Kerlig Team")
                
                Link("Visit Website", destination: URL(string: "https://kerlig.app")!)
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
}
