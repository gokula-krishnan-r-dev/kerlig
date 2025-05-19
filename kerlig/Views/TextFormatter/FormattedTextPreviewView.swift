import SwiftUI

// MARK: - Documentation
/**
 # Rich Text Formatter
 
 A powerful text formatter for SwiftUI that implements markdown-style formatting.
 
 ## Features
 - **Bold text** with double asterisks
 - _Italic text_ with underscores
 - `Code blocks` with backticks
 - Headers with # symbols (# ## ###)
 - Bullet lists (- * +) and numbered lists (1. 2.)
 - Block quotes (> text)
 - Horizontal rules (---)
 - Links ([text](url))
 - Line breaks (/n)
 
 ## Usage
 ```swift
 FormattedTextView("**Hello World**")
 ```
 
 ## Configuration
 You can customize font size, text color, alignment, and line spacing:
 ```swift
 FormattedTextView(
     text,
     fontSize: 16,
     textColor: .primary,
     alignment: .leading,
     lineSpacing: 6
 )
 ```
 */

// MARK: - Formatted Text View
/// A view that renders formatted text with markdown-style syntax
/// - Supports **bold text** for bold formatting
/// - Automatically converts /n to line breaks
/// - Allows customization of text appearance
public struct FormattedTextView: View {
    private let text: String
    private let fontSize: CGFloat
    private let textColor: Color
    private let alignment: TextAlignment
    private let lineSpacing: CGFloat
    private let documentStyle: DocumentStyle

    /// Document styling options for the formatted text
    public enum DocumentStyle {
        /// Standard document with default styling
        case standard
        /// Academic paper style with serif fonts, increased line spacing
        case academic
        /// Modern magazine style with dynamic fonts and spacing
        case magazine
        /// Compact technical documentation style
        case technical
        /// VS Code-inspired dark theme
        case vscodeDark
        /// VS Code-inspired light theme
        case vscodeLight
        /// Custom style with specified parameters
        case custom(primaryFont: Font, headerFont: Font, codeFont: Font)
        
        /// Returns the body text font for this document style
        func bodyFont(size: CGFloat) -> Font {
            switch self {
            case .standard:
                return .system(size: size)
            case .academic:
                return .system(size: size, design: .serif)
            case .magazine:
                return .system(size: size, weight: .light, design: .rounded)
            case .technical:
                return .system(size: size, design: .monospaced)
            case .vscodeDark, .vscodeLight:
                return .system(size: size, design: .monospaced)
            case .custom(let primaryFont, _, _):
                return primaryFont
            }
        }
        
        /// Returns the header font for this document style
        func headingFont(size: CGFloat, level: Int) -> Font {
            switch self {
            case .standard:
                return .system(size: size, weight: .bold)
            case .academic:
                return .system(size: size, weight: .bold, design: .serif)
            case .magazine:
                return .system(size: size, weight: .heavy, design: .rounded)
            case .technical:
                return .system(size: size, weight: .bold)
            case .vscodeDark, .vscodeLight:
                return .system(size: size, weight: .bold)
            case .custom(_, let headerFont, _):
                return headerFont
            }
        }
        
        /// Returns the code font for this document style
        func codeFont(size: CGFloat) -> Font {
            switch self {
            case .standard, .academic, .magazine:
                return .system(size: size, design: .monospaced)
            case .technical, .vscodeDark, .vscodeLight:
                return .system(size: size, weight: .regular, design: .monospaced)
            case .custom(_, _, let codeFont):
                return codeFont
            }
        }
        
        /// Returns the appropriate horizontal padding for sections
        var sectionPadding: CGFloat {
            switch self {
            case .standard:
                return 4
            case .academic:
                return 8
            case .magazine:
                return 12
            case .technical, .vscodeDark, .vscodeLight:
                return 6
            case .custom:
                return 8
            }
        }
        
        /// Returns the appropriate background color for the document
        func backgroundColor(isDarkMode: Bool) -> Color {
            switch self {
            case .vscodeDark:
                return Color(red: 0.12, green: 0.12, blue: 0.12)
            case .vscodeLight:
                return Color(red: 0.98, green: 0.98, blue: 0.98)
            default:
                return isDarkMode ? Color.black.opacity(0.7) : Color.white
            }
        }
        
