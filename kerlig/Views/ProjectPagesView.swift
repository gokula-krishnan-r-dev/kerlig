import SwiftUI
import AppKit
import MarkdownUI

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
    @State private var showingPageEditorModal = false
    @State private var pageToEdit: ProjectPage?
    
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
        .sheet(isPresented: $showingPageEditorModal) {
            if let page = pageToEdit {
                PageEditorModal(
                    page: page,
                    noteStore: noteStore,
                    selectedProject: selectedProject,
                    isPresented: $showingPageEditorModal
                )
            }
        }
        .onChange(of: showingPageEditorModal) { _, isShowing in
            if !isShowing {
                // Force refresh the UI after modal closes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Refresh the page data
                    if let pageId = pageToEdit?.id,
                       let updatedPage = noteStore.pages.first(where: { $0.id == pageId }) {
                        pageToEdit = updatedPage
                        selectedPage = updatedPage
                    }
                    
                    // Clear the edited page reference to force list refresh
                    pageToEdit = nil
                    
                    // Force a UI update by triggering a state change
                    withAnimation(.easeInOut(duration: 0.3)) {
                        // This will cause the list to re-render with updated data
                    }
                }
            }
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
                            pageToEdit = page
                            editingContent = page.content
                            showingPageEditorModal = true
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

// MARK: - Page Editor Modal
struct PageEditorModal: View {
    let page: ProjectPage
    @ObservedObject var noteStore: NoteStore
    var selectedProject: Project?
    @Binding var isPresented: Bool
    
    @State private var editingTitle: String
    @State private var editingContent: String
    @State private var isPreviewMode = false
    @State private var showingTaskSelector = false
    @State private var animateIn = false
    @State private var tags: [String]
    @State private var newTag = ""
    @State private var isAddingTag = false
    @State private var isPinned: Bool
    @State private var isSaving = false
    @State private var showingSaveSuccess = false
    @State private var autoSaveTimer: Timer?
    @State private var lastSaveTime: Date?
    @State private var saveWorkItem: DispatchWorkItem?
    
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
    
