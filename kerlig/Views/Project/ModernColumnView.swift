import SwiftUI

struct ModernColumnView: View {
    let column: NoteColumn
    let notes: [Note]
    let noteStore: NoteStore
    let onRefresh: () -> Void
    @State private var isAddingTask = false
    @State private var newTaskTitle = ""
    @State private var selectedTaskTab: TaskTab = .regular
    @State private var estimatedTime = "00:00"
    @State private var taskDescription = ""
    @State private var scheduledDate = Date()
    @State private var scheduledTime = Date()
    @State private var taskPriority: TaskPriority = .medium
    @State private var reminderMinutes = 15
    @State private var taskMediaContent = MediaContent()
    @State private var showMediaPicker = false
    
    // Drag and Drop states
    @State private var isDropTargeted = false
    @State private var draggedNote: Note? = nil
    @State private var dropPosition: DropPosition = .end
    @State private var insertionIndex: Int? = nil
    @State private var isProcessingDrop = false
    @State private var dropFeedbackOpacity = 0.0
    @State private var dropSuccessful = false
    @State private var dropHighlightedZone: DropPosition? = nil
    
    enum TaskTab: String, CaseIterable {
        case regular = "Regular"
        case scheduled = "Scheduled"
        
        var iconName: String {
            switch self {
            case .regular: return "plus.circle"
            case .scheduled: return "calendar.badge.clock"
            }
        }
    }
    
    enum DropPosition: Equatable {
        case top, middle(Int), end
        
