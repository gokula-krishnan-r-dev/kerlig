import AppKit
import SwiftUI

class ClipboardPanelController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private var clipboardService = ClipboardMonitoringService.shared
    private var visualEffectView: NSVisualEffectView?
    private var hotkeyManager: HotkeyManager?
    
    // MARK: - Panel Management
    
    func showPanel() {
        if panel == nil {
            createPanel()
        }
        
        guard let panel = panel else { return }
        
        // Position panel at center of current screen
        positionPanel()
        
        // Show panel with animation
        panel.orderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Start clipboard monitoring if not already started
        clipboardService.startMonitoring()
        
        // Add entrance animation
        panel.alphaValue = 0.0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 1.0
        }
        
        // Setup global monitor for outside clicks
        setupGlobalMonitor()
        
        NSLog("📋 Clipboard panel shown")
    }
    
    func hidePanel() {
        guard let panel = panel else { return }
        
        // Fade out animation
        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().alphaValue = 0.0
            },
            completionHandler: {
                panel.orderOut(nil)
                NSLog("📋 Clipboard panel hidden")
            }
        )
    }
    
    func togglePanel() {
        if panel?.isVisible == true {
            hidePanel()
        } else {
            showPanel()
        }
    }
    
    // MARK: - Panel Creation
    
    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 500),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure panel properties
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.hasShadow = true
        
        // Hide standard window buttons
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Create visual effect view for backdrop
        let visualEffectView = NSVisualEffectView()
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 16
        visualEffectView.layer?.masksToBounds = true
        
        if let contentView = panel.contentView {
            contentView.addSubview(visualEffectView)
            
            NSLayoutConstraint.activate([
                visualEffectView.topAnchor.constraint(equalTo: contentView.topAnchor),
                visualEffectView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                visualEffectView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                visualEffectView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
            
            self.visualEffectView = visualEffectView
        }
        
        // Create SwiftUI content
        let hostingController = NSHostingController(
            rootView: ClipboardFloatingPanelView(
                onClose: { [weak self] in
                    self?.hidePanel()
                },
                onInsert: { [weak self] item in
                    self?.insertClipboardItem(item)
                }
            )
            .environmentObject(clipboardService)
        )
        
        // Add hosting view to visual effect view
        let hostView = hostingController.view
        hostView.translatesAutoresizingMaskIntoConstraints = false
        hostView.wantsLayer = true
        hostView.layer?.backgroundColor = NSColor.clear.cgColor
        
        visualEffectView.addSubview(hostView)
        NSLayoutConstraint.activate([
            hostView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            hostView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            hostView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            hostView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor)
        ])
        
        // Set window delegate
        panel.delegate = self
        
        // Configure auto-hide behavior
        panel.hidesOnDeactivate = true
        
        self.panel = panel
    }
    
    private func positionPanel() {
        guard let panel = panel else { return }
        
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelFrame = panel.frame
            
            let x = screenFrame.midX - panelFrame.width / 2
            let y = screenFrame.midY - panelFrame.height / 2
            
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    // MARK: - Global Monitor
    
    private func setupGlobalMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else { return }
            
            let mouseLocation = NSEvent.mouseLocation
            let panelFrame = panel.frame
            
            // Hide panel if click is outside
            if !NSPointInRect(mouseLocation, panelFrame) {
                DispatchQueue.main.async {
                    self.hidePanel()
                }
            }
        }
    }
    
    // MARK: - Insert Functionality
    
    private func insertClipboardItem(_ item: ClipboardHistoryItem) {
        // Copy item to clipboard
        clipboardService.copyItemToClipboard(item)
        
        // Hide panel briefly
        hidePanel()
        
        // Use HotkeyManager to paste the content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.pasteToActiveApplication()
        }
    }
    
    private func pasteToActiveApplication() {
        if hotkeyManager == nil {
            hotkeyManager = HotkeyManager()
        }
        
        // Simulate Command+V to paste
        let success = hotkeyManager?.simulateCommandV() ?? false
        
        if success {
            NSLog("📋 Successfully pasted clipboard content")
        } else {
            NSLog("❌ Failed to paste clipboard content")
        }
    }
    
    // MARK: - Window Delegate
    
    func windowDidResignKey(_ notification: Notification) {
        // Auto-hide when panel loses focus
        hidePanel()
    }
    
    func windowWillClose(_ notification: Notification) {
        panel = nil
    }
}

// MARK: - Floating Panel SwiftUI View

struct ClipboardFloatingPanelView: View {
    @EnvironmentObject var clipboardService: ClipboardMonitoringService
    @State private var searchText = ""
    @State private var hoveredItem: ClipboardHistoryItem?
    
    let onClose: () -> Void
    let onInsert: (ClipboardHistoryItem) -> Void
    
