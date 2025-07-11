import Foundation
import ServiceManagement

class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()
    
    private let launcherBundleId = "com.kerlig.LaunchAtLoginHelper"
    
    private init() {}
    
    var isEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "LaunchAtLogin")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "LaunchAtLogin")
            setLaunchAtLogin(enabled: newValue)
        }
    }
    
    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            // Use the new SMAppService API for macOS 13+
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    NSLog("✅ Launch at login enabled")
                } else {
                    try SMAppService.mainApp.unregister()
                    NSLog("❌ Launch at login disabled")
                }
            } catch {
                NSLog("❌ Failed to set launch at login: \(error)")
            }
        } else {
            // Use the legacy SMLoginItemSetEnabled for older macOS versions
            let success = SMLoginItemSetEnabled(launcherBundleId as CFString, enabled)
            if success {
                NSLog("✅ Launch at login \(enabled ? "enabled" : "disabled")")
            } else {
                NSLog("❌ Failed to set launch at login")
            }
        }
    }
    
    func checkStatus() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // For older versions, we rely on UserDefaults
            return isEnabled
        }
    }
} 