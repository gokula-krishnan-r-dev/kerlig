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
    
    // Scheduled task properties
    var isScheduled: Bool
    var scheduledDate: Date?
    var scheduledTime: Date?
    var priority: TaskPriority
    var imageData: Data? // Store task image as Data
    var description: String? // Additional description for scheduled tasks
    var reminderMinutes: Int? // Minutes before scheduled time to show reminder
    var hasBeenNotified: Bool // Track if notification has been shown
    
    init(id: UUID = UUID(), title: String, content: String, creationDate: Date = Date(), lastModified: Date = Date(), isFavorite: Bool = false, category: NoteCategory = .uncategorized, color: String? = nil, estimatedTime: String? = nil, isCompleted: Bool = false, actualTime: TimeInterval? = nil, isScheduled: Bool = false, scheduledDate: Date? = nil, scheduledTime: Date? = nil, priority: TaskPriority = .medium, imageData: Data? = nil, description: String? = nil, reminderMinutes: Int? = nil, hasBeenNotified: Bool = false) {
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
        self.isScheduled = isScheduled
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.priority = priority
        self.imageData = imageData
        self.description = description
        self.reminderMinutes = reminderMinutes
        self.hasBeenNotified = hasBeenNotified
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
}

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .green
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.triangle.fill"
        }
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

struct Release: Identifiable, Codable, Hashable {
    var id: UUID
    var version: String
    var name: String
    var description: String
    var creationDate: Date
    var lastModified: Date
    var targetDate: Date?
    var status: ReleaseStatus
    var projectId: UUID
    var columnIds: [UUID] // Each release has its own set of columns
    
    init(id: UUID = UUID(), version: String, name: String, description: String = "", creationDate: Date = Date(), lastModified: Date = Date(), targetDate: Date? = nil, status: ReleaseStatus = .planning, projectId: UUID, columnIds: [UUID] = []) {
        self.id = id
        self.version = version
        self.name = name
        self.description = description
        self.creationDate = creationDate
        self.lastModified = lastModified
        self.targetDate = targetDate
        self.status = status
        self.projectId = projectId
        self.columnIds = columnIds
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Release, rhs: Release) -> Bool {
        lhs.id == rhs.id
    }
}

enum ReleaseStatus: String, Codable, CaseIterable {
    case planning = "Planning"
    case inProgress = "In Progress"
    case testing = "Testing"
    case released = "Released"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .planning: return .blue
        case .inProgress: return .orange
        case .testing: return .purple
        case .released: return .green
        case .cancelled: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .planning: return "lightbulb"
        case .inProgress: return "hammer"
        case .testing: return "checkmark.shield"
        case .released: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }
}

struct Project: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var description: String
    var creationDate: Date
    var lastModified: Date
    var releaseIds: [UUID] // Projects now contain releases instead of notes directly
    var color: Color?
    var isArchived: Bool
    var logoImageData: Data? // Store the project logo image as Data
    var pageIds: [UUID] = [] // IDs of pages associated with this project
    
    init(id: UUID = UUID(), title: String, description: String, creationDate: Date = Date(), lastModified: Date = Date(), releaseIds: [UUID] = [], color: Color? = nil, isArchived: Bool = false, logoImageData: Data? = nil, pageIds: [UUID] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.creationDate = creationDate
        self.lastModified = lastModified
        self.releaseIds = releaseIds
        self.color = color
        self.isArchived = isArchived
        self.logoImageData = logoImageData
        self.pageIds = pageIds
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

// New model for project pages
struct ProjectPage: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var content: String // Rich text content stored as attributed string data
    var creationDate: Date
    var lastModified: Date
    var projectId: UUID
    var associatedTaskIds: [UUID] = [] // IDs of tasks associated with this page
    var tags: [String] = []
    var isPinned: Bool = false
    
    init(id: UUID = UUID(), title: String, content: String = "", creationDate: Date = Date(), lastModified: Date = Date(), projectId: UUID, associatedTaskIds: [UUID] = [], tags: [String] = [], isPinned: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.creationDate = creationDate
        self.lastModified = lastModified
        self.projectId = projectId
        self.associatedTaskIds = associatedTaskIds
        self.tags = tags
        self.isPinned = isPinned
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ProjectPage, rhs: ProjectPage) -> Bool {
        lhs.id == rhs.id
    }
}

