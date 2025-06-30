import SwiftUI

struct ColumnRowView: View {
    let column: NoteColumn
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(column.color ?? .gray)
                .frame(width: 10, height: 10)
            
            Text(column.title)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text("\(column.noteIds.count)")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(hex: "#2C2C2E"))
                .cornerRadius(8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color(hex: "#1C1C1E") : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}