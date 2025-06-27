import Foundation
import SwiftUI

struct Note: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var content: String
    var creationDate: Date
    var lastModified: Date
    var isFavorite: Bool
    var actualTime: TimeInterval?
    var category: NoteCategory
    var color: String? // Hex color code for note customization
    var estimatedTime: String?
    var isCompleted: Bool
    
    init(id: UUID = UUID(), title: String, content: String, creationDate: Date = Date(), lastModified: Date = Date(), isFavorite: Bool = false, category: NoteCategory = .uncategorized, color: String? = nil, estimatedTime: String? = nil, isCompleted: Bool = false, actualTime: TimeInterval? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.creationDate = creationDate
        self.lastModified = lastModified
        self.actualTime = actualTime
        self.isFavorite = isFavorite
        self.category = category
        self.color = color
        self.estimatedTime = estimatedTime
        self.isCompleted = isCompleted
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
    case backlog = "Backlog"
    case thisWeek = "This Week"
    case today = "Today"
    case done = "Done"
    case cancelled = "Cancelled"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
            case .uncategorized: return "tray"
            case .backlog: return "tray"
            case .thisWeek: return "calendar"
            case .today: return "calendar"
            case .done: return "checkmark.circle"
            case .cancelled: return "xmark.circle"
        }
    }
    
    var color: Color {
        switch self {
            case .uncategorized: return .gray
            case .backlog: return .blue
            case .thisWeek: return .purple
            case .today: return .green
            case .done: return .orange
            case .cancelled: return .red
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

struct NoteColumn: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var noteIds: [UUID]
    var order: Int
    var color: Color?
    
    init(id: UUID = UUID(), title: String, noteIds: [UUID] = [], order: Int, color: Color? = nil) {
        self.id = id
        self.title = title
        self.noteIds = noteIds
        self.order = order
        self.color = color
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NoteColumn, rhs: NoteColumn) -> Bool {
        lhs.id == rhs.id
    }
}

extension Color: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let colorString = try container.decode(String.self)
        self = Color(hex: colorString) ?? .accentColor
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("#007AFF")
    }
}

// Define text formatting options
struct TextFormatting: Codable, Hashable {
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderlined: Bool = false
    var fontSize: Int = 14
    var fontColor: String = "#000000"
    var backgroundColor: String? = nil
    
    static func defaultFormatting() -> TextFormatting {
        return TextFormatting()
    }
}

