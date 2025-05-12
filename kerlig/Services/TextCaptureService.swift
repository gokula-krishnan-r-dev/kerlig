import SwiftUI
import Combine
import Carbon
import AppKit

class TextCaptureService: ObservableObject {
    @Published var lastCapturedText: String = ""
    @Published var isShowingPreview: Bool = false
    
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // Capture method preference
    @AppStorage("captureMethod") private var captureMethod = "simulation" // "simulation" or "accessibility"
    
    init() {
        setupKeyboardShortcut()
        
        // Auto-hide preview after delay
        $isShowingPreview
            .filter { $0 }
            .sink { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.isShowingPreview = false
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupKeyboardShortcut() {
        // Local monitoring (when this app is active)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                self?.captureSelectedText()
                return nil // Consume the event
            }
            return event // Pass the event through
        }
    }
    
    func captureSelectedText() {
        // Get the frontmost application
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            debugPrint("No frontmost application found")
            return
        }
        
        debugPrint("Attempting to capture from app: \(frontmostApp.localizedName ?? "Unknown")")
        
        // Try using accessibility API first
        if captureMethod == "accessibility" {
            if captureTextUsingAccessibility(from: frontmostApp) {
                return
            }
        }
        
        // Fall back to simulating keyboard shortcut
        simulateCopyCommand()
        
        // Give a slight delay for the copy operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.getTextFromPasteboard()
        }
    }

    func getTextFromSelection() -> String {
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else {
            debugPrint("No text found in pasteboard")
            return ""
        }
        return text
    }
    
    private func captureTextUsingAccessibility(from app: NSRunningApplication) -> Bool {
        // Get the AXUIElement for the application
        let pid = app.processIdentifier
        let axApp = AXUIElementCreateApplication(pid)
        
        // Get the focused UI element
        var focusedElement: CFTypeRef?
        let focusedElementResult = AXUIElementCopyAttributeValue(
            axApp,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        
        if focusedElementResult != AXError.success {
            return false
        }
        
        guard let focusedAXElement = focusedElement else {
            return false
        }
        
        // Get the selected text
        var selectedText: CFTypeRef?
        let selectedTextResult = AXUIElementCopyAttributeValue(
            focusedAXElement as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )
        
        if selectedTextResult == AXError.success, 
           let cfString = selectedText,
           let text = CFGetTypeID(cfString) == CFStringGetTypeID() ? (cfString as! CFString) as String : nil,
           !text.isEmpty {
            // We got the text via accessibility!
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.lastCapturedText = text
                self.isShowingPreview = true
                
                NotificationCenter.default.post(
                    name: Notification.Name("TextCaptured"),
                    object: nil,
                    userInfo: ["text": text]
                )
                
                debugPrint("Successfully captured text via accessibility: \(text.prefix(20))...")
            }
            return true
        }
        
        return false
    }
    
    private func simulateCopyCommand() {
        // Create a CGEvent for Command Down
        let cmdDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand
        cmdDown?.post(tap: .cghidEventTap)
        
        // Create a CGEvent for 'c' Down
        let cDown = CGEvent(keyboardEventSource: nil, virtualKey: 0x08, keyDown: true)
        cDown?.flags = .maskCommand
        cDown?.post(tap: .cghidEventTap)
        
        // Create a CGEvent for 'c' Up
        let cUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x08, keyDown: false)
        cUp?.flags = .maskCommand
        cUp?.post(tap: .cghidEventTap)
        
        // Create a CGEvent for Command Up
        let cmdUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x37, keyDown: false)
        cmdUp?.post(tap: .cghidEventTap)
    }
    
    private func getTextFromPasteboard() {
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else {
            debugPrint("No text found in pasteboard")
            return
        }
        
        // Store the captured text
        lastCapturedText = text
        
        // Show the preview
        isShowingPreview = true
        
        // Post notification for snippet manager
        NotificationCenter.default.post(name: Notification.Name("TextCaptured"), 
                                        object: nil, 
                                        userInfo: ["text": lastCapturedText])
        
        debugPrint("Successfully captured text: \(text.prefix(20))...")
    }
    
    func startMonitoring() {
        // Global monitoring (when other apps are active)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                DispatchQueue.main.async {
                    self?.captureSelectedText()
                }
            }
        }
    }
    
    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    func setCaptureMethod(_ method: String) {
        captureMethod = method
    }
    
    deinit {
        stopMonitoring()
    }
} 