        static func == (lhs: DropPosition, rhs: DropPosition) -> Bool {
            switch (lhs, rhs) {
            case (.top, .top):
                return true
            case (.end, .end):
                return true
            case let (.middle(index1), .middle(index2)):
                return index1 == index2
            default:
                return false
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Enhanced column header
            columnHeader
            
            // Notes list with drag and drop support
            notesScrollView
            
            // Professional task creation section
            taskCreationSection
        }
        .padding(18)
        .background(columnBackground)
        .overlay(columnBorder)
        .overlay(dropIndicatorOverlay)
        .overlay(processingDropOverlay)
        .overlay(successFeedbackOverlay)
        .scaleEffect(isDropTargeted ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDropTargeted)
        .dropDestination(for: Note.self) { droppedNotes, location in
            handleNoteDrop(droppedNotes, at: location)
        } isTargeted: { targeted in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isDropTargeted = targeted
                if !targeted {
                    dropHighlightedZone = nil
                }
            }
        }
        .onChange(of: isProcessingDrop) { _, newValue in
            if newValue {
                // Animate drop feedback
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    dropFeedbackOpacity = 1.0
                }
            } else {
                dropFeedbackOpacity = 0.0
            }
        }
    }
    
    // MARK: - Column Header
    private var columnHeader: some View {
        HStack {
            Circle()
                .fill(columnColorGradient)
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: (column.color ?? .blue).opacity(0.4), radius: 2, x: 0, y: 1)
            
            Text(column.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Notes count badge with enhanced styling
            HStack(spacing: 4) {
                Text("\(notes.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                
                if isDropTargeted {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(notesCountBackground)
        }
    }
    
    // MARK: - Processing Drop Overlay
    private var processingDropOverlay: some View {
        Group {
            if isProcessingDrop {
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                        .background(.ultraThinMaterial)
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Moving task...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.7))
                    )
                }
                .opacity(dropFeedbackOpacity)
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - Success Feedback Overlay
    private var successFeedbackOverlay: some View {
        Group {
            if dropSuccessful {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                        .opacity(0.9)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var columnColorGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                (column.color ?? .blue).opacity(0.8),
                (column.color ?? .blue)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var notesCountBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(isDropTargeted ? 0.25 : 0.15))
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isDropTargeted ? 
                        Color.green.opacity(0.5) : 
                        Color.white.opacity(0.1), 
                        lineWidth: isDropTargeted ? 1.5 : 1
                    )
            )
    }
    
    // MARK: - Notes Scroll View with Drop Zones
    private var notesScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                // Top drop zone
                if isDropTargeted {
                    dropZoneIndicator(for: .top)
                        .onDragEntered {
                            dropHighlightedZone = .top
                        }
                        .onDragExited {
                            if dropHighlightedZone == .top {
                                dropHighlightedZone = nil
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                }
                
                ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                    VStack(spacing: 8) {
                        ModernNoteCard(note: note, noteStore: noteStore, onUpdate: onRefresh)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        
                        // Insert drop zone between notes when dragging
                        if isDropTargeted && index < notes.count - 1 {
                            dropZoneIndicator(for: .middle(index + 1))
                                .onDragEntered {
                                    dropHighlightedZone = .middle(index + 1)
                                }
                                .onDragExited {
                                    if dropHighlightedZone == .middle(index + 1) {
                                        dropHighlightedZone = nil
                                    }
                                }
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                
                // Bottom drop zone
                if isDropTargeted {
                    dropZoneIndicator(for: .end)
                        .onDragEntered {
                            dropHighlightedZone = .end
                        }
                        .onDragExited {
                            if dropHighlightedZone == .end {
                                dropHighlightedZone = nil
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.bottom, 16)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: notes.count)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDropTargeted)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dropHighlightedZone)
        }
        .frame(maxHeight: .infinity)
        .clipped()
        .gesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .local)
                .onChanged { value in
                    if isDropTargeted {
                        updateDropHighlightFromDragLocation(value.location)
                    }
                }
        )
    }
    
    private func updateDropHighlightFromDragLocation(_ location: CGPoint) {
        // This would need to be more sophisticated in a real implementation
        // with actual measurements of the view geometry
        let yPosition = location.y
        let totalHeight: CGFloat = 500 // Approximate height, would be better with GeometryReader
        
        if yPosition < 50 {
            dropHighlightedZone = .top
        } else if yPosition > totalHeight - 50 {
            dropHighlightedZone = .end
        } else {
            // Calculate which middle zone we're in
            let noteHeight: CGFloat = 80 // Approximate height of each note
            let index = Int((yPosition - 50) / (noteHeight + 12))
            if index >= 0 && index < notes.count {
                dropHighlightedZone = .middle(index)
            }
        }
    }
    
    private func dropZoneIndicator(for position: DropPosition) -> some View {
        let isHighlighted = dropHighlightedZone == position
        
        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(isHighlighted ? 0.4 : 0.2))
                .frame(height: isHighlighted ? 8 : 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(isHighlighted ? 0.9 : 0.6), 
                               style: StrokeStyle(lineWidth: isHighlighted ? 3 : 2, dash: [8, 4]))
                )
                .scaleEffect(x: isHighlighted ? 1.1 : 1.0, y: isHighlighted ? 2.5 : 2.0)
            
            if isHighlighted {
                Text(dropPositionLabel(for: position))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.7))
                    )
                    .offset(y: -16)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: isHighlighted ? 20 : 10)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)
        .padding(.vertical, isHighlighted ? 4 : 2)
    }
    
    private func dropPositionLabel(for position: DropPosition) -> String {
        switch position {
        case .top:
            return "Move to Top"
        case .middle(let index):
            return "Insert at Position \(index + 1)"
        case .end:
            return "Add to Bottom"
        }
    }
    
    // MARK: - Task Creation Section
    private var taskCreationSection: some View {
        VStack(spacing: 0) {
            if isAddingTask {
                professionalTaskCreationView
            } else {
                addTaskButton
            }
        }
    }
    
    // MARK: - Drop Indicator Overlay
    private var dropIndicatorOverlay: some View {
        Group {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.6),
                                Color.green.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.05))
                    )
                    .overlay(
                        Group {
                            if dropHighlightedZone == nil {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Text("Drop here to add task")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.green)
                                            .padding(10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.black.opacity(0.7))
                                            )
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Background and Styling
    private var columnBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(isDropTargeted ? 0.08 : 0.04))
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .shadow(
                color: Color.black.opacity(isDropTargeted ? 0.15 : 0.1), 
                radius: isDropTargeted ? 12 : 8, 
                x: 0, 
                y: isDropTargeted ? 6 : 4
            )
    }
    
    private var columnBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(isDropTargeted ? 0.25 : 0.15),
                        Color.white.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isDropTargeted ? 2 : 1
            )
    }
    
    // MARK: - Drag and Drop Logic
    private func handleNoteDrop(_ droppedNotes: [Note], at location: CGPoint) -> Bool {
        guard let droppedNote = droppedNotes.first else { return false }
        
        // Don't allow dropping a note on itself
        if notes.contains(where: { $0.id == droppedNote.id }) {
            return false
        }
        
        // Calculate drop position based on highlighted zone or location
        let targetPosition = dropHighlightedZone ?? calculateDropPosition(at: location)
        
        // Show processing animation
        withAnimation(.easeInOut(duration: 0.2)) {
            isProcessingDrop = true
        }
        
        // Perform the move operation with a slight delay to show the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let success = moveNoteToColumn(droppedNote, at: targetPosition)
            
            withAnimation(.easeInOut(duration: 0.2)) {
                isProcessingDrop = false
                if success {
                    dropSuccessful = true
                    // Reset success indicator after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation {
                            dropSuccessful = false
                        }
                    }
                }
            }
        }
        
        return true // Return true to accept the drop immediately
    }
    
    private func calculateDropPosition(at location: CGPoint) -> DropPosition {
        // Improved implementation that calculates position based on Y coordinate
        let headerHeight: CGFloat = 50 // Approximate header height
        let footerHeight: CGFloat = 60 // Approximate footer height
        let totalHeight: CGFloat = 600 // Approximate total height, adjust based on your view
        
        // If we're near the top of the content area
        if location.y < headerHeight + 40 {
            return .top
        }
        
        // If we're near the bottom of the content area
        if location.y > totalHeight - footerHeight - 40 {
            return .end
        }
        
        // Calculate which note we're closest to
        let noteHeight: CGFloat = 80 // Approximate height of each note card
        let spacing: CGFloat = 12 // Spacing between notes
        
        let contentY = location.y - headerHeight
        let noteIndex = Int(contentY / (noteHeight + spacing))
        
        if noteIndex < 0 {
            return .top
        } else if noteIndex >= notes.count {
            return .end
        } else {
            return .middle(noteIndex)
        }
    }
    
    private func moveNoteToColumn(_ note: Note, at position: DropPosition) -> Bool {
        // Find the source column and remove the note
        guard let sourceColumnIndex = noteStore.columns.firstIndex(where: { column in
            column.noteIds.contains(note.id)
        }) else {
            return false
        }
        
        // Remove from source column
        var sourceColumn = noteStore.columns[sourceColumnIndex]
        sourceColumn.noteIds.removeAll { $0 == note.id }
        noteStore.columns[sourceColumnIndex] = sourceColumn
        noteStore.updateColumn(sourceColumn)
        
        // Add to target column (this column)
        guard let targetColumnIndex = noteStore.columns.firstIndex(where: { $0.id == column.id }) else {
            return false
        }
        
        var targetColumn = noteStore.columns[targetColumnIndex]
        
        // Insert at appropriate position
        switch position {
        case .top:
            targetColumn.noteIds.insert(note.id, at: 0)
        case .middle(let index):
            let safeIndex = min(index, targetColumn.noteIds.count)
            targetColumn.noteIds.insert(note.id, at: safeIndex)
        case .end:
            targetColumn.noteIds.append(note.id)
        }
        
        noteStore.columns[targetColumnIndex] = targetColumn
        noteStore.updateColumn(targetColumn)
        
        // Save changes and refresh
        noteStore.saveNotes()
        
        // Provide haptic feedback
        provideSuccessFeedback()
        
        // Refresh the UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onRefresh()
        }
        
        return true
    }
    
    private func provideSuccessFeedback() {
        // Provide visual and haptic feedback for successful drop
        let feedback = NSHapticFeedbackManager.defaultPerformer
        feedback.perform(.alignment, performanceTime: .default)
    }
    
    // MARK: - Professional Task Creation UI
    
    private var professionalTaskCreationView: some View {
        VStack(spacing: 12) {
            taskCreationHeader
            taskTabSelector
            taskFormContent
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(taskCreationBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    private var taskCreationHeader: some View {
        HStack {
            Button("CANCEL") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    resetTaskForm()
                    isAddingTask = false
                }
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.gray)
            
            Spacer()
            
            Text("Create Task")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button("CONFIRM") {
                selectedTaskTab == .regular ? createRegularTask() : createScheduledTask()
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(confirmButtonBackground)
            .cornerRadius(16)
            .disabled(newTaskTitle.isEmpty)
            .opacity(newTaskTitle.isEmpty ? 0.5 : 1.0)
        }
    }
    
    private var confirmButtonBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                (column.color ?? .blue).opacity(0.8),
                (column.color ?? .blue)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
    }
    
    private var taskTabSelector: some View {
        HStack(spacing: 4) {
            ForEach(TaskTab.allCases, id: \.self) { tab in
                taskTabButton(for: tab)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func taskTabButton(for tab: TaskTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTaskTab = tab
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 10, weight: .medium))
                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selectedTaskTab == tab ? .white : .gray.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: selectedTaskTab)
    }
    
    private var taskTabActiveBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                (column.color ?? .blue).opacity(0.3),
                (column.color ?? .blue).opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke((column.color ?? .blue).opacity(0.4), lineWidth: 0.5)
        )
    }
    
    private var taskFormContent: some View {
        Group {
            if selectedTaskTab == .regular {
                regularTaskForm
            } else {
                scheduledTaskForm
            }
        }
    }
    
    private var regularTaskForm: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("Enter task title", text: $newTaskTitle)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(taskInputBackground)
                    .cornerRadius(8)
                    .onSubmit {
                        createRegularTask()
                    }
                
                TextField("Est. time", text: $estimatedTime)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .frame(width: 70)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(taskInputBackground)
                    .cornerRadius(8)
            }
            
            // Media toggle
            mediaToggleSection
            
            if showMediaPicker {
                CompactMediaPickerView(mediaContent: $taskMediaContent)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showMediaPicker)
    }
    
    private var scheduledTaskForm: some View {
        VStack(spacing: 10) {
            // Title and description
            VStack(spacing: 6) {
                TextField("Enter task title", text: $newTaskTitle)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(taskInputBackground)
                    .cornerRadius(8)
                
                TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(taskInputBackground)
                    .cornerRadius(8)
                    .frame(minHeight: 35)
            }
            
            // Compact scheduling controls
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Date")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    DatePicker("", selection: $scheduledDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .scaleEffect(0.85)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Time")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    DatePicker("", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .scaleEffect(0.85)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Priority")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    
                    Menu {
                        ForEach(TaskPriority.allCases) { priority in
                            Button(action: { taskPriority = priority }) {
                                HStack {
                                    Image(systemName: priority.iconName)
                                    Text(priority.rawValue)
                                    if taskPriority == priority {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                                .foregroundColor(priority.color)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: taskPriority.iconName)
                                .font(.system(size: 10))
                            Text(taskPriority.rawValue)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(taskPriority.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(taskInputBackground)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Media toggle
            mediaToggleSection
            
            if showMediaPicker {
                CompactMediaPickerView(mediaContent: $taskMediaContent)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showMediaPicker)
    }
    
    private var mediaToggleSection: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: showMediaPicker ? "photo.fill" : "photo")
                    .font(.system(size: 11))
                    .foregroundColor(showMediaPicker ? (column.color ?? .blue) : .gray)
                
                Text("Media")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Toggle("", isOn: $showMediaPicker)
                .toggleStyle(SwitchToggleStyle(tint: column.color ?? .blue))
                .scaleEffect(0.7)
                .onChange(of: showMediaPicker) { _, value in
                    if !value {
                        taskMediaContent = MediaContent()
                    }
                }
        }
    }
    
    private var taskInputBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
    }
    
    private var taskCreationBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.06))
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
    
    private var addTaskButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isAddingTask = true
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(column.color ?? .blue)
                Text("Add Task")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [6, 3]))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .hoverEffect(.lift)
        .transition(.opacity)
    }
    
    // MARK: - Task Creation Methods
    
    private func createRegularTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newNote = Note(
            title: newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            content: "",
            category: .today,
            estimatedTime: estimatedTime.isEmpty ? nil : estimatedTime,
            mediaContent: showMediaPicker && taskMediaContent.hasContent ? taskMediaContent : nil
        )
        
        addTaskToColumn(newNote)
    }
    
    private func createScheduledTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newNote = Note(
            title: newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            content: taskDescription.isEmpty ? "" : taskDescription,
            category: .today,
            estimatedTime: estimatedTime.isEmpty ? nil : estimatedTime,
            scheduledDate: scheduledDate,
            scheduledTime: scheduledTime,
            priority: taskPriority,
            description: taskDescription.isEmpty ? nil : taskDescription,
            reminderMinutes: reminderMinutes,
            mediaContent: showMediaPicker && taskMediaContent.hasContent ? taskMediaContent : nil
        )
        
        addTaskToColumn(newNote)
    }
    
    private func addTaskToColumn(_ newNote: Note) {
        // Add note to the main store
        noteStore.notes.append(newNote)
        
        // Add note ID to the column
        if let columnIndex = noteStore.columns.firstIndex(where: { $0.id == column.id }) {
            var updatedColumn = noteStore.columns[columnIndex]
            updatedColumn.noteIds.append(newNote.id)
            noteStore.columns[columnIndex] = updatedColumn
            noteStore.updateColumn(updatedColumn)
        }
        
        // Save changes
        noteStore.saveNotes()
        
        // Reset form and close
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            resetTaskForm()
            isAddingTask = false
        }
        
        // Refresh the view
        onRefresh()
    }
    
    private func resetTaskForm() {
        newTaskTitle = ""
        estimatedTime = "00:00"
        taskDescription = ""
        scheduledDate = Date()
        scheduledTime = Date()
        taskPriority = .medium
        reminderMinutes = 15
        selectedTaskTab = .regular
        taskMediaContent = MediaContent()
        showMediaPicker = false
    }
}

