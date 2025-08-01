import SwiftUI

struct ClipboardHistoryView: View {
    @StateObject private var clipboardService = ClipboardMonitoringService.shared
    @State private var searchText = ""
    @State private var selectedItem: ClipboardHistoryItem?
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: ClipboardHistoryItem?
    @State private var hoveredItem: ClipboardHistoryItem?
    
    private var filteredItems: [ClipboardHistoryItem] {
        clipboardService.searchHistory(query: searchText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Content
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                clipboardListView
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            clipboardService.startMonitoring()
        }
        .onDisappear {
            // Keep monitoring when view disappears
        }
        .alert("Delete Clipboard Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { itemToDelete = nil }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    clipboardService.deleteItem(item)
                }
                itemToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this clipboard item?")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("Clipboard History")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Monitor status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(clipboardService.isMonitoring ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Text(clipboardService.isMonitoring ? "Monitoring" : "Paused")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Control buttons
                Menu {
                    Button(action: {
                        if clipboardService.isMonitoring {
                            clipboardService.stopMonitoring()
                        } else {
                            clipboardService.startMonitoring()
                        }
                    }) {
                        Label(clipboardService.isMonitoring ? "Pause Monitoring" : "Start Monitoring", 
                              systemImage: clipboardService.isMonitoring ? "pause.circle" : "play.circle")
                    }
                    
                    Divider()
                    
                    Button(action: {
                        clipboardService.clearHistory()
                    }) {
                        Label("Clear All History", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .menuStyle(BorderlessButtonMenuStyle())
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search clipboard history...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlColor))
            .cornerRadius(8)
            
            // Stats
            HStack {
                Text("\(filteredItems.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !searchText.isEmpty {
                    Text("Filtered from \(clipboardService.clipboardHistory.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: searchText.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Clipboard History" : "No Search Results")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(searchText.isEmpty ? 
                     "Copy some text or images to see them here.\nClipboard monitoring is \(clipboardService.isMonitoring ? "active" : "paused")." :
                     "Try adjusting your search terms.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            if searchText.isEmpty && !clipboardService.isMonitoring {
                Button("Start Monitoring") {
                    clipboardService.startMonitoring()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Clipboard List
    
    private var clipboardListView: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredItems) { item in
                    ClipboardItemRow(
                        item: item,
                        isSelected: selectedItem?.id == item.id,
                        isHovered: hoveredItem?.id == item.id,
                        onSelect: { selectedItem = item },
                        onCopy: { clipboardService.copyItemToClipboard(item) },
                        onDelete: { 
                            itemToDelete = item
                            showingDeleteAlert = true
                        }
                    )
                    .onHover { hovering in
                        hoveredItem = hovering ? item : nil
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Clipboard Item Row

struct ClipboardItemRow: View {
    let item: ClipboardHistoryItem
    let isSelected: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    @State private var showingFullText = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: item.typeIcon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Main text with preview
                Text(item.displayText)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(showingFullText ? nil : 2)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                
                // Metadata row
                HStack(spacing: 8) {
                    // Source app
                    if let sourceApp = item.sourceApp {
                        Text(sourceApp)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    // Timestamp
                    Text(item.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Content type badge
                    contentTypeBadge
                }
            }
            
            Spacer()
            
            // Action buttons (shown on hover/selection)
            if isHovered || isSelected {
                HStack(spacing: 4) {
                    // Toggle full text button for long content
                    if item.displayText.count > 100 {
                        Button(action: { showingFullText.toggle() }) {
                            Image(systemName: showingFullText ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .help(showingFullText ? "Show preview" : "Show full text")
                    }
                    
                    // Copy button
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    .help("Copy to clipboard")
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .help("Delete item")
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
            onCopy() // Auto-copy when selected
        }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: showingFullText)
        .padding(.horizontal, 16)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        } else if isHovered {
            return Color(NSColor.controlAccentColor).opacity(0.08)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.3)
        } else if isHovered {
            return Color(NSColor.controlAccentColor).opacity(0.2)
        } else {
            return Color.clear
        }
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
    
    @ViewBuilder
    private var contentTypeBadge: some View {
        switch item.content {
        case .text(let text):
            Text("\(text.count) chars")
                .font(.caption2)
                .foregroundColor(.secondary)
        case .image(let data):
            Text("\(formatBytes(data.count))")
                .font(.caption2)
                .foregroundColor(.secondary)
        case .file(_, let data):
            Text("\(formatBytes(data.count))")
                .font(.caption2)
                .foregroundColor(.secondary)
        case .rtf(let text):
            Text("RTF • \(text.count) chars")
                .font(.caption2)
                .foregroundColor(.secondary)
        case .html(let text):
            Text("HTML • \(text.count) chars")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Preview

struct ClipboardHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ClipboardHistoryView()
            .frame(width: 400, height: 600)
    }
}