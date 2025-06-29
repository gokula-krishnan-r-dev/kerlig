import SwiftUI

struct NoteBoardView: View {
    @StateObject private var noteStore = NoteStore()
    @State private var isAddingColumn = false
    @State private var newColumnTitle = ""
    @State private var selectedColumnColor: Color = .blue
    @Environment(\.colorScheme) private var colorScheme
    private let floatingSidebarController = FloatingSidebarController()
    
    // Animation states
    @State private var isHeaderVisible = false
    @State private var areColumnsVisible = false
    
    // Search and filter states
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var selectedFilter: FilterOption = .all
    @State private var isFilterMenuOpen = false
    
    // View mode and UI states
    @State private var viewMode: ViewMode = .board
    @State private var isCompactMode = false
    @State private var showCompletedTasks = true
    @State private var isSettingsOpen = false
    
    // Column management
    @State private var draggingColumnId: UUID?
    @State private var isDraggingColumn = false
    
    // Define a consistent color palette
    private let primaryBgColor = Color(hex: "#1A1A1C")
    private let secondaryBgColor = Color(hex: "#242426") 
    private let accentColor = Color(hex: "#4CAF50")
    private let accentGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#4CAF50"), Color(hex: "#45A049")]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    private let availableColors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink,
        Color(hex: "#00BCD4"), Color(hex: "#FF5722"), Color(hex: "#9C27B0")
    ]
    
    // Computed properties for filtering
    private var filteredColumns: [NoteColumn] {
        noteStore.columns.sorted(by: { $0.order < $1.order })
    }
    
    private var filteredNotes: [UUID: [Note]] {
        var result = [UUID: [Note]]()
        
        for column in filteredColumns {
            let notes = noteStore.getNotesForColumn(column)
                .filter { note in
                    let matchesSearch = searchText.isEmpty || 
                        note.title.lowercased().contains(searchText.lowercased()) ||
                        note.content.lowercased().contains(searchText.lowercased())
                    
                    let matchesFilter: Bool
                    switch selectedFilter {
                    case .all:
                        matchesFilter = true
                    case .completed:
                        matchesFilter = note.isCompleted
                    case .incomplete:
                        matchesFilter = !note.isCompleted
                    }
                    
                    let matchesCompleted = showCompletedTasks || !note.isCompleted
                    
                    return matchesSearch && matchesFilter && matchesCompleted
                }
            
            result[column.id] = notes
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            headerView
            
            // Main content based on view mode
            Group {
                if viewMode == .board {
                    boardView
                } else {
                    listView
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(primaryBgColor)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    isHeaderVisible = true
                    areColumnsVisible = true
                }
            }
        }
        .sheet(isPresented: $isAddingColumn) {
            addColumnSheet
        }
        .sheet(isPresented: $isSettingsOpen) {
            settingsView
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 0) {
            // Main header with title and actions
            HStack {
                Text("Notes Board")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // View mode toggle
                HStack(spacing: 2) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewMode = .board
                        }
                    }) {
                        Image(systemName: "square.grid.2x2")
                            .foregroundColor(viewMode == .board ? .white : .gray)
                            .padding(8)
                            .background(viewMode == .board ? Color(hex: "#2C2C2E") : Color.clear)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewMode = .list
                        }
                    }) {
                        Image(systemName: "list.bullet")
                            .foregroundColor(viewMode == .list ? .white : .gray)
                            .padding(8)
                            .background(viewMode == .list ? Color(hex: "#2C2C2E") : Color.clear)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(4)
                .background(Color(hex: "#1C1C1E"))
                .cornerRadius(10)
                
                // Settings button
                Button(action: {
                    isSettingsOpen = true
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color(hex: "#2C2C2E"))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Start working button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        let window = NSApplication.shared.windows.first
                        window?.close()
                        floatingSidebarController.toggleSidebar()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .rotationEffect(.degrees(45))
                        Text("Start Working Now")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accentGradient)
                    .cornerRadius(20)
                    .shadow(color: accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(AnimatedButtonStyle())
            }
            .padding()
            .background(Color(hex: "#1C1C1E"))
            .opacity(isHeaderVisible ? 1 : 0)
            .offset(y: isHeaderVisible ? 0 : -20)
            
            // Search and filter bar
            HStack(spacing: 16) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(isSearchActive ? accentColor : .gray)
                        .font(.system(size: 14))
                    
                    TextField("Search tasks...", text: $searchText, onEditingChanged: { editing in
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
                .padding(8)
                .background(Color(hex: "#2C2C2E"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSearchActive ? accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                )
                
                // Filter menu
                Menu {
                    Button(action: { selectedFilter = .all }) {
                        HStack {
                            Text("All Tasks")
                            if selectedFilter == .all {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button(action: { selectedFilter = .completed }) {
                        HStack {
                            Text("Completed Tasks")
                            if selectedFilter == .completed {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button(action: { selectedFilter = .incomplete }) {
                        HStack {
                            Text("Incomplete Tasks")
                            if selectedFilter == .incomplete {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        withAnimation {
                            showCompletedTasks.toggle()
                        }
                    }) {
                        HStack {
                            Text("Show Completed Tasks")
                            Spacer()
                            Image(systemName: showCompletedTasks ? "checkmark.square" : "square")
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 14))
                        Text(selectedFilter.rawValue)
                            .font(.system(size: 14))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#2C2C2E"))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Add column button
                Button(action: {
                    isAddingColumn = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                        Text("New Column")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accentGradient)
                    .cornerRadius(8)
                }
                .buttonStyle(AnimatedButtonStyle())
                
                // Compact mode toggle
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isCompactMode.toggle()
                    }
                }) {
                    Image(systemName: isCompactMode ? "arrow.left.and.right.square" : "arrow.up.and.down.square")
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color(hex: "#2C2C2E"))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .help(isCompactMode ? "Expand columns" : "Compact columns")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(hex: "#1C1C1E").opacity(0.8))
            .opacity(isHeaderVisible ? 1 : 0)
        }
    }
    
    private var boardView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: isCompactMode ? 8 : 16) {
                ForEach(Array(zip(filteredColumns.indices, filteredColumns)), id: \.1.id) { index, column in
                    NoteColumnView(
                        column: column,
                        notes: filteredNotes[column.id] ?? [],
                        noteStore: noteStore
                    )
                    .onAppear {
                        noteStore.loadNotes()
                    }
                    .onChange(of: noteStore.notes) { _, _ in
                        noteStore.loadNotes()
                    }
                    .opacity(areColumnsVisible ? 1 : 0)
                    .offset(y: areColumnsVisible ? 0 : 50)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1 + Double(index) * 0.1), value: areColumnsVisible)
                    .frame(width: isCompactMode ? 280 : 320)
                    .overlay(
                        dragHandleOverlay(for: column)
                            .opacity(isDraggingColumn ? 1 : 0)
                    )
                    .onDrag {
                        self.draggingColumnId = column.id
                        self.isDraggingColumn = true
                        return NSItemProvider(object: column.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], isTargeted: nil) { providers in
                        guard let draggedId = self.draggingColumnId else { return false }
                        
                        if draggedId != column.id {
                            reorderColumns(from: draggedId, to: column.id)
                        }
                        
                        self.isDraggingColumn = false
                        return true
                    }
                }
                
                // Add column button (visual)
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: "#2C2C2E"))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.gray)
                        )
                    Text("Add Column")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(width: isCompactMode ? 180 : 200, height: 140)
                .background(Color(hex: "#1C1C1E"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .onTapGesture {
                    isAddingColumn = true
                }
                .opacity(areColumnsVisible ? 1 : 0)
                .offset(y: areColumnsVisible ? 0 : 50)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3 + Double(noteStore.columns.count) * 0.1), value: areColumnsVisible)
            }
            .padding()
        }
    }
    
    private var listView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(filteredColumns, id: \.id) { column in
                    VStack(alignment: .leading, spacing: 8) {
                        // Column header
                        HStack {
                            Circle()
                                .fill(column.color ?? .gray)
                                .frame(width: 12, height: 12)
                            
                            Text(column.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\((filteredNotes[column.id] ?? []).count) tasks")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#1C1C1E"))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Notes in this column
                        if let notes = filteredNotes[column.id], !notes.isEmpty {
                            ForEach(notes) { note in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(column.color ?? .gray)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(note.title)
                                        .font(.system(size: 14))
                                        .foregroundColor(note.isCompleted ? .gray : .white)
                                        .strikethrough(note.isCompleted)
                                    
                                    Spacer()
                                    
                                    if let estimatedTime = note.estimatedTime, !estimatedTime.isEmpty {
                                        Text(estimatedTime)
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color(hex: "#1C1C1E"))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color(hex: "#2C2C2E"))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                        } else {
                            Text("No tasks")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(hex: "#1C1C1E"))
                    .cornerRadius(12)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: filteredNotes)
                }
            }
            .padding()
        }
    }
    
    private var addColumnSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("New Column")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Cancel") {
                    isAddingColumn = false
                }
                .foregroundColor(.gray)
            }
            .padding()
            .background(Color(hex: "#1C1C1E"))
            
            VStack(spacing: 24) {
                TextField("Column Title", text: $newColumnTitle)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(hex: "#2C2C2E"))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onSubmit {
                        createNewColumn()
                    }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    ZStack {
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColumnColor == color ? 3 : 0)
                                        
                                        if selectedColumnColor == color {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 16, height: 16)
                                        }
                                    }
                                )
                                .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 2)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedColumnColor = color
                                    }
                                }
                        }
                    }
                }
                
                Button(action: {
                    createNewColumn()
                }) {
                    Text("Create Column")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentGradient)
                        .cornerRadius(8)
                        .shadow(color: accentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(AnimatedButtonStyle())
                .disabled(newColumnTitle.isEmpty)
                .opacity(newColumnTitle.isEmpty ? 0.6 : 1)
            }
            .padding()
        }
        .background(Color(hex: "#1C1C1E"))
        .frame(width: 400)
        .cornerRadius(12)
    }
    
    private var settingsView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Board Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Done") {
                    isSettingsOpen = false
                }
                .foregroundColor(accentColor)
            }
            .padding()
            .background(Color(hex: "#1C1C1E"))
            
            ScrollView {
                VStack(spacing: 24) {
                    // Board appearance section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Appearance")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Toggle("Compact Mode", isOn: $isCompactMode)
                            .toggleStyle(SwitchToggleStyle(tint: accentColor))
                        
                        Toggle("Show Completed Tasks", isOn: $showCompletedTasks)
                            .toggleStyle(SwitchToggleStyle(tint: accentColor))
                    }
                    .padding()
                    .background(Color(hex: "#2C2C2E"))
                    .cornerRadius(12)
                    
                    // Column management section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Columns")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(noteStore.columns.sorted(by: { $0.order < $1.order }), id: \.id) { column in
                            HStack {
                                Circle()
                                    .fill(column.color ?? .gray)
                                    .frame(width: 12, height: 12)
                                
                                Text(column.title)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: {
                                    deleteColumn(column)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.system(size: 14))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .opacity(noteStore.columns.count > 1 ? 1 : 0.3)
                                .disabled(noteStore.columns.count <= 1)
                            }
                            .padding()
                            .background(Color(hex: "#1C1C1E"))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(hex: "#2C2C2E"))
                    .cornerRadius(12)
                    
                    // Reset section
                    Button(action: {
                        // Reset board to default state
                        resetBoard()
                    }) {
                        Text("Reset Board to Default")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#2C2C2E"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
        }
        .background(Color(hex: "#1C1C1E"))
        .frame(width: 400, height: 500)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    private func dragHandleOverlay(for column: NoteColumn) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(column.color ?? .gray)
                .frame(height: 3)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
    
    // MARK: - Helper Methods
    
    private func createNewColumn() {
        if !newColumnTitle.isEmpty {
            noteStore.addColumn(
                title: newColumnTitle,
                color: selectedColumnColor
            )
            isAddingColumn = false
            newColumnTitle = ""
            selectedColumnColor = .blue
        }
    }
    
    private func deleteColumn(_ column: NoteColumn) {
        withAnimation {
            noteStore.deleteColumn(column)
        }
    }
    
    private func reorderColumns(from sourceId: UUID, to targetId: UUID) {
        guard let sourceIndex = noteStore.columns.firstIndex(where: { $0.id == sourceId }),
              let targetIndex = noteStore.columns.firstIndex(where: { $0.id == targetId }) else {
            return
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            let sourceOrder = noteStore.columns[sourceIndex].order
            let targetOrder = noteStore.columns[targetIndex].order
            
            if sourceOrder < targetOrder {
                // Moving right
                for i in 0..<noteStore.columns.count {
                    if noteStore.columns[i].order > sourceOrder && noteStore.columns[i].order <= targetOrder {
                        noteStore.columns[i].order -= 1
                    }
                }
            } else {
                // Moving left
                for i in 0..<noteStore.columns.count {
                    if noteStore.columns[i].order < sourceOrder && noteStore.columns[i].order >= targetOrder {
                        noteStore.columns[i].order += 1
                    }
                }
            }
            
            noteStore.columns[sourceIndex].order = targetOrder
            
            // Update all columns
            for column in noteStore.columns {
                noteStore.updateColumn(column)
            }
        }
    }
    
    private func resetBoard() {
        // Clear existing data
        for column in noteStore.columns {
            noteStore.deleteColumn(column)
        }
        
        // Reset to default columns
        noteStore.columns = [
            NoteColumn(title: "Backlog", order: 0, color: .blue),
            NoteColumn(title: "This week", order: 1, color: .orange),
            NoteColumn(title: "Today", order: 2, color: .green),
            NoteColumn(title: "Done", order: 3, color: .orange),
            NoteColumn(title: "Cancelled", order: 4, color: .red)
        ]
        
        // Save the default columns
        for column in noteStore.columns {
            noteStore.updateColumn(column)
        }
        
        isSettingsOpen = false
    }
}

// MARK: - Supporting Types

enum ViewMode {
    case board, list
}



#Preview {
    NoteBoardView()
} 
