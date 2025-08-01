import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Clipboard Item Model
struct ClipboardHistoryItem: Identifiable, Codable {
    let id = UUID()
    let content: ClipboardContent
    let timestamp: Date
    let sourceApp: String?
    
    var displayText: String {
        switch content {
        case .text(let text):
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .image:
            return "📷 Image"
        case .file(let filename, _):
            return "📁 \(filename)"
        case .rtf(let text):
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .html(let text):
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    var typeIcon: String {
        switch content {
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "doc"
        case .rtf: return "doc.richtext"
        case .html: return "globe"
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Clipboard Content Types
enum ClipboardContent: Codable {
    case text(String)
    case image(Data)
    case file(filename: String, data: Data)
    case rtf(String)
    case html(String)
    
    var searchableText: String {
        switch self {
        case .text(let text), .rtf(let text), .html(let text):
            return text.lowercased()
        case .file(let filename, _):
            return filename.lowercased()
        case .image:
            return "image photo picture"
        }
    }
}

// MARK: - Clipboard Monitoring Service
class ClipboardMonitoringService: ObservableObject {
    static let shared = ClipboardMonitoringService()
    
    @Published var clipboardHistory: [ClipboardHistoryItem] = []
    @Published var isMonitoring: Bool = false
    
    private var monitoringTimer: Timer?
    private var lastChangeCount: Int = 0
    private let maxHistoryItems: Int = 100
    private let pasteboard = NSPasteboard.general
    
    // Storage key for persistence
    private let storageKey = "clipboardHistory"
    
    init() {
        loadHistoryFromStorage()
        setupInitialState()
    }
    
    // MARK: - Public Interface
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        lastChangeCount = pasteboard.changeCount
        
        // Monitor clipboard changes every 0.5 seconds
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForClipboardChanges()
        }
        
        NSLog("📋 Clipboard monitoring started")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        NSLog("📋 Clipboard monitoring stopped")
    }
    
    func clearHistory() {
        clipboardHistory.removeAll()
        saveHistoryToStorage()
    }
    
    func deleteItem(_ item: ClipboardHistoryItem) {
        clipboardHistory.removeAll { $0.id == item.id }
        saveHistoryToStorage()
    }
    
    func copyItemToClipboard(_ item: ClipboardHistoryItem) {
        pasteboard.clearContents()
        
        switch item.content {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let imageData):
            if let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            }
        case .file(_, let data):
            // For file content, we'll treat it as data
            pasteboard.setData(data, forType: .fileURL)
        case .rtf(let rtfText):
            if let rtfData = rtfText.data(using: .utf8) {
                pasteboard.setData(rtfData, forType: .rtf)
            }
        case .html(let htmlText):
            pasteboard.setString(htmlText, forType: .html)
        }
        
        NSLog("📋 Copied item to clipboard: \(item.displayText.prefix(20))...")
    }
    
    func searchHistory(query: String) -> [ClipboardHistoryItem] {
        guard !query.isEmpty else { return clipboardHistory }
        
        let lowercaseQuery = query.lowercased()
        return clipboardHistory.filter { item in
            item.content.searchableText.contains(lowercaseQuery) ||
            item.sourceApp?.lowercased().contains(lowercaseQuery) == true
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialState() {
        lastChangeCount = pasteboard.changeCount
    }
    
    private func checkForClipboardChanges() {
        let currentChangeCount = pasteboard.changeCount
        
        guard currentChangeCount != lastChangeCount else { return }
        
        lastChangeCount = currentChangeCount
        captureCurrentClipboardContent()
    }
    
    private func captureCurrentClipboardContent() {
        guard let items = pasteboard.pasteboardItems, !items.isEmpty else { return }
        
        let sourceApp = getCurrentAppName()
        
        for item in items {
            if let content = extractContentFromItem(item) {
                let historyItem = ClipboardHistoryItem(
                    content: content,
                    timestamp: Date(),
                    sourceApp: sourceApp
                )
                
                // Avoid duplicates by checking if the same content was just added
                if !isDuplicate(historyItem) {
                    addToHistory(historyItem)
                }
            }
        }
    }
    
    private func extractContentFromItem(_ item: NSPasteboardItem) -> ClipboardContent? {
        // Priority order: text, RTF, HTML, images, files
        
        // Check for plain text
        if let text = item.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .text(text)
        }
        
        // Check for RTF
        if let rtfData = item.data(forType: .rtf),
           let rtfString = String(data: rtfData, encoding: .utf8) {
            return .rtf(rtfString)
        }
        
        // Check for HTML
        if let htmlText = item.string(forType: .html), !htmlText.isEmpty {
            return .html(htmlText)
        }
        
        // Check for images
        if let imageData = item.data(forType: .png) ?? item.data(forType: .jpeg) ?? item.data(forType: .tiff) {
            return .image(imageData)
        }
        
        // Check for file URLs
        if let fileURLData = item.data(forType: .fileURL),
           let fileURL = URL(dataRepresentation: fileURLData, relativeTo: nil) {
            let filename = fileURL.lastPathComponent
            return .file(filename: filename, data: fileURLData)
        }
        
        return nil
    }
    
    private func isDuplicate(_ newItem: ClipboardHistoryItem) -> Bool {
        // Check if the same content was added in the last 2 seconds
        let recentItems = clipboardHistory.prefix(3)
        
        for item in recentItems {
            if abs(item.timestamp.timeIntervalSinceNow) < 2.0 {
                switch (item.content, newItem.content) {
                case (.text(let oldText), .text(let newText)):
                    return oldText == newText
                case (.image(let oldData), .image(let newData)):
                    return oldData == newData
                case (.file(let oldFilename, let oldData), .file(let newFilename, let newData)):
                    return oldFilename == newFilename && oldData == newData
                case (.rtf(let oldRtf), .rtf(let newRtf)):
                    return oldRtf == newRtf
                case (.html(let oldHtml), .html(let newHtml)):
                    return oldHtml == newHtml
                default:
                    continue
                }
            }
        }
        
        return false
    }
    
    private func addToHistory(_ item: ClipboardHistoryItem) {
        DispatchQueue.main.async {
            // Add to beginning of array
            self.clipboardHistory.insert(item, at: 0)
            
            // Limit history size
            if self.clipboardHistory.count > self.maxHistoryItems {
                self.clipboardHistory.removeLast()
            }
            
            // Save to storage
            self.saveHistoryToStorage()
            
            NSLog("📋 Added to clipboard history: \(item.displayText.prefix(20))... from \(item.sourceApp ?? "Unknown")")
        }
    }
    
    private func getCurrentAppName() -> String? {
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            return frontmostApp.localizedName ?? frontmostApp.bundleIdentifier
        }
        return nil
    }
    
    // MARK: - Persistence
    
    private func saveHistoryToStorage() {
        do {
            let data = try JSONEncoder().encode(clipboardHistory)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            NSLog("❌ Failed to save clipboard history: \(error)")
        }
    }
    
    private func loadHistoryFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        
        do {
            clipboardHistory = try JSONDecoder().decode([ClipboardHistoryItem].self, from: data)
            NSLog("📋 Loaded \(clipboardHistory.count) clipboard history items")
        } catch {
            NSLog("❌ Failed to load clipboard history: \(error)")
            clipboardHistory = []
        }
    }
    
    deinit {
        stopMonitoring()
    }
}

// MARK: - Extensions

extension NSPasteboard.PasteboardType {
    static let png = NSPasteboard.PasteboardType("public.png")
    static let jpeg = NSPasteboard.PasteboardType("public.jpeg")
}