class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var projects: [Project] = []
    @Published var columns: [NoteColumn] = []
    @Published var currentNote: Note?
    @Published var textFormatting: TextFormatting = TextFormatting.defaultFormatting()

    //in notes showonly pending notes
    func getPendingNotes() -> [Note] {

        
        return notes.filter { !$0.isCompleted }
    }

    //get a first note from pending notes
    func getFirstPendingNote() -> Note? {
        return getPendingNotes().first
    }

    //getCompletedNotes
    func getCompletedNotes() -> [Note] {
        return notes.filter { $0.isCompleted }
    }

    //fetch all completed note and sum up the actual time
    func getTotalTimeSpentOnCompletedNotes() -> String {
        let totalSeconds = getCompletedNotes().reduce(0) { $0 + ($1.actualTime ?? 0) }
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) % 3600 / 60
        let seconds = Int(totalSeconds) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }




    
    private let notesKey = "savedNotes_v3"
    private let projectsKey = "savedProjects_v1"
    private let columnsKey = "savedColumns_v1"
    
    init() {
        loadNotes()
        loadProjects()
        loadColumns()
        
        // Set the first note as current if available
        if !notes.isEmpty {
            currentNote = notes[0]
        }
    }

    //refreshNotes

    func refreshNotes() {
        loadNotes()
    }
    
    func setCurrentNote(_ note: Note) {
        currentNote = note
    }
    
    func setCurrentNoteById(_ noteId: UUID) {
        currentNote = notes.first(where: { $0.id == noteId })
    }
    
    func addNote(id: UUID, title: String, content: String, category: NoteCategory = .uncategorized) {
        let newNote = Note(id: id, title: title, content: content, category: category)
        notes.append(newNote)
        saveNotes()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.lastModified = Date()
            notes[index] = updatedNote
            saveNotes()
            
            // Update current note if it's the one being updated
            if currentNote?.id == note.id {
                currentNote = updatedNote
            }
            
            // Update any projects containing this note
            updateProjectsLastModified(noteId: note.id)

            //reload the note
            loadNotes()
        }
    }
    
    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        saveNotes()
        
        // Clear current note if it's the one being deleted
        if currentNote?.id == id {
            currentNote = notes.first
        }
        
        // Remove note from any projects
        for var project in projects {
            if project.noteIds.contains(id) {
                project.noteIds.removeAll { $0 == id }
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
    
    // Make saveNotes public so it can be called from outside the class
    func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
        }
    }
    
     func loadNotes() {
        if let savedNotes = UserDefaults.standard.data(forKey: notesKey) {
            if let decodedNotes = try? JSONDecoder().decode([Note].self, from: savedNotes) {
                notes = decodedNotes
                print("Notes loaded successfully")
                print(notes)
                return
            }
        }


        print("No saved notes found")
        
        // Add sample notes if no saved notes found
        notes = [
            Note(title: "Welcome to Notes", content: "This is a sample note to get you started. You can create new notes, edit them, and mark favorites.", category: .uncategorized),
            Note(title: "Meeting Notes", content: "Discuss project timeline and deliverables", isFavorite: true, category: .backlog),
            Note(title: "Shopping List", content: "- Milk\n- Eggs\n- Bread\n- Fruits", category: .today)
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
    
    // MARK: - Column Management
    func addColumn(title: String, color: Color? = nil) {
        let order = columns.count
        let newColumn = NoteColumn(title: title, order: order, color: color)
        columns.append(newColumn)
        saveColumns()
    }
    
    func updateColumn(_ column: NoteColumn) {
        if let index = columns.firstIndex(where: { $0.id == column.id }) {
            columns[index] = column
            saveColumns()
        }
    }
    
    func deleteColumn(_ column: NoteColumn) {
        columns.removeAll { $0.id == column.id }
        // Reorder remaining columns
        for (index, var column) in columns.enumerated() {
            column.order = index
            columns[index] = column
        }
        saveColumns()
    }
    
    func moveNote(_ note: Note, from sourceColumn: NoteColumn, to targetColumn: NoteColumn) {
        var updatedSourceColumn = sourceColumn
        var updatedTargetColumn = targetColumn
        
        updatedSourceColumn.noteIds.removeAll { $0 == note.id }
        if !updatedTargetColumn.noteIds.contains(note.id) {
            updatedTargetColumn.noteIds.append(note.id)
        }
        
        updateColumn(updatedSourceColumn)
        updateColumn(updatedTargetColumn)
    }
    
    func getNotesForColumn(_ column: NoteColumn) -> [Note] {
        return notes.filter { column.noteIds.contains($0.id) }
    }
    
    private func saveColumns() {
        if let encoded = try? JSONEncoder().encode(columns) {
            UserDefaults.standard.set(encoded, forKey: columnsKey)
        }
    }
    
    private func loadColumns() {
        if let savedColumns = UserDefaults.standard.data(forKey: columnsKey) {
            if let decodedColumns = try? JSONDecoder().decode([NoteColumn].self, from: savedColumns) {
                columns = decodedColumns
                return
            }
        }
        
        // Add default columns if no saved columns found
        columns = [
            NoteColumn(title: "Backlog", order: 0, color: .blue),
            NoteColumn(title: "This week", order: 1, color: .orange),
            NoteColumn(title: "Today", order: 2, color: .green),
            NoteColumn(title: "Done", order: 3, color: .orange),
            NoteColumn(title: "Cancelled", order: 4, color: .red)
        ]
        
        // Distribute existing notes among default columns
        if !notes.isEmpty {
            let notesPerColumn = notes.count / columns.count
            for (index, var column) in columns.enumerated() {
                let start = index * notesPerColumn
                let end = index == columns.count - 1 ? notes.count : start + notesPerColumn
                column.noteIds = Array(notes[start..<end].map { $0.id })
                columns[index] = column
            }
        }
        
        saveColumns()
    }
    
    // MARK: - Text Formatting
    func applyBold() {
        textFormatting.isBold.toggle()
    }
    
    func applyItalic() {
        textFormatting.isItalic.toggle()
    }
    
    func applyUnderline() {
        textFormatting.isUnderlined.toggle()
    }
    
    func changeFontSize(_ size: Int) {
        textFormatting.fontSize = size
    }
    
    func changeFontColor(_ hexColor: String) {
        textFormatting.fontColor = hexColor
    }
} 
