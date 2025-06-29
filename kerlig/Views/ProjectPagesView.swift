import SwiftUI
import AppKit

struct ProjectPagesView: View {
    @ObservedObject var noteStore: NoteStore
    @Binding var selectedProject: Project?
    @State private var selectedPage: ProjectPage?
    @State private var isAddingPage = false
    @State private var newPageTitle = ""
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var showingTaskSelector = false
    @State private var editingContent = ""
    @State private var isEditingPage = false
    @State private var animateIn = false
    
    // Color palette
    private let primaryBgColor = Color(hex: "#0A0A0B")
    private let secondaryBgColor = Color(hex: "#1C1C1E")
    private let cardBgColor = Color(hex: "#2C2C2E")
    private let accentColor = Color(hex: "#007AFF")
    private let accentGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#007AFF"), Color(hex: "#0056CC")]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var filteredPages: [ProjectPage] {
        guard let project = selectedProject else { return [] }
        let projectPages = noteStore.getPagesForProject(project)
        
        if searchText.isEmpty {
            return projectPages
        }
        
        return projectPages.filter { page in
            page.title.lowercased().contains(searchText.lowercased()) ||
            page.content.lowercased().contains(searchText.lowercased()) ||
            page.tags.contains { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        ZStack {
            if selectedProject == nil {
                noProjectSelectedView
            } else if isEditingPage, let page = selectedPage {
                pageEditorView(page: page)
            } else {
                pagesListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(primaryBgColor)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    animateIn = true
                }
            }
            
            // Create default page for project if it has no pages
            if let project = selectedProject, noteStore.getPagesForProject(project).isEmpty {
                let defaultPage = noteStore.createDefaultPageForProject(project)
                selectedPage = defaultPage
            }
        }
        .onChange(of: selectedProject) { _, newProject in
            if let project = newProject {
                let projectPages = noteStore.getPagesForProject(project)
                if projectPages.isEmpty {
                    let defaultPage = noteStore.createDefaultPageForProject(project)
                    selectedPage = defaultPage
                } else {
                    selectedPage = projectPages.first
                }
                isEditingPage = false
            } else {
                selectedPage = nil
            }
        }
        .sheet(isPresented: $isAddingPage) {
            addPageSheet
        }
    }
    
    // MARK: - View Components
    
