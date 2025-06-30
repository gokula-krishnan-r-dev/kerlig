// import SwiftUI

// struct LeftSidebarView: View {
//        @StateObject private var noteStore = NoteStore()
//     @Binding var selectedProject: Project?
//     @Binding var isAddingProject: Bool
//     @Binding var filteredProjects: [Project]
//     @Binding var searchText: String
//     @Binding var selectedFilter: FilterOption
//     @Binding var showCompletedTasks: Bool
//     @Binding var animateIn: Bool
//     @Binding var isProjectListExpanded: Bool
//     @Binding var isReleaseListExpanded: Bool
//     @Binding var isColumnsListExpanded: Bool
//     @Binding var isLoadingColumns: Bool
//     @Binding var taskColumns: [NoteColumn]
//     @Binding var taskColumnNotes: [UUID: [Note]]
//     @Binding var selectedRelease: Release?
//     @Binding var isAddingRelease: Bool
//     @Binding var createDefaultColumnsForRelease: (Release) -> Void
//     @Binding var loadTaskDataForRelease: (Release) -> Void
//     @Binding var filteredReleases: [Release]
//      // Color palette   
//     private let primaryBgColor = Color(hex: "#0A0A0B")
//     private let secondaryBgColor = Color(hex: "#1C1C1E")
//     private let cardBgColor = Color(hex: "#2C2C2E")
//     private let accentColor = Color(hex: "#007AFF")
//     private let successColor = Color(hex: "#34C759")
//     private let warningColor = Color(hex: "#FF9F0A")
//     private let errorColor = Color(hex: "#FF3B30")

//      private let accentGradient = LinearGradient(
//         gradient: Gradient(colors: [Color(hex: "#007AFF"), Color(hex: "#0056CC")]),
//         startPoint: .leading,
//         endPoint: .trailing
//     )

//     var body: some View {
//  VStack(spacing: 0) {
//             // Header
//             sidebarHeader
            
//             // Search bar
//             searchBar
            
//             // Projects list
//             projectsList
            
//             // Releases section
//             if selectedProject != nil {
//                 releasesSection
//             }
//         }
//         .frame(width: 350)
//         .background(secondaryBgColor)
//         .overlay(
//             Rectangle()
//                 .frame(width: 1)
//                 .foregroundColor(Color.gray.opacity(0.2))
//                 .offset(x: 1),
//             alignment: .trailing
//         )
//     }
//       private var sidebarHeader: some View {
//         HStack {
//             VStack(alignment: .leading, spacing: 4) {
//                 Text("Task Management")
//                     .font(.title2)
//                     .fontWeight(.bold)
//                     .foregroundColor(.white)
                
//                 Text("\(filteredProjects.count) projects")
//                     .font(.caption)
//                     .foregroundColor(.gray)
//             }
            
//             Spacer()
            
//             Button(action: {
//                 isAddingProject = true
//             }) {
//                 Image(systemName: "plus.circle.fill")
//                     .font(.title3)
//                     .foregroundColor(accentColor)
//             }
//             .buttonStyle(AnimatedButtonStyle())
//         }
//         .padding()
//         .background(Color(hex: "#1C1C1E"))
//         .opacity(animateIn ? 1 : 0)
//         .offset(y: animateIn ? 0 : -20)
//         .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)
//     }
    
//     private var searchBar: some View {
//         HStack {
//             Image(systemName: "magnifyingglass")
//                 .foregroundColor(.gray)
//                 .font(.system(size: 14))
            
//             TextField("Search projects and tasks...", text: $searchText)
//                 .textFieldStyle(PlainTextFieldStyle())
//                 .font(.system(size: 14))
//                 .foregroundColor(.white)
            
//             if !searchText.isEmpty {
//                 Button(action: {
//                     searchText = ""
//                 }) {
//                     Image(systemName: "xmark.circle.fill")
//                         .foregroundColor(.gray)
//                         .font(.system(size: 14))
//                 }
//                 .buttonStyle(PlainButtonStyle())
//             }
//         }
//         .padding(10)
//         .background(cardBgColor)
//         .cornerRadius(8)
//         .padding(.horizontal)
//         .padding(.bottom, 8)
//         .opacity(animateIn ? 1 : 0)
//         .offset(y: animateIn ? 0 : -10)
//         .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)
//     }
    