        /// Returns the appropriate code block background color
        func codeBlockBackgroundColor(isDarkMode: Bool) -> Color {
            switch self {
            case .vscodeDark:
                return Color(red: 0.16, green: 0.16, blue: 0.16)
            case .vscodeLight:
                return Color(red: 0.95, green: 0.95, blue: 0.95)
            default:
                return isDarkMode ? Color.black.opacity(0.6) : Color.gray.opacity(0.1)
            }
        }
        
        /// Returns the appropriate link color
        func linkColor(isDarkMode: Bool) -> Color {
            switch self {
            case .vscodeDark:
                return Color.blue.opacity(0.8)
            case .vscodeLight:
                return Color.blue
            default:
                return isDarkMode ? Color.blue.opacity(0.8) : Color.blue
            }
        }
    }
    
    public init(
        _ text: String,
        fontSize: CGFloat = 15,
        textColor: Color = .primary,
        alignment: TextAlignment = .leading,
        lineSpacing: CGFloat = 4,
        documentStyle: DocumentStyle = .standard
    ) {
        self.text = text
        self.fontSize = fontSize
        self.textColor = textColor
        self.alignment = alignment
        self.lineSpacing = lineSpacing
        self.documentStyle = documentStyle
    }
    
    public var body: some View {
        formattedText
            .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : alignment == .trailing ? .trailing : .center)
    }
    
    private var formattedText: some View {
        let components = TextFormatter.parse(text)
        
        return VStack(alignment: alignment == .leading ? .leading : alignment == .trailing ? .trailing : .center, spacing: lineSpacing) {
            ForEach(components.indices, id: \.self) { index in
                let component = components[index]
                
                switch component.type {
                case .plainText:
                    Text(component.text)
                        .font(documentStyle.bodyFont(size: fontSize))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(alignment)
                case .boldText:
                    Text(component.text)
                        .font(documentStyle.bodyFont(size: fontSize).bold())
                        .foregroundColor(textColor)
                        .multilineTextAlignment(alignment)
                case .italicText:
                    Text(component.text)
                        .font(documentStyle.bodyFont(size: fontSize).italic())
                        .foregroundColor(textColor)
                        .multilineTextAlignment(alignment)
                case .codeText:
                    Text(component.text)
                        .font(documentStyle.codeFont(size: fontSize))
                        .padding(4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(alignment)
                case .bulletPoint:
                    bulletPointView(text: component.text)
                case .numberedPoint(let number):
                    numberedPointView(text: component.text, number: number)
                case .header(let level):
                    headerView(text: component.text, level: level)
                case .quote:
                    quoteView(text: component.text)
                case .link(let url):
                    enhancedLinkView(text: component.text, url: url)
                case .image(let url, let alt):
                    imageView(url: url, alt: alt)
                case .horizontalRule:
                    Divider()
                        .background(textColor.opacity(0.5))
                        .padding(.vertical, 8)
                case .codeBlock(let language):
                    codeBlockView(text: component.text, language: language)
                case .taskList(let checked):
                    taskListItemView(text: component.text, isChecked: checked)
                case .thinkContent(let content):
                    thinkContentView(content: content, text: component.text)
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private func bulletPointView(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(documentStyle.bodyFont(size: fontSize))
                .foregroundColor(textColor)
            
            Text(text)
                .font(documentStyle.bodyFont(size: fontSize))
                .foregroundColor(textColor)
                .multilineTextAlignment(alignment)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, documentStyle.sectionPadding)
    }
    
    private func numberedPointView(text: String, number: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(documentStyle.bodyFont(size: fontSize))
                .foregroundColor(textColor)
                .frame(width: 24, alignment: .trailing)
            
            Text(text)
                .font(documentStyle.bodyFont(size: fontSize))
                .foregroundColor(textColor)
                .multilineTextAlignment(alignment)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, documentStyle.sectionPadding)
    }
    
    private func headerView(text: String, level: Int) -> some View {
        let scale: CGFloat = switch level {
            case 1: 1.5
            case 2: 1.3
            case 3: 1.15
            case 4: 1.05
            default: 1.0
        }
        
        return Text(text)
            .font(documentStyle.headingFont(size: fontSize * scale, level: level))
            .foregroundColor(textColor)
            .multilineTextAlignment(alignment)
            .padding(.vertical, 4)
    }
    
    private func quoteView(text: String) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 3)
            
            Text(text)
                .font(documentStyle.bodyFont(size: fontSize))
                .italic()
                .foregroundColor(textColor.opacity(0.8))
                .multilineTextAlignment(alignment)
        }
        .padding(.vertical, 4)
    }
    
    private func enhancedLinkView(text: String, url: URL) -> some View {
        Link(destination: url) {
            Text(text)
                .font(documentStyle.bodyFont(size: fontSize))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(documentStyle.linkColor(isDarkMode: textColor == .white))
                .cornerRadius(4)
                .multilineTextAlignment(alignment)
        }
    }
    
    private func imageView(url: URL, alt: String) -> some View {
        VStack(alignment: alignment == .leading ? .leading : alignment == .trailing ? .trailing : .center, spacing: 4) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 120)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(4)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .frame(height: 120)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: 320)
            
            if !alt.isEmpty {
                Text(alt)
                    .font(documentStyle.bodyFont(size: fontSize - 2))
                    .foregroundColor(textColor.opacity(0.7))
                    .italic()
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Code Block View
    private func codeBlockView(text: String, language: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            codeBlockHeaderView(text: text, language: language)
            codeBlockContentView(text: text, language: language)
        }
        .foregroundColor(textColor)
        .background(documentStyle.codeBlockBackgroundColor(isDarkMode: textColor == .white))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.vertical, 8)
    }
    
    private func codeBlockHeaderView(text: String, language: String) -> some View {
        HStack {
            if !language.isEmpty {
                Text(language)
                    .font(.system(size: fontSize - 3, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            } else {
                Text("code")
                    .font(.system(size: fontSize - 3, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
            
            Spacer()
            
            // Copy button with hover effect
            CopyButton(text: text)
        }
        .background(Color.black.opacity(0.15))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private func codeBlockContentView(text: String, language: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                codeLineNumbersView(text: text)
                
                // Code text with syntax highlighting
                SyntaxHighlightedText(
                    code: text,
                    language: language,
                    fontSize: fontSize,
                    textColor: textColor,
                    font: documentStyle.codeFont(size: fontSize)
                )
                .padding(12)
                .padding(.leading, 4)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func codeLineNumbersView(text: String) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(Array(text.components(separatedBy: "\n").indices), id: \.self) { index in
                Text("\(index + 1)")
                    .font(.system(size: fontSize - 2, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
                    .frame(width: 30, alignment: .trailing)
                    .padding(.vertical, 1.5)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 12)
        .padding(.horizontal, 8)
        .background(Color.black.opacity(0.1))
    }
    
    // MARK: - Copy Button Component
    private struct CopyButton: View {
        let text: String
        @State private var isCopied = false
        @State private var isHovering = false
        
        var body: some View {
            Button(action: {
                copyToClipboard(text)
                withAnimation {
                    isCopied = true
                }
                // Reset copied state after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isCopied = false
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                    
                    if isHovering || isCopied {
                        Text(isCopied ? "Copied!" : "Copy")
                            .font(.system(size: 12, design: .monospaced))
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isCopied ? Color.green.opacity(0.2) : (isHovering ? Color.secondary.opacity(0.15) : Color.clear))
                )
                .foregroundColor(isCopied ? .green : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            .padding(.trailing, 8)
        }
        
        private func copyToClipboard(_ text: String) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([text as NSString])
        }
    }
    
    private func taskListItemView(text: String, isChecked: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .foregroundColor(isChecked ? .green : .gray)
                .font(.system(size: fontSize))
            
            Text(text)
                .font(documentStyle.bodyFont(size: fontSize))
                .foregroundColor(textColor)
                .strikethrough(isChecked)
                .multilineTextAlignment(alignment)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, documentStyle.sectionPadding)
    }
    
    private func thinkContentView(content: String, text: String) -> some View {
        CollapsibleThinkView(
            content: content,
            fontSize: fontSize, textColor: textColor,
        )
    }
}


struct CollapsibleThinkView: View {
    let content: String
    var fontSize: CGFloat = 16
    var textColor: Color = .primary
    
    @State private var isExpanded: Bool = false
    @State private var isHovering: Bool = false
    private let animationDuration: Double = 0.25
    var body: some View {
        VStack(spacing: 0) {

HStack{
    Text("Thinking")
    // .font(documentStyle.bodyFont(size: fontSize))
    .foregroundColor(textColor)

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
.padding(.horizontal, 8)

    VStack{
        Text(content)
        // .font(documentStyle.bodyFont(size: fontSize))
        .foregroundColor(textColor)
        .lineLimit(isExpanded ? nil : 2)
    }   
    .padding(.vertical, 8)
        .padding(.horizontal, 2)
        } 
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .border(Color.white.opacity(0.1), width: 1)
        .cornerRadius(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.03))
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
    }
}

// MARK: - Text Formatter
public struct TextFormatter {
    public struct TextComponent {
        public enum ComponentType {
            case plainText
            case boldText
            case italicText
            case codeText
            case bulletPoint
            case numberedPoint(number: Int)
            case header(level: Int)
            case quote
            case link(url: URL)
            case image(url: URL, alt: String)
            case horizontalRule
            case codeBlock(language: String)
            case taskList(checked: Bool)
            case thinkContent(content: String)
        }
        
        public let text: String
        public let type: ComponentType
        
        public init(text: String, type: ComponentType) {
            self.text = text
            self.type = type
        }
    }
    
    public static func parse(_ text: String) -> [TextComponent] {
        // Replace /n with actual newlines
        var formattedText = text.replacingOccurrences(of: "/n", with: "\n")
        
        // Split the text by newlines
        let lines = formattedText.components(separatedBy: "\n")
        
        var components: [TextComponent] = []
        var numberedListCounter = 0
        var inCodeBlock = false
        var codeBlockLanguage = ""
        var codeBlockContent = ""
        var inThinkBlock = false
        var thinkContent = ""
        
        // Define a regex pattern for <think> and </think> tags
        let openTagPattern = "<think>"
        let closeTagPattern = "</think>"
        
        // Process each line
        for (index, line) in lines.enumerated() {
            // Check for think block start
            if line.contains(openTagPattern) && !inThinkBlock {
                inThinkBlock = true
                
                // Handle text before the <think> tag on the same line
                if let range = line.range(of: openTagPattern) {
                    let beforeTag = line[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
                    if !beforeTag.isEmpty {
                        // Process text before the tag as normal content
                        components.append(TextComponent(text: beforeTag, type: .plainText))
                    }
                    
                    // Extract content after the <think> tag on the same line
                    let afterTag = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    if !afterTag.isEmpty {
                        thinkContent = afterTag
                    }
                }
                continue
            } 
            // Check for think block end
            else if line.contains(closeTagPattern) && inThinkBlock {
                // Extract content before the </think> tag on the same line
                if let range = line.range(of: closeTagPattern) {
                    let beforeTag = line[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
                    if !beforeTag.isEmpty {
                        if !thinkContent.isEmpty {
                            thinkContent += "\n" + beforeTag
                        } else {
                            thinkContent = beforeTag
                        }
                    }
                    
                    // Process text after the </think> tag as normal content
                    let afterTag = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    if !afterTag.isEmpty {
                        // Save the current think block
                        if !thinkContent.isEmpty {
                            components.append(TextComponent(text: thinkContent, type: .thinkContent(content: thinkContent)))
                        }
                        
                        // Reset think content and state
                        inThinkBlock = false
                        thinkContent = ""
                        
                        // Process the rest of the line as normal content
                        components.append(TextComponent(text: afterTag, type: .plainText))
                        continue
                    }
                }
                
                // Add the think block content
                if !thinkContent.isEmpty {
                    components.append(TextComponent(text: thinkContent, type: .thinkContent(content: thinkContent)))
                }
                
                // Reset think content and state
                inThinkBlock = false
                thinkContent = ""
                continue
            } 
            // Accumulate think block content
            else if inThinkBlock {
                if !thinkContent.isEmpty {
                    thinkContent += "\n" + line
                } else {
                    thinkContent = line
                }
                continue
            }
            
            // Check for code block start/end
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    components.append(TextComponent(text: codeBlockContent, type: .codeBlock(language: codeBlockLanguage)))
                    inCodeBlock = false
                    codeBlockContent = ""
                    codeBlockLanguage = ""
                    continue
                } else {
                    // Start code block
                    inCodeBlock = true
                    // Get language if specified
                    if line.count > 3 {
                        codeBlockLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    }
                    continue
                }
            }
            
            if inCodeBlock {
                if !codeBlockContent.isEmpty {
                    codeBlockContent += "\n"
                }
                codeBlockContent += line
                continue
            }
            
            // Rest of the parsing logic for other markdown elements
            // ... existing code for parsing other elements ...
            
            if line.isEmpty {
                // Add empty line
                components.append(TextComponent(text: " ", type: .plainText))
                continue
            }
            
            // Check for horizontal rule
            if line.matches(pattern: "^-{3,}$") || line.matches(pattern: "^\\*{3,}$") {
                components.append(TextComponent(text: "", type: .horizontalRule))
                continue
            }
            
            // Check for task list
            if line.matches(pattern: "^\\s*- \\[[ x]\\]\\s+") {
                let isChecked = line.contains("- [x]")
                if let range = line.range(of: "^\\s*- \\[[ x]\\]\\s+", options: .regularExpression) {
                    let taskText = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    components.append(TextComponent(text: taskText, type: .taskList(checked: isChecked)))
                    continue
                }
            }
            
            // Check for headers (supports multiple levels #, ##, ###)
            if line.hasPrefix("#") {
                var level = 0
                var headerText = line
                
                // Count the number of # at the beginning
                while headerText.hasPrefix("#") && level < 6 {
                    level += 1
                    headerText.removeFirst()
                }
                
                // Get the header text and trim whitespace
                headerText = headerText.trimmingCharacters(in: .whitespaces)
                components.append(TextComponent(text: headerText, type: .header(level: level)))
                continue
            }
            
            // Check for blockquotes
            if line.hasPrefix(">") {
                let quoteText = line.dropFirst().trimmingCharacters(in: .whitespaces)
                components.append(TextComponent(text: quoteText, type: .quote))
                continue
            }
            
            // Check for bullet points
            if line.matches(pattern: "^[\\*\\-\\+]\\s+") {
                // Reset numbered list counter
                numberedListCounter = 0
                
                // Extract bullet text (after *, -, or + and whitespace)
                if let range = line.range(of: #"^[\*\-\+]\s+"#, options: .regularExpression) {
                    let bulletText = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    components.append(TextComponent(text: bulletText, type: .bulletPoint))
                    continue
                }
            }
            
            // Check for numbered list
            if line.matches(pattern: "^\\d+\\.\\s+") {
                // Extract the number and text
                if let range = line.range(of: #"^\d+\.\s+"#, options: .regularExpression),
                   let numberString = line.prefix(upTo: range.lowerBound).last,
                   let number = Int(String(numberString)) {
                    let listText = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    numberedListCounter = number
                    components.append(TextComponent(text: listText, type: .numberedPoint(number: number)))
                    continue
                } else {
                    // If the number can't be parsed, increment the counter
                    numberedListCounter += 1
                    if let range = line.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                        let listText = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
                        components.append(TextComponent(text: listText, type: .numberedPoint(number: numberedListCounter)))
                        continue
                    }
                }
            }
            
            // Process formatting within the line
            var currentIndex = line.startIndex
            var currentText = ""
            var inBold = false
            var inItalic = false
            var inCode = false
            var inLink = false
            var linkText = ""
            
            while currentIndex < line.endIndex {
                let char = line[currentIndex]
                let nextIndex = line.index(after: currentIndex)
                
                // Check for image ![alt](url)
                if char == "!" && nextIndex < line.endIndex && line[nextIndex] == "[" {
                    // Start of image alt text
                    if !currentText.isEmpty {
                        components.append(TextComponent(text: currentText, type: .plainText))
                        currentText = ""
                    }
                    
                    // Skip the "!["
                    let altStartIndex = line.index(nextIndex, offsetBy: 1)
                    if let altEndIndex = line[altStartIndex...].firstIndex(of: "]"),
                       altEndIndex < line.endIndex,
                       let urlStartDelimiter = line[altEndIndex...].firstIndex(of: "("),
                       urlStartDelimiter < line.endIndex {
                        
                        let altText = String(line[altStartIndex..<altEndIndex])
                        let urlStartIndex = line.index(after: urlStartDelimiter)
                        
                        if let urlEndIndex = line[urlStartIndex...].firstIndex(of: ")") {
                            let urlString = String(line[urlStartIndex..<urlEndIndex])
                            if let url = URL(string: urlString) {
                                components.append(TextComponent(text: altText, type: .image(url: url, alt: altText)))
                            } else {
                                components.append(TextComponent(text: "![" + altText + "](" + urlString + ")", type: .plainText))
                            }
                            currentIndex = line.index(after: urlEndIndex)
                            continue
                        }
                    }
                }
                
                // Check for bold (**text**)
                if char == "*" && nextIndex < line.endIndex && line[nextIndex] == "*" {
                    if inBold {
                        // End of bold text
                        if !currentText.isEmpty {
                            components.append(TextComponent(text: currentText, type: .boldText))
                            currentText = ""
                        }
                        inBold = false
                        currentIndex = line.index(currentIndex, offsetBy: 2)
                        if currentIndex >= line.endIndex { break }
                    } else {
                        // Start of bold text
                        if !currentText.isEmpty {
                            components.append(TextComponent(text: currentText, type: .plainText))
                            currentText = ""
                        }
                        inBold = true
                        currentIndex = line.index(currentIndex, offsetBy: 2)
                        if currentIndex >= line.endIndex { break }
                    }
                    continue
                }
                
                // Check for italic (_text_)
                if char == "_" {
                    if inItalic {
                        // End of italic text
                        if !currentText.isEmpty {
                            components.append(TextComponent(text: currentText, type: .italicText))
                            currentText = ""
                        }
                        inItalic = false
                    } else {
                        // Start of italic text
                        if !currentText.isEmpty {
                            components.append(TextComponent(text: currentText, type: .plainText))
                            currentText = ""
                        }
                        inItalic = true
                    }
                    currentIndex = nextIndex
                    continue
                }
                
                // Check for code (`text`)
                if char == "`" {
                    if inCode {
                        // End of code text
                        if !currentText.isEmpty {
                            components.append(TextComponent(text: currentText, type: .codeText))
                            currentText = ""
                        }
                        inCode = false
                    } else {
                        // Start of code text
                        if !currentText.isEmpty {
                            components.append(TextComponent(text: currentText, type: .plainText))
                            currentText = ""
                        }
                        inCode = true
                    }
                    currentIndex = nextIndex
                    continue
                }
                
                // Check for links [text](url)
                if char == "[" && !inLink && !inBold && !inItalic && !inCode {
                    // Start of link text
                    if !currentText.isEmpty {
                        components.append(TextComponent(text: currentText, type: .plainText))
                        currentText = ""
                    }
                    inLink = true
                    linkText = ""
                    currentIndex = nextIndex
                    continue
                } else if char == "]" && inLink && nextIndex < line.endIndex && line[nextIndex] == "(" {
                    // End of link text, start of URL
                    let urlStartIndex = line.index(nextIndex, offsetBy: 1)
                    if let urlEndIndex = line[urlStartIndex...].firstIndex(of: ")") {
                        let urlString = String(line[urlStartIndex..<urlEndIndex])
                        if let url = URL(string: urlString) {
                            components.append(TextComponent(text: linkText, type: .link(url: url)))
                        } else {
                            components.append(TextComponent(text: linkText, type: .plainText))
                        }
                        inLink = false
                        linkText = ""
                        currentText = ""
                        currentIndex = line.index(after: urlEndIndex)
                        continue
                    }
                } else if inLink {
                    // Add to link text
                    linkText.append(char)
                    currentIndex = nextIndex
                    continue
                }
                
                // Add the character to current text
                currentText.append(char)
                currentIndex = nextIndex
            }
            
            // Add any remaining text
            if !currentText.isEmpty {
                let type: TextComponent.ComponentType
                if inBold {
                    type = .boldText
                } else if inItalic {
                    type = .italicText
                } else if inCode {
                    type = .codeText
                } else {
                    type = .plainText
                }
                
                components.append(TextComponent(text: currentText, type: type))
            }
        }
        
        // Handle any unclosed code block
        if inCodeBlock && !codeBlockContent.isEmpty {
            components.append(TextComponent(text: codeBlockContent, type: .codeBlock(language: codeBlockLanguage)))
        }
        
        return components
    }
}

// MARK: - String Extensions
extension String {
    func matches(pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(self.startIndex..., in: self)
        return regex.firstMatch(in: self, range: range) != nil
    }
}

extension String {
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch {
            return []
        }
    }
}


// MARK: - Code Syntax Highlighting
private struct SyntaxHighlightedText: View {
    let code: String
    let language: String
    let fontSize: CGFloat
    let textColor: Color
    let font: Font
    
    var body: some View {
        if language.isEmpty || !supportedLanguages.contains(language.lowercased()) {
            Text(code)
                .font(font)
                .foregroundColor(textColor)
        } else {
            highlightedText
        }
    }
    
    private var highlightedText: some View {
        let lines = code.components(separatedBy: "\n")
        
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(lines.indices, id: \.self) { index in
                highlightLine(lines[index])
                    .padding(.vertical, 0.5)
                if index < lines.count - 1 {
                    Spacer().frame(height: 0)
                }
            }
        }
    }
    
    private func highlightLine(_ line: String) -> some View {
        let components = tokenize(line)
        
        return HStack(spacing: 0) {
            ForEach(components.indices, id: \.self) { index in
                let (text, type) = components[index]
                Text(text)
                    .font(font)
                    .foregroundColor(colorForTokenType(type))
            }
        }
    }
    
    private func tokenize(_ line: String) -> [(String, TokenType)] {
        var result: [(String, TokenType)] = []
        
        // Very basic tokenization - this can be expanded for better highlighting
        let keywordPattern = "\\b(func|let|var|return|if|else|guard|switch|case|for|while|in|self|class|struct|enum|protocol|extension|import|public|private|internal|static|override)\\b"
        let stringPattern = "\"[^\"]*\""
        let commentPattern = "\\/\\/.*$"
        let numberPattern = "\\b\\d+\\.?\\d*\\b"
        
        // Split by different token types
        if line.matches(pattern: commentPattern) {
            result.append((line, .comment))
            return result
        }
        
        var remaining = line
        
        // Extract strings
        while let stringRange = remaining.range(of: stringPattern, options: .regularExpression) {
            let before = String(remaining[..<stringRange.lowerBound])
            if !before.isEmpty {
                result.append(contentsOf: processRemainingText(before))
            }
            
            let stringValue = String(remaining[stringRange])
            result.append((stringValue, .string))
            
            if stringRange.upperBound >= remaining.endIndex {
                remaining = ""
                break
            }
            
            remaining = String(remaining[stringRange.upperBound...])
        }
        
        // Process any remaining text
        if !remaining.isEmpty {
            result.append(contentsOf: processRemainingText(remaining))
        }
        
        return result
    }
    
    private func processRemainingText(_ text: String) -> [(String, TokenType)] {
        var result: [(String, TokenType)] = []
        let keywordPattern = "\\b(func|let|var|return|if|else|guard|switch|case|for|while|in|self|class|struct|enum|protocol|extension|import|public|private|internal|static|override)\\b"
        let numberPattern = "\\b\\d+\\.?\\d*\\b"
        
        var remaining = text
        
        // Extract keywords
        while let keywordRange = remaining.range(of: keywordPattern, options: .regularExpression) {
            let before = String(remaining[..<keywordRange.lowerBound])
            if !before.isEmpty {
                result.append((before, .plain))
            }
            
            let keyword = String(remaining[keywordRange])
            result.append((keyword, .keyword))
            
            if keywordRange.upperBound >= remaining.endIndex {
                remaining = ""
                break
            }
            
            remaining = String(remaining[keywordRange.upperBound...])
        }
        
        // Any final remaining text
        if !remaining.isEmpty {
            var finalRemaining = remaining
            
            // Look for numbers in the final remaining text
            while let numberRange = finalRemaining.range(of: numberPattern, options: .regularExpression) {
                let before = String(finalRemaining[..<numberRange.lowerBound])
                if !before.isEmpty {
                    result.append((before, .plain))
                }
                
                let number = String(finalRemaining[numberRange])
                result.append((number, .number))
                
                if numberRange.upperBound >= finalRemaining.endIndex {
                    finalRemaining = ""
                    break
                }
                
                finalRemaining = String(finalRemaining[numberRange.upperBound...])
            }
            
            if !finalRemaining.isEmpty {
                result.append((finalRemaining, .plain))
            }
        }
        
        return result
    }
    
    private func colorForTokenType(_ type: TokenType) -> Color {
        switch type {
        case .keyword:
            return Color.pink.opacity(0.8)
        case .string:
            return Color.green.opacity(0.8)
        case .comment:
            return Color.gray.opacity(0.7)
        case .number:
            return Color.blue.opacity(0.8)
        case .plain:
            return textColor
        }
    }
    
    private enum TokenType {
        case keyword
        case string
        case comment
        case number
        case plain
    }
    
    private let supportedLanguages = ["swift", "javascript", "typescript", "python", "java", "c", "cpp", "csharp", "go", "rust", "ruby", "php"]
}

