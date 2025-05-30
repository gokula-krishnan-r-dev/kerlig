import SwiftUI
import AppKit

struct ProjectsPanelView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    // State variables
    @State private var projects: [VSCodeProject] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = true
    @State private var selectedProject: VSCodeProject? = nil
    @State private var hoveredProjectId: UUID? = nil
    @State private var showNoProjectsFound: Bool = false
    
    // Injected dependencies
    let projectsService: VSCodeProjectsService
    let onClose: () -> Void
    
    // Computed properties
    private var filteredProjects: [VSCodeProject] {
        if searchText.isEmpty {
            return projects
        } else {
            return projects.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.path.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search
            VStack(spacing: 12) {
                HStack {
                    Text("VS Code Projects")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(0.7)
                    .padding(.trailing, 4)
                }
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                    
                    TextField("Search projects...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .font(.system(size: 14))
                        .onSubmit {
                            if let firstProject = filteredProjects.first {
                                openProject(firstProject)
                            }
                        }
                        .onAppear {
                            // Auto-focus the search field
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                NSApp.keyWindow?.makeFirstResponder(
                                    NSApp.keyWindow?.contentView?.viewWithTag(100) as? NSTextField
                                )
                            }
                        }
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.1))
                )
                .frame(height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // Project list
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                    .padding()
                Spacer()
            } else if showNoProjectsFound {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No VS Code projects found")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Make sure VS Code is installed and you have opened projects with it")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding()
                Spacer()
            } else if filteredProjects.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    
                    Text("No matching projects")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Try a different search term")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding()
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredProjects) { project in
                            ProjectItemView(
                                project: project,
                                isHovered: hoveredProjectId == project.id,
                                onHover: { isHovered in
                                    if isHovered {
                                        hoveredProjectId = project.id
                                    } else if hoveredProjectId == project.id {
                                        hoveredProjectId = nil
                                    }
                                },
                                onClick: {
                                    openProject(project)
                                }
                            )
                            .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .onAppear {
            loadProjects()
        }
    }
    
    // Load projects from service
    private func loadProjects() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedProjects = projectsService.loadProjects()
            
            DispatchQueue.main.async {
                projects = loadedProjects
                isLoading = false
                showNoProjectsFound = loadedProjects.isEmpty
            }
        }
    }
    
    // Open selected project
    private func openProject(_ project: VSCodeProject) {
        selectedProject = project
        
        // Attempt to open the project with VS Code
        if projectsService.openProject(at: project.path) {
            // Close the panel after successful opening
            onClose()
        } else {
            // Show error alert if opening fails
            let alert = NSAlert()
            alert.messageText = "Failed to Open Project"
            alert.informativeText = "Could not open project at path: \(project.path)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

// Individual project item view
struct ProjectItemView: View {
    let project: VSCodeProject
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let onClick: () -> Void
    
    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 12) {
                // VS Code icon
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.blue)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    // Project name
                    Text(project.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Project path
                    Text(project.path)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Last opened date if available
                if let lastOpened = project.lastOpened {
                    Text(formatDate(lastOpened))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Open icon
                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1.0 : 0.0)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.primary.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover(perform: onHover)
    }
    
    // Format date to relative time
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "Yesterday" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour) hour\(hour == 1 ? "" : "s") ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute) minute\(minute == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
} 