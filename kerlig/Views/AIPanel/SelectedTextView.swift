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
    @State private var clipboardImage: NSImage? = nil
    @State private var hasImageContent: Bool = false
    @State private var imageQuery: String = ""
    @State private var isProcessingQuery: Bool = false
    @State private var geminiResponse: String = ""
    @State private var showResponse: Bool = false
    
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
        if isVisible {
            VStack(alignment: .leading, spacing: 8) {
                // Header with source indicator and expand/collapse controls
                HStack {
                    // Source indicator
                    sourceIndicator
                    
                    Spacer()
                    
                    // Expand/collapse button
                    if !hasImageContent {
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
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Content - either text or image
                if hasImageContent && clipboardImage != nil {
                    VStack(spacing: 12) {
                        imageContent
                        
                        // Query input for Gemini
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ask Gemini about this image:")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("Ask a question about this image...", text: $imageQuery)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.system(size: 14))
                                
                                // Break up the complex expression by using separate views
                                submitButton
                            }
                        }
                        
                        // Gemini response
                        if showResponse && !geminiResponse.isEmpty {
                            geminiResponseView
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                } else if !displayedText.isEmpty {
                    textContent
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
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
            .onAppear {
                checkForClipboardImage()
            }
        }
    }
    
    // Extract submit button to separate view
    private var submitButton: some View {
        Button(action: {
            submitImageToGemini()
        }) {
            Text("Submit")
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(accentColor)
                )
                .foregroundColor(.white)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(imageQuery.isEmpty || isProcessingQuery)
        .opacity(imageQuery.isEmpty || isProcessingQuery ? 0.6 : 1.0)
        .overlay(loadingIndicator)
    }
    
    // Extract loading indicator to separate view
    private var loadingIndicator: some View {
        Group {
            if isProcessingQuery {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
    }
    
    // Extract Gemini response view to separate view
    private var geminiResponseView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Gemini's Response")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                copyResponseButton
            }
            
            Text(geminiResponse)
                .font(.system(size: 13))
                .lineSpacing(4)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(textBackgroundColor)
                )
                .textSelection(.enabled)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
        .transition(.opacity)
    }
    
    // Extract copy button to separate view
    private var copyResponseButton: some View {
        Button(action: {
            copyToClipboard(geminiResponse)
            showCopiedNotification = true
            
            // Hide notification after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showCopiedNotification = false
            }
        }) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(copyButtonScale)
        .overlay(copyNotification)
    }
    
    // Extract copy notification to separate view
    private var copyNotification: some View {
        Group {
            if showCopiedNotification {
                Text("Copied!")
                    .font(.system(size: 10))
                    .padding(4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
                    .offset(y: -20)
                    .transition(.opacity)
            }
        }
    }
    
    // Image content view
    private var imageContent: some View {
        VStack(alignment: .center) {
            if let image = clipboardImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // Submit image to Gemini AI
    private func submitImageToGemini() {
        guard let image = clipboardImage, !imageQuery.isEmpty else { return }
        
        isProcessingQuery = true
        showResponse = false
        
        // In a real implementation, you would convert the NSImage to the format needed by Gemini API
        // and send the request to the Gemini API
        
        // Simulate API call to Gemini
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // This is where you would process the actual Gemini response
            geminiResponse = generateSampleResponse(for: imageQuery)
            isProcessingQuery = false
            
            withAnimation(.easeIn(duration: 0.3)) {
                showResponse = true
            }
        }
    }
    
    // Sample response generator (replace with actual Gemini API integration)
    private func generateSampleResponse(for query: String) -> String {
        let responses = [
            "This appears to be a PNG file icon. PNG (Portable Network Graphics) is a raster-graphics file format that supports lossless data compression.",
            "The image shows a document icon that represents a PNG image file. PNG files are commonly used for web graphics, logos, and images that require transparency.",
            "This is a visual representation of a PNG file. PNG files support alpha channel transparency and are widely used in digital graphics and web design.",
            "I can see a PNG file icon in this image. PNG is a popular image format developed as an improved alternative to GIF, supporting more colors and better compression."
        ]
        
        return responses.randomElement() ?? "I can analyze this image for you. It appears to be a PNG file icon which represents an image file in the PNG format."
    }
    
    // Check if clipboard contains an image
    private func checkForClipboardImage() {
        // Only check for image if source is clipboard
        if appState.textSource == .clipboard {
            let pasteboard = NSPasteboard.general
            
            // Check for image types
            if let image = NSImage(pasteboard: pasteboard) {
                clipboardImage = image
                hasImageContent = true
            } else {
                clipboardImage = nil
                hasImageContent = false
            }
        } else {
            clipboardImage = nil
            hasImageContent = false
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
            return hasImageContent ? ("photo", .green) : ("doc.on.clipboard", .green)
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
            return hasImageContent ? "Clipboard Image" : "From Clipboard"
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