    private var noProjectSelectedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No Project Selected")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Select a project to view and manage its pages")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)
    }
    
    private var pagesListView: some View {
        VStack(spacing: 0) {
            // Header
            pagesHeader
            
            // Search bar
            searchBar
            
            // Pages list
            if filteredPages.isEmpty {
                emptyPagesView
            } else {
                pagesList
            }
        }
    }
    
    private var pagesHeader: some View {
        HStack {
            if let project = selectedProject {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        // Project logo
                        if let logoData = project.logoImageData, let nsImage = NSImage(data: logoData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        } else {
                            Circle()
                                .fill(project.color ?? .blue)
                                .frame(width: 32, height: 32)
                        }
                        
                        Text("\(project.title) Pages")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text("\(noteStore.getPagesForProject(project).count) pages")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button(action: {
                isAddingPage = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("New Page")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(accentGradient)
                .cornerRadius(8)
            }
            .buttonStyle(AnimatedButtonStyle())
        }
        .padding()
        .background(secondaryBgColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2))
                .offset(y: 1),
            alignment: .bottom
        )
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -10)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(isSearchActive ? accentColor : .gray)
                .font(.system(size: 14))
            
            TextField("Search pages...", text: $searchText, onEditingChanged: { editing in
                withAnimation {
                    isSearchActive = editing
                }
            })
            .textFieldStyle(PlainTextFieldStyle())
            .font(.system(size: 14))
            .foregroundColor(.white)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(10)
        .background(cardBgColor)
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -10)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateIn)
    }
    
    private var pagesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(zip(filteredPages.indices, filteredPages)), id: \.1.id) { index, page in
                    PageRowView(
                        page: page,
                        project: selectedProject,
                        isSelected: selectedPage?.id == page.id,
                        noteStore: noteStore,
                        onSelect: {
                            selectedPage = page
                            isEditingPage = true
                            editingContent = page.content
                        },
                        onDelete: {
                            deletePage(page)
                        },
                        onTogglePin: {
                            togglePagePin(page)
                        }
                    )
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3 + Double(index) * 0.05), value: animateIn)
                }
            }
            .padding()
        }
    }
    
    private var emptyPagesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Pages Found")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if searchText.isEmpty {
                Text("Create your first page to start documenting this project")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    isAddingPage = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Create First Page")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(accentGradient)
                    .cornerRadius(20)
                }
                .buttonStyle(AnimatedButtonStyle())
                .padding(.top, 10)
            } else {
                Text("No pages match your search criteria")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    searchText = ""
                }) {
                    Text("Clear Search")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .opacity(animateIn ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
    }
    
    private func pageEditorView(page: ProjectPage) -> some View {
        VStack(spacing: 0) {
            // Editor header
            HStack {
                Button(action: {
                    // Save changes and go back to list
                    if editingContent != page.content {
                        var updatedPage = page
                        updatedPage.content = editingContent
                        noteStore.updatePage(updatedPage)
                        selectedPage = updatedPage
                    }
                    isEditingPage = false
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back to Pages")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text(page.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Associate task button
                Button(action: {
                    showingTaskSelector = true
                }) {
                    Image(systemName: "link.badge.plus")
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(cardBgColor)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Associate tasks with this page")
                .popover(isPresented: $showingTaskSelector) {
                    TaskSelectorView(
                        noteStore: noteStore,
                        selectedProject: selectedProject,
                        page: page
                    )
                    .frame(width: 300, height: 400)
                }
            }
            .padding()
            .background(secondaryBgColor)
            
            // Rich text editor
            RichTextEditorView(text: $editingContent)
                .padding()
            
            // Associated tasks section
            if !noteStore.getTasksForPage(page).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Associated Tasks")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(noteStore.getTasksForPage(page)) { note in
                                AssociatedTaskView(note: note, onRemove: {
                                    noteStore.removeTaskFromPage(taskId: note.id, pageId: page.id)
                                })
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
                .background(cardBgColor.opacity(0.5))
            }
        }
    }
    
    private var addPageSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Page")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Cancel") {
                    isAddingPage = false
                    newPageTitle = ""
                }
                .foregroundColor(.gray)
            }
            .padding()
            .background(secondaryBgColor)
            
            // Form
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Page Title")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Enter page title", text: $newPageTitle)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .background(cardBgColor)
                        .cornerRadius(8)
                        .onSubmit {
                            if !newPageTitle.isEmpty {
                                createNewPage()
                            }
                        }
                }
                
                Button(action: {
                    createNewPage()
                }) {
                    Text("Create Page")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentGradient)
                        .cornerRadius(8)
                        .shadow(color: accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(AnimatedButtonStyle())
                .disabled(newPageTitle.isEmpty)
                .opacity(newPageTitle.isEmpty ? 0.6 : 1)
            }
            .padding()
        }
        .background(secondaryBgColor)
        .frame(width: 400)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func createNewPage() {
        guard let project = selectedProject, !newPageTitle.isEmpty else { return }
        
        let newPage = noteStore.addPage(
            title: newPageTitle,
            projectId: project.id
        )
        
        selectedPage = newPage
        isEditingPage = true
        editingContent = newPage.content
        isAddingPage = false
        newPageTitle = ""
    }
    
    private func deletePage(_ page: ProjectPage) {
        noteStore.deletePage(page)
        
        if selectedPage?.id == page.id {
            if let project = selectedProject {
                let projectPages = noteStore.getPagesForProject(project)
                selectedPage = projectPages.first
            } else {
                selectedPage = nil
            }
            isEditingPage = false
        }
    }
    
    private func togglePagePin(_ page: ProjectPage) {
        var updatedPage = page
        updatedPage.isPinned.toggle()
        noteStore.updatePage(updatedPage)
        
        if selectedPage?.id == page.id {
            selectedPage = updatedPage
        }
    }
}

// MARK: - Supporting Views

struct PageRowView: View {
    let page: ProjectPage
    let project: Project?
    let isSelected: Bool
    let noteStore: NoteStore
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void
    
