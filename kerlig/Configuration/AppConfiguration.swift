import Foundation

/// Application configuration and constants
struct AppConfiguration {
    
    /// Application URLs
    struct URLs {
        /// Base URL for the application website
        static let baseURL = "https://kerlig.app"
        
        /// Support and help URLs
        static let requestChange = "\(baseURL)/request-change"
        static let writeReview = "\(baseURL)/write-review"
        static let reportBug = "\(baseURL)/report-bug"
        static let checkForUpdates = "\(baseURL)/check-for-updates"
        static let version = "\(baseURL)/version"
        static let settings = "\(baseURL)/settings"
        static let launchAtStartup = "\(baseURL)/launch-at-startup"
        static let about = "\(baseURL)/about"
        static let support = "\(baseURL)/support"
        static let documentation = "\(baseURL)/docs"
        static let privacyPolicy = "\(baseURL)/privacy"
        static let termsOfService = "\(baseURL)/terms"
    }
    
    /// Application default settings
    struct Defaults {
        /// Default AI model
        static let aiModel = "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
        
        /// Default theme
        static let theme = "light"
        
        /// Default hotkey enabled status
        static let hotkeyEnabled = true
    }
    
    /// Application feature flags
    struct FeatureFlags {
        /// Whether the app should show experimental features
        static let showExperimentalFeatures = false
        
        /// Whether analytics are enabled
        static let analyticsEnabled = true
    }
    
    /// Application version information
    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// Application build information
    static var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// Full version string including build number
    static var fullVersionString: String {
        return "Version \(appVersion) (\(buildNumber))"
    }
} 