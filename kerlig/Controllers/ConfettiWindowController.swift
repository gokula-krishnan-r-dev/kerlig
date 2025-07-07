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
        let confettiView = ConfettiView(isActive: true)
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
            
            let confettiView = ConfettiView(isActive: true)
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

// MARK: - Confetti View
struct ConfettiView: NSViewRepresentable {
    var isActive: Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if isActive {
            addConfettiAnimation(to: nsView)
        } else {
            removeConfettiAnimation(from: nsView)
        }
    }
    
    private func addConfettiAnimation(to view: NSView) {
        // Remove any existing confetti layers first
        removeConfettiAnimation(from: view)
        
        // Create multiple emitter layers for a more festive effect
        addEmitterLayer(to: view, position: CGPoint(x: view.bounds.width / 2, y: view.bounds.height + 10), isTopEmitter: true)
        addEmitterLayer(to: view, position: CGPoint(x: view.bounds.width / 4, y: view.bounds.height + 10), isTopEmitter: true)
        addEmitterLayer(to: view, position: CGPoint(x: view.bounds.width * 3 / 4, y: view.bounds.height + 10), isTopEmitter: true)
        
        // Add emitters at the sides for more coverage
        addEmitterLayer(to: view, position: CGPoint(x: 0, y: view.bounds.height * 0.7), isTopEmitter: false, isLeftSide: true)
        addEmitterLayer(to: view, position: CGPoint(x: view.bounds.width, y: view.bounds.height * 0.7), isTopEmitter: false, isLeftSide: false)
        
        // Automatically stop after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            removeConfettiAnimation(from: view)
        }
    }
    
    private func addEmitterLayer(to view: NSView, position: CGPoint, isTopEmitter: Bool = true, isLeftSide: Bool = false) {
        // Create emitter layer
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = position
        
        // Configure emitter based on position (top vs sides)
        if isTopEmitter {
            // Top emitters
            emitter.emitterShape = .line
            emitter.emitterSize = CGSize(width: view.bounds.width / 3, height: 1)
        } else {
            // Side emitters
            emitter.emitterShape = .point
            emitter.emitterSize = CGSize(width: 1, height: 100)
        }
        
        emitter.renderMode = .additive
        
        // Create confetti particles with different colors and shapes
        let colors: [NSColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow, .systemPurple, .systemOrange, .systemTeal, .systemPink]
        var cells: [CAEmitterCell] = []
        
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 15
            cell.lifetime = 10
            cell.lifetimeRange = 3
            cell.velocity = CGFloat.random(in: 180...250)
            cell.velocityRange = 50
            
            // Configure emission direction based on emitter position
            if isTopEmitter {
                cell.emissionLongitude = .pi
                cell.emissionRange = .pi / 3
            } else {
                cell.emissionRange = .pi / 2
                cell.emissionLongitude = isLeftSide ? 0 : .pi
            }
            
            cell.spin = CGFloat.random(in: 2...5)
            cell.spinRange = 2
            cell.scaleRange = 0.25
            cell.scaleSpeed = -0.1
            
            // Apply physics with some randomness
            cell.yAcceleration = CGFloat.random(in: 50...100)
            cell.xAcceleration = CGFloat.random(in: -20...20)
            
            // Create a shape for the confetti
            let shape = createConfettiShape(with: color)
            cell.contents = shape
            
            cells.append(cell)
        }
        
        emitter.emitterCells = cells
        
        // Add the emitter layer to the view's layer
        view.wantsLayer = true
        view.layer?.addSublayer(emitter)
        
        // Tag the layer for later removal
        emitter.name = "confettiLayer"
    }
    
    private func createConfettiShape(with color: NSColor) -> CGImage? {
        // Random size for more variety
        let sizeVariation = CGFloat.random(in: 8...15)
        let size = CGSize(width: sizeVariation, height: sizeVariation)
        let renderer = NSImage(size: size)
        
        renderer.lockFocus()
        
        // Draw a random shape (rectangle, circle, triangle, star, or custom)
        let shapeType = Int.random(in: 0...4)
        color.set()
        
        switch shapeType {
        case 0:
            // Rectangle
            NSBezierPath(rect: NSRect(x: 0, y: 0, width: size.width, height: size.height)).fill()
        case 1:
            // Circle
            NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size.width, height: size.height)).fill()
        case 2:
            // Triangle
            let path = NSBezierPath()
            path.move(to: NSPoint(x: size.width/2, y: 0))
            path.line(to: NSPoint(x: size.width, y: size.height))
            path.line(to: NSPoint(x: 0, y: size.height))
            path.close()
            path.fill()
        case 3:
            // Star
            drawStar(in: NSRect(x: 0, y: 0, width: size.width, height: size.height))
        case 4:
            // Custom shape (heart)
            drawHeart(in: NSRect(x: 0, y: 0, width: size.width, height: size.height))
        default:
            break
        }
        
        renderer.unlockFocus()
        
        if let cgImage = renderer.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return cgImage
        }
        
        return nil
    }
    
    private func drawStar(in rect: NSRect) {
        let path = NSBezierPath()
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4
        
        let points = 5
        var angle = -CGFloat.pi / 2
        let angleIncrement = .pi * 2 / CGFloat(points)
        
        path.move(to: NSPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle)))
        
        for _ in 0..<points {
            angle += angleIncrement / 2
            path.line(to: NSPoint(x: center.x + innerRadius * cos(angle), y: center.y + innerRadius * sin(angle)))
            angle += angleIncrement / 2
            path.line(to: NSPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle)))
        }
        
        path.close()
        path.fill()
    }
    
    private func drawHeart(in rect: NSRect) {
        let path = NSBezierPath()
        
        // Scale to fit the rect
        let width = rect.width
        let height = rect.height
        
        // Start at bottom center
        path.move(to: NSPoint(x: width/2, y: 0))
        
        // Draw the left half of the heart
        path.curve(to: NSPoint(x: 0, y: height/3),
                  controlPoint1: NSPoint(x: width/4, y: 0),
                  controlPoint2: NSPoint(x: 0, y: height/6))
        
        path.curve(to: NSPoint(x: width/2, y: height),
                  controlPoint1: NSPoint(x: 0, y: height*2/3),
                  controlPoint2: NSPoint(x: width/4, y: height))
        
        // Draw the right half of the heart
        path.curve(to: NSPoint(x: width, y: height/3),
                  controlPoint1: NSPoint(x: width*3/4, y: height),
                  controlPoint2: NSPoint(x: width, y: height*2/3))
        
        path.curve(to: NSPoint(x: width/2, y: 0),
                  controlPoint1: NSPoint(x: width, y: height/6),
                  controlPoint2: NSPoint(x: width*3/4, y: 0))
        
        path.close()
        path.fill()
    }
    
    private func removeConfettiAnimation(from view: NSView) {
        if let sublayers = view.layer?.sublayers {
            for layer in sublayers {
                if layer.name == "confettiLayer" {
                    layer.removeFromSuperlayer()
                }
            }
        }
    }
}
