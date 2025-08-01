import Foundation
import SwiftUI
import Carbon

// MARK: - Hotkey Configuration Model

struct HotkeyConfiguration: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var description: String
    var shortcut: KeyboardShortcut?
    var isEnabled: Bool
    var action: HotkeyAction
    var isSystemDefault: Bool
    var lastModified: Date
    
    init(name: String, description: String, shortcut: KeyboardShortcut? = nil, isEnabled: Bool = true, action: HotkeyAction, isSystemDefault: Bool = false) {
        self.name = name
        self.description = description
        self.shortcut = shortcut
        self.isEnabled = isEnabled
        self.action = action
        self.isSystemDefault = isSystemDefault
        self.lastModified = Date()
    }
    
    mutating func updateShortcut(_ newShortcut: KeyboardShortcut?) {
        self.shortcut = newShortcut
        self.lastModified = Date()
    }
    
    mutating func toggle() {
        self.isEnabled.toggle()
        self.lastModified = Date()
    }
    
    var displayShortcut: String {
        return shortcut?.displayString ?? "Not Set"
    }
    
    var isConfigured: Bool {
        return shortcut != nil
    }
}

// MARK: - Keyboard Shortcut

struct KeyboardShortcut: Equatable {
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags
    let displayKey: String
    
    init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, displayKey: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.displayKey = displayKey
    }
    
    var displayString: String {
        var components: [String] = []
        
        if modifiers.contains(.control) {
            components.append("⌃")
        }
        if modifiers.contains(.option) {
            components.append("⌥")
        }
        if modifiers.contains(.shift) {
            components.append("⇧")
        }
        if modifiers.contains(.command) {
            components.append("⌘")
        }
        
        components.append(displayKey)
        return components.joined()
    }
    
    var carbonModifiers: UInt32 {
        var carbonMods: UInt32 = 0
        
        if modifiers.contains(.command) {
            carbonMods |= UInt32(cmdKey)
        }
        if modifiers.contains(.shift) {
            carbonMods |= UInt32(shiftKey)
        }
        if modifiers.contains(.option) {
            carbonMods |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            carbonMods |= UInt32(controlKey)
        }
        
        return carbonMods
    }
    
    // Predefined common shortcuts
    static let optionSpace = KeyboardShortcut(
        keyCode: UInt16(kVK_Space),
        modifiers: [.option],
        displayKey: "Space"
    )
    
    static let commandShiftR = KeyboardShortcut(
        keyCode: UInt16(kVK_ANSI_R),
        modifiers: [.command, .shift],
        displayKey: "R"
    )
    
    static let commandShiftA = KeyboardShortcut(
        keyCode: UInt16(kVK_ANSI_A),
        modifiers: [.command, .shift],
        displayKey: "A"
    )
    
    static let commandShiftV = KeyboardShortcut(
        keyCode: UInt16(kVK_ANSI_V),
        modifiers: [.command, .shift],
        displayKey: "V"
    )
}

// MARK: - KeyboardShortcut Protocol Conformances

extension KeyboardShortcut: Codable {
    enum CodingKeys: String, CodingKey {
        case keyCode, modifiers, displayKey
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyCode = try container.decode(UInt16.self, forKey: .keyCode)
        displayKey = try container.decode(String.self, forKey: .displayKey)
        
        let modifierRawValue = try container.decode(UInt.self, forKey: .modifiers)
        modifiers = NSEvent.ModifierFlags(rawValue: modifierRawValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(displayKey, forKey: .displayKey)
        try container.encode(modifiers.rawValue, forKey: .modifiers)
    }
}

extension KeyboardShortcut: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(keyCode)
        hasher.combine(modifiers.rawValue)
        hasher.combine(displayKey)
    }
}

// MARK: - Hotkey Actions

enum HotkeyAction: String, CaseIterable, Codable {
    case textCapture = "textCapture"
    case whisperMode = "whisperMode"
    case aiPanel = "aiPanel"
    case floatingSidebar = "floatingSidebar"
    case projectsPanel = "projectsPanel"
    case clipboardHistory = "clipboardHistory"
    case quickNote = "quickNote"
    case voiceRecording = "voiceRecording"
    case screenCapture = "screenCapture"
    case taskTimer = "taskTimer"
    
    var displayName: String {
        switch self {
        case .textCapture: return "Text Capture & AI"
        case .whisperMode: return "Whisper Mode (Voice)"
        case .aiPanel: return "AI Panel"
        case .floatingSidebar: return "Floating Sidebar"
        case .projectsPanel: return "Projects Panel"
        case .clipboardHistory: return "Clipboard History"
        case .quickNote: return "Quick Note"
        case .voiceRecording: return "Voice Recording"
        case .screenCapture: return "Screen Capture"
        case .taskTimer: return "Task Timer"
        }
    }
    
