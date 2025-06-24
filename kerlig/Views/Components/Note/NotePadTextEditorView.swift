import SwiftUI

struct NotePadTextEditorView: View {
    @ObservedObject var noteStore: NoteStore
    @State private var text: String = ""
    @State private var showColorPicker: Bool = false
    @State private var selectedColor: Color = .white
    @State private var fontSize: CGFloat = 14
    @State private var title: String = ""
    @Binding var isNoteIcon: Bool
    private let fontSizes: [CGFloat] = [12, 14, 16, 18, 20, 24]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Formatting toolbar
            HStack(spacing: 12) {
                // Bold button
                FormatButton(
                    icon: "bold",
                    isActive: noteStore.textFormatting.isBold,
                    action: { noteStore.applyBold() }
                )

                Spacer()

                //add close button 
                Button(action: {
                    isNoteIcon = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
              
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.05))
            
            // Text editor
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.system(size: fontSize, weight: noteStore.textFormatting.isBold ? .bold : .regular, design: .default))
                    .foregroundColor(Color(hex: noteStore.textFormatting.fontColor) ?? .black)
                    .padding(10)
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
                    }
                
                // Placeholder text if empty
                if text.isEmpty {
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
//                if let color = Color(hex: noteStore.textFormatting.fontColor) {
//                    selectedColor = color
//                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
    
    // Date formatter for last edited date
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
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
                .font(.system(size: 16))
                .foregroundColor(isActive ? .accentColor : .primary)
                .frame(width: 32, height: 32)
                .background(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

//// Extension to apply text styles
//extension View {
//    func italic(_ isItalic: Bool) -> some View {
//        if isItalic {
//            return self.italic()
//        }
//        return self
//    }
//    
//    func underlined(_ isUnderlined: Bool) -> some View {
//        self.underline(isUnderlined)
//    }
//}

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
