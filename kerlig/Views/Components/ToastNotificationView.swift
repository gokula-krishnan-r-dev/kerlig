import SwiftUI
import AppKit

struct ToastNotificationView: View {
    let message: String
    let icon: String?
    let duration: TimeInterval
    @State private var isVisible = false
    
    private let onDismiss: () -> Void
    
    init(message: String, icon: String? = nil, duration: TimeInterval = 3.0, onDismiss: @escaping () -> Void = {}) {
        self.message = message
        self.icon = icon
        self.duration = duration
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            }
            
            Text(message)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
            
            // Auto-dismiss after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                dismissToast()
            }
        }
    }
    
    private func dismissToast() {
        withAnimation {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Toast Manager
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published private var toastWindows: [ToastWindow] = []
    
    private init() {}
    
    func showToast(message: String, icon: String? = nil, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {
            let toastWindow = ToastWindow(message: message, icon: icon, duration: duration) { [weak self] window in
                self?.removeToast(window)
            }
            
            self.toastWindows.append(toastWindow)
            toastWindow.show()
        }
    }
    
    private func removeToast(_ window: ToastWindow) {
        DispatchQueue.main.async {
            self.toastWindows.removeAll { $0 === window }
        }
    }
    
    func dismissAllToasts() {
        DispatchQueue.main.async {
            self.toastWindows.forEach { $0.close() }
            self.toastWindows.removeAll()
        }
    }
}

// MARK: - Toast Window
class ToastWindow: NSWindow {
    private let onDismiss: (ToastWindow) -> Void
    
    init(message: String, icon: String? = nil, duration: TimeInterval = 3.0, onDismiss: @escaping (ToastWindow) -> Void) {
        self.onDismiss = onDismiss
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        setupContent(message: message, icon: icon, duration: duration)
    }
    
    private func setupWindow() {
        // Window configuration
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        
        // Remove from window menu
        isExcludedFromWindowsMenu = true
        
        // Set initial position (will be adjusted in show())
        center()
    }
    
    private func setupContent(message: String, icon: String? = nil, duration: TimeInterval = 3.0) {
        let toastView = ToastNotificationView(
            message: message,
            icon: icon,
            duration: duration
        ) { [weak self] in
            self?.performDismiss()
        }
        
        let hostingView = NSHostingView(rootView: toastView)
        hostingView.frame = contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        
        contentView?.addSubview(hostingView)
        
        // Adjust window size to content
        let idealSize = hostingView.intrinsicContentSize
        let windowSize = NSSize(
            width: max(idealSize.width + 40, 200),
            height: max(idealSize.height + 24, 60)
        )
        
        setContentSize(windowSize)
    }
    
    func show() {
        // Position at bottom center of screen
        guard let screen = NSScreen.main else { return }
        
        let screenRect = screen.visibleFrame
        let windowSize = frame.size
        
        let x = screenRect.midX - windowSize.width / 2
        let y = screenRect.minY + 100 // 100 points from bottom
        
        setFrameOrigin(NSPoint(x: x, y: y))
        orderFront(nil)
        
        // Add click to dismiss
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        contentView?.addGestureRecognizer(clickGesture)
    }
    
    @objc private func handleClick() {
        performDismiss()
    }
    
    private func performDismiss() {
        // Animate out
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            animator().alphaValue = 0
            animator().setFrame(frame.offsetBy(dx: 0, dy: -20), display: true)
        } completionHandler: { [weak self] in
            guard let self = self else { return }
            self.close()
            self.onDismiss(self)
        }
    }
    
    override func close() {
        super.close()
        onDismiss(self)
    }
}

// MARK: - Convenience Extensions
extension ToastNotificationView {
    static func show(message: String, icon: String? = nil, duration: TimeInterval = 3.0) {
        ToastManager.shared.showToast(message: message, icon: icon, duration: duration)
    }
    
    static func showSuccess(message: String, duration: TimeInterval = 3.0) {
        show(message: message, icon: "checkmark.circle.fill", duration: duration)
    }
    
    static func showError(message: String, duration: TimeInterval = 4.0) {
        show(message: message, icon: "exclamationmark.triangle.fill", duration: duration)
    }
    
    static func showInfo(message: String, duration: TimeInterval = 3.0) {
        show(message: message, icon: "info.circle.fill", duration: duration)
    }
    
    static func showWarning(message: String, duration: TimeInterval = 3.5) {
        show(message: message, icon: "exclamationmark.triangle.fill", duration: duration)
    }
}

// MARK: - Multiple Toast Positioning
extension ToastManager {
    private func getNextToastPosition() -> NSPoint {
        guard let screen = NSScreen.main else {
            return NSPoint(x: 0, y: 100)
        }
        
        let screenRect = screen.visibleFrame
        let baseY = screenRect.minY + 100
        let spacing: CGFloat = 80
        
        let yOffset = CGFloat(toastWindows.count) * spacing
        
        return NSPoint(
            x: screenRect.midX - 150, // Assuming 300px width
            y: baseY + yOffset
        )
    }
}

// MARK: - Preview
struct ToastNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ToastNotificationView(
                message: "Message copied. You can paste it anywhere you want.",
                icon: "doc.on.clipboard.fill"
            )
            
            ToastNotificationView(
                message: "Recording started successfully",
                icon: "mic.fill"
            )
            
            ToastNotificationView(
                message: "Processing your voice...",
                icon: "waveform"
            )
        }
        .frame(width: 400, height: 300)
        .background(Color.gray.opacity(0.1))
    }
} 