    private var filteredItems: [ClipboardHistoryItem] {
        clipboardService.searchHistory(query: searchText).prefix(8).map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                clipboardListView
            }
        }
        .frame(width: 480, height: 600)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Title and close button
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "doc.on.clipboard.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Clipboard History")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Press ⌘⇧V to open anywhere")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onClose) {
                    ZStack {
                        Circle()
                            .fill(Color.secondary.opacity(0.1))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .help("Close (Esc)")
            }
            
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("Search clipboard history...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .help("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            
            // Status and info bar
            HStack {
                // Monitoring status
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(clipboardService.isMonitoring ? .green.opacity(0.15) : .red.opacity(0.15))
                            .frame(width: 16, height: 16)
                        
                        Circle()
                            .fill(clipboardService.isMonitoring ? .green : .red)
                            .frame(width: 6, height: 6)
                    }
                    
                    Text(clipboardService.isMonitoring ? "Active" : "Paused")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(clipboardService.isMonitoring ? .green : .red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((clipboardService.isMonitoring ? Color.green : Color.red).opacity(0.1))
                .cornerRadius(6)
                
                Spacer()
                
                // Items count
                HStack(spacing: 4) {
                    Image(systemName: "doc.stack")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(filteredItems.count) of \(clipboardService.clipboardHistory.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Shortcut hint
                if filteredItems.isEmpty {
                    Spacer()
                    
                    Text("⌘C to copy • ⌘V to paste")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            Rectangle()
                .fill(Color(NSColor.windowBackgroundColor).opacity(0.95))
                .overlay(
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: searchText.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Clipboard History" : "No Results Found")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(searchText.isEmpty ? "Copy some content to get started" : "Try different search terms")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "command")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        Text("C")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                        Text("to copy content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "command")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        Image(systemName: "shift")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        Text("V")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                        Text("to open this panel anywhere")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.accentColor.opacity(0.05))
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Clipboard List
    
    private var clipboardListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredItems, id: \.id) { item in
                    ClipboardFloatingItemRow(
                        item: item,
                        isHovered: hoveredItem?.id == item.id,
                        onInsert: { onInsert(item) }
                    )
                    .onHover { hovering in
                        hoveredItem = hovering ? item : nil
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Floating Item Row

struct ClipboardFloatingItemRow: View {
    let item: ClipboardHistoryItem
    let isHovered: Bool
    let onInsert: () -> Void
    @State private var imageData: Data?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Content preview area
                contentPreview
                
                // Content details
                VStack(alignment: .leading, spacing: 4) {
                    // Content text/description
                    Text(item.displayText)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(isImageContent ? 1 : 3)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    // Metadata row
                    HStack(spacing: 8) {
                        // Content type badge
                        contentTypeBadge
                        
                        // Source app
                        if let sourceApp = item.sourceApp {
                            Text(sourceApp)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        // Timestamp
                        Text(item.timeAgo)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 8)
                
                // Action buttons
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Image preview (if image content)
            if isImageContent {
                imagePreviewSection
            }
        }
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: isHovered ? 1.5 : 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onInsert()
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onAppear {
            loadImageIfNeeded()
        }
    }
    
    // MARK: - Content Preview
    
    @ViewBuilder
    private var contentPreview: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 36, height: 36)
            
            Image(systemName: item.typeIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
        }
    }
    
    // MARK: - Content Type Badge
    
    private var contentTypeBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(iconColor)
                .frame(width: 6, height: 6)
            
            Text(contentTypeText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(iconColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(iconColor.opacity(0.1))
        .cornerRadius(4)
    }
    
    // MARK: - Action Buttons
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 6) {
            // Primary insert button
            Button(action: onInsert) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.caption)
                    Text("Insert")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .opacity(isHovered ? 1.0 : 0.8)
            
            // Secondary actions (only show on hover)
            if isHovered {
                HStack(spacing: 4) {
                    // Copy button
                    Button(action: {
                        ClipboardMonitoringService.shared.copyItemToClipboard(item)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy to clipboard")
                    
                    // More options (future use)
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("More options")
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
    }
    
    // MARK: - Image Preview Section
    
    @ViewBuilder
    private var imagePreviewSection: some View {
        if let imageData = imageData, let nsImage = NSImage(data: imageData) {
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                    .background(Color.secondary.opacity(0.3))
                
                HStack {
                    Text("Image Preview")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Click to insert")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.horizontal, 16)
                
                // Image preview
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 120)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .onTapGesture {
                        onInsert()
                    }
                    .scaleEffect(isHovered ? 1.02 : 1.0)
                
                // Image details
                HStack {
                    Text("Size: \(formatImageSize(nsImage))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Tap image to insert")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                        .opacity(isHovered ? 1.0 : 0.7)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isImageContent: Bool {
        if case .image = item.content {
            return true
        }
        return false
    }
    
    private var contentTypeText: String {
        switch item.content {
        case .text: return "Text"
        case .image: return "Image"
        case .file: return "File"
        case .rtf: return "Rich Text"
        case .html: return "HTML"
        }
    }
    
    private var backgroundColor: Color {
        if isHovered {
            return Color(NSColor.controlBackgroundColor).opacity(0.8)
        } else {
            return Color(NSColor.controlBackgroundColor).opacity(0.4)
        }
    }
    
    private var borderColor: Color {
        if isHovered {
            return Color.accentColor.opacity(0.5)
        } else {
            return Color.secondary.opacity(0.2)
        }
    }
    
    private var iconBackgroundColor: Color {
        iconColor.opacity(0.15)
    }
    
    private var iconColor: Color {
        switch item.content {
        case .text: return .blue
        case .image: return .green
        case .file: return .orange
        case .rtf: return .purple
        case .html: return .red
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadImageIfNeeded() {
        guard case .image(let data) = item.content else { return }
        self.imageData = data
    }
    
    private func formatImageSize(_ image: NSImage) -> String {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        return "\(width) × \(height)"
    }
}

