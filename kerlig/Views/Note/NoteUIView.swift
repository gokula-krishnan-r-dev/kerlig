//
//  ContentView.swift
//  Streamline
//
//  Created by gokul on 17/04/25.
//

import SwiftUI
import Foundation



struct NoteUIView: View {
    @StateObject private var noteStore = NoteStore()
    @State private var selectedNote: Note?
    @State private var selectedProject: Project?
    @State private var isAddingNewNote = false
    @State private var isAddingNewProject = false
    @State private var newNoteTitle = ""
    @State private var newNoteContent = ""
    @State private var newProjectTitle = ""
    @State private var newProjectDescription = ""
    @State private var searchText = ""
    @State private var selectedCategory: NoteCategory?
    @State private var isShowingProjects = false
    @Environment(\.colorScheme) private var colorScheme
    
    // Break complex expressions into simpler parts
    private var filteredNotes: [Note] {
        let allNotes = noteStore.notes
        let projectFiltered = filterByProject(notes: allNotes)
        let categoryFiltered = filterByCategory(notes: projectFiltered)
        return filterBySearch(notes: categoryFiltered)
    }
    
    private func filterByProject(notes: [Note]) -> [Note] {
        guard let project = selectedProject else { return notes }
        return noteStore.getNotesForProject(project)
    }
    
    private func filterByCategory(notes: [Note]) -> [Note] {
        guard let category = selectedCategory else { return notes }
        return notes.filter { $0.category == category }
    }
    
