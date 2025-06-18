import Foundation

// MARK: - Streaming Test Helper

/**
 * Helper utility to test streaming functionality
 */
class StreamingTestHelper {
    
    /// Enable simulation mode for testing
    static func enableSimulationMode() {
        UserDefaults.standard.set(true, forKey: "useSimulationMode")
        print("✅ Simulation mode enabled - will use fake streaming responses")
    }
    
    /// Disable simulation mode to use real API
    static func disableSimulationMode() {
        UserDefaults.standard.set(false, forKey: "useSimulationMode")
        print("✅ Simulation mode disabled - will use real API")
    }
    
    /// Check if simulation mode is currently enabled
    static var isSimulationModeEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "useSimulationMode")
    }
    
    /// Toggle simulation mode
    static func toggleSimulationMode() {
        if isSimulationModeEnabled {
            disableSimulationMode()
        } else {
            enableSimulationMode()
        }
    }
    
    /// Print current mode status
    static func printStatus() {
        let mode = isSimulationModeEnabled ? "SIMULATION" : "REAL API"
        print("🔧 Current streaming mode: \(mode)")
    }
}

// MARK: - Usage Instructions

/**
 # How to Test Streaming
 
 ## Enable Simulation Mode (for testing without API)
 
 In your code or console:
 ```swift
 StreamingTestHelper.enableSimulationMode()
 ```
 
 This will make the app use simulated streaming responses instead of calling the real API.
 
 ## Disable Simulation Mode (use real API)
 
 ```swift
 StreamingTestHelper.disableSimulationMode()
 ```
 
 ## Check Current Mode
 
 ```swift
 StreamingTestHelper.printStatus()
 ```
 
 ## What You'll See in Debug Logs
 
 ### When Simulation Mode is Enabled:
 - `🎯 [UI] Using simulation mode`
 - Fake streaming responses will appear
 - No network calls are made
 
 ### When Using Real API:
 - `🚀 [STREAMING] Starting streaming response generation`
 - Real network requests to your API
 - Server-Sent Events or JSON response processing
 
 ## Debug Log Flow
 
 1. **UI Layer**: `🎯 [UI]` - User interaction and UI updates
 2. **Streaming Service**: `🚀 [STREAMING]` - API request setup
 3. **Network Delegate**: `📦 [DELEGATE]` - Raw data reception
 4. **Line Processing**: `🔍 [LINE]` - Parsing streaming data
 5. **App State**: `📝 [APPSTATE]` - State management and typing effects
 
 This comprehensive logging will help you identify exactly where any issues occur.
 */ 