import SwiftUI

struct HistoryView: View {
    var body: some View {
  VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 64))
                .foregroundColor(.purple)
            
            Text("History")
                .font(.title)
                .fontWeight(.bold)
            
            Text("History functionality - Coming Soon!")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}