    private func filterBySearch(notes: [Note]) -> [Note] {
        if searchText.isEmpty { return notes }
        return notes.filter { 
            $0.title.localizedCaseInsensitiveContains(searchText) || 
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Get list row backgrounds
    private func getRowBackground(isSelected: Bool) -> Color {
        if isSelected {
            return colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
        } else {
            return colorScheme == .dark ? Color.black : Color.white
        }
    }
    
    private func getProjectBackground(for project: Project) -> Color {
        let isSelected = selectedProject?.id == project.id
        return getRowBackground(isSelected: isSelected)
    }
    
    private func getNoteBackground(for note: Note) -> Color {
        let isSelected = selectedNote?.id == note.id
        return getRowBackground(isSelected: isSelected)
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(selectedProject?.title ?? "Notes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.leading)
                    
                    Spacer()
                    
                    // Add note button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isAddingNewNote = true
                            selectedNote = nil
                            newNoteTitle = ""
                            newNoteContent = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                    
                    // Menu
                    Menu {
                        Button {
                            withAnimation {
                                isShowingProjects.toggle()
                            }
                        } label: {
                            Label(isShowingProjects ? "Show Notes" : "Show Projects", 
                                  systemImage: isShowingProjects ? "note.text" : "folder")
                        }
                        
                        Divider()
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isAddingNewProject = true
                            }
                        } label: {
                            Label("New Project", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.trailing)
                }
                .padding(.vertical, 8)
                
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
//                // Category scroll view
//                if !isShowingProjects {
//                    CategoryScrollView(selectedCategory: $selectedCategory)
//                        .padding(.horizontal)
//                        .padding(.bottom, 8)
//                }
                
                // List content
                Group {
                    if isShowingProjects {
                        projectListView
                    } else {
                        noteListView
                    }
                }
            }
            .frame(minWidth: 250)
            .overlay {
                if isAddingNewProject {
                    newProjectOverlay
                }
            }
        } detail: {
            ZStack {
                Group {
                    if isAddingNewNote {
                        NewNoteView(
                            title: $newNoteTitle,
                            content: $newNoteContent,
                            onSave: {
                                if !newNoteTitle.isEmpty || !newNoteContent.isEmpty {
                                    let category = selectedCategory ?? .uncategorized
                                    noteStore.addNote(
                                        title: newNoteTitle.isEmpty ? "Untitled" : newNoteTitle, 
                                        content: newNoteContent,
                                        category: category
                                    )
                                    
                                    // Add to project if one is selected
                                    if let project = selectedProject, let newNoteId = noteStore.notes.last?.id {
                                        noteStore.addNoteToProject(noteId: newNoteId, projectId: project.id)
                                    }
                                    
                                    isAddingNewNote = false
                                }
                            },
                            onCancel: {
                                withAnimation {
                                    isAddingNewNote = false
                                }
                            },
                            selectedCategory: selectedCategory
                        )
                        .transition(.move(edge: .trailing))
                    } else if let note = selectedNote {
                        NoteDetailView(note: note, onUpdate: { updatedNote in
                            noteStore.updateNote(updatedNote)
                        })
                        .id(note.id) // Force view refresh when selection changes
                        .transition(.asymmetric(insertion: .move(edge: .trailing), 
                                              removal: .move(edge: .leading)))
                    } else {
                        PlaceholderView(isShowingProjects: isShowingProjects)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .animation(.easeInOut, value: selectedNote?.id)
            .animation(.easeInOut, value: isAddingNewNote)
        }
        .navigationTitle("")
    
    }
    
    // MARK: - Extracted Views
    private var projectListView: some View {
        List(selection: $selectedProject) {
            ForEach(noteStore.projects) { project in
                ProjectRow(project: project, noteCount: noteStore.getNotesForProject(project).count)
                    .tag(project)
                    .listRowBackground(getProjectBackground(for: project))
                    .contextMenu {
                        Button(role: .destructive, action: {
                            noteStore.deleteProject(project)
                            if selectedProject?.id == project.id {
                                selectedProject = nil
                            }
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onDelete { indexSet in
                let projectsToDelete = indexSet.map { noteStore.projects[$0] }
                for project in projectsToDelete {
                    noteStore.deleteProject(project)
                    if selectedProject?.id == project.id {
                        selectedProject = nil
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .transition(.move(edge: .leading))
        .onChange(of: selectedProject) { newProject in
            print("Selected project: \(String(describing: newProject?.title))")
        }
    }
    
    private var noteListView: some View {
        List(selection: $selectedNote) {
            ForEach(filteredNotes) { note in
                NoteRow(note: note)
                    .tag(note)
                    .listRowBackground(getNoteBackground(for: note))
                    .contextMenu {
                        // Favorite button
                        Button(action: {
                            noteStore.toggleFavorite(note)
                        }) {
                            Label(note.isFavorite ? "Remove from Favorites" : "Add to Favorites", 
                                  systemImage: note.isFavorite ? "star.slash" : "star")
                        }
                        
                        // Category menu
                        Menu {
                            ForEach(NoteCategory.allCases) { category in
                                Button {
                                    var updatedNote = note
                                    updatedNote.category = category
                                    noteStore.updateNote(updatedNote)
                                } label: {
                                    Label(category.rawValue, systemImage: category.iconName)
                                }
                            }
                        } label: {
                            Label("Change Category", systemImage: "tag")
                        }
                        
                        // Project actions
                        projectContextMenu(for: note)
                        
                        // Delete button
                        Button(role: .destructive, action: {
                            noteStore.deleteNote(note)
                            if selectedNote?.id == note.id {
                                selectedNote = nil
                            }
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onDelete { indexSet in
                let notesToDelete = indexSet.map { filteredNotes[$0] }
                for note in notesToDelete {
                    noteStore.deleteNote(note)
                    if selectedNote?.id == note.id {
                        selectedNote = nil
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .transition(.move(edge: .trailing))
        .onChange(of: selectedNote) { newNote in
            print("Selected note: \(String(describing: newNote?.title))")
        }
    }
    
    private func projectContextMenu(for note: Note) -> some View {
        Group {
            if let project = selectedProject {
                Button {
                    noteStore.removeNoteFromProject(noteId: note.id, projectId: project.id)
                } label: {
                    Label("Remove from Project", systemImage: "folder.badge.minus")
                }
            } else {
                Menu {
                    ForEach(noteStore.projects) { project in
                        Button {
                            noteStore.addNoteToProject(noteId: note.id, projectId: project.id)
                        } label: {
                            Label(project.title, systemImage: "folder")
                        }
                    }
                } label: {
                    Label("Add to Project", systemImage: "folder.badge.plus")
                }
            }
        }
    }
    
    private var newProjectOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
                .onTapGesture {
                    withAnimation {
                        isAddingNewProject = false
                    }
                }
            
            NewProjectView(
                title: $newProjectTitle,
                description: $newProjectDescription,
                onSave: {
                    if !newProjectTitle.isEmpty {
                        noteStore.addProject(title: newProjectTitle, description: newProjectDescription)
                        withAnimation {
                            isAddingNewProject = false
                            newProjectTitle = ""
                            newProjectDescription = ""
                        }
                    }
                },
                onCancel: {
                    withAnimation {
                        isAddingNewProject = false
                    }
                }
            )
            .frame(width: 300, height: 250)
            .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.white)
            .cornerRadius(12)
            .shadow(radius: 20)
            .transition(.scale)
        }
    }
}