    @State private var isHovered = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Page icon or project color
                ZStack {
                    Circle()
                        .fill(project?.color ?? .blue)
                        .frame(width: 36, height: 36)
                        .opacity(0.2)
                    
                    Image(systemName: page.isPinned ? "doc.fill" : "doc")
                        .font(.system(size: 16))
                        .foregroundColor(project?.color ?? .blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(page.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if page.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Text(formatDate(page.lastModified))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        if !page.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(page.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.system(size: 10))
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            .frame(height: 20)
                        }
                        
                        let taskCount = noteStore.getTasksForPage(page).count
                        if taskCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.system(size: 10))
                                Text("\(taskCount)")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                if isHovered || isSelected {
                    HStack(spacing: 8) {
                        Button(action: onTogglePin) {
                            Image(systemName: page.isPinned ? "pin.slash" : "pin")
                                .font(.system(size: 12))
                                .foregroundColor(page.isPinned ? .yellow : .gray)
                                .padding(6)
                                .background(Color(hex: "#3C3C3E"))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help(page.isPinned ? "Unpin page" : "Pin page")
                        
                        Button(action: {
                            showDeleteConfirm = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.8))
                                .padding(6)
                                .background(Color(hex: "#3C3C3E"))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Delete page")
                        .confirmationDialog("Delete Page", isPresented: $showDeleteConfirm) {
                            Button("Delete", role: .destructive) {
                                onDelete()
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Are you sure you want to delete '\(page.title)'?")
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: "#2C2C2E") : (isHovered ? Color(hex: "#1C1C1E") : Color(hex: "#1C1C1E").opacity(0.5)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? (project?.color ?? .blue).opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct RichTextEditorView: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textColor = .white
        textView.backgroundColor = NSColor(Color(hex: "#1C1C1E"))
        textView.delegate = context.coordinator
        textView.string = text
        
        // Enable rich text formatting
        textView.isRichText = true
        textView.usesFontPanel = true
        textView.usesRuler = true
        textView.smartInsertDeleteEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticLinkDetectionEnabled = true
        
        // Add standard editing menu
        let menu = NSMenu()
        menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Bold", action: #selector(NSFontManager.addFontTrait(_:)), keyEquivalent: "b")
        menu.addItem(withTitle: "Italic", action: #selector(NSFontManager.addFontTrait(_:)), keyEquivalent: "i")
        menu.addItem(withTitle: "Underline", action: #selector(NSText.underline(_:)), keyEquivalent: "u")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        textView.menu = menu
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditorView
        
        init(_ parent: RichTextEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

struct TaskSelectorView: View {
    @ObservedObject var noteStore: NoteStore
    var selectedProject: Project?
    var page: ProjectPage
    @State private var searchText = ""
    
    var filteredTasks: [Note] {
        guard let project = selectedProject else { return [] }
        
        let allProjectTasks = noteStore.getNotesForProject(project)
        let alreadyAssociatedIds = Set(page.associatedTaskIds)
        
        let availableTasks = allProjectTasks.filter { !alreadyAssociatedIds.contains($0.id) }
        
        if searchText.isEmpty {
            return availableTasks
        }
        
        return availableTasks.filter { task in
            task.title.lowercased().contains(searchText.lowercased()) ||
            task.content.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Associate Tasks")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(Color(hex: "#1C1C1E"))
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search tasks...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color(hex: "#2C2C2E"))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Task list
            if filteredTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text(searchText.isEmpty ? "No available tasks" : "No matching tasks")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredTasks) { task in
                            Button(action: {
                                noteStore.associateTaskWithPage(taskId: task.id, pageId: page.id)
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(task.isCompleted ? .green : .gray)
                                    
                                    Text(task.title)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(hex: "#2C2C2E"))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(hex: "#1C1C1E"))
    }
}

struct AssociatedTaskView: View {
    let note: Note
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(note.isCompleted ? .green : .gray)
                .font(.system(size: 12))
            
            Text(note.title)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .lineLimit(1)
            
            if isHovered {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.7))
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: "#2C2C2E"))
        .cornerRadius(16)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    ProjectPagesView(
        noteStore: NoteStore(),
        selectedProject: .constant(nil)
    )
} 