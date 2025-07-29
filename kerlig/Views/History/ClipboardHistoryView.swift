import SwiftUI

struct ClipboardHistoryView: View {
    var body: some View {
 VStack(spacing: 20) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("Clipboard History")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Clipboard history functionality - Coming Soon!")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}