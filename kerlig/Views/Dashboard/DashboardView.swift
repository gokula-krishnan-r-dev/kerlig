import SwiftUI

struct DashboardView: View {
    @StateObject private var noteStore = NoteStore()
    @State private var showTaskTimerDemo = false
    @State private var currentTime = Date()
    @State private var timeTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let floatingSidebarController = FloatingSidebarController()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Header Section
                headerSection
                
                // Stats Overview
                statsOverviewSection
                
                // Active Timer Section
                if noteStore.activeTimerNote != nil {
                    activeTimerSection
                }
                
                // Quick Actions
                quickActionsSection
                
                // Recent Tasks
                recentTasksSection
                
                // Task Categories Overview
                categoriesOverviewSection
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(NSColor.controlBackgroundColor),
                    Color(NSColor.controlBackgroundColor).opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onReceive(timeTimer) { _ in
            currentTime = Date()
        }
        .sheet(isPresented: $showTaskTimerDemo) {
            TaskTimerDemoView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(greetingText)")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currentTime, style: .time)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(currentTime, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Stats Overview Section
    private var statsOverviewSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
            StatCard(
                title: "Total Tasks",
                value: "\(noteStore.notes.count)",
                icon: "list.bullet",
                color: .blue,
                gradient: [.blue, .blue.opacity(0.7)]
            )
            
            StatCard(
                title: "Pending",
                value: "\(noteStore.getPendingNotes().count)",
                icon: "clock.fill",
                color: .orange,
                gradient: [.orange, .orange.opacity(0.7)]
            )
            
            StatCard(
                title: "Completed",
                value: "\(noteStore.getCompletedNotes().count)",
                icon: "checkmark.circle.fill",
                color: .green,
                gradient: [.green, .green.opacity(0.7)]
            )
            
            StatCard(
                title: "Time Spent",
                value: noteStore.getTotalTimeSpentOnCompletedNotes(),
                icon: "timer.circle.fill",
                color: .purple,
                gradient: [.purple, .purple.opacity(0.7)]
            )
        }
    }
    
    // MARK: - Active Timer Section
    private var activeTimerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "timer.circle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Active Timer")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(noteStore.formatTime(noteStore.getTotalElapsedTimeForActiveTask()))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            if let activeNote = noteStore.activeTimerNote {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activeNote.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                        
                        Text("Status: \(noteStore.globalTimerState.rawValue.capitalized)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(timerStatusColor)
                        .frame(width: 12, height: 12)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                // MacWrite Button
                Button(action: showMacWrite) {
                    ActionCard(
                        title: "Mac Write",
                        subtitle: "Start writing and capture tasks",
                        icon: "pencil.circle.fill",
                        color: .green,
                        isProminent: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Task Timer Demo Button
                Button(action: { showTaskTimerDemo = true }) {
                    ActionCard(
                        title: "Task Timer",
                        subtitle: "Demo timer functionality",
                        icon: "timer.circle.fill",
                        color: .blue,
                        isProminent: false
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Recent Tasks Section
    private var recentTasksSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Button("View All") {
                    // Navigate to task management
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(Array(noteStore.notes.prefix(5).enumerated()), id: \.element.id) { index, note in
                    DashboardTaskRowView(note: note, index: index)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Categories Overview Section
    private var categoriesOverviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Task Categories")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(NoteCategory.allCases, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        count: noteStore.notes.filter { $0.category == category }.count
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Properties
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Night"
        }
    }
    
    private var timerStatusColor: Color {
        switch noteStore.globalTimerState {
        case .running: return .green
        case .paused: return .yellow
        case .break: return .blue
        case .stopped: return .gray
        }
    }
    
    // MARK: - Helper Functions
    private func showMacWrite() {
        // Close any existing windows first
        if let existingWindow = NSApp.windows.first(where: { $0.isVisible }) {
            existingWindow.close()
        }
        floatingSidebarController.toggleSidebar()
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: gradient.map { $0.opacity(0.1) }),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isProminent: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isProminent ? .white : color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isProminent ? .white : .primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(isProminent ? .white.opacity(0.8) : .secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "arrow.right.circle.fill")
                .font(.title3)
                .foregroundColor(isProminent ? .white.opacity(0.8) : color.opacity(0.7))
        }
        .padding(16)
        .background(
            isProminent ? 
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [color.opacity(0.1), color.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isProminent ? Color.clear : color.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isProminent ? 1.02 : 1.0)
        .shadow(color: isProminent ? color.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
    }
}

struct DashboardTaskRowView: View {
    let note: Note
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            Circle()
                .fill(note.priority.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(note.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .strikethrough(note.isCompleted)
                    .foregroundColor(note.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    Text(note.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(note.category.color.opacity(0.2), in: Capsule())
                        .foregroundColor(note.category.color)
                    
                    if let actualTime = note.actualTime, actualTime > 0 {
                        Text(formatTimeShort(actualTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if note.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.subheadline)
            } else if note.timerState == .running {
                Image(systemName: "timer.circle.fill")
                    .foregroundColor(.orange)
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
    }
    
    private func formatTimeShort(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct CategoryCard: View {
    let category: NoteCategory
    let count: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: category.iconName)
                .font(.title3)
                .foregroundColor(category.color)
            
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(category.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(category.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(category.color.opacity(0.2), lineWidth: 1)
        )
    }
}