// MARK: - Compact Media Picker View
// MARK: - Drag Gesture Extensions
extension View {
    func onDragEntered(perform action: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in action() }
        )
    }
    
    func onDragExited(perform action: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in action() }
        )
    }
}

struct CompactMediaPickerView: View {
    @Binding var mediaContent: MediaContent
    @State private var selectedImageData: Data?
    @State private var selectedEmoji: String = ""
    @State private var mediaType: MediaType = .image
    
    enum MediaType: String, CaseIterable {
        case image = "Image"
        case emoji = "Emoji"
        
        var iconName: String {
            switch self {
            case .image: return "photo"
            case .emoji: return "face.smiling"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Media type selector
            HStack(spacing: 4) {
                ForEach(MediaType.allCases, id: \.self) { type in
                    Button(action: {
                        mediaType = type
                        clearCurrentContent()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: type.iconName)
                                .font(.system(size: 9))
                            Text(type.rawValue)
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(mediaType == type ? .white : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            mediaType == type ? 
                            Color.blue.opacity(0.3) : 
                            Color.clear
                        )
                        .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Content input
            switch mediaType {
            case .image:
                imagePickerSection
            case .emoji:
                emojiPickerSection
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    private var imagePickerSection: some View {
        VStack(spacing: 6) {
            if let imageData = selectedImageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 40)
                    .cornerRadius(6)
            } else {
                Button("Select Image") {
                    selectImage()
                }
                .font(.system(size: 10))
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.1))
                )
            }
        }
        .onChange(of: selectedImageData) { _, imageData in
            if let imageData = imageData {
                mediaContent = MediaContent(type: .image, imageData: imageData)
            }
        }
    }
    
    private var emojiPickerSection: some View {
        HStack {
            TextField("Enter emoji", text: $selectedEmoji)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 60)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                )
                .onChange(of: selectedEmoji) { _, emoji in
                    if !emoji.isEmpty {
                        mediaContent = MediaContent(type: .emoji, emoji: String(emoji.prefix(1)))
                    }
                }
        }
    }
    
    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                do {
                    selectedImageData = try Data(contentsOf: url)
                } catch {
                    print("Error loading image: \(error)")
                }
            }
        }
    }
    
    private func clearCurrentContent() {
        selectedImageData = nil
        selectedEmoji = ""
        mediaContent = MediaContent()
    }
}