//     private var projectsList: some View {
//         VStack(alignment: .leading, spacing: 0) {
//             // Projects header
//             HStack {
//                 Button(action: {
//                     withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
//                         isProjectListExpanded.toggle()
//                     }
//                 }) {
//                     HStack(spacing: 8) {
//                         Image(systemName: isProjectListExpanded ? "chevron.down" : "chevron.right")
//                             .font(.system(size: 12, weight: .medium))
//                             .foregroundColor(.gray)
                        
//                         Text("PROJECTS")
//                             .font(.system(size: 12, weight: .semibold))
//                             .foregroundColor(.gray)
                        
//                         Spacer()
                        
//                         Text("\(filteredProjects.count)")
//                             .font(.system(size: 11, weight: .medium))
//                             .foregroundColor(.gray)
//                             .padding(.horizontal, 6)
//                             .padding(.vertical, 2)
//                             .background(Color.gray.opacity(0.2))
//                             .cornerRadius(8)
//                     }
//                 }
//                 .buttonStyle(PlainButtonStyle())
//             }
//             .padding(.horizontal)
//             .padding(.vertical, 8)
            
//             // Projects list
//             if isProjectListExpanded {
//                 ScrollView {
//                     LazyVStack(spacing: 4) {
//                         ForEach(Array(zip(filteredProjects.indices, filteredProjects)), id: \.1.id) { index, project in
//                             ProjectRowView(
//                                 project: project,
//                                 isSelected: selectedProject?.id == project.id,
//                                 onSelect: {
//                                     withAnimation(.easeInOut(duration: 0.3)) {
//                                         selectedProject = project
//                                     }
//                                 },
//                                 onDelete: {
//                                     deleteProject(project)
//                                 }
//                             )
//                             .opacity(animateIn ? 1 : 0)
//                             .offset(x: animateIn ? 0 : -20)
//                             .animation(.easeOut(duration: 0.4).delay(0.3 + Double(index) * 0.05), value: animateIn)
//                         }
//                     }
//                     .padding(.horizontal, 8)
//                 }
//             }
            
//             // All releases list (not filtered by project)
//             allReleasesList
//         }
//     }

//     private var allReleasesList: some View {
//         VStack(alignment: .leading, spacing: 0) {
//             // Releases header
//             HStack {
//                 Button(action: {
//                     withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
//                         isReleaseListExpanded.toggle()
//                     }
//                 }) {
//                     HStack(spacing: 8) {
//                         Image(systemName: isReleaseListExpanded ? "chevron.down" : "chevron.right")
//                             .font(.system(size: 12, weight: .medium))
//                             .foregroundColor(.gray)
                        
//                         Text("ALL RELEASES")
//                             .font(.system(size: 12, weight: .semibold))
//                             .foregroundColor(.gray)
                        
//                         Spacer()
                        
//                         Text("\(noteStore.releases.count)")
//                             .font(.system(size: 11, weight: .medium))
//                             .foregroundColor(.gray)
//                             .padding(.horizontal, 6)
//                             .padding(.vertical, 2)
//                             .background(Color.gray.opacity(0.2))
//                             .cornerRadius(8)
//                     }
//                 }
//                 .buttonStyle(PlainButtonStyle())
//             }
//             .padding(.horizontal)
//             .padding(.vertical, 8)
//             .background(Color.gray.opacity(0.05))
            
//             if isReleaseListExpanded && !noteStore.releases.isEmpty {
//                 ScrollView {
//                     LazyVStack(spacing: 4) {
//                         ForEach(noteStore.releases.sorted(by: { $0.creationDate > $1.creationDate })) { release in
//                             let project = noteStore.projects.first(where: { $0.id == release.projectId })
//                             ReleaseRowView(
//                                 release: release,
//                                 projectTitle: getProjectTitle(for: release),
//                                 isSelected: selectedRelease?.id == release.id,
//                                 onSelect: {
//                                     // Find and select the project first
//                                     if let project = noteStore.projects.first(where: { $0.id == release.projectId }) {
//                                         selectedProject = project
//                                         // Then select the release
//                                         selectedRelease = release
//                                     }
//                                 },
//                                 onDelete: {
//                                     deleteRelease(release)
//                                 },
//                                 projectLogoData: project?.logoImageData
//                             )
//                             .padding(.horizontal, 8)
//                         }
//                     }
//                     .padding(.vertical, 4)
//                 }
//                 .frame(maxHeight: 200)
//             }
            
