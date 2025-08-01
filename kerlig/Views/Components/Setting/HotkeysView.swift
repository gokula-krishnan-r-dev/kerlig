import SwiftUI
import Carbon

struct HotkeysView: View {
    @StateObject private var hotkeyManager = HotkeyConfigurationManager()
    @State private var selectedCategory: ActionCategory? = nil
    @State private var searchText: String = ""
    @State private var selectedLayout: LayoutOption = .card
    @State private var showingConflictAlert: Bool = false
    @State private var conflictingConfiguration: HotkeyConfiguration? = nil
    @State private var keyRecorder = KeyRecorder()
    
    enum LayoutOption: String, CaseIterable {
        case card = "Card"
        case compact = "Compact"
        
        var icon: String {
            switch self {
            case .card: return "rectangle.grid.1x2"
            case .compact: return "rectangle.grid.2x2"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Category Filter
            categoryFilterSection
            
            Divider()
            
            // Hotkeys Content
            ScrollView {
                LazyVStack(spacing: 16) {
                    if hotkeyManager.configurations.isEmpty {
                        emptyState
                    } else {
                        hotkeysList
                    }
                }
                .padding()
            }
        }
        .alert("Shortcut Conflict", isPresented: $showingConflictAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Replace") {
                // Handle conflict resolution
                if let conflict = conflictingConfiguration {
                    // Implementation for replacing existing shortcut
                }
            }
        } message: {
            if let conflict = conflictingConfiguration {
                Text("This shortcut is already assigned to '\(conflict.name)'. Do you want to replace it?")
            }
        }
        .onAppear {
            setupKeyRecorder()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Hotkeys")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Layout Toggle
                layoutToggle
                
                // Info Button
                Button(action: { showHelpPopover() }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Hotkey Help")
            }
            
            // Search Bar
            searchBar
            
            // Stats Row
            statsRow
        }
        .padding()
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            TextField("Search hotkeys...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 14))
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.05))
        )
    }
    
    private var layoutToggle: some View {
        HStack(spacing: 4) {
            ForEach(LayoutOption.allCases, id: \.self) { layout in
                Button(action: { selectedLayout = layout }) {
                    Image(systemName: layout.icon)
                        .font(.system(size: 14))
                        .foregroundColor(selectedLayout == layout ? .blue : .secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                .help(layout.rawValue + " Layout")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.05))
        )
    }
    
    private var statsRow: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("\(filteredConfigurations.count) hotkeys")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
                Text("\(enabledConfigurationsCount) enabled")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "gear")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("\(configuredCount) configured")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Category Filter Section
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All Categories
                CategoryChip(
                    title: "All",
                    icon: "grid",
                    count: hotkeyManager.configurations.count,
                    isSelected: selectedCategory == nil,
                    color: .blue
                ) {
                    selectedCategory = nil
                }
                
                // Individual Categories
                ForEach(ActionCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        count: hotkeyManager.getConfigurations(for: category).count,
                        isSelected: selectedCategory == category,
                        color: category.color
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Hotkeys List
    
    private var hotkeysList: some View {
        LazyVStack(spacing: 16) {
            if let category = selectedCategory {
                // Single category view
                let configurations = hotkeyManager.getConfigurations(for: category).filter(matchesSearch)
                
                if !configurations.isEmpty {
                    CategorySection(
                        category: category,
                        configurations: configurations,
                        layout: selectedLayout,
                        isRecording: hotkeyManager.isRecording,
                        recordingFor: hotkeyManager.recordingFor,
                        onToggle: { config in
                            hotkeyManager.toggleConfiguration(config.id)
                        },
                        onRecord: { config in
                            startRecording(for: config)
                        },
                        onClear: { config in
                            hotkeyManager.removeShortcut(for: config.id)
                        }
                    )
                }
            } else {
                // All categories grouped view
                ForEach(ActionCategory.allCases, id: \.self) { category in
                    let configurations = hotkeyManager.getConfigurations(for: category).filter(matchesSearch)
                    
                    if !configurations.isEmpty {
                        CategorySection(
                            category: category,
                            configurations: configurations,
                            layout: selectedLayout,
                            isRecording: hotkeyManager.isRecording,
                            recordingFor: hotkeyManager.recordingFor,
                            onToggle: { config in
                                hotkeyManager.toggleConfiguration(config.id)
                            },
                            onRecord: { config in
                                startRecording(for: config)
                            },
                            onClear: { config in
                                hotkeyManager.removeShortcut(for: config.id)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Hotkeys Found")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Try adjusting your search or category filter")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Computed Properties
    
    private var filteredConfigurations: [HotkeyConfiguration] {
        var configs = hotkeyManager.configurations
        
        if let category = selectedCategory {
            configs = configs.filter { $0.action.category == category }
        }
        
        if !searchText.isEmpty {
            configs = configs.filter(matchesSearch)
        }
        
        return configs
    }
    
    private var enabledConfigurationsCount: Int {
        filteredConfigurations.filter { $0.isEnabled }.count
    }
    
    private var configuredCount: Int {
        filteredConfigurations.filter { $0.isConfigured }.count
    }
    
    // MARK: - Helper Methods
    
    private func matchesSearch(_ config: HotkeyConfiguration) -> Bool {
        guard !searchText.isEmpty else { return true }
        
        let searchLower = searchText.lowercased()
        return config.name.lowercased().contains(searchLower) ||
               config.description.lowercased().contains(searchLower) ||
               config.action.displayName.lowercased().contains(searchLower) ||
               config.displayShortcut.lowercased().contains(searchLower)
    }
    
    private func startRecording(for configuration: HotkeyConfiguration) {
        hotkeyManager.startRecording(for: configuration.id)
        keyRecorder.startRecording { shortcut in
            handleRecordedShortcut(shortcut, for: configuration)
        }
    }
    
    private func handleRecordedShortcut(_ shortcut: KeyboardShortcut, for configuration: HotkeyConfiguration) {
        // Check for conflicts
        if let conflict = hotkeyManager.hasConflict(for: shortcut, excluding: configuration.id) {
            conflictingConfiguration = conflict
            showingConflictAlert = true
        } else {
            hotkeyManager.recordShortcut(shortcut)
        }
        keyRecorder.stopRecording()
    }
    
    private func setupKeyRecorder() {
        // Setup global key monitoring for hotkey recording
    }
    
    private func showHelpPopover() {
        // Show help information about hotkeys
    }
}

// MARK: - Supporting Views

struct CategorySection: View {
    let category: ActionCategory
    let configurations: [HotkeyConfiguration]
    let layout: HotkeysView.LayoutOption
    let isRecording: Bool
    let recordingFor: UUID?
    let onToggle: (HotkeyConfiguration) -> Void
    let onRecord: (HotkeyConfiguration) -> Void
    let onClear: (HotkeyConfiguration) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .font(.system(size: 16))
                
                Text(category.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("(\(configurations.count))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Quick Actions
                HStack(spacing: 8) {
                    Button("Enable All") {
                        // Enable all in category
                    }
                    .buttonStyle(PlainButtonStyle())
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                    
                    Button("Clear All") {
                        // Clear all shortcuts in category
                    }
                    .buttonStyle(PlainButtonStyle())
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                }
            }
            
            // Configurations Grid
            LazyVGrid(columns: gridColumns, spacing: gridSpacing) {
                ForEach(configurations) { config in
                    configurationCard(for: config)
                }
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        switch layout {
        case .card:
            return [GridItem(.adaptive(minimum: 350, maximum: 500), spacing: 12)]
        case .compact:
            return [GridItem(.adaptive(minimum: 280, maximum: 350), spacing: 8)]
        }
    }
    
    private var gridSpacing: CGFloat {
        switch layout {
        case .card: return 12
        case .compact: return 8
        }
    }
    
    private func configurationCard(for config: HotkeyConfiguration) -> some View {
        Group {
            switch layout {
            case .card:
                HotkeyCard(
                    configuration: config,
                    isRecording: isRecording && recordingFor == config.id,
                    onToggle: { onToggle(config) },
                    onRecord: { onRecord(config) },
                    onClear: { onClear(config) }
                )
            case .compact:
                CompactHotkeyCard(
                    configuration: config,
                    isRecording: isRecording && recordingFor == config.id,
                    onToggle: { onToggle(config) },
                    onRecord: { onRecord(config) }
                )
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                
                Text("(\(count))")
                    .font(.system(size: 11))
                    .opacity(0.7)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : Color.primary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Key Recorder

class KeyRecorder: ObservableObject {
    private var callback: ((KeyboardShortcut) -> Void)?
    private var monitor: Any?
    
    func startRecording(completion: @escaping (KeyboardShortcut) -> Void) {
        callback = completion
        
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = event.keyCode
            let modifiers = event.modifierFlags.intersection([.command, .option, .shift, .control])
            
            
            
            let displayKey = UInt16.keyCodeToString(keyCode)
            let shortcut = KeyboardShortcut(
                keyCode: keyCode,
                modifiers: modifiers,
                displayKey: displayKey
            )
            
            DispatchQueue.main.async {
                self.callback?(shortcut)
            }
            
            return nil // Consume the event
        }
    }
    
    func stopRecording() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        callback = nil
    }
    
    private func isModifierKey(_ keyCode: UInt16) -> Bool {
        let modifierKeys: [UInt16] = [
            UInt16(kVK_Command),
            UInt16(kVK_Shift),
            UInt16(kVK_CapsLock),
            UInt16(kVK_Option),
            UInt16(kVK_Control),
            UInt16(kVK_RightShift),
            UInt16(kVK_RightOption),
            UInt16(kVK_RightControl),
            UInt16(kVK_Function)
        ]
        return modifierKeys.contains(keyCode)
    }
}

// MARK: - Preview

#Preview {
    HotkeysView()
        .frame(width: 800, height: 600)
}
