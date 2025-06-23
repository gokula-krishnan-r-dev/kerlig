import Foundation
import AppKit
import Carbon.HIToolbox

/// A professional service for recording keyboard shortcuts with global key monitoring
class ShortcutRecorderService: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var recordedShortcut: KeyboardShortcut?
    
    private var keyMonitor: Any?
    private var flagsMonitor: Any?
    
    // Available modifier keys
    struct KeyboardShortcut: Equatable {
        let key: String
        let modifiers: NSEvent.ModifierFlags
        let displayString: String
        
        init(key: String, modifiers: NSEvent.ModifierFlags = []) {
            self.key = key
            self.modifiers = modifiers
            self.displayString = Self.createDisplayString(key: key, modifiers: modifiers)
        }
        
        private static func createDisplayString(key: String, modifiers: NSEvent.ModifierFlags) -> String {
            var components: [String] = []
            
            if modifiers.contains(.control) {
                components.append("⌃")
            }
            if modifiers.contains(.option) {
                components.append("⌥")
            }
            if modifiers.contains(.shift) {
                components.append("⇧")
            }
            if modifiers.contains(.command) {
                components.append("⌘")
            }
            
            components.append(key)
            return components.joined()
        }
    }
    
    /// Start recording a keyboard shortcut
    func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        recordedShortcut = nil
        
        
        // Monitor key down events
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        // Monitor flags changed events for modifier-only shortcuts
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        
        // Also add local monitor for when our app is active
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil // Consume the event
        }
    }
    
    /// Stop recording
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        
        if let keyMonitor = keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        
        if let flagsMonitor = flagsMonitor {
            NSEvent.removeMonitor(flagsMonitor)
            self.flagsMonitor = nil
        }
    }
    
    /// Cancel recording without saving
    func cancelRecording() {
        stopRecording()
        recordedShortcut = nil
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        guard isRecording else { return }
        
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard let characters = event.charactersIgnoringModifiers?.uppercased(),
              characters.count == 1,
              characters.rangeOfCharacter(from: CharacterSet.alphanumerics) != nil else {
            return
        }
        
        // Create the shortcut
        let shortcut = KeyboardShortcut(key: characters, modifiers: modifiers)
        
        DispatchQueue.main.async {
            self.recordedShortcut = shortcut
            self.stopRecording()
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        // Handle modifier-only shortcuts if needed
        // For now, we require an actual key press
    }
    
    deinit {
        stopRecording()
    }
}



/// Extension to convert to storage format
extension ShortcutRecorderService.KeyboardShortcut {
    /// Convert to simple string format for storage (e.g., "E" for Command+E)
    var storageString: String {
        // For now, we'll store just the key for Command+Key shortcuts
        // This matches the existing CustomAction shortcutKey format
        if modifiers.contains(.command) && modifiers.subtracting(.command).isEmpty {
            return key
        }
        // For other combinations, we might need to extend the storage format
        return key
    }
    
   
} 