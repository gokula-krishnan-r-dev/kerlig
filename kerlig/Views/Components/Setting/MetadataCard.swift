import SwiftUI


// MARK: - Metadata Card
struct MetadataCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.05))
        )
    }
}