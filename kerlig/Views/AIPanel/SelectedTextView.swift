import AppKit
import SwiftUI
import PDFKit

struct SelectedTextView: View {
  // Access AppState for dynamic values
  @EnvironmentObject var appState: AppState
  @Environment(\.colorScheme) var colorScheme

  let displayedText: String
  let isVisible: Bool
  @State private var isHovered: Bool = false
  @State private var showCopiedNotification: Bool = false
  @State private var isExpanded: Bool = false
  @State private var copyButtonScale: CGFloat = 1.0

  private let maxCollapsedLines: Int = 3
  private let animationDuration: Double = 0.25

  // Calculate word count
  private var wordCount: Int {
    displayedText.split(separator: " ").count
  }

  // Calculate character count
  private var characterCount: Int {
    displayedText.count
  }

  // Text truncation logic
  private var displayText: String {
    if isExpanded {
      return displayedText
    } else {
      // Get approximate number of characters we can display in the collapsed view
      let lineHeight: CGFloat = 20
      let maxCollapsedHeight: CGFloat = 120

      // Number of visible lines within the collapsed height (minus padding)
      let visibleLines = Int((maxCollapsedHeight - 32) / lineHeight)

      // Estimate based on lines and character count
      let lines = displayedText.components(separatedBy: "\n")

      if lines.count > visibleLines {
        // More lines than we can display
        return lines.prefix(visibleLines).joined(separator: "\n") + "\n..."
      } else if displayedText.count > visibleLines * 60 {
        // Approximate character cutoff based on visible lines and estimated chars per line
        let maxChars = visibleLines * 60
        let index = displayedText.index(
          displayedText.startIndex, offsetBy: min(maxChars, displayedText.count))
        return displayedText.count > maxChars
          ? String(displayedText[..<index]) + "..." : displayedText
      }

      return displayedText
    }
  }

  // Get accent color dynamically based on app state and color scheme
  private var accentColor: Color {
    appState.isDarkMode || colorScheme == .dark ? Color.blue : Color.blue.opacity(0.8)
  }

  // Background color based on color scheme
  private var cardBackgroundColor: Color {
    appState.isDarkMode || colorScheme == .dark
      ? Color(NSColor(red: 32 / 255, green: 32 / 255, blue: 36 / 255, alpha: 1.0))
      : Color(NSColor.windowBackgroundColor)
  }

