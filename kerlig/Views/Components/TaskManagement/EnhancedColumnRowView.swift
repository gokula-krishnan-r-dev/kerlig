import SwiftUI
struct EnhancedColumnRowView: View {
    let column: NoteColumn
    let taskCount: Int
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Column color indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(column.color ?? .gray)
                .frame(width: 6, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(column.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Order: \(column.order + 1)")
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.7))
            }
            
            Spacer()
            
            // Task count with progress indicator
            HStack(spacing: 6) {
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.8))
                
                Text("\(taskCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(taskCount > 0 ? (column.color ?? .gray).opacity(0.2) : Color.gray.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(taskCount > 0 ? (column.color ?? .gray).opacity(0.4) : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(hex: "#1C1C1E") : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? (column.color ?? .gray).opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}