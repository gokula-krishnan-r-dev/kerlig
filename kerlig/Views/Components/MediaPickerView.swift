import SwiftUI
import AppKit

struct MediaPickerView: View {
    @Binding var mediaContent: MediaContent
    @State private var showingImagePicker = false
    @State private var showingEmojiPicker = false
    @State private var selectedEmoji = "😊"
    
    // Emoji categories for organized selection
    private let emojiCategories: [EmojiCategory] = [
        EmojiCategory(name: "Smileys", emojis: ["😊", "😂", "🥰", "😍", "🤔", "😅", "😇", "🙂", "😉", "😌", "😎", "🤗", "🤩", "🥳", "😋", "😛", "🤪", "😏", "😳", "😴"]),
        EmojiCategory(name: "Objects", emojis: ["📝", "📊", "📈", "📉", "🎯", "🔥", "💡", "⚡", "🔔", "📱", "💻", "🖥️", "⌚", "📷", "🎵", "🎨", "🛠️", "⚙️", "🔧", "🔨"]),
        EmojiCategory(name: "Nature", emojis: ["🌟", "⭐", "🌈", "🌸", "🌺", "🌻", "🌷", "🌹", "🍀", "🌿", "🌱", "🌳", "🌲", "🌴", "🌵", "🌾", "🌊", "🔥", "❄️", "☀️"]),
        EmojiCategory(name: "Food", emojis: ["🍎", "🍊", "🍋", "🍌", "🍇", "🍓", "🍑", "🍒", "🥝", "🍅", "🥑", "🌽", "🥕", "🥔", "🍞", "🧀", "🍕", "🍔", "🌮", "🍜"]),
        EmojiCategory(name: "Activities", emojis: ["🎮", "🎯", "🎲", "🎸", "🎤", "🎧", "🎬", "📚", "📖", "✏️", "🖊️", "📐", "📏", "🔍", "🔎", "💼", "🎒", "👑", "🏆", "🎖️"])
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            headerView
            
            if mediaContent.hasContent {
                currentMediaView
            } else {
                emptyStateView
            }
        }
        .sheet(isPresented: $showingEmojiPicker) {
            EmojiPickerSheet(
                selectedEmoji: $selectedEmoji,
                categories: emojiCategories,
                onEmojiSelected: { emoji in
                    setEmoji(emoji)
                    showingEmojiPicker = false
                }
            )
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Media (optional)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            
            Spacer()
            
            if mediaContent.hasContent {
                Button(action: clearMedia) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.8))
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var currentMediaView: some View {
        HStack(spacing: 12) {
            // Media preview
            Group {
                switch mediaContent.type {
                case .image:
                    if let imageData = mediaContent.imageData,
                       let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    }
                case .emoji:
                    Text(mediaContent.emoji ?? "😊")
                        .font(.system(size: 32))
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#2C2C2E"))
                        )
                case .none:
                    EmptyView()
                }
            }
            
            // Media info
            VStack(alignment: .leading, spacing: 4) {
                Text(mediaContent.displayText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                
                if let originalSize = mediaContent.originalSize {
                    Text(formatFileSize(originalSize))
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: showImagePicker) {
                    Image(systemName: "photo")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showingEmojiPicker = true }) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#2C2C2E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .onTapGesture {
            if mediaContent.type == .image {
                showImagePicker()
            } else if mediaContent.type == .emoji {
                showingEmojiPicker = true
            }
        }
    }
    
    private var emptyStateView: some View {
        HStack(spacing: 16) {
            Button(action: showImagePicker) {
                VStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                    Text("Image")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#2C2C2E"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { showingEmojiPicker = true }) {
                VStack(spacing: 6) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                    Text("Emoji")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#2C2C2E"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Actions
    
    private func showImagePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                processImage(from: url)
            }
        }
    }
    
    private func processImage(from url: URL) {
        guard let image = NSImage(contentsOf: url) else { return }
        
        // Optimize image before storing
        let optimizedImageData = optimizeImage(image)
        let fileName = url.lastPathComponent
        
        mediaContent = MediaContent(
            type: .image,
            imageData: optimizedImageData,
            fileName: fileName
        )
    }
    
    private func setEmoji(_ emoji: String) {
        mediaContent = MediaContent(
            type: .emoji,
            emoji: emoji
        )
    }
    
    private func clearMedia() {
        mediaContent = MediaContent()
    }
    
    // MARK: - Image Optimization
    
    private func optimizeImage(_ image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return image.tiffRepresentation
        }
        
        // Resize if too large
        let maxSize: CGFloat = 800
        let originalSize = image.size
        var newSize = originalSize
        
        if originalSize.width > maxSize || originalSize.height > maxSize {
            let scaleFactor = min(maxSize / originalSize.width, maxSize / originalSize.height)
            newSize = CGSize(width: originalSize.width * scaleFactor, height: originalSize.height * scaleFactor)
        }
        
        // Create resized image
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        resizedImage.unlockFocus()
        
        // Convert to JPEG with compression
        if let resizedTiffData = resizedImage.tiffRepresentation,
           let resizedBitmap = NSBitmapImageRep(data: resizedTiffData) {
            return resizedBitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
        }
        
        return image.tiffRepresentation
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Supporting Views

struct EmojiCategory {
    let name: String
    let emojis: [String]
}

struct EmojiPickerSheet: View {
    @Binding var selectedEmoji: String
    let categories: [EmojiCategory]
    let onEmojiSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory = 0
    @State private var searchText = ""
    
    var filteredEmojis: [String] {
        if searchText.isEmpty {
            return categories[selectedCategory].emojis
        } else {
            return categories.flatMap { $0.emojis }.filter { emoji in
                // Simple search - could be enhanced with emoji descriptions
                return true
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("Choose Emoji")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(hex: "#1C1C1E"))
            
            // Category Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories.indices, id: \.self) { index in
                        Button(action: {
                            selectedCategory = index
                        }) {
                            Text(categories[index].name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedCategory == index ? .white : .gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedCategory == index ? Color.blue : Color.clear)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(hex: "#2C2C2E"))
            
            // Emoji Grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                    ForEach(filteredEmojis, id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji = emoji
                            onEmojiSelected(emoji)
                        }) {
                            Text(emoji)
                                .font(.system(size: 24))
                                .frame(width: 40, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedEmoji == emoji ? Color.blue.opacity(0.3) : Color.clear)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .background(Color(hex: "#1C1C1E"))
        }
        .frame(width: 400, height: 500)
        .background(Color(hex: "#1C1C1E"))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct MediaPickerView_Previews: PreviewProvider {
    static var previews: some View {
        MediaPickerView(mediaContent: .constant(MediaContent()))
            .preferredColorScheme(.dark)
            .frame(width: 300)
    }
} 