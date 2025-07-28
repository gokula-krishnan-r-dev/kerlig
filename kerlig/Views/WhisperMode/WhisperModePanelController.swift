import Foundation
import SwiftUI
import AppKit

class WhisperModePanelController: NSWindowController {
    private var whisperPanel: WhisperModePanel?
    private var panelWindow: NSWindow?
    private var isVisible = false
    
    // State management
    private var currentState: PanelState = .idle {
        didSet {
            updatePanelState()
        }
    }
    
    // Callbacks
    var onStopRecording: (() -> Void)?
    var onCancel: (() -> Void)?
    
    // MARK: - Panel States
    enum PanelState: Equatable {
        case idle
        case recording
        case processing
        case error(String)
    }
    
    // MARK: - Initialization
    override init(window: NSWindow?) {
        super.init(window: window)
        setupWindow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init() {
        self.init(window: nil)
    }
    
    // MARK: - Public Methods
    
    func showPanel(completion: @escaping () -> Void = {}) {
        guard !isVisible else {
            completion()
            return
        }
        
        NSLog("🎭 Showing Whisper Mode panel")
        
        DispatchQueue.main.async { [weak self] in
            self?.createPanelWindow()
            self?.animateIn {
                self?.isVisible = true
                completion()
            }
        }
    }
    
    func hidePanel(completion: @escaping () -> Void = {}) {
        guard isVisible else {
            completion()
            return
        }
        
        NSLog("🎭 Hiding Whisper Mode panel")
        
        DispatchQueue.main.async { [weak self] in
            self?.animateOut {
                self?.isVisible = false
                self?.cleanupWindow()
                completion()
            }
        }
    }
    
    func showRecordingState() {
        currentState = .recording
    }
    
    func showProcessingState() {
        currentState = .processing
    }
    
    func showError(message: String) {
        currentState = .error(message)
    }
    
    func updateRecordingAnimation(isRecording: Bool) {
        // This will be handled by the view's state management
    }
    
    // MARK: - Private Methods
    
    private func setupWindow() {
        // Initial setup - actual window creation happens in showPanel
    }
    
    private func createPanelWindow() {
        // Create the SwiftUI view
        whisperPanel = WhisperModePanel(
            onStopRecording: { [weak self] in
                self?.handleStopRecording()
            },
            onCancel: { [weak self] in
                self?.handleCancel()
            }
        )
        
        // Create the hosting view
        let hostingView = NSHostingView(rootView: whisperPanel!)
        
        // Calculate size
        let panelSize = NSSize(width: 320, height: 260)
        
        // Create the window
        panelWindow = NSWindow(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window
        panelWindow?.contentView = hostingView
        panelWindow?.backgroundColor = .clear
        panelWindow?.isOpaque = false
        panelWindow?.hasShadow = false
        panelWindow?.level = .floating
        panelWindow?.acceptsMouseMovedEvents = true
        panelWindow?.ignoresMouseEvents = false
        panelWindow?.isExcludedFromWindowsMenu = true
        
        // Position at center of screen
        positionWindow()
        
        // Set self as window controller
        window = panelWindow
    }
    
    private func positionWindow() {
        guard let window = panelWindow,
              let screen = NSScreen.main else { return }
        
        let screenRect = screen.visibleFrame
        let windowSize = window.frame.size
        
        let x = screenRect.midX - windowSize.width / 2
        let y = screenRect.midY - windowSize.height / 2
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    private func animateIn(completion: @escaping () -> Void) {
        guard let window = panelWindow else {
            completion()
            return
        }
        
        // Set initial state for animation
        window.alphaValue = 0.0
        window.setFrame(
            window.frame.insetBy(dx: 20, dy: 20),
            display: true
        )
        
        // Show the window
        window.orderFront(nil)
        
        // Animate in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            window.animator().alphaValue = 1.0
            window.animator().setFrame(
                window.frame.insetBy(dx: -20, dy: -20),
                display: true
            )
        } completionHandler: {
            completion()
        }
    }
    
    private func animateOut(completion: @escaping () -> Void) {
        guard let window = panelWindow else {
            completion()
            return
        }
        
        // Animate out
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            window.animator().alphaValue = 0.0
            window.animator().setFrame(
                window.frame.insetBy(dx: 10, dy: 10),
                display: true
            )
        } completionHandler: {
            window.orderOut(nil)
            completion()
        }
    }
    
    private func cleanupWindow() {
        panelWindow?.close()
        panelWindow = nil
        whisperPanel = nil
        window = nil
    }
    
    private func updatePanelState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let panel = self.whisperPanel else { return }
            
            switch self.currentState {
            case .idle:
                panel.updateRecordingState(isRecording: false)
                panel.updateProcessingState(isProcessing: false)
                panel.updateErrorState(message: nil)
                
            case .recording:
                panel.updateRecordingState(isRecording: true)
                panel.updateProcessingState(isProcessing: false)
                panel.updateErrorState(message: nil)
                
            case .processing:
                panel.updateRecordingState(isRecording: false)
                panel.updateProcessingState(isProcessing: true)
                panel.updateErrorState(message: nil)
                
            case .error(let message):
                panel.updateRecordingState(isRecording: false)
                panel.updateProcessingState(isProcessing: false)
                panel.updateErrorState(message: message)
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleStopRecording() {
        NSLog("🛑 Panel requested stop recording")
        onStopRecording?()
    }
    
    private func handleCancel() {
        NSLog("❌ Panel requested cancel")
        onCancel?()
    }
}

// MARK: - Keyboard Event Handling
extension WhisperModePanelController {
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36: // Return key
            if currentState == .recording {
                handleStopRecording()
            } else if currentState == .idle {
                // Start recording (handled by WhisperModeManager)
                WhisperModeManager.shared.activateWhisperMode()
            }
            
        case 53: // Escape key
            handleCancel()
            
        default:
            super.keyDown(with: event)
        }
    }
}

// MARK: - Window Delegate
extension WhisperModePanelController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        isVisible = false
        cleanupWindow()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Ensure the panel can receive keyboard events
        panelWindow?.makeFirstResponder(panelWindow?.contentView)
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // Optionally hide panel when it loses focus
        // hidePanel()
    }
}

// MARK: - Recording Progress Updates
extension WhisperModePanelController {
    func updateRecordingProgress(duration: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            self?.whisperPanel?.updateRecordingDuration(duration)
        }
    }
}

// MARK: - Static Helper Methods
extension WhisperModePanelController {
    static func createAndShow() -> WhisperModePanelController {
        let controller = WhisperModePanelController()
        controller.showPanel()
        return controller
    }
} 