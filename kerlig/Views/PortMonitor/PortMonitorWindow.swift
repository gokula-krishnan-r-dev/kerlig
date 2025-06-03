import SwiftUI

struct PortMonitorWindow: View {
    var body: some View {
        PortMonitorView()
            .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - Window Management
extension PortMonitorWindow {
    static func open() {
        // Check if window already exists
        for window in NSApp.windows where window.title == "Port Monitor" {
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        // Create new window
        let contentView = PortMonitorWindow()
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Port Monitor"
        window.center()
        window.setFrameAutosaveName("PortMonitorWindow")
        window.contentViewController = hostingController
        window.makeKeyAndOrderFront(nil)
    }
}
