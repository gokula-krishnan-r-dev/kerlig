import SwiftUI

struct URLManagerPanelView: View {
    @ObservedObject var urlManagerService: URLManagerService
    @State private var newURLText: String = ""
    @State private var showingError: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
                .padding(.horizontal, 20)
            
            // Content
            contentView
        }
        .background(Color.clear)
        .onAppear {
            isTextFieldFocused = true
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { showingError = false }
        } message: {
            Text(urlManagerService.errorMessage ?? "An unknown error occurred")
        }
        .onChange(of: urlManagerService.errorMessage) { error in
            if error != nil {
                showingError = true
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("URL Manager")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Save and organize your favorite websites")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(PlainButtonStyle())
            
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        VStack(spacing: 16) {
            // URL Input Section
            urlInputSection
            
            // Saved URLs List
            savedURLsList
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - URL Input Section
    
    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                Text("Add New Website")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            HStack(spacing: 12) {
                TextField("Enter website URL (e.g., https://github.com/user/repo)", text: $newURLText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        addURL()
                    }
                
                Button(action: addURL) {
                    HStack(spacing: 6) {
                        if urlManagerService.isLoadingGitHub {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus")
                        }
                        Text("Add")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(newURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || urlManagerService.isLoadingGitHub)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Saved URLs List
    
    private var savedURLsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.orange)
                Text("Saved Websites")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(urlManagerService.savedURLs.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if urlManagerService.savedURLs.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(urlManagerService.savedURLs) { savedURL in
                            URLRowView(
                                savedURL: savedURL,
                                onOpen: { urlManagerService.openURL(savedURL.url) },
                                onDelete: { urlManagerService.removeURL(savedURL) }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No websites saved yet")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Add your first website using the field above.\nGitHub repositories will show enhanced previews!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Actions
    
    private func addURL() {
        let trimmedURL = newURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else { return }
        
        // Auto-add https:// if no scheme is provided
        let finalURL = trimmedURL.hasPrefix("http://") || trimmedURL.hasPrefix("https://") ? 
            trimmedURL : "https://\(trimmedURL)"
        
        urlManagerService.saveURL(finalURL)
        newURLText = ""
        isTextFieldFocused = true
    }
}

// MARK: - URL Row View

struct URLRowView: View {
    let savedURL: SavedURL
    let onOpen: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Leading icon or avatar
            leadingIcon
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(savedURL.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if savedURL.isGitHubRepo, let githubData = savedURL.githubData {
                    githubInfoView(githubData)
                } else {
                    Text(savedURL.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button(action: onOpen) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .opacity(isHovered ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onOpen()
        }
        .contextMenu {
            Button("Open", action: onOpen)
            Button("Delete", action: onDelete)
        }
    }
    
    @ViewBuilder
    private var leadingIcon: some View {
        if savedURL.isGitHubRepo, let githubData = savedURL.githubData, let avatarURL = githubData.avatarURL {
            AsyncImage(url: URL(string: avatarURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.secondary)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
        } else {
            Image(systemName: savedURL.isGitHubRepo ? "doc.text" : "globe")
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    @ViewBuilder
    private func githubInfoView(_ githubData: GitHubRepoData) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let description = githubData.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 12) {
                if let language = githubData.language {
                    Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let stars = githubData.starCount {
                    Label("\(stars)", systemImage: "star")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let forks = githubData.forkCount {
                    Label("\(forks)", systemImage: "arrow.branch")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    URLManagerPanelView(
        urlManagerService: URLManagerService(),
        onClose: {}
    )
    .frame(width: 600, height: 500)
} 