//             // Task columns list (for selected release)
//             if let release = selectedRelease {
//                 taskColumnsList(for: release)
//             }
//         }
//         .opacity(animateIn ? 1 : 0)
//         .offset(y: animateIn ? 0 : 20)
//         .animation(.easeOut(duration: 0.6).delay(0.5), value: animateIn)
//     }
//       private func taskColumnsList(for release: Release) -> some View {
//         VStack(alignment: .leading, spacing: 0) {
//             // Columns header
//             HStack {
//                 Button(action: {
//                     withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
//                         isColumnsListExpanded.toggle()
//                     }
//                 }) {
//                     HStack(spacing: 8) {
//                         Image(systemName: isColumnsListExpanded ? "chevron.down" : "chevron.right")
//                             .font(.system(size: 12, weight: .medium))
//                             .foregroundColor(.gray)
                        
//                         Text("TASK COLUMNS")
//                             .font(.system(size: 12, weight: .semibold))
//                             .foregroundColor(.gray)
                        
//                         Spacer()
                        
//                         if isLoadingColumns {
//                             ProgressView()
//                                 .scaleEffect(0.7)
//                                 .progressViewStyle(CircularProgressViewStyle(tint: .gray))
//                         } else {
//                             Text("\(taskColumns.count)")
//                                 .font(.system(size: 11, weight: .medium))
//                                 .foregroundColor(.gray)
//                                 .padding(.horizontal, 6)
//                                 .padding(.vertical, 2)
//                                 .background(Color.gray.opacity(0.2))
//                                 .cornerRadius(8)
//                         }
//                     }
//                 }
//                 .buttonStyle(PlainButtonStyle())
//             }
//             .padding(.horizontal)
//             .padding(.vertical, 8)
//             .background(Color.gray.opacity(0.05))
            
//             if isColumnsListExpanded {
//                 if isLoadingColumns {
//                     HStack {
//                         Spacer()
//                         ProgressView("Loading columns...")
//                             .font(.system(size: 12))
//                             .foregroundColor(.gray)
//                         Spacer()
//                     }
//                     .padding()
//                 } else if !taskColumns.isEmpty {
//                     ScrollView {
//                         LazyVStack(spacing: 4) {
//                             ForEach(taskColumns.sorted(by: { $0.order < $1.order })) { column in
//                                 EnhancedColumnRowView(
//                                     column: column,
//                                     taskCount: taskColumnNotes[column.id]?.count ?? 0
//                                 )
//                                 .padding(.horizontal, 8)
//                             }
//                         }
//                         .padding(.vertical, 4)
//                     }
//                     .frame(maxHeight: 200)
//                 } else {
//                     VStack(spacing: 12) {
//                         Image(systemName: "rectangle.3.group")
//                             .font(.system(size: 24))
//                             .foregroundColor(.gray.opacity(0.5))
                        
//                         Text("No columns available")
//                             .font(.system(size: 12))
//                             .foregroundColor(.gray)
                        
//                         Button(action: {
//                             createDefaultColumnsForRelease(release)
//                             loadTaskDataForRelease(release)
//                         }) {
//                             Text("Create Default Columns")
//                                 .font(.system(size: 11, weight: .medium))
//                                 .foregroundColor(.white)
//                                 .padding(.horizontal, 12)
//                                 .padding(.vertical, 6)
//                                 .background(accentColor)
//                                 .cornerRadius(12)
//                         }
//                         .buttonStyle(AnimatedButtonStyle())
//                     }
//                     .frame(maxWidth: .infinity, alignment: .center)
//                     .padding()
//                 }
//             }
//         }
//         .opacity(animateIn ? 1 : 0)
//         .offset(y: animateIn ? 0 : 20)
//         .animation(.easeOut(duration: 0.6).delay(0.6), value: animateIn)
//     }

//      // Helper function to get project title for a release
//     private func getProjectTitle(for release: Release) -> String {
//         if let project = noteStore.projects.first(where: { $0.id == release.projectId }) {
//             return project.title
//         }
//         return "Unknown Project"
//     }
    
//     // Delete project function
//     private func deleteProject(_ project: Project) {
//         // First delete all releases associated with this project
//         let projectReleases = noteStore.getReleasesForProject(project)
//         for release in projectReleases {
//             noteStore.deleteRelease(release)
//         }
        
//         // Then delete the project itself
//         noteStore.deleteProject(project)
        
//         // Update selection if needed
//         if selectedProject?.id == project.id {
//             selectedProject = noteStore.projects.first
//             selectedRelease = nil
//         }
//     }
    
//     // Delete release function
//     private func deleteRelease(_ release: Release) {
//         noteStore.deleteRelease(release)
        