  // Text background color based on color scheme
  private var textBackgroundColor: Color {
    appState.isDarkMode || colorScheme == .dark
      ? Color(NSColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0))
      : Color(NSColor.textBackgroundColor)
  }

  // Stats background color
  private var statsBackgroundColor: Color {
    appState.isDarkMode || colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
  }

  var body: some View {
    if !displayedText.isEmpty && isVisible {
      VStack(alignment: .leading, spacing: 8) {
        // Header with source indicator and expand/collapse controls
        HStack {
          // Source indicator
          sourceIndicator

          Spacer()

          // Expand/collapse button
          Button(action: {
            withAnimation(.easeInOut(duration: animationDuration)) {
              isExpanded.toggle()
            }
          }) {
            HStack(spacing: 4) {
              Text(isExpanded ? "Collapse" : "Expand")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

              Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
              RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
                .overlay(
                  RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
            )
          }
          .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)

        // Text content
        textContent
          .padding(.horizontal, 16)
          .padding(.bottom, 12)
      }
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.white.opacity(0.05))
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
          )
      )
      .padding(.top, 8)
      .transition(.move(edge: .top).combined(with: .opacity))
    }
  }

  // Source indicator - shows where the text came from
  private var sourceIndicator: some View {
    HStack(spacing: 6) {
      // Icon based on source
      Image(systemName: sourceIcon.0)
        .font(.system(size: 12))
        .foregroundColor(sourceIcon.1)

      // Text indicating source
      Text(sourceText)
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(.primary.opacity(0.8))
    }
  }

  // Dynamic icon and color based on source
  private var sourceIcon: (String, Color) {
    switch appState.textSource {
    case .directSelection:
      return ("text.cursor", .blue)
    case .clipboard:
      return ("doc.on.clipboard", .green)
    case .userInput:
      return ("keyboard", .purple)
    case .unknown:
      return ("default", .blue)
    }
  }

  // Dynamic text based on source
  private var sourceText: String {
    switch appState.textSource {
    case .directSelection:
      return "Selected Text"
    case .clipboard:
      return "From Clipboard"
    case .userInput:
      return "Your Input"
    case .unknown:
      return "default"
    }
  }

  // Text content area - shows either full text or collapsed version
  private var textContent: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Show either collapsed or expanded text
      if isExpanded {
        // Full text - check if it's a file path for expanded view too
        if isFilePath(displayedText) {
          fileContentView
        } else {
          Text(AttributedString(displayedText))
            .font(.system(size: 13))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
        }
      } else {
        // Collapsed view - handle file paths and regular text
        if isFilePath(displayedText) {
          fileContentView
        } else {
          // Collapsed text (first few lines)
          Text(getPreviewText())
            .font(.system(size: 13))
            .lineSpacing(4)
            .lineLimit(maxCollapsedLines)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
        }
      }
    }
  }
  
  // Professional file content view with support for multiple formats
  private var fileContentView: some View {
    let fileType = getFileType(displayedText)
    
      return VStack(alignment: .leading, spacing: 8) {
      // File header with icon and path
      fileHeaderView(fileType: fileType)
      
      // File-specific content based on type
      Group {
        switch fileType {
        case .image:
          imagePreviewView
        case .pdf:
          pdfPreviewView
        case .audio:
          audioFileView
        case .video:
          videoFileView
        case .document:
          documentFileView
        case .text:
          textFileView
        case .archive:
          archiveFileView
        case .unknown:
          unknownFileView
        }
      }
      .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
  }
  
  // File header with appropriate icon and path
  private func fileHeaderView(fileType: FileType) -> some View {
    HStack {
      Image(systemName: fileType.icon)
        .foregroundColor(fileType.color)
        .font(.system(size: 14, weight: .medium))
      
      VStack(alignment: .leading, spacing: 2) {
        Text(getFileName(displayedText))
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(.primary)
          .lineLimit(1)
          .truncationMode(.middle)
        
        Text(displayedText)
          .font(.system(size: 11))
          .foregroundColor(.secondary)
          .lineLimit(1)
          .truncationMode(.middle)
          .textSelection(.enabled)
      }
      
      Spacer()
      
      // File type badge
      Text(fileType.displayName)
        .font(.system(size: 10, weight: .medium))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(fileType.color.opacity(0.1))
        .foregroundColor(fileType.color)
        .cornerRadius(4)
    }
  }
  
  // Image preview view
  private var imagePreviewView: some View {
    Group {
      if let nsImage = loadImageFromPath(displayedText) {
        Image(nsImage: nsImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: .infinity, maxHeight: isExpanded ? 300 : 150)
          .cornerRadius(8)
          .clipped()
      } else {
        placeholderView(icon: "photo.badge.exclamationmark", message: "Image not found")
      }
    }
  }
  
  // PDF preview view
  private var pdfPreviewView: some View {
    Group {
      if let pdfPreview = loadPDFPreview(displayedText) {
        Image(nsImage: pdfPreview)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: .infinity, maxHeight: isExpanded ? 300 : 150)
          .cornerRadius(8)
          .clipped()
      } else {
        VStack(spacing: 8) {
          Image(systemName: "doc.text.fill")
            .font(.system(size: 32))
            .foregroundColor(.red)
          
          Text("PDF Document")
            .font(.system(size: 14, weight: .medium))
          
          if let fileInfo = getFileInfo(displayedText) {
            Text(fileInfo)
              .font(.system(size: 12))
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
          }
        }
        .frame(height: isExpanded ? 150 : 100)
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
      }
    }
  }
  
  // Audio file view
  private var audioFileView: some View {
    VStack(spacing: 8) {
      Image(systemName: "music.note")
        .font(.system(size: 32))
        .foregroundColor(.blue)
      
      Text("Audio File")
        .font(.system(size: 14, weight: .medium))
      
      if let fileInfo = getFileInfo(displayedText) {
        Text(fileInfo)
          .font(.system(size: 12))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
      
      // Audio controls placeholder
      HStack(spacing: 12) {
        Button(action: {}) {
          Image(systemName: "play.circle.fill")
            .font(.system(size: 24))
            .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
        
        Text("Click to play")
          .font(.system(size: 12))
          .foregroundColor(.secondary)
      }
    }
    .frame(height: isExpanded ? 150 : 100)
    .frame(maxWidth: .infinity)
    .background(Color.blue.opacity(0.05))
    .cornerRadius(8)
  }
  
  // Video file view
  private var videoFileView: some View {
    VStack(spacing: 8) {
      Image(systemName: "play.rectangle.fill")
        .font(.system(size: 32))
        .foregroundColor(.purple)
      
      Text("Video File")
        .font(.system(size: 14, weight: .medium))
      
      if let fileInfo = getFileInfo(displayedText) {
        Text(fileInfo)
          .font(.system(size: 12))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .frame(height: isExpanded ? 150 : 100)
    .frame(maxWidth: .infinity)
    .background(Color.purple.opacity(0.05))
    .cornerRadius(8)
  }
  
  // Document file view
  private var documentFileView: some View {
    VStack(spacing: 8) {
      Image(systemName: "doc.text.fill")
        .font(.system(size: 32))
        .foregroundColor(.green)
      
      Text("Document")
        .font(.system(size: 14, weight: .medium))
      
      if let fileInfo = getFileInfo(displayedText) {
        Text(fileInfo)
          .font(.system(size: 12))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .frame(height: isExpanded ? 150 : 100)
    .frame(maxWidth: .infinity)
    .background(Color.green.opacity(0.05))
    .cornerRadius(8)
  }
  
  // Text file view with preview
  private var textFileView: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: "doc.text")
          .foregroundColor(.orange)
        Text("Text File")
          .font(.system(size: 14, weight: .medium))
        Spacer()
      }
      
      if let content = loadTextFileContent(displayedText) {
        ScrollView {
          Text(content)
            .font(.system(size: 11))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
        }
        .frame(maxHeight: isExpanded ? 200 : 80)
      } else {
        placeholderView(icon: "doc.text.badge.exclamationmark", message: "Text file not found")
      }
    }
  }
  
  // Archive file view
  private var archiveFileView: some View {
    VStack(spacing: 8) {
      Image(systemName: "archivebox.fill")
        .font(.system(size: 32))
        .foregroundColor(.brown)
      
      Text("Archive")
        .font(.system(size: 14, weight: .medium))
      
      if let fileInfo = getFileInfo(displayedText) {
        Text(fileInfo)
          .font(.system(size: 12))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .frame(height: isExpanded ? 150 : 100)
    .frame(maxWidth: .infinity)
    .background(Color.brown.opacity(0.05))
    .cornerRadius(8)
  }
  
  // Unknown file type view
  private var unknownFileView: some View {
    VStack(spacing: 8) {
      Image(systemName: "doc.fill")
        .font(.system(size: 32))
        .foregroundColor(.gray)
      
      Text("Unknown File")
        .font(.system(size: 14, weight: .medium))
      
      if let fileInfo = getFileInfo(displayedText) {
        Text(fileInfo)
          .font(.system(size: 12))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .frame(height: isExpanded ? 150 : 100)
    .frame(maxWidth: .infinity)
    .background(Color.gray.opacity(0.05))
    .cornerRadius(8)
  }
  
  // Generic placeholder view
  private func placeholderView(icon: String, message: String) -> some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color.gray.opacity(0.1))
      .frame(height: isExpanded ? 150 : 100)
      .overlay(
        VStack(spacing: 4) {
          Image(systemName: icon)
            .font(.system(size: 24))
            .foregroundColor(.secondary)
          
          Text(message)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
      )
  }
  
  // File type enumeration
  private enum FileType {
    case image, pdf, audio, video, document, text, archive, unknown
    
    var icon: String {
      switch self {
      case .image: return "photo.fill"
      case .pdf: return "doc.text.fill"
      case .audio: return "music.note"
      case .video: return "play.rectangle.fill"
      case .document: return "doc.text.fill"
      case .text: return "doc.text"
      case .archive: return "archivebox.fill"
      case .unknown: return "doc.fill"
      }
    }
    
    var color: Color {
      switch self {
      case .image: return .blue
      case .pdf: return .red
      case .audio: return .blue
      case .video: return .purple
      case .document: return .green
      case .text: return .orange
      case .archive: return .brown
      case .unknown: return .gray
      }
    }
    
    var displayName: String {
      switch self {
      case .image: return "IMAGE"
      case .pdf: return "PDF"
      case .audio: return "AUDIO"
      case .video: return "VIDEO"
      case .document: return "DOC"
      case .text: return "TEXT"
      case .archive: return "ARCHIVE"
      case .unknown: return "FILE"
      }
    }
  }
  
  // Helper function to detect if text is a file path
  private func isFilePath(_ text: String) -> Bool {
    // Check if it looks like a file path
    guard text.contains("/") || text.contains("\\") else { return false }
    
    // Check if it has a file extension
    let components = text.components(separatedBy: ".")
    return components.count > 1 && !components.last!.isEmpty
  }
  
  // Helper function to determine file type
  private func getFileType(_ path: String) -> FileType {
    let lowercaseExt = getFileExtension(path).lowercased()
    
    let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "tif", "webp", "svg", "ico", "heic", "heif"]
    let audioExtensions = ["mp3", "wav", "flac", "aac", "ogg", "m4a", "wma", "aiff"]
    let videoExtensions = ["mp4", "avi", "mov", "wmv", "flv", "webm", "mkv", "m4v"]
    let documentExtensions = ["doc", "docx", "xls", "xlsx", "ppt", "pptx", "rtf", "odt", "ods", "odp"]
    let textExtensions = ["txt", "md", "json", "xml", "csv", "log", "py", "js", "html", "css", "swift", "java", "cpp", "c", "h"]
    let archiveExtensions = ["zip", "rar", "7z", "tar", "gz", "bz2", "xz"]
    
    if lowercaseExt == "pdf" {
      return .pdf
    } else if imageExtensions.contains(lowercaseExt) {
      return .image
    } else if audioExtensions.contains(lowercaseExt) {
      return .audio
    } else if videoExtensions.contains(lowercaseExt) {
      return .video
    } else if documentExtensions.contains(lowercaseExt) {
      return .document
    } else if textExtensions.contains(lowercaseExt) {
      return .text
    } else if archiveExtensions.contains(lowercaseExt) {
      return .archive
    } else {
      return .unknown
    }
  }
  
  // Helper function to get file extension
  private func getFileExtension(_ path: String) -> String {
    return (path as NSString).pathExtension
  }
  
  // Helper function to get file name from path
  private func getFileName(_ path: String) -> String {
    return (path as NSString).lastPathComponent
  }
  
  // Helper function to get file information
  private func getFileInfo(_ path: String) -> String? {
    var filePath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Handle file:// URLs
    if filePath.hasPrefix("file://") {
      if let url = URL(string: filePath) {
        filePath = url.path
      }
    }
    
    // Expand tilde
    if filePath.hasPrefix("~") {
      filePath = NSString(string: filePath).expandingTildeInPath
    }
    
    // Get file attributes
    do {
      let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
      let size = attributes[.size] as? Int64 ?? 0
      let modificationDate = attributes[.modificationDate] as? Date
      
      var info = formatFileSize(size)
      
      if let date = modificationDate {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        info += "\nModified: \(formatter.string(from: date))"
      }
      
      return info
    } catch {
      return "File information unavailable"
    }
  }
  
  // Helper function to format file size
  private func formatFileSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
  
  // Helper function to load image from file path
  private func loadImageFromPath(_ path: String) -> NSImage? {
    var filePath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if filePath.hasPrefix("file://") {
      if let url = URL(string: filePath) {
        filePath = url.path
      }
    }
    
    if filePath.hasPrefix("~") {
      filePath = NSString(string: filePath).expandingTildeInPath
    }
    
    return NSImage(contentsOfFile: filePath)
  }
  
  // Helper function to load PDF preview
  private func loadPDFPreview(_ path: String) -> NSImage? {
    var filePath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if filePath.hasPrefix("file://") {
      if let url = URL(string: filePath) {
        filePath = url.path
      }
    }
    
    if filePath.hasPrefix("~") {
      filePath = NSString(string: filePath).expandingTildeInPath
    }
    
    guard let pdfDoc = PDFDocument(url: URL(fileURLWithPath: filePath)),
          let page = pdfDoc.page(at: 0) else {
      return nil
    }
    
    let pageRect = page.bounds(for: .mediaBox)
    let renderer = NSGraphicsContext.current?.cgContext
    
    let image = NSImage(size: pageRect.size)
    image.lockFocus()
    
    if let context = NSGraphicsContext.current?.cgContext {
      context.saveGState()
      context.translateBy(x: 0, y: pageRect.size.height)
      context.scaleBy(x: 1.0, y: -1.0)
      page.draw(with: .mediaBox, to: context)
      context.restoreGState()
    }
    
    image.unlockFocus()
    return image
  }
  
  // Helper function to load text file content
  private func loadTextFileContent(_ path: String) -> String? {
    var filePath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if filePath.hasPrefix("file://") {
      if let url = URL(string: filePath) {
        filePath = url.path
      }
    }
    
    if filePath.hasPrefix("~") {
      filePath = NSString(string: filePath).expandingTildeInPath
    }
    
    do {
      let content = try String(contentsOfFile: filePath, encoding: .utf8)
      // Limit content for preview
      let maxLength = isExpanded ? 1000 : 200
      return content.count > maxLength ? String(content.prefix(maxLength)) + "..." : content
    } catch {
      return nil
    }
  }

  // Helper to get preview text (first few lines)
  private func getPreviewText() -> AttributedString {
    let lines = displayedText.split(separator: "\n")

    if lines.count <= maxCollapsedLines {
      return AttributedString(displayedText)
    } else {
      let previewLines = lines.prefix(maxCollapsedLines)
      let preview = previewLines.joined(separator: "\n")
      var result = AttributedString(preview)

      // Add ellipsis indicator if text is truncated
      if lines.count > maxCollapsedLines {
        let ellipsis = AttributedString("\n...")
        result.append(ellipsis)
      }

      return result
    }
  }

  // Copy to clipboard function
  private func copyToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)

    // Also update the appState if needed
    appState.updateSelectedText(text, source: .clipboard)
  }

  // Calculate dynamic height based on text content
  private func calculateTextHeight() -> CGFloat {
    if isExpanded {
      return 200  // Maximum expanded height
    } else {
      // Calculate approximate height based on text content
      let lineHeight: CGFloat = 20  // Approximate height per line including spacing
      let minHeight: CGFloat = 60  // Minimum height for any content
      let maxCollapsedHeight: CGFloat = 60  // Maximum height when collapsed

      // Count lines (explicitly shown newlines plus estimated line wraps)
      let explicitLineCount = displayedText.components(separatedBy: "\n").count

      // Estimate additional wrapped lines based on character count
      // Assuming approximately 60 characters per line for the given width
      let charsPerLine = 60
      let textLength = displayedText.count
      let estimatedWrappedLines = textLength / charsPerLine

      // Total estimated lines
      let totalEstimatedLines = max(explicitLineCount, estimatedWrappedLines)

      // Calculate height based on line count with padding
      let calculatedHeight = CGFloat(totalEstimatedLines) * lineHeight + 32  // 32px for padding

      // Return constrained height
      return min(max(calculatedHeight, minHeight), maxCollapsedHeight)
    }
  }

  // Determine if we should show the expand button
  private func shouldShowExpandButton() -> Bool {
    if isExpanded {
      // Always show when expanded (to collapse)
      return true
    }

    // Check if text is truncated
    let lineHeight: CGFloat = 20
    let maxCollapsedHeight: CGFloat = 120
    let visibleLines = Int((maxCollapsedHeight - 32) / lineHeight)
    let charsPerLine = 60
    let maxVisibleChars = visibleLines * charsPerLine

    // Show button if:
    // 1. The text has more lines than can be displayed
    // 2. The text has more characters than can be comfortably displayed
    let lines = displayedText.components(separatedBy: "\n")
    return lines.count > visibleLines || displayedText.count > maxVisibleChars
  }
}

