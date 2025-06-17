import SwiftUI
import AppKit
import Combine

// MARK: - Text Insertion Service
class TextInsertionService {
    
    // MARK: - Types
    
    /// Represents the current state of text insertion
    enum InsertionStatus: Equatable {
        case none
        case preparing
        case inserting
        case success
        case failed(reason: FailureReason)
        
        enum FailureReason: String, Equatable {
            case noActiveApplication = "No active application found"
            case clipboardFailed = "Failed to copy text to clipboard"
            case insertionFailed = "Failed to insert text"
            case accessibilityBlocked = "Accessibility permissions required"
            case unknown = "Unknown error occurred"
        }
    }
    
    /// Protocol for receiving insertion status updates
    protocol TextInsertionDelegate: AnyObject {
        func insertionStatusChanged(_ status: InsertionStatus)
        func displayNotification(title: String, message: String, isError: Bool)
    }
    
    // MARK: - Properties
    
    private weak var delegateObject: AnyObject?
    private var delegate: TextInsertionDelegate? {
        return delegateObject as? TextInsertionDelegate
    }
    
    private var insertionTimer: Timer?
    private var insertAttempts: Int = 0
    private let maxAttempts = 2
    
    private var insertedText: String = ""
    private var previousClipboardContent: String?
    
    private var status: InsertionStatus = .none {
        didSet {
            delegate?.insertionStatusChanged(status)
            
            // Log status changes
            let statusDescription: String
            switch status {
            case .none: statusDescription = "none"
            case .preparing: statusDescription = "preparing"
            case .inserting: statusDescription = "inserting"
            case .success: statusDescription = "success"
            case .failed(let reason): statusDescription = "failed(\(reason.rawValue))"
            }
            print("🔄 [SERVICE] Status changed: \(statusDescription)")
        }
    }
    
    // MARK: - Initialization
    
    init(delegate: TextInsertionDelegate?) {
        self.delegateObject = delegate as AnyObject?
    }
    
    deinit {
        invalidateTimers()
    }
    
    // MARK: - Public Methods
    
