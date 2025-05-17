import SwiftUI
import AppKit

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
                let index = displayedText.index(displayedText.startIndex, offsetBy: min(maxChars, displayedText.count))
                return displayedText.count > maxChars ? 
                    String(displayedText[..<index]) + "..." : 
                    displayedText
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
        appState.isDarkMode || colorScheme == .dark ? 
            Color(NSColor(red: 32/255, green: 32/255, blue: 36/255, alpha: 1.0)) : 
            Color(NSColor.windowBackgroundColor)
    }
    
    // Text background color based on color scheme
    private var textBackgroundColor: Color {
        appState.isDarkMode || colorScheme == .dark ? 
            Color(NSColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1.0)) : 
            Color(NSColor.textBackgroundColor)
    }
    
    // Stats background color
    private var statsBackgroundColor: Color {
        appState.isDarkMode || colorScheme == .dark ?
            Color.gray.opacity(0.2) :
            Color.gray.opacity(0.1)
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
                // Full text
                Text(AttributedString(displayedText))
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
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
            let minHeight: CGFloat = 60   // Minimum height for any content
            let maxCollapsedHeight: CGFloat = 60 // Maximum height when collapsed
            
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

struct SelectedTextView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        
        Group {
            VStack {
                SelectedTextView(
                    displayedText: "This is a sample text that would be selected by the user.\nIt demonstrates how the component displays and handles the selected text from another application.\nThis is the third line of text.\nThis is the fourth line of text.\nThis line should be hidden initially.",
                    isVisible: true
                )
                
                SelectedTextView(
                    displayedText: "This is a shorter sample text with no line breaks that fits within the initial view.",
                    isVisible: true
                )
            }
            .frame(width: 500)
            .padding()
            .preferredColorScheme(.dark)
            .environmentObject(appState)
            
            VStack {
                SelectedTextView(
                    displayedText: "This is a sample text that would be selected by the user.\nIt demonstrates how the component displays and handles the selected text from another application.\nThis is the third line of text.\nThis is the fourth line of text.\nThis line should be hidden initially.",
                    isVisible: true
                )
                
                SelectedTextView(
                    displayedText: "This is a shorter sample text with no line breaks that fits within the initial view.",
                    isVisible: true
                )
            }
            .frame(width: 500)
            .padding()
            .preferredColorScheme(.light)
            .environmentObject(appState)
        }
    }
} 
