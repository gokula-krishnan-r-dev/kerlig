import Cocoa
import SwiftUI

// MARK: - Confetti Window Controller
class ConfettiWindowController: NSObject {
    
    // MARK: - Properties
    private var confettiWindow: NSWindow?
    private var timer: Timer?
    private let displayDuration: TimeInterval
    private var hostingView: NSHostingView<ConfettiView>? // Strong reference to hosting view
    
    // MARK: - Initialization
    init(displayDuration: TimeInterval = 3.0) {
        self.displayDuration = displayDuration
        super.init()
    }
    
    
    
    // MARK: - Public Methods
    func showConfetti() {
        // Clean up any existing confetti first
        hideConfetti()
        
        guard let screen = NSScreen.main else {
            print("Warning: Could not access main screen")
            return
        }
        
        // Create overlay window with precise full-screen dimensions
        let window = createOverlayWindow(for: screen)
        
        // Configure confetti view
        let confettiView = ConfettiView(isActive: true , direction: .bothSides  )
        let hostingView = NSHostingView(rootView: confettiView)
        
        // Keep strong reference to prevent deallocation
        self.hostingView = hostingView
        
        // Ensure hosting view fills the entire window
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = hostingView
        
        // Add constraints to ensure full coverage
        if let contentView = window.contentView {
            NSLayoutConstraint.activate([
                hostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
                hostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
        
        // Store reference and display
        self.confettiWindow = window
        window.makeKeyAndOrderFront(nil)
        
        // Schedule automatic closure
        scheduleAutoClose()
    }
    
    func hideConfetti() {
        cleanup()
    }
    
    // MARK: - Private Methods
    private func createOverlayWindow(for screen: NSScreen) -> NSWindow {
        // Use entire screen frame for true full screen coverage
        let screenFrame = screen.frame
        
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties for overlay
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = NSWindow.Level.screenSaver // Higher than floating for true overlay
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        // Ensure window covers entire screen and stays on top
        window.setFrame(screenFrame, display: true)
        
        return window
    }
    
    private func scheduleAutoClose() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.hideConfetti()
            }
        }
        // Ensure timer runs even during tracking loops
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
        
        // Close window on main thread to avoid threading issues
        DispatchQueue.main.async { [weak self] in
            self?.confettiWindow?.close()
            self?.confettiWindow = nil
            self?.hostingView = nil
        }
    }
}

// MARK: - Extensions
extension ConfettiWindowController {
    
    /// Show confetti with custom duration
    func showConfetti(duration: TimeInterval) {
        showConfetti()
        
        // Override the scheduled timer with custom duration
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.hideConfetti()
            }
        }
        // Ensure timer runs even during tracking loops
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    /// Check if confetti is currently being displayed
    var isShowingConfetti: Bool {
        return confettiWindow != nil && confettiWindow?.isVisible == true
    }
}

// MARK: - Usage Example
extension ConfettiWindowController {
    
    /// Convenience method for celebration scenarios
    static func celebrate(duration: TimeInterval = 3.0) {
        let controller = ConfettiWindowController(displayDuration: duration)
        controller.showConfetti()
        
        // Keep a reference to prevent premature deallocation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
            // Allow controller to be deallocated after animation completes
            _ = controller.isShowingConfetti
        }
    }
}

// MARK: - Multi-Screen Support (Optional)
extension ConfettiWindowController {
    
    /// Show confetti on all screens
    func showConfettiOnAllScreens() {
        hideConfetti() // Clean up existing
        
        // Create a strong reference array to keep controllers alive
        var activeControllers: [ConfettiWindowController] = []
        
        NSScreen.screens.forEach { screen in
            let controller = ConfettiWindowController(displayDuration: displayDuration)
            
            // Create window for specific screen
            let window = controller.createOverlayWindow(for: screen)
            
            let confettiView = ConfettiView(isActive: true, direction: .bothSides)
            let hostingView = NSHostingView(rootView: confettiView)
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            window.contentView = hostingView
            
            // Keep strong reference to prevent deallocation
            controller.hostingView = hostingView
            controller.confettiWindow = window
            
            window.makeKeyAndOrderFront(nil)
            activeControllers.append(controller)
        }
        
        // Auto-close all screens after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration + 0.5) {
            activeControllers.forEach { $0.hideConfetti() }
            // Clear reference to allow deallocation
            activeControllers.removeAll()
        }
    }
}