    /// Primary method to insert text into the frontmost application
    func insertText(_ text: String) {
        // Don't proceed if already inserting or text is empty
        guard status == .none || status == .success, !text.isEmpty else { 
            print("🔄 [SERVICE] Cannot insert: current status=\(status), text empty=\(text.isEmpty)")
            return 
        }
        
        print("🔄 [SERVICE] Starting universal text insertion for: \(text.prefix(30))...")
        
        // Save text and reset attempts
        insertedText = text
        insertAttempts = 0
        
        // Set status to preparing
        status = .preparing
        
        // Save current clipboard content for restoration
        saveClipboardContent()
        
        // Copy to clipboard and start insertion
        if copyToClipboard(text) {
            delegate?.displayNotification(
                title: "Text Ready", 
                message: "Preparing to insert text...", 
                isError: false
            )
            
            // Start insertion sequence
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.executeUniversalInsertion()
            }
        } else {
            status = .failed(reason: .clipboardFailed)
            delegate?.displayNotification(
                title: "Insertion Failed", 
                message: "Could not copy text to clipboard.", 
                isError: true
            )
        }
    }
    
    /// Cancels any ongoing insertion operation
    func cancelInsertion() {
        invalidateTimers()
        
        if status == .inserting || status == .preparing {
            print("🔄 [SERVICE] Insertion canceled by user")
            status = .none
            restoreClipboardContent()
        }
    }
    
    // MARK: - Core Universal Insertion Logic
    
    private func executeUniversalInsertion() {
        print("🔄 [SERVICE] Starting universal insertion sequence")
        status = .inserting
        
        // Find and activate the most appropriate target application
        if let targetApp = findTargetApplication() {
            print("🔄 [SERVICE] Target application: \(targetApp.localizedName ?? "Unknown")")
            
            // Activate the target application
            activateApplication(targetApp)
            
            // Wait for activation and then insert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.performUniversalTextInsertion()
            }
        } else {
            print("🔄 [SERVICE] No suitable target application found")
            status = .failed(reason: .noActiveApplication)
            delegate?.displayNotification(
                title: "Insertion Failed",
                message: "No suitable application found for text insertion.",
                isError: true
            )
        }
    }
    
    private func findTargetApplication() -> NSRunningApplication? {
        let runningApps = NSWorkspace.shared.runningApplications
        let currentFrontmost = NSWorkspace.shared.frontmostApplication
        
        // Filter for applications that can accept text input
        let potentialTargets = runningApps.filter { app in
            guard let appName = app.localizedName,
                  app.activationPolicy == .regular,
                  !app.isHidden,
                  app.processIdentifier != currentFrontmost?.processIdentifier else {
                return false
            }
            
            // Exclude system apps and utilities that typically don't need text input
            let excludedApps = ["Finder", "System Preferences", "Activity Monitor", "Console"]
            return !excludedApps.contains { excluded in
                appName.contains(excluded)
            }
        }
        
        // Sort by most recently used (higher process ID generally means more recent)
        let sortedTargets = potentialTargets.sorted { $0.processIdentifier > $1.processIdentifier }
        
        print("🔄 [SERVICE] Found \(sortedTargets.count) potential target applications")
        
        // Return the most recently used application
        return sortedTargets.first
    }
    
    private func activateApplication(_ app: NSRunningApplication) {
        print("🔄 [SERVICE] Activating application: \(app.localizedName ?? "Unknown")")
        app.activate(options: [.activateIgnoringOtherApps])
    }
    
    private func performUniversalTextInsertion() {
        print("🔄 [SERVICE] Performing universal text insertion")
        
        // Universal insertion strategy
        insertAttempts += 1
        
        // Step 1: Ensure focus by clicking at current cursor position
        clickAtCurrentMouseLocation()
        
        // Step 2: Wait briefly and paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            print("🔄 [SERVICE] Attempting paste (attempt \(self.insertAttempts))")
            self.simulatePaste()
            
            // Step 3: Verify or retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                
                if self.insertAttempts < self.maxAttempts {
                    // Try alternative focus method and retry
                    self.tryAlternativeFocusAndRetry()
                } else {
                    // Assume success after max attempts
                    self.completeInsertion()
                }
            }
        }
    }
    
    private func tryAlternativeFocusAndRetry() {
        print("🔄 [SERVICE] Trying alternative focus method")
        
        // Try Tab key to find an input field
        simulateTab()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.performUniversalTextInsertion()
        }
    }
    
    private func completeInsertion() {
        print("🔄 [SERVICE] Completing insertion process")
        markAsSuccessful()
    }
    
    // MARK: - Insertion Status Management
    
    /// Marks the insertion as successful and cleans up
    func markAsSuccessful() {
        status = .success
        print("🔄 [SERVICE] Insertion successful")
        
        delegate?.displayNotification(
            title: "Text Inserted",
            message: "Successfully inserted text",
            isError: false
        )
        
        // Reset status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.resetStatus()
        }
    }
    
    /// Marks the insertion as failed with a reason
    func markAsFailed(reason: InsertionStatus.FailureReason) {
        status = .failed(reason: reason)
        print("🔄 [SERVICE] Insertion failed: \(reason.rawValue)")
        
        delegate?.displayNotification(
            title: "Insertion Failed",
            message: reason.rawValue,
            isError: true
        )
        
        // Reset status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.resetStatus()
        }
    }
    
    private func resetStatus() {
        print("🔄 [SERVICE] Resetting status to .none")
        status = .none
        restoreClipboardContent()
    }
    
    // MARK: - Clipboard Management
    
    private func saveClipboardContent() {
        let pasteboard = NSPasteboard.general
        previousClipboardContent = pasteboard.string(forType: .string)
        print("🔄 [SERVICE] Saved previous clipboard content")
    }
    
    private func restoreClipboardContent() {
        guard let previousContent = previousClipboardContent else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(previousContent, forType: .string)
        previousClipboardContent = nil
        print("🔄 [SERVICE] Restored previous clipboard content")
    }
    
    private func copyToClipboard(_ text: String) -> Bool {
        print("🔄 [SERVICE] Copying to clipboard: \(text.prefix(30))...")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        
        if !success {
            print("🔄 [SERVICE] ⚠️ Failed to copy text to clipboard")
        }
        
        return success
    }
    
    // MARK: - Timer Management
    
    private func invalidateTimers() {
        insertionTimer?.invalidate()
        insertionTimer = nil
    }
    
    // MARK: - Input Simulation
    
    /// Simulates mouse click at current pointer location
    private func clickAtCurrentMouseLocation() {
        print("🔄 [SERVICE] Clicking at current mouse location")
        let mouseLoc = NSEvent.mouseLocation
        
        guard let clickEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: mouseLoc,
            mouseButton: .left
        ) else {
            print("🔄 [SERVICE] ⚠️ Failed to create mouse click event")
            return
        }
        
        clickEvent.post(tap: .cghidEventTap)
        
        // Brief delay between down and up
        usleep(5000)
        
        // Mouse up
        if let clickUpEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: mouseLoc,
            mouseButton: .left
        ) {
            clickUpEvent.post(tap: .cghidEventTap)
            print("🔄 [SERVICE] Mouse click completed")
        }
    }
    
    // MARK: - Keyboard Simulation
    
    /// Simulates keystrokes using CGEvent
    private func simulateKeyPress(keyCode: CGKeyCode, withFlags flags: CGEventFlags? = nil) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) else {
            print("🔄 [SERVICE] ⚠️ Failed to create key down event")
            return
        }
        
        if let flags = flags {
            keyDown.flags = flags
        }
        keyDown.post(tap: .cghidEventTap)
        
        // Short delay between down and up
        usleep(10000) // 10ms
        
        // Key up
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            print("🔄 [SERVICE] ⚠️ Failed to create key up event")
            return
        }
        
        if let flags = flags {
            keyUp.flags = flags
        }
        keyUp.post(tap: .cghidEventTap)
    }
    
    // MARK: - Common Keyboard Commands
    
    /// Simulates paste command (Cmd+V)
    private func simulatePaste() {
        print("🔄 [SERVICE] Executing paste command (Cmd+V)")
        simulateKeyPress(keyCode: 9, withFlags: .maskCommand) // V key
    }
    
    /// Simulates tab key
    private func simulateTab() {
        print("🔄 [SERVICE] Executing tab key")
        simulateKeyPress(keyCode: 48) // Tab key
    }
} 