class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    @Published var projects: [Project] = []
    @Published var releases: [Release] = []
    @Published var columns: [NoteColumn] = []
    @Published var currentNote: Note?
    @Published var textFormatting: TextFormatting = TextFormatting.defaultFormatting()
    @Published var pages: [ProjectPage] = [] // Store for project pages

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
    private let projectsKey = "savedProjects_v2"
    private let releasesKey = "savedReleases_v1"
    private let columnsKey = "savedColumns_v1"
    private let pagesKey = "savedPages_v1" // New key for pages
    
    init() {
        loadNotes()
        loadProjects()
        loadReleases()
        loadColumns()
        loadPages()
        
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
    
    // MARK: - Scheduled Task Methods
    func addScheduledNote(
        id: UUID = UUID(),
        title: String,
        content: String = "",
        description: String? = nil,
        scheduledDate: Date,
        scheduledTime: Date,
        priority: TaskPriority,
        estimatedTime: String? = nil,
        reminderMinutes: Int? = 15,
        imageData: Data? = nil,
        category: NoteCategory = .today
    ) {
        let scheduledNote = Note(
            id: id,
            title: title,
            content: content,
            category: category,
            estimatedTime: estimatedTime,
            isScheduled: true,
            scheduledDate: scheduledDate,
            scheduledTime: scheduledTime,
            priority: priority,
            imageData: imageData,
            description: description,
            reminderMinutes: reminderMinutes
        )
        notes.append(scheduledNote)
        saveNotes()
    }
    
    func getScheduledNotes() -> [Note] {
        return notes.filter { $0.isScheduled && !$0.isCompleted }
            .sorted { note1, note2 in
                guard let date1 = note1.scheduledDate,
                      let time1 = note1.scheduledTime,
                      let date2 = note2.scheduledDate,
                      let time2 = note2.scheduledTime else {
                    return false
                }
                
                let combined1 = Calendar.current.date(
                    bySettingHour: Calendar.current.component(.hour, from: time1),
                    minute: Calendar.current.component(.minute, from: time1),
                    second: 0,
                    of: date1
                ) ?? date1
                
                let combined2 = Calendar.current.date(
                    bySettingHour: Calendar.current.component(.hour, from: time2),
                    minute: Calendar.current.component(.minute, from: time2),
                    second: 0,
                    of: date2
                ) ?? date2
                
                return combined1 < combined2
            }
    }
    
    func getOverdueScheduledNotes() -> [Note] {
        let now = Date()
        return getScheduledNotes().filter { note in
            guard let scheduledDate = note.scheduledDate,
                  let scheduledTime = note.scheduledTime else { return false }
            
            let combinedDateTime = Calendar.current.date(
                bySettingHour: Calendar.current.component(.hour, from: scheduledTime),
                minute: Calendar.current.component(.minute, from: scheduledTime),
                second: 0,
                of: scheduledDate
            ) ?? scheduledDate
            
            return combinedDateTime < now
        }
    }
    
    func getUpcomingScheduledNotes(within minutes: Int = 15) -> [Note] {
        let now = Date()
        let futureTime = Calendar.current.date(byAdding: .minute, value: minutes, to: now) ?? now
        
        return getScheduledNotes().filter { note in
            guard let scheduledDate = note.scheduledDate,
                  let scheduledTime = note.scheduledTime else { return false }
            
            let combinedDateTime = Calendar.current.date(
                bySettingHour: Calendar.current.component(.hour, from: scheduledTime),
                minute: Calendar.current.component(.minute, from: scheduledTime),
                second: 0,
                of: scheduledDate
            ) ?? scheduledDate
            
            return combinedDateTime > now && combinedDateTime <= futureTime && !note.hasBeenNotified
        }
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
            if project.releaseIds.contains(id) {
                project.releaseIds.removeAll { $0 == id }
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
            if !project.releaseIds.contains(noteId) {
                project.releaseIds.append(noteId)
                project.lastModified = Date()
                projects[index] = project
                saveProjects()
            }
        }
    }
    
    func removeNoteFromProject(noteId: UUID, projectId: UUID) {
        if let index = projects.firstIndex(where: { $0.id == projectId }) {
            var project = projects[index]
            project.releaseIds.removeAll { $0 == noteId }
            project.lastModified = Date()
            projects[index] = project
            saveProjects()
        }
    }
    
    func getReleasesForProject(_ project: Project) -> [Release] {
        return releases.filter { project.releaseIds.contains($0.id) }
    }
    
    func getNotesForProject(_ project: Project) -> [Note] {
        // Get all notes from all releases in this project
        let projectReleases = getReleasesForProject(project)
        var allNotes: [Note] = []
        
        for release in projectReleases {
            let releaseColumns = columns.filter { release.columnIds.contains($0.id) }
            for column in releaseColumns {
                let columnNotes = notes.filter { column.noteIds.contains($0.id) }
                allNotes.append(contentsOf: columnNotes)
            }
        }
        
        return allNotes
    }
    
    private func updateProjectsLastModified(noteId: UUID) {
        for (index, project) in projects.enumerated() {
            if project.releaseIds.contains(noteId) {
                var updatedProject = project
                updatedProject.lastModified = Date()
                projects[index] = updatedProject
            }
        }
        saveProjects()
    }
    
    // MARK: - Release Management
    func addRelease(projectId: UUID, version: String, name: String, description: String = "", targetDate: Date? = nil) {
        let newRelease = Release(version: version, name: name, description: description, targetDate: targetDate, projectId: projectId)
        releases.append(newRelease)
        
        // Add release to project
        if let projectIndex = projects.firstIndex(where: { $0.id == projectId }) {
            var project = projects[projectIndex]
            project.releaseIds.append(newRelease.id)
            project.lastModified = Date()
            projects[projectIndex] = project
        }
        
        // Create default columns for this release
        createDefaultColumnsForRelease(newRelease.id)
        
        saveReleases()
        saveProjects()
    }
    
    func updateRelease(_ release: Release) {
        if let index = releases.firstIndex(where: { $0.id == release.id }) {
            var updatedRelease = release
            updatedRelease.lastModified = Date()
            releases[index] = updatedRelease
            saveReleases()
            
            // Update project last modified
            if let projectIndex = projects.firstIndex(where: { $0.releaseIds.contains(release.id) }) {
                var project = projects[projectIndex]
                project.lastModified = Date()
                projects[projectIndex] = project
                saveProjects()
            }
        }
    }
    
    func deleteRelease(_ release: Release) {
        // Remove release from project
        if let projectIndex = projects.firstIndex(where: { $0.releaseIds.contains(release.id) }) {
            var project = projects[projectIndex]
            project.releaseIds.removeAll { $0 == release.id }
            project.lastModified = Date()
            projects[projectIndex] = project
        }
        
        // Delete all columns and notes associated with this release
        let releaseColumns = columns.filter { release.columnIds.contains($0.id) }
        for column in releaseColumns {
            let columnNotes = notes.filter { column.noteIds.contains($0.id) }
            for note in columnNotes {
                notes.removeAll { $0.id == note.id }
            }
            columns.removeAll { $0.id == column.id }
        }
        
        // Remove release
        releases.removeAll { $0.id == release.id }
        
        saveReleases()
        saveProjects()
        saveColumns()
        saveNotes()
    }
    
    func getColumnsForRelease(_ release: Release) -> [NoteColumn] {
        return columns.filter { release.columnIds.contains($0.id) }.sorted(by: { $0.order < $1.order })
    }
    
    func getNotesForRelease(_ release: Release) -> [UUID: [Note]] {
        var result = [UUID: [Note]]()
        let releaseColumns = getColumnsForRelease(release)
        
        for column in releaseColumns {
            let columnNotes = notes.filter { column.noteIds.contains($0.id) }
            result[column.id] = columnNotes
        }
        
        return result
    }
    
    private func createDefaultColumnsForRelease(_ releaseId: UUID) {
        let defaultColumnTitles = ["Backlog", "In Progress", "Today", "Review", "Done", "Cancelled"]
        let defaultColors: [Color] = [.blue, .orange, .purple, .green, .red, .gray]
        
        var newColumnIds: [UUID] = []
        
        for (index, title) in defaultColumnTitles.enumerated() {
            let newColumn = NoteColumn(
                title: title,
                order: index,
                color: defaultColors[index]
            )
            columns.append(newColumn)
            newColumnIds.append(newColumn.id)
        }
        
        // Update release with column IDs
        if let releaseIndex = releases.firstIndex(where: { $0.id == releaseId }) {
            var release = releases[releaseIndex]
            release.columnIds = newColumnIds
            releases[releaseIndex] = release
        }
    }
    
    private func saveReleases() {
        if let encoded = try? JSONEncoder().encode(releases) {
            UserDefaults.standard.set(encoded, forKey: releasesKey)
        }
    }
    
    private func loadReleases() {
        if let savedReleases = UserDefaults.standard.data(forKey: releasesKey) {
            if let decodedReleases = try? JSONDecoder().decode([Release].self, from: savedReleases) {
                releases = decodedReleases
                return
            }
        }
        
        // Initialize with empty releases array
        releases = []
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
        let sampleProject = Project(
            title: "My First Project",
            description: "A collection of important tasks and releases",
            color: .blue
        )
        
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
    
    // MARK: - Task Management
    func moveNoteToEnd(_ note: Note) {
        // First, check if the note exists in the array
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        
        // Create a mutable copy of the note
        var updatedNote = note
        updatedNote.lastModified = Date() // Update the modification date
        
        // Remove the note from its current position
        notes.remove(at: index)
        
        // Find the position to insert - after the last pending note
        let pendingNotes = notes.filter { !$0.isCompleted }
        if let lastPendingIndex = notes.lastIndex(where: { !$0.isCompleted }) {
            // Insert after the last pending note
            notes.insert(updatedNote, at: lastPendingIndex + 1)
        } else {
            // If no pending notes, insert at the beginning
            notes.insert(updatedNote, at: 0)
        }
        
        // Update any columns containing this note to maintain the same order
        for (columnIndex, column) in columns.enumerated() {
            if column.noteIds.contains(note.id) {
                var updatedColumn = column
                updatedColumn.noteIds.removeAll { $0 == note.id }
                updatedColumn.noteIds.append(note.id) // Add to the end
                columns[columnIndex] = updatedColumn
            }
        }
        
        // Save changes
        saveNotes()
        saveColumns()
    }

    // MARK: - Page Management
    
    func addPage(title: String, content: String = "", projectId: UUID, isPinned: Bool = false) -> ProjectPage {
        let newPage = ProjectPage(
            title: title,
            content: content,
            projectId: projectId,
            isPinned: isPinned
        )
        
        pages.append(newPage)
        
        // Add page to project
        if let projectIndex = projects.firstIndex(where: { $0.id == projectId }) {
            var project = projects[projectIndex]
            project.pageIds.append(newPage.id)
            project.lastModified = Date()
            projects[projectIndex] = project
        }
        
        savePages()
        saveProjects()
        
        return newPage
    }
    
    func updatePage(_ page: ProjectPage) {
        if let index = pages.firstIndex(where: { $0.id == page.id }) {
            var updatedPage = page
            updatedPage.lastModified = Date()
            pages[index] = updatedPage
            savePages()
            
            // Update project last modified
            if let projectIndex = projects.firstIndex(where: { $0.id == page.projectId }) {
                var project = projects[projectIndex]
                project.lastModified = Date()
                projects[projectIndex] = project
                saveProjects()
            }
        }
    }
    
    func deletePage(_ page: ProjectPage) {
        // Remove page from project
        if let projectIndex = projects.firstIndex(where: { $0.id == page.projectId }) {
            var project = projects[projectIndex]
            project.pageIds.removeAll { $0 == page.id }
            project.lastModified = Date()
            projects[projectIndex] = project
            saveProjects()
        }
        
        // Remove page
        pages.removeAll { $0.id == page.id }
        savePages()
    }
    
    func getPagesForProject(_ project: Project) -> [ProjectPage] {
        return pages.filter { project.pageIds.contains($0.id) }
            .sorted(by: { 
                // Sort by pinned status first, then by last modified date
                if $0.isPinned && !$1.isPinned {
                    return true
                } else if !$0.isPinned && $1.isPinned {
                    return false
                } else {
                    return $0.lastModified > $1.lastModified
                }
            })
    }
    
    func createDefaultPageForProject(_ project: Project) -> ProjectPage {
        let defaultContent = """
        # \(project.title) Documentation
        
        ## Overview
        This page contains documentation and notes related to the project "\(project.title)".
        
        ## Project Details
        **Description:** \(project.description)
        **Created:** \(formatDate(project.creationDate))
        
        ## Tasks
        - [ ] Review project requirements
        - [ ] Set up initial project structure
        - [ ] Schedule kickoff meeting
        
        ## Notes
        Add your project notes here...
        """
        
        return addPage(
            title: "Project Overview",
            content: defaultContent,
            projectId: project.id,
            isPinned: true
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func associateTaskWithPage(taskId: UUID, pageId: UUID) {
        if let pageIndex = pages.firstIndex(where: { $0.id == pageId }) {
            var page = pages[pageIndex]
            if !page.associatedTaskIds.contains(taskId) {
                page.associatedTaskIds.append(taskId)
                page.lastModified = Date()
                pages[pageIndex] = page
                savePages()
            }
        }
    }
    
    func removeTaskFromPage(taskId: UUID, pageId: UUID) {
        if let pageIndex = pages.firstIndex(where: { $0.id == pageId }) {
            var page = pages[pageIndex]
            page.associatedTaskIds.removeAll { $0 == taskId }
            page.lastModified = Date()
            pages[pageIndex] = page
            savePages()
        }
    }
    
    func getTasksForPage(_ page: ProjectPage) -> [Note] {
        return notes.filter { page.associatedTaskIds.contains($0.id) }
    }
    
    private func savePages() {
        if let encoded = try? JSONEncoder().encode(pages) {
            UserDefaults.standard.set(encoded, forKey: pagesKey)
        }
    }
    
    private func loadPages() {
        if let savedPages = UserDefaults.standard.data(forKey: pagesKey) {
            if let decodedPages = try? JSONDecoder().decode([ProjectPage].self, from: savedPages) {
                pages = decodedPages
                return
            }
        }
        
        // Initialize with empty pages array
        pages = []
    }
} 
