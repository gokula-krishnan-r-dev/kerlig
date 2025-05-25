import Foundation
import os.log

/// Application logger for consistent and efficient logging
class AppLogger {
    /// Log categories
    enum Category: String {
        case ui = "UI"
        case network = "Network"
        case data = "Data"
        case general = "General"
        case statusBar = "StatusBar"
        case textCapture = "TextCapture"
        case aiService = "AIService"
        
        /// Convert to OSLog subsystem
        var osLogCategory: String {
            return "com.kerlig.app.\(self.rawValue.lowercased())"
        }
    }
    
    /// Log levels
    enum Level {
        case debug
        case info
        case warning
        case error
        case critical
        
        /// Convert to OSLog type
        var osLogType: OSLogType {
            switch self {
            case .debug:
                return .debug
            case .info:
                return .info
            case .warning:
                return .default
            case .error:
                return .error
            case .critical:
                return .fault
            }
        }
    }
    
    /// The category for this logger instance
    private let category: Category
    
    /// The underlying OS log
    private let log: OSLog
    
    /// Create a new logger for a specific category
    /// - Parameter category: The category for this logger
    init(category: Category) {
        self.category = category
        self.log = OSLog(subsystem: category.osLogCategory, category: category.rawValue)
    }
    
    /// Log a message with the specified level
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The severity level
    ///   - file: The file where the log was called (automatically filled)
    ///   - function: The function where the log was called (automatically filled)
    ///   - line: The line where the log was called (automatically filled)
    func log(
        _ message: String,
        level: Level = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        os_log("%{public}@", log: log, type: level.osLogType, logMessage)
        
        // In debug builds, also print to console for easier debugging
        #if DEBUG
        let levelString: String
        switch level {
        case .debug:
            levelString = "DEBUG"
        case .info:
            levelString = "INFO"
        case .warning:
            levelString = "WARNING"
        case .error:
            levelString = "ERROR"
        case .critical:
            levelString = "CRITICAL"
        }
        
        print("[\(levelString)] \(category.rawValue) - \(logMessage)")
        #endif
    }
}

/// Global loggers for convenience
extension AppLogger {
    /// UI logger
    static let ui = AppLogger(category: .ui)
    
    /// Network logger
    static let network = AppLogger(category: .network)
    
    /// Data logger
    static let data = AppLogger(category: .data)
    
    /// General logger
    static let general = AppLogger(category: .general)
    
    /// Status Bar logger
    static let statusBar = AppLogger(category: .statusBar)
    
    /// Text Capture logger
    static let textCapture = AppLogger(category: .textCapture)
    
    /// AI Service logger
    static let aiService = AppLogger(category: .aiService)
} 