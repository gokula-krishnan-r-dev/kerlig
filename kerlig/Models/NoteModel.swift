import Foundation
import SwiftUI

struct Note: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var content: String
    var creationDate: Date
    var lastModified: Date
    var isFavorite: Bool
    var category: NoteCategory
    var color: String? // Hex color code for note customization
    
    init(id: UUID = UUID(), title: String, content: String, creationDate: Date = Date(), lastModified: Date = Date(), isFavorite: Bool = false, category: NoteCategory = .uncategorized, color: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.creationDate = creationDate
        self.lastModified = lastModified
        self.isFavorite = isFavorite
        self.category = category
        self.color = color
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
}

enum NoteCategory: String, Codable, CaseIterable, Identifiable {
    case uncategorized = "Uncategorized"
    case personal = "Personal"
    case work = "Work"
    case project = "Project"
    case ideas = "Ideas"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
            case .uncategorized: return "tray"
            case .personal: return "person"
            case .work: return "briefcase"
            case .project: return "folder"
            case .ideas: return "lightbulb"
        }
    }
    
    var color: Color {
        switch self {
            case .uncategorized: return .gray
            case .personal: return .blue
            case .work: return .purple
            case .project: return .green
            case .ideas: return .orange
        }
    }
}

struct Project: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var description: String
    var creationDate: Date
    var lastModified: Date
    var noteIds: [UUID]
    
    init(id: UUID = UUID(), title: String, description: String, creationDate: Date = Date(), lastModified: Date = Date(), noteIds: [UUID] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.creationDate = creationDate
        self.lastModified = lastModified
        self.noteIds = noteIds
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }
}

class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var projects: [Project] = []
    
    private let notesKey = "savedNotes"
    private let projectsKey = "savedProjects"
    
    init() {
        loadNotes()
        loadProjects()
    }
    
    func addNote(title: String, content: String, category: NoteCategory = .uncategorized) {
        let newNote = Note(title: title, content: content, category: category)
        notes.append(newNote)
        saveNotes()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.lastModified = Date()
            notes[index] = updatedNote
            saveNotes()
            
            // Update any projects containing this note
            updateProjectsLastModified(noteId: note.id)
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
        
        // Remove note from any projects
        for var project in projects {
            if project.noteIds.contains(note.id) {
                project.noteIds.removeAll { $0 == note.id }
                project.lastModified = Date()
                if let index = projects.firstIndex(where: { $0.id == project.id }) {
                    projects[index] = project
                }
            }
        }
        saveProjects()
    }
    
    func toggleFavorite(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.isFavorite.toggle()
            updatedNote.lastModified = Date()
            notes[index] = updatedNote
            saveNotes()
        }
    }
    
    func addProject(title: String, description: String) {
        let newProject = Project(title: title, description: description)
        projects.append(newProject)
        saveProjects()
    }
    
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            var updatedProject = project
            updatedProject.lastModified = Date()
            projects[index] = updatedProject
            saveProjects()
        }
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        saveProjects()
    }
    
    func addNoteToProject(noteId: UUID, projectId: UUID) {
        if let index = projects.firstIndex(where: { $0.id == projectId }) {
            var project = projects[index]
            if !project.noteIds.contains(noteId) {
                project.noteIds.append(noteId)
                project.lastModified = Date()
                projects[index] = project
                saveProjects()
            }
        }
    }
    
    func removeNoteFromProject(noteId: UUID, projectId: UUID) {
        if let index = projects.firstIndex(where: { $0.id == projectId }) {
            var project = projects[index]
            project.noteIds.removeAll { $0 == noteId }
            project.lastModified = Date()
            projects[index] = project
            saveProjects()
        }
    }
    
    func getNotesForProject(_ project: Project) -> [Note] {
        return notes.filter { project.noteIds.contains($0.id) }
    }
    
    private func updateProjectsLastModified(noteId: UUID) {
        for (index, project) in projects.enumerated() {
            if project.noteIds.contains(noteId) {
                var updatedProject = project
                updatedProject.lastModified = Date()
                projects[index] = updatedProject
            }
        }
        saveProjects()
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
        }
    }
    
    private func loadNotes() {
        if let savedNotes = UserDefaults.standard.data(forKey: notesKey) {
            if let decodedNotes = try? JSONDecoder().decode([Note].self, from: savedNotes) {
                notes = decodedNotes
                return
            }
        }
        
        // Add sample notes if no saved notes found
        notes = [
            Note(title: "Welcome to Notes", content: "This is a sample note to get you started. You can create new notes, edit them, and mark favorites.", category: .uncategorized),
            Note(title: "Meeting Notes", content: "Discuss project timeline and deliverables", isFavorite: true, category: .work),
            Note(title: "Shopping List", content: "- Milk\n- Eggs\n- Bread\n- Fruits", category: .personal)
        ]
    }
    
    private func saveProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: projectsKey)
        }
    }
    
    private func loadProjects() {
        if let savedProjects = UserDefaults.standard.data(forKey: projectsKey) {
            if let decodedProjects = try? JSONDecoder().decode([Project].self, from: savedProjects) {
                projects = decodedProjects
                return
            }
        }
        
        // Add sample project if no saved projects found
        var sampleProject = Project(
            title: "My First Project",
            description: "A collection of important notes"
        )
        
        if !notes.isEmpty {
            // Add first two notes to sample project
            sampleProject.noteIds = [notes[0].id, notes[1].id]
        }
        
        projects = [sampleProject]
    }
} 