    var description: String {
        switch self {
        case .textCapture: return "Capture selected text and open AI panel for processing"
        case .whisperMode: return "Start voice recording for AI transcription and processing"
        case .aiPanel: return "Open AI panel for direct interaction"
        case .floatingSidebar: return "Toggle floating sidebar with notes and tasks"
        case .projectsPanel: return "Open projects management panel"
        case .clipboardHistory: return "Show clipboard history panel"
        case .quickNote: return "Create a new quick note"
        case .voiceRecording: return "Start/stop voice recording"
        case .screenCapture: return "Capture screen for AI analysis"
        case .taskTimer: return "Start/stop task timer"
        }
    }
    
    var icon: String {
        switch self {
        case .textCapture: return "text.cursor"
        case .whisperMode: return "mic.fill"
        case .aiPanel: return "brain.head.profile"
        case .floatingSidebar: return "sidebar.left"
        case .projectsPanel: return "folder.fill"
        case .clipboardHistory: return "doc.on.clipboard"
        case .quickNote: return "note.text.badge.plus"
        case .voiceRecording: return "waveform"
        case .screenCapture: return "camera.viewfinder"
        case .taskTimer: return "timer"
        }
    }
    
    var category: ActionCategory {
        switch self {
        case .textCapture, .aiPanel, .whisperMode:
            return .ai
        case .floatingSidebar, .projectsPanel, .quickNote:
            return .productivity
        case .clipboardHistory, .screenCapture:
            return .utilities
        case .voiceRecording, .taskTimer:
            return .media
        }
    }
    
    var color: Color {
        return category.color
    }
}

enum ActionCategory: String, CaseIterable {
    case ai = "AI & Intelligence"
    case productivity = "Productivity"
    case utilities = "Utilities"
    case media = "Media & Recording"
    
    var color: Color {
        switch self {
        case .ai: return .purple
        case .productivity: return .blue
        case .utilities: return .green
        case .media: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .ai: return "brain.head.profile"
        case .productivity: return "briefcase.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        case .media: return "play.circle.fill"
        }
    }
}

// MARK: - Hotkey Manager Class

class HotkeyConfigurationManager: ObservableObject {
    @Published var configurations: [HotkeyConfiguration] = []
    @Published var isRecording: Bool = false
    @Published var recordingFor: UUID? = nil
    
    private let userDefaultsKey = "hotkeyConfigurations"
    
    init() {
        loadConfigurations()
        setupDefaultConfigurations()
    }
    
    // MARK: - Default Configurations
    
    private func setupDefaultConfigurations() {
        if configurations.isEmpty {
            configurations = [
                HotkeyConfiguration(
                    name: "Text Capture & AI",
                    description: "Capture selected text and process with AI",
                    shortcut: .optionSpace,
                    action: .textCapture,
                    isSystemDefault: true
                ),
                HotkeyConfiguration(
                    name: "Whisper Mode",
                    description: "Voice recording and AI transcription",
                    shortcut: .commandShiftR,
                    action: .whisperMode,
                    isSystemDefault: true
                ),
                HotkeyConfiguration(
                    name: "AI Panel",
                    description: "Open AI interaction panel",
                    action: .aiPanel
                ),
                HotkeyConfiguration(
                    name: "Floating Sidebar",
                    description: "Toggle floating sidebar with notes",
                    action: .floatingSidebar
                ),
                HotkeyConfiguration(
                    name: "Projects Panel",
                    description: "Open projects management",
                    action: .projectsPanel
                ),
                HotkeyConfiguration(
                    name: "Clipboard History",
                    description: "Show clipboard history",
                    shortcut: .commandShiftV,
                    action: .clipboardHistory,
                    isSystemDefault: true
                ),
                HotkeyConfiguration(
                    name: "Quick Note",
                    description: "Create a new quick note",
                    action: .quickNote
                ),
                HotkeyConfiguration(
                    name: "Voice Recording",
                    description: "Start/stop voice recording",
                    action: .voiceRecording
                ),
                HotkeyConfiguration(
                    name: "Screen Capture",
                    description: "Capture screen for AI analysis",
                    action: .screenCapture
                ),
                HotkeyConfiguration(
                    name: "Task Timer",
                    description: "Start/stop task timer",
                    action: .taskTimer
                )
            ]
            saveConfigurations()
        }
    }
    
    // MARK: - Configuration Management
    
    func updateConfiguration(_ configuration: HotkeyConfiguration) {
        if let index = configurations.firstIndex(where: { $0.id == configuration.id }) {
            configurations[index] = configuration
            saveConfigurations()
        }
    }
    
