import SwiftUI

// Extension to convert Color to hex string
extension Color {
    func toHex() -> String? {
        let uiColor = NSColor(self)
        guard let components = uiColor.cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

// Enum for text formatting actions
enum TextAction {
    case bold, italic, underline, strikethrough, bullet, checkbox, increaseIndent, decreaseIndent
    case heading(level: Int)
    case fontSize(size: CGFloat)
    case fontColor(color: Color)
    case alignment(alignment: TextAlignment)
}

struct NotePadTextEditorView: View {
    @ObservedObject var noteStore: NoteStore
    @State private var text: String = ""
    @State private var showColorPicker: Bool = false
    @State private var showFontPicker: Bool = false
    @FocusState private var isFocused: Bool
    @State private var selectedColor: Color = .white
    @State private var fontSize: CGFloat = 14
    @State private var title: String = ""
    @Binding var isNoteIcon: Bool
    @State private var selectedTextRange: NSRange?
    @State private var textAlignment: TextAlignment = .leading
    @State private var processedText: AttributedString = AttributedString("")
    @State private var useRichText: Bool = false
    
    private let fontSizes: [CGFloat] = [12, 14, 16, 18, 20, 24]
    
    // Colors for the rich text editor
    private let colorPalette: [Color] = [
        .white, .black, .red, .orange, .yellow, .green, .blue, .purple, .pink
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title
            HStack {
                TextField("Note Title", text: $title)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .onChange(of: title) { newValue in
                        if let id = noteStore.currentNote?.id {
                            noteStore.updateNote(Note(
                                id: id,
                                title: newValue,
                                content: noteStore.currentNote?.content ?? "",
                                category: noteStore.currentNote?.category ?? .uncategorized
                            ))
                        }
                    }
                
                Spacer()
                
                Button(action: {
                    isNoteIcon = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.05))
            
            Divider()
            
            // Primary formatting toolbar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    // Text style
                    FormatButton(
                        icon: "bold",
                        isActive: noteStore.textFormatting.isBold,
                        action: { noteStore.applyBold() }
                    )
                    
                    FormatButton(
                        icon: "italic",
                        isActive: noteStore.textFormatting.isItalic,
                        action: { noteStore.applyItalic() }
                    )
                    
                    FormatButton(
                        icon: "underline",
                        isActive: noteStore.textFormatting.isUnderlined,
                        action: { noteStore.applyUnderline() }
                    )
                    
                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, 4)
                    
                    // Text alignment
                    Group {
                        FormatButton(
                            icon: "text.alignleft",
                            isActive: textAlignment == .leading,
                            action: { textAlignment = .leading }
                        )
                        
                        FormatButton(
                            icon: "text.aligncenter",
                            isActive: textAlignment == .center,
                            action: { textAlignment = .center }
                        )
                        
                        FormatButton(
                            icon: "text.alignright",
                            isActive: textAlignment == .trailing,
                            action: { textAlignment = .trailing }
                        )
                    }
                    
                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, 4)
                    
                    // Lists
                    Group {
                        FormatButton(
                            icon: "list.bullet",
                            isActive: false,
                            action: { insertBulletPoint() }
                        )
                        
                        FormatButton(
                            icon: "checklist",
                            isActive: false,
                            action: { insertCheckbox() }
                        )
                        
                        FormatButton(
                            icon: "increase.indent",
                            isActive: false,
                            action: { increaseIndent() }
                        )
                        
                        FormatButton(
                            icon: "decrease.indent",
                            isActive: false,
                            action: { decreaseIndent() }
                        )
                    }
                    
                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal, 4)
                    
                    // Font size
                    Menu {
                        ForEach(fontSizes, id: \.self) { size in
                            Button(action: {
                                fontSize = size
                                noteStore.changeFontSize(Int(size))
                            }) {
                                Text("\(Int(size))")
                                    .font(.system(size: size))
                            }
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Text("\(Int(fontSize))")
                                .font(.system(size: 12))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    // Color picker button
                    Button(action: {
                        showColorPicker.toggle()
                    }) {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 18, height: 18)
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .popover(isPresented: $showColorPicker) {
                        VStack(spacing: 12) {
                            Text("Text Color")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 30))], spacing: 8) {
                                ForEach(colorPalette, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 24, height: 24)
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                        .onTapGesture {
                                            selectedColor = color
                                            if let hexColor = color.toHex() {
                                                noteStore.changeFontColor(hexColor)
                                            }
                                            showColorPicker = false
                                        }
                                }
                            }
                            .padding()
                        }
                        .frame(width: 200)
                        .padding(.bottom, 8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.gray.opacity(0.05))
            
            Divider()
            
            // Add a toggle for rich text mode
            HStack {
                Spacer()
                
                Toggle("Rich Text", isOn: $useRichText)
                    .toggleStyle(SwitchToggleStyle())
                    .padding(.horizontal)
                    .onChange(of: useRichText) { newValue in
                        if newValue {
                            processedText = processTextWithMarkdown(text)
                        }
                    }
            }
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.05))
            
            Divider()
            
            // Text editor
            ZStack(alignment: .topLeading) {
                if useRichText {
                    // Rich text view
                    Text(processedText)
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding()
                } else {
                    // Plain text editor
                    TextEditor(text: $text)
                        .font(.system(size: fontSize, weight: noteStore.textFormatting.isBold ? .bold : .regular, design: .default))
                        .foregroundColor(selectedColor)
                        .padding(10)
                        .focused($isFocused)
                        .multilineTextAlignment(textAlignment)
                        .scrollContentBackground(.hidden)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding()
                        .onChange(of: text) { newValue in
                            if let id = noteStore.currentNote?.id {
                                noteStore.updateNote(Note(
                                    id: id,
                                    title: noteStore.currentNote?.title ?? "",
                                    content: newValue,
                                    category: noteStore.currentNote?.category ?? .uncategorized
                                ))
                            }
                            
                            if useRichText {
                                processedText = processTextWithMarkdown(newValue)
                            }
                        }
                        .onTapGesture { location in
                            handleTextEditorTap(at: location)
                        }
                }
                
                // Placeholder text if empty
                if text.isEmpty && !useRichText {
                    Text("Start typing your note...")
                        .font(.system(size: fontSize))
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.horizontal, 26)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                text = noteStore.currentNote?.content ?? ""
                title = noteStore.currentNote?.title ?? ""
                
                // Set initial formatting values
                fontSize = CGFloat(noteStore.textFormatting.fontSize)
                selectedColor = Color(hex: noteStore.textFormatting.fontColor)
            }
            
            // Status bar
            HStack {
                Text("\(text.count) characters")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("Last edited: \(dateFormatter.string(from: noteStore.currentNote?.lastModified ?? Date()))")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.05))
        }
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isFocused = true
            }
        }
        // Add keyboard shortcuts
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Group {
                    Button(action: { noteStore.applyBold() }) {
                        Image(systemName: "bold")
                    }
                    .keyboardShortcut("b", modifiers: .command)
                    
                    Button(action: { noteStore.applyItalic() }) {
                        Image(systemName: "italic")
                    }
                    .keyboardShortcut("i", modifiers: .command)
                    
                    Button(action: { noteStore.applyUnderline() }) {
                        Image(systemName: "underline")
                    }
                    .keyboardShortcut("u", modifiers: .command)
                    
                    Button(action: { insertBulletPoint() }) {
                        Image(systemName: "list.bullet")
                    }
                    .keyboardShortcut("l", modifiers: .command)
                    
                    Button(action: { insertCheckbox() }) {
                        Image(systemName: "checklist")
                    }
                    .keyboardShortcut("k", modifiers: .command)
                }
            }
        }
    }
    
    // Helper methods for rich text editing
    private func insertBulletPoint() {
        let bulletPoint = "• "
        insertAtCursorOrNewLine(bulletPoint)
    }
    
    private func insertCheckbox() {
        let checkbox = "☐ "
        insertAtCursorOrNewLine(checkbox)
    }
    
    private func increaseIndent() {
        let currentLines = text.split(separator: "\n")
        let indentedLines = currentLines.map { "    \($0)" }
        text = indentedLines.joined(separator: "\n")
    }
    
    private func decreaseIndent() {
        let currentLines = text.split(separator: "\n")
        let unindentedLines = currentLines.map { line -> String in
            if line.hasPrefix("    ") {
                return String(line.dropFirst(4))
            } else if line.hasPrefix("\t") {
                return String(line.dropFirst(1))
            }
            return String(line)
        }
        text = unindentedLines.joined(separator: "\n")
    }
    
    private func insertAtCursorOrNewLine(_ insertion: String) {
        // For now, just append to the end or start a new line
        if text.isEmpty {
            text = insertion
        } else if text.hasSuffix("\n") {
            text.append(insertion)
        } else {
            text.append("\n\(insertion)")
        }
    }
    
    // Toggle checkbox state in the text
    private func toggleCheckbox(at lineIndex: Int) {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        guard lineIndex < lines.count else { return }
        
        var updatedLines = [String]()
        
        for (index, line) in lines.enumerated() {
            if index == lineIndex {
                let lineStr = String(line)
                if lineStr.hasPrefix("☐ ") {
                    updatedLines.append(lineStr.replacingOccurrences(of: "☐ ", with: "☑ "))
                } else if lineStr.hasPrefix("☑ ") {
                    updatedLines.append(lineStr.replacingOccurrences(of: "☑ ", with: "☐ "))
                } else {
                    updatedLines.append(lineStr)
                }
            } else {
                updatedLines.append(String(line))
            }
        }
        
        text = updatedLines.joined(separator: "\n")
    }
    
    // Date formatter for last edited date
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private func handleTextEditorTap(at location: CGPoint) {
        // This is a simplified implementation since we can't directly get the text position from a location
        // In a real implementation, you would need to use NSTextView's hit testing capabilities
        
        // For now, we'll use a workaround:
        // 1. Get the current text and split it into lines
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        
        // 2. Calculate approximate line height
        let lineHeight = fontSize * 1.5
        
        // 3. Estimate which line was tapped based on vertical position
        // Adjust these values based on your UI layout
        let verticalOffset = 10.0 // Padding top in the TextEditor
        let estimatedLineIndex = Int((location.y - verticalOffset) / lineHeight)
        
        // 4. Check if the line has a checkbox and if the tap was in the checkbox area
        if estimatedLineIndex >= 0 && estimatedLineIndex < lines.count {
            let line = String(lines[estimatedLineIndex])
            if (line.hasPrefix("☐ ") || line.hasPrefix("☑ ")) && location.x < 30 {
                // Toggle the checkbox
                toggleCheckbox(at: estimatedLineIndex)
            }
        }
    }
    
    // Process text with basic markdown-like formatting
    private func processTextWithMarkdown(_ input: String) -> AttributedString {
        var attributedString = AttributedString(input)
        
        // Process the text line by line
        let lines = input.split(separator: "\n", omittingEmptySubsequences: false)
        var currentPosition = 0
        
        for line in lines {
            let lineString = String(line)
            let lineLength = lineString.count
            
            // Process headings (# Heading)
            if lineString.hasPrefix("# ") {
                let headingRange = NSRange(location: currentPosition + 2, length: lineLength - 2)
                if let range = Range(headingRange, in: attributedString) {
                    attributedString[range].font = .system(size: fontSize * 1.5, weight: .bold)
                }
            } else if lineString.hasPrefix("## ") {
                let headingRange = NSRange(location: currentPosition + 3, length: lineLength - 3)
                if let range = Range(headingRange, in: attributedString) {
                    attributedString[range].font = .system(size: fontSize * 1.3, weight: .bold)
                }
            }
            
            // Process bold text (**bold**)
            var boldRanges = findPatternRanges(in: lineString, pattern: "\\*\\*(.*?)\\*\\*")
            for range in boldRanges {
                // Adjust range to exclude the ** markers
                let contentRange = NSRange(location: currentPosition + range.location + 2, length: range.length - 4)
                if let attrRange = Range(contentRange, in: attributedString) {
                    attributedString[attrRange].font = .system(size: fontSize, weight: .bold)
                }
            }
            
            // Process italic text (*italic*)
            var italicRanges = findPatternRanges(in: lineString, pattern: "\\*(.*?)\\*")
            for range in italicRanges {
                // Adjust range to exclude the * markers
                let contentRange = NSRange(location: currentPosition + range.location + 1, length: range.length - 2)
                if let attrRange = Range(contentRange, in: attributedString) {
                    attributedString[attrRange].font = .system(size: fontSize, weight: .regular, design: .default).italic()
                }
            }
            
            // Process checkboxes
            if lineString.hasPrefix("☑ ") {
                let checkboxRange = NSRange(location: currentPosition, length: 2)
                if let range = Range(checkboxRange, in: attributedString) {
                    attributedString[range].foregroundColor = .green
                }
            } else if lineString.hasPrefix("☐ ") {
                let checkboxRange = NSRange(location: currentPosition, length: 2)
                if let range = Range(checkboxRange, in: attributedString) {
                    attributedString[range].foregroundColor = .gray
                }
            }
            
            // Process bullet points
            if lineString.hasPrefix("• ") {
                let bulletRange = NSRange(location: currentPosition, length: 2)
                if let range = Range(bulletRange, in: attributedString) {
                    attributedString[range].foregroundColor = .blue
                }
            }
            
            // Move to next line
            currentPosition += lineLength + 1 // +1 for the newline character
        }
        
        return attributedString
    }
    
    // Helper function to find pattern ranges
    private func findPatternRanges(in text: String, pattern: String) -> [NSRange] {
        var ranges = [NSRange]()
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                ranges.append(match.range)
            }
        } catch {
            print("Error creating regex: \(error)")
        }
        
        return ranges
    }
}

// Helper struct for formatting buttons
struct FormatButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isActive ? .accentColor : .primary)
                .frame(width: 32, height: 32)
                .background(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}

// Preview
#Preview {
    NotePadTextEditorView(noteStore: NoteStore(), isNoteIcon: .constant(true))
        .frame(width: 600, height: 400)
}