//         // Update selection if needed
//         if selectedRelease?.id == release.id {
//             if let project = selectedProject {
//                 let releases = noteStore.getReleasesForProject(project)
//                 selectedRelease = releases.first
//             }
//         }
//     }

        
//     private var releasesSection: some View {
//         VStack(alignment: .leading, spacing: 0) {
//             // Releases header
//             HStack {
//                 Text("RELEASES")
//                     .font(.system(size: 12, weight: .semibold))
//                     .foregroundColor(.gray)
                
//                 Spacer()
                
//                 Text("\(filteredReleases.count)")
//                     .font(.system(size: 11, weight: .medium))
//                     .foregroundColor(.gray)
//                     .padding(.horizontal, 6)
//                     .padding(.vertical, 2)
//                     .background(Color.gray.opacity(0.2))
//                     .cornerRadius(8)
                
//                 Button(action: {
//                     isAddingRelease = true
//                 }) {
//                     Image(systemName: "plus")
//                         .font(.system(size: 12))
//                         .foregroundColor(accentColor)
//                 }
//                 .buttonStyle(AnimatedButtonStyle())
//             }
//             .padding(.horizontal)
//             .padding(.vertical, 8)
//             .background(Color.gray.opacity(0.05))
            
//             // Release dropdown/selector
//             if !filteredReleases.isEmpty {
//                 Menu {
//                     ForEach(filteredReleases, id: \.id) { release in
//                         Button(action: {
//                             withAnimation(.easeInOut(duration: 0.3)) {
//                                 selectedRelease = release
//                             }
//                         }) {
//                             HStack {
//                                 Image(systemName: release.status.iconName)
//                                     .foregroundColor(release.status.color)
                                
//                                 VStack(alignment: .leading) {
//                                     Text("v\(release.version)")
//                                         .font(.system(size: 14, weight: .semibold))
//                                     Text(release.name)
//                                         .font(.system(size: 12))
//                                         .foregroundColor(.gray)
//                                 }
                                
//                                 if selectedRelease?.id == release.id {
//                                     Spacer()
//                                     Image(systemName: "checkmark")
//                                         .foregroundColor(accentColor)
//                                 }
//                             }
//                         }
//                     }
//                 } label: {
//                     HStack {
//                         if let release = selectedRelease {
//                             HStack(spacing: 8) {
//                                 Image(systemName: release.status.iconName)
//                                     .foregroundColor(release.status.color)
//                                     .font(.system(size: 14))
                                
//                                 VStack(alignment: .leading, spacing: 2) {
//                                     Text("v\(release.version)")
//                                         .font(.system(size: 14, weight: .semibold))
//                                         .foregroundColor(.white)
                                    
//                                     Text(release.name)
//                                         .font(.system(size: 12))
//                                         .foregroundColor(.gray)
//                                 }
                                
//                                 Spacer()
                                
//                                 Image(systemName: "chevron.down")
//                                     .font(.system(size: 10))
//                                     .foregroundColor(.gray)
//                             }
//                         } else {
//                             HStack {
//                                 Text("Select Release")
//                                     .font(.system(size: 14))
//                                     .foregroundColor(.gray)
                                
//                                 Spacer()
                                
//                                 Image(systemName: "chevron.down")
//                                     .font(.system(size: 10))
//                                     .foregroundColor(.gray)
//                             }
//                         }
//                     }
//                     .padding()
//                     .background(cardBgColor)
//                     .cornerRadius(8)
//                 }
//                 .padding(.horizontal)
//             } else {
//                 // No releases message
//                 VStack(spacing: 12) {
//                     Image(systemName: "calendar.badge.plus")
//                         .font(.system(size: 24))
//                         .foregroundColor(.gray.opacity(0.5))
                    
//                     Text("No releases yet")
//                         .font(.system(size: 14))
//                         .foregroundColor(.gray)
                    
//                     Button(action: {
//                         isAddingRelease = true
//                     }) {
//                         Text("Create First Release")
//                             .font(.system(size: 12, weight: .medium))
//                             .foregroundColor(.white)
//                             .padding(.horizontal, 16)
//                             .padding(.vertical, 8)
//                             .background(accentGradient)
//                             .cornerRadius(16)
//                     }
//                     .buttonStyle(AnimatedButtonStyle())
//                 }
//                 .frame(maxWidth: .infinity)
//                 .padding()
//             }
//         }
//         .opacity(animateIn ? 1 : 0)
//         .offset(y: animateIn ? 0 : 20)
//         .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
//     }
    
// }