    init(page: ProjectPage, noteStore: NoteStore, selectedProject: Project?, isPresented: Binding<Bool>) {
        self.page = page
        self.noteStore = noteStore
        self.selectedProject = selectedProject
        self._isPresented = isPresented
        self._editingTitle = State(initialValue: page.title)
        self._editingContent = State(initialValue: page.content)
        self._tags = State(initialValue: page.tags)
        self._isPinned = State(initialValue: page.isPinned)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                primaryBgColor
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Content area
                    contentArea
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Footer
                    footerView
                }
                .opacity(animateIn ? 1 : 0)
                .scaleEffect(animateIn ? 1 : 0.95)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateIn)
            }
        }
        .frame(minWidth: 800, idealWidth: 1000, maxWidth: .infinity, 
               minHeight: 600, idealHeight: 700, maxHeight: .infinity)
        .onAppear {
            withAnimation {
                animateIn = true
            }
            setupAutoSave()
        }
        .onDisappear {
            autoSaveTimer?.invalidate()
        }
        .onChange(of: editingTitle) { _, _ in
            scheduleAutoSave()
        }
        .onChange(of: editingContent) { _, _ in
            scheduleAutoSave()
        }
        .onChange(of: tags) { _, _ in
            scheduleAutoSave()
        }
        .onChange(of: isPinned) { _, _ in
            scheduleAutoSave()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            // Top bar with close button
            HStack {
                Button(action: {
                    closeModal()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                        Text("Close")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Toggle view mode
                HStack(spacing: 8) {
                    Button(action: { isPreviewMode = false }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isPreviewMode ? .gray : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isPreviewMode ? Color.clear : accentColor)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { isPreviewMode = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                            Text("Preview")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isPreviewMode ? .white : .gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isPreviewMode ? accentColor : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    // Pin toggle
                    Button(action: {
                        withAnimation {
                            isPinned.toggle()
                        }
                    }) {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .foregroundColor(isPinned ? .yellow : .gray)
                            .padding(8)
                            .background(cardBgColor)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(isPinned ? "Unpin page" : "Pin page")
                    
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
            }
            .padding()
            .background(secondaryBgColor)
            
            // Title editor
            titleEditor
            
            // Tags section
            tagsSection
        }
    }
    
    private var titleEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let project = selectedProject {
                    // Project logo
                    if let logoData = project.logoImageData, let nsImage = NSImage(data: logoData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(project.color ?? .blue)
                            .frame(width: 24, height: 24)
                    }
                }
                
                HStack {
                    TextField("Page title", text: $editingTitle)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .background(Color.clear)
                    
                    // Auto-save status in title area
                    if isSaving {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            
                            Text("Saving")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        .transition(.opacity)
                    }
                }
            }
            
            HStack(spacing: 16) {
                Text("Created: \(formatDate(page.creationDate))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("Modified: \(formatDate(page.lastModified))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if !noteStore.getTasksForPage(page).isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 10))
                        Text("\(noteStore.getTasksForPage(page).count) tasks")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(cardBgColor.opacity(0.3))
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tags")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    isAddingTag = true
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(accentColor)
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagView(tag: tag) {
                            withAnimation {
                                tags.removeAll { $0 == tag }
                            }
                        }
                    }
                    
                    if isAddingTag {
                        HStack(spacing: 4) {
                            TextField("New tag", text: $newTag)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .frame(width: 80)
                                .onSubmit {
                                    addTag()
                                }
                            
                            Button(action: addTag) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                isAddingTag = false
                                newTag = ""
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(cardBgColor)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        .background(cardBgColor.opacity(0.1))
    }
    
    private var contentArea: some View {
        GeometryReader { geometry in
            if isPreviewMode {
                // Preview mode with MarkdownUI
                ScrollView {
                    Markdown(editingContent)
                        .markdownTheme(.gitHub)
                        .markdownTextStyle(\.text) {
                            ForegroundColor(.white)
                        }
                        .markdownTextStyle(\.code) {
                            FontFamilyVariant(.monospaced)
                            FontSize(.em(0.85))
                            ForegroundColor(.green)
                            BackgroundColor(.gray.opacity(0.2))
                        }
                        .markdownBlockStyle(\.blockquote) { configuration in
                            configuration.label
                                .padding()
                                .markdownTextStyle {
                                    FontCapsVariant(.lowercaseSmallCaps)
                                    FontWeight(.semibold)
                                    BackgroundColor(nil)
                                }
                                .overlay(alignment: .leading) {
                                    Rectangle()
                                        .fill(accentColor)
                                        .frame(width: 4)
                                }
                                .background(accentColor.opacity(0.1))
                        }
                        .markdownBlockStyle(\.codeBlock) { configuration in
                            configuration.label
                                .padding()
                                .background(cardBgColor)
                                .cornerRadius(8)
                        }
                        .padding()
                }
                .background(primaryBgColor)
            } else {
                // Edit mode
                VStack(spacing: 0) {
                    // Toolbar
                    markdownToolbar
                    
                    // Editor
                    MarkdownEditorView(text: $editingContent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    
    private var markdownToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Formatting buttons
                Group {
                    ToolbarButton(icon: "bold", title: "Bold") {
                        insertMarkdown("**", "**")
                    }
                    
                    ToolbarButton(icon: "italic", title: "Italic") {
                        insertMarkdown("*", "*")
                    }
                    
                    ToolbarButton(icon: "strikethrough", title: "Strikethrough") {
                        insertMarkdown("~~", "~~")
                    }
                    
                    ToolbarButton(icon: "link", title: "Link") {
                        insertMarkdown("[", "](url)")
                    }
                    
                    ToolbarButton(icon: "photo", title: "Image") {
                        insertMarkdown("![", "](image-url)")
                    }
                    
                    ToolbarButton(icon: "code", title: "Inline Code") {
                        insertMarkdown("`", "`")
                    }
                    
                    ToolbarButton(icon: "doc.plaintext", title: "Code Block") {
                        insertMarkdown("\n```\n", "\n```\n")
                    }
                    
                    ToolbarButton(icon: "list.bullet", title: "Bullet List") {
                        insertMarkdown("\n- ", "")
                    }
                    
                    ToolbarButton(icon: "list.number", title: "Numbered List") {
                        insertMarkdown("\n1. ", "")
                    }
                    
                    ToolbarButton(icon: "text.quote", title: "Quote") {
                        insertMarkdown("\n> ", "")
                    }
                }
                
                Divider()
                    .frame(height: 20)
                
                // Header buttons
                Group {
                    ToolbarButton(icon: "h1.square", title: "Heading 1") {
                        insertMarkdown("\n# ", "")
                    }
                    
                    ToolbarButton(icon: "h2.square", title: "Heading 2") {
                        insertMarkdown("\n## ", "")
                    }
                    
                    ToolbarButton(icon: "h3.square", title: "Heading 3") {
                        insertMarkdown("\n### ", "")
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .frame(height: 44)
        .background(cardBgColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var footerView: some View {
        HStack {
            // Associated tasks
            if !noteStore.getTasksForPage(page).isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Text("Linked Tasks:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        ForEach(noteStore.getTasksForPage(page)) { note in
                            HStack(spacing: 4) {
                                Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(note.isCompleted ? .green : .gray)
                                    .font(.system(size: 10))
                                
                                Text(note.title)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(cardBgColor)
                            .cornerRadius(12)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Auto-save status indicator
            HStack(spacing: 8) {
                if isSaving {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        
                        Text("Saving...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .transition(.opacity)
                } else if let lastSaveTime = lastSaveTime {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        
                        Text("Auto-saved \(timeAgoString(from: lastSaveTime))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .opacity(showingSaveSuccess ? 1 : 0.7)
                    .animation(.easeInOut(duration: 0.3), value: showingSaveSuccess)
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 6, height: 6)
                        
                        Text("Auto-save enabled")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(secondaryBgColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .top
        )
    }
    
    // MARK: - Helper Methods
    
    private func addTag() {
        guard !newTag.isEmpty && !tags.contains(newTag) else { return }
        withAnimation {
            tags.append(newTag)
            newTag = ""
            isAddingTag = false
        }
    }
    
    private func insertMarkdown(_ prefix: String, _ suffix: String) {
        editingContent += prefix + "text" + suffix
    }
    
    private func setupAutoSave() {
        // Initial setup - no timer needed since we're doing immediate auto-save
    }
    
    private func scheduleAutoSave() {
        // Cancel any pending save operation
        saveWorkItem?.cancel()
        
        // Reset save success indicator when changes are made
        showingSaveSuccess = false
        
        // Create new save work item with 1.5 second debounce
        let workItem = DispatchWorkItem {
            self.performAutoSave()
        }
        
        // Store the work item
        saveWorkItem = workItem
        
        // Schedule the save after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }
    
    private func performAutoSave() {
        guard !isSaving else { return }
        
        // Validate inputs
        let trimmedTitle = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }
        
        // Check if there are actual changes
        guard hasChanges() else { return }
        
        isSaving = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            savePage { success in
                DispatchQueue.main.async {
                    self.isSaving = false
                    
                    if success {
                        self.lastSaveTime = Date()
                        
                        // Show success feedback briefly
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.showingSaveSuccess = true
                        }
                        
                        // Hide success indicator after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                self.showingSaveSuccess = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func hasChanges() -> Bool {
        let currentTitle = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentContent = editingContent.trimmingCharacters(in: .whitespacesAndNewlines)
        let originalTitle = page.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let originalContent = page.content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return currentTitle != originalTitle ||
               currentContent != originalContent ||
               tags != page.tags ||
               isPinned != page.isPinned
    }
    
    private func savePage(completion: @escaping (Bool) -> Void) {
        var updatedPage = page
        updatedPage.title = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedPage.content = editingContent
        updatedPage.tags = tags
        updatedPage.isPinned = isPinned
        updatedPage.lastModified = Date()
        
        // Perform the save operation
        noteStore.updatePage(updatedPage)
        
        // Simulate async operation completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion(true)
        }
    }
    
    private func closeModal() {
        // Cancel any pending save operations
        saveWorkItem?.cancel()
        autoSaveTimer?.invalidate()
        
        // Perform final save if there are changes
        if hasChanges() && !editingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            performFinalSave {
                self.dismissModal()
            }
        } else {
            dismissModal()
        }
    }
    
    private func performFinalSave(completion: @escaping () -> Void) {
        guard !isSaving else {
            completion()
            return
        }
        
        isSaving = true
        
        savePage { success in
            DispatchQueue.main.async {
                self.isSaving = false
                completion()
            }
        }
    }
    
    private func dismissModal() {
        withAnimation {
            animateIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views for Modal

struct ToolbarButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(PlainButtonStyle())
        .help(title)
    }
}

struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.system(size: 12))
                .foregroundColor(.blue)
            
            if isHovered {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct MarkdownEditorView: NSViewRepresentable {
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = .white
        textView.backgroundColor = NSColor(Color(hex: "#0A0A0B"))
        textView.delegate = context.coordinator
        textView.string = text
        
        // Enhanced text view settings
        textView.isRichText = false
        textView.smartInsertDeleteEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = true
        textView.textContainerInset = NSSize(width: 16, height: 16)
        
        // Syntax highlighting would be added here
        configureSyntaxHighlighting(textView)
        
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
    
    private func configureSyntaxHighlighting(_ textView: NSTextView) {
        // Basic markdown syntax highlighting
        // You could implement more sophisticated syntax highlighting here
        // For now, we'll keep it simple with the monospaced font
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownEditorView
        
        init(_ parent: MarkdownEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

#Preview {
    ProjectPagesView(
        noteStore: NoteStore(),
        selectedProject: .constant(nil)
    )
} 