    func toggleConfiguration(_ id: UUID) {
        if let index = configurations.firstIndex(where: { $0.id == id }) {
            configurations[index].toggle()
            saveConfigurations()
        }
    }
    
    func setShortcut(for id: UUID, shortcut: KeyboardShortcut?) {
        if let index = configurations.firstIndex(where: { $0.id == id }) {
            configurations[index].updateShortcut(shortcut)
            saveConfigurations()
        }
    }
    
    func removeShortcut(for id: UUID) {
        setShortcut(for: id, shortcut: nil)
    }
    
    func getConfiguration(for action: HotkeyAction) -> HotkeyConfiguration? {
        return configurations.first { $0.action == action }
    }
    
    func getEnabledConfigurations() -> [HotkeyConfiguration] {
        return configurations.filter { $0.isEnabled && $0.isConfigured }
    }
    
    func hasConflict(for shortcut: KeyboardShortcut, excluding id: UUID? = nil) -> HotkeyConfiguration? {
        return configurations.first { config in
            if let excludeId = id, config.id == excludeId { return false }
            return config.shortcut == shortcut && config.isEnabled
        }
    }
    
    // MARK: - Recording State
    
    func startRecording(for id: UUID) {
        isRecording = true
        recordingFor = id
    }
    
    func stopRecording() {
        isRecording = false
        recordingFor = nil
    }
    
    func recordShortcut(_ shortcut: KeyboardShortcut) {
        guard let recordingId = recordingFor else { return }
        
        // Check for conflicts
        if let conflict = hasConflict(for: shortcut, excluding: recordingId) {
            // Handle conflict - for now, we'll just set it anyway
            // In a full implementation, you might want to show a warning
        }
        
        setShortcut(for: recordingId, shortcut: shortcut)
        stopRecording()
    }
    
    // MARK: - Persistence
    
    private func saveConfigurations() {
        if let encoded = try? JSONEncoder().encode(configurations) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadConfigurations() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([HotkeyConfiguration].self, from: data) else {
            return
        }
        configurations = decoded
    }
    
    // MARK: - Categories
    
    func getConfigurations(for category: ActionCategory) -> [HotkeyConfiguration] {
        return configurations.filter { $0.action.category == category }
    }
    
    var groupedConfigurations: [ActionCategory: [HotkeyConfiguration]] {
        return Dictionary(grouping: configurations) { $0.action.category }
    }
}

// MARK: - Key Code Utilities

