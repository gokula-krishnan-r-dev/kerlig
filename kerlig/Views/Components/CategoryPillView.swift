import SwiftUI

struct CategoryPill: View {
    let category: NoteCategory?
    @Binding var selectedCategory: NoteCategory?
    @Environment(\.colorScheme) private var colorScheme
    
    private var isSelected: Bool {
        (category == nil && selectedCategory == nil) || category == selectedCategory
    }
    
    private var title: String {
        category?.rawValue ?? "All"
    }
    
    private var iconName: String {
        category?.iconName ?? "tray.full"
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
            }
        } label: {
            HStack {
                Image(systemName: iconName)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? (category?.color ?? Color.gray) : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct CategoryScrollView: View {
    @Binding var selectedCategory: NoteCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryPill(category: nil, selectedCategory: $selectedCategory)
                
                ForEach(NoteCategory.allCases) { category in
                    CategoryPill(category: category, selectedCategory: $selectedCategory)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }
}

