import MarkdownUI
import SwiftUI


// MARK: - Documentation
/**
 # Rich Text Formatter
 
 A powerful text formatter for SwiftUI that uses MarkdownUI library for markdown-style formatting.
 
 ## Features
 - **Bold text** with double asterisks
 - _Italic text_ with underscores
 - `Code blocks` with backticks
 - Headers with # symbols (# ## ###)
 - Bullet lists (- * +) and numbered lists (1. 2.)
 - Block quotes (> text)
 - Horizontal rules (---)
 - Links ([text](url))
 - Images ![alt](url)
 - Tables and task lists
 - Line breaks (/n)
 
 ## Usage
 ```swift
 FormattedTextView("**Hello World**")
 ```
 
 ## Configuration
 You can customize font size, text color, alignment, and document style:
 ```swift
 FormattedTextView(
     text,
     fontSize: 16,
     textColor: .primary,
     alignment: .leading,
     lineSpacing: 6,
     documentStyle: .github
 )
 ```
 */

// MARK: - Formatted Text View
/// A view that renders formatted text with markdown-style syntax using MarkdownUI
/// - Supports full GitHub Flavored Markdown syntax
/// - Automatically converts /n to line breaks
/// - Allows customization of text appearance and themes
public struct FormattedTextView: View {
    private let text: String
    private let fontSize: CGFloat
    private let textColor: Color
    private let alignment: TextAlignment
    private let lineSpacing: CGFloat
    private let documentStyle: DocumentStyle

    /// Document styling options for the formatted text
    public enum DocumentStyle {
        /// Standard document with basic MarkdownUI theme
        case standard
        /// Academic paper style
        case academic
        /// Modern magazine style
        case magazine
        /// Technical documentation style
        case technical
        /// VS Code-inspired dark theme
        case vscodeDark
        /// VS Code-inspired light theme
        case vscodeLight
        /// GitHub-style theme
        case github
        /// Custom style with specified parameters
        case custom(primaryFont: Font, headerFont: Font, codeFont: Font)
        
        /// Returns the appropriate MarkdownUI theme
        var markdownTheme: Theme {
            switch self {
            case .github, .vscodeDark, .vscodeLight:
                return .gitHub
            default:
                return .basic
            }
        }
        
        /// Returns custom theme modifications
        func applyCustomizations(to view: some View, fontSize: CGFloat, textColor: Color) -> some View {
            let baseView = view
                // .markdownTextStyle {
                //     FontSize(.em(fontSize / 16.0))
                //     ForegroundColor(textColor)
                // }
            
            switch self {
            case .academic:
                return baseView
                    // .markdownTextStyle {
                    //     FontFamily(.serif)
                    // }
                    // .markdownHeadingStyle { configuration in
                    //     configuration.label
                    //         .font(.system(.body, design: .serif).bold())
                    // }
            case .magazine:
                return baseView
                    // .markdownTextStyle {
                    //     FontFamily(.rounded)
                    //     FontWeight(.light)
                    // }
                    // .markdownHeadingStyle { configuration in
                    //     configuration.label
                    //         .font(.system(.body, design: .rounded).heavy())
                    // }
            case .technical:
                return baseView
                    // .markdownTextStyle {
                    //     FontFamily(.monospaced)
                    // }
                    // .markdownCodeStyle {
                    //     FontFamily(.monospaced)
                    //     FontWeight(.regular)
                    // }
            case .vscodeDark:
                return baseView
                    // .markdownTextStyle {
                    //     FontFamily(.monospaced)
                    // }
                    // .markdownCodeStyle {
                    //     FontFamily(.monospaced)
                    //     BackgroundColor(Color(red: 0.16, green: 0.16, blue: 0.16))
                    //     ForegroundColor(.white)
                    // }
                    // .markdownBlockStyle(\.codeBlock) { configuration in
                    //     configuration.label
                    //         .padding()
                    //         .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                    //         .cornerRadius(8)
                    // }
            case .vscodeLight:
                return baseView
                    // .markdownTextStyle {
                    //     FontFamily(.monospaced)
                    // }
                    // .markdownCodeStyle {
                    //     FontFamily(.monospaced)
                    //     BackgroundColor(Color(red: 0.95, green: 0.95, blue: 0.95))
                    //     ForegroundColor(.black)
                    // }
                    // .markdownBlockStyle(\.codeBlock) { configuration in
                    //     configuration.label
                    //         .padding()
                    //         .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                    //         .cornerRadius(8)
                    // }
            case .custom(let primaryFont, let headerFont, _):
                return baseView
                    // .markdownHeadingStyle { configuration in
                    //     configuration.label
                    //         .font(headerFont)
                    // }
            default:
                return baseView
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
        let markdownView = Markdown(processedText)
            .markdownTheme(documentStyle.markdownTheme)
        
        documentStyle.applyCustomizations(to: markdownView, fontSize: fontSize, textColor: textColor)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
            .multilineTextAlignment(alignment)
    }
    
    private var processedText: String {
        // Convert /n to actual newlines for compatibility with existing code
        return text.replacingOccurrences(of: "/n", with: "\n")
    }
    
    private var frameAlignment: Alignment {
        switch alignment {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        case .center:
            return .center
        @unknown default:
            return .leading
        }
    }
}