extension UInt16 {
    static func keyCodeToString(_ keyCode: UInt16) -> String {
        switch keyCode {
        case UInt16(kVK_ANSI_A): return "A"
        case UInt16(kVK_ANSI_S): return "S"
        case UInt16(kVK_ANSI_D): return "D"
        case UInt16(kVK_ANSI_F): return "F"
        case UInt16(kVK_ANSI_H): return "H"
        case UInt16(kVK_ANSI_G): return "G"
        case UInt16(kVK_ANSI_Z): return "Z"
        case UInt16(kVK_ANSI_X): return "X"
        case UInt16(kVK_ANSI_C): return "C"
        case UInt16(kVK_ANSI_V): return "V"
        case UInt16(kVK_ANSI_B): return "B"
        case UInt16(kVK_ANSI_Q): return "Q"
        case UInt16(kVK_ANSI_W): return "W"
        case UInt16(kVK_ANSI_E): return "E"
        case UInt16(kVK_ANSI_R): return "R"
        case UInt16(kVK_ANSI_Y): return "Y"
        case UInt16(kVK_ANSI_T): return "T"
        case UInt16(kVK_ANSI_1): return "1"
        case UInt16(kVK_ANSI_2): return "2"
        case UInt16(kVK_ANSI_3): return "3"
        case UInt16(kVK_ANSI_4): return "4"
        case UInt16(kVK_ANSI_6): return "6"
        case UInt16(kVK_ANSI_5): return "5"
        case UInt16(kVK_ANSI_Equal): return "="
        case UInt16(kVK_ANSI_9): return "9"
        case UInt16(kVK_ANSI_7): return "7"
        case UInt16(kVK_ANSI_Minus): return "-"
        case UInt16(kVK_ANSI_8): return "8"
        case UInt16(kVK_ANSI_0): return "0"
        case UInt16(kVK_ANSI_RightBracket): return "]"
        case UInt16(kVK_ANSI_O): return "O"
        case UInt16(kVK_ANSI_U): return "U"
        case UInt16(kVK_ANSI_LeftBracket): return "["
        case UInt16(kVK_ANSI_I): return "I"
        case UInt16(kVK_ANSI_P): return "P"
        case UInt16(kVK_ANSI_L): return "L"
        case UInt16(kVK_ANSI_J): return "J"
        case UInt16(kVK_ANSI_Quote): return "'"
        case UInt16(kVK_ANSI_K): return "K"
        case UInt16(kVK_ANSI_Semicolon): return ";"
        case UInt16(kVK_ANSI_Backslash): return "\\"
        case UInt16(kVK_ANSI_Comma): return ","
        case UInt16(kVK_ANSI_Slash): return "/"
        case UInt16(kVK_ANSI_N): return "N"
        case UInt16(kVK_ANSI_M): return "M"
        case UInt16(kVK_ANSI_Period): return "."
        case UInt16(kVK_ANSI_Grave): return "`"
        case UInt16(kVK_ANSI_KeypadDecimal): return "."
        case UInt16(kVK_ANSI_KeypadMultiply): return "*"
        case UInt16(kVK_ANSI_KeypadPlus): return "+"
        case UInt16(kVK_ANSI_KeypadClear): return "Clear"
        case UInt16(kVK_ANSI_KeypadDivide): return "/"
        case UInt16(kVK_ANSI_KeypadEnter): return "Enter"
        case UInt16(kVK_ANSI_KeypadMinus): return "-"
        case UInt16(kVK_ANSI_KeypadEquals): return "="
        case UInt16(kVK_ANSI_Keypad0): return "0"
        case UInt16(kVK_ANSI_Keypad1): return "1"
        case UInt16(kVK_ANSI_Keypad2): return "2"
        case UInt16(kVK_ANSI_Keypad3): return "3"
        case UInt16(kVK_ANSI_Keypad4): return "4"
        case UInt16(kVK_ANSI_Keypad5): return "5"
        case UInt16(kVK_ANSI_Keypad6): return "6"
        case UInt16(kVK_ANSI_Keypad7): return "7"
        case UInt16(kVK_ANSI_Keypad8): return "8"
        case UInt16(kVK_ANSI_Keypad9): return "9"
        case UInt16(kVK_Return): return "Return"
        case UInt16(kVK_Tab): return "Tab"
        case UInt16(kVK_Space): return "Space"
        case UInt16(kVK_Delete): return "Delete"
        case UInt16(kVK_Escape): return "Escape"
        case UInt16(kVK_Command): return "Command"
        case UInt16(kVK_Shift): return "Shift"
        case UInt16(kVK_CapsLock): return "Caps Lock"
        case UInt16(kVK_Option): return "Option"
        case UInt16(kVK_Control): return "Control"
        case UInt16(kVK_RightShift): return "Right Shift"
        case UInt16(kVK_RightOption): return "Right Option"
        case UInt16(kVK_RightControl): return "Right Control"
        case UInt16(kVK_Function): return "fn"
        case UInt16(kVK_F17): return "F17"
        case UInt16(kVK_VolumeUp): return "Volume Up"
        case UInt16(kVK_VolumeDown): return "Volume Down"
        case UInt16(kVK_Mute): return "Mute"
        case UInt16(kVK_F18): return "F18"
        case UInt16(kVK_F19): return "F19"
        case UInt16(kVK_F20): return "F20"
        case UInt16(kVK_F5): return "F5"
        case UInt16(kVK_F6): return "F6"
        case UInt16(kVK_F7): return "F7"
        case UInt16(kVK_F3): return "F3"
        case UInt16(kVK_F8): return "F8"
        case UInt16(kVK_F9): return "F9"
        case UInt16(kVK_F11): return "F11"
        case UInt16(kVK_F13): return "F13"
        case UInt16(kVK_F16): return "F16"
        case UInt16(kVK_F14): return "F14"
        case UInt16(kVK_F10): return "F10"
        case UInt16(kVK_F12): return "F12"
        case UInt16(kVK_F15): return "F15"
        case UInt16(kVK_Help): return "Help"
        case UInt16(kVK_Home): return "Home"
        case UInt16(kVK_PageUp): return "Page Up"
        case UInt16(kVK_ForwardDelete): return "Forward Delete"
        case UInt16(kVK_F4): return "F4"
        case UInt16(kVK_End): return "End"
        case UInt16(kVK_F2): return "F2"
        case UInt16(kVK_PageDown): return "Page Down"
        case UInt16(kVK_F1): return "F1"
        case UInt16(kVK_LeftArrow): return "←"
        case UInt16(kVK_RightArrow): return "→"
        case UInt16(kVK_DownArrow): return "↓"
        case UInt16(kVK_UpArrow): return "↑"
        default: return "Unknown"
        }
    }
}