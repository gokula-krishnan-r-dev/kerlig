import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedSection: SettingsSection = .permissions
    @State private var animateSections: Bool = false
    
    enum SettingsSection: String, CaseIterable {
        case permissions = "Permissions"
        case aiModel = "AI Model"
        case advanced = "Advanced"
        
        var icon: String {
            switch self {
            case .permissions: return "lock.shield"
            case .aiModel: return "cpu"
            case .advanced: return "gearshape.2"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Settings Header
            HStack {
                Text("Settings")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "333333"))
                
                Spacer()
                
                Button(action: {
                    appState.saveSettings()
                }) {
                    Text("Save")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            // Section Navigation Tabs
            HStack(spacing: 0) {
                ForEach(SettingsSection.allCases, id: \.rawValue) { section in
                    SettingsSectionTab(
                        section: section,
                        isSelected: selectedSection == section,
                        onSelect: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedSection = section
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 30)
            
            Divider()
                .padding(.top, 4)
            
            // Main Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Section Content
                    switch selectedSection {
                    case .permissions:
                        PermissionsSettingsView()
                            .environmentObject(appState)
                            .transition(.opacity)
                            .padding(30)
                    case .aiModel:
                        AIModelSettingsView()
                            .environmentObject(appState)
                            .transition(.opacity)
                            .padding(30)
                    case .advanced:
                        AdvancedSettingsView()
                            .environmentObject(appState)
                            .transition(.opacity)
                            .padding(30)
                    }
                }
                .frame(maxWidth: .infinity)
                .animation(.easeInOut(duration: 0.3), value: selectedSection)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            animateSections = true
        }
    }
}

// MARK: - Settings Section Tab
struct SettingsSectionTab: View {
    let section: SettingsView.SettingsSection
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? Color(hex: "845CEF") : Color(hex: "666666"))
                
                Text(section.rawValue)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? Color(hex: "845CEF") : Color(hex: "666666"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? 
                Color(hex: "845CEF").opacity(0.1) : 
                Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Permissions Settings
struct PermissionsSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var hasAccessibilityPermission: Bool = false
    @State private var hasAutomationPermission: Bool = false
    @State private var animateItems: Bool = false
    
    private let hotkeyManager = HotkeyManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Section header
            VStack(alignment: .leading, spacing: 8) {
                Text("App Permissions")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "333333"))
                
                Text("Kerlig needs certain permissions to work properly.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "666666"))
            }
            .padding(.bottom, 10)
            .opacity(animateItems ? 1 : 0)
            .offset(y: animateItems ? 0 : 20)
            
            // Accessibility Permission
            PermissionRow(
                icon: "hand.tap",
                title: "Accessibility Permission",
                description: "Required to capture text selections from any app",
                isGranted: hasAccessibilityPermission,
                onAction: openAccessibilitySettings
            )
            .padding(.vertical, 5)
            .opacity(animateItems ? 1 : 0)
            .offset(y: animateItems ? 0 : 20)
            
            // Automation Permission
            PermissionRow(
                icon: "gearshape.arrow.circlepath",
                title: "Automation Permission",
                description: "Required to control other apps and services",
                isGranted: hasAutomationPermission,
                onAction: openAutomationSettings
            )
            .padding(.vertical, 5)
            .opacity(animateItems ? 1 : 0)
            .offset(y: animateItems ? 0 : 20)
            
            // Privacy Explanation
            VStack(alignment: .leading, spacing: 15) {
                Text("Privacy & Data Usage")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "333333"))
                
                Text("Kerlig processes text locally on your device whenever possible. We only send selected text to AI models when you explicitly request AI assistance. Your data is never stored or used for training purposes.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "666666"))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(Color(hex: "f5f7fa"))
            .cornerRadius(10)
            .opacity(animateItems ? 1 : 0)
            .offset(y: animateItems ? 0 : 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            checkPermissions()
            
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                animateItems = true
            }
        }
    }
    
    private func checkPermissions() {
        // Check accessibility permission
        let checkOptions = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: false]
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(checkOptions as CFDictionary)
        
        // Check automation permission (simplified)
        hasAutomationPermission = hotkeyManager.hasAutomationPermission()
    }
    
    private func openAccessibilitySettings() {
        if #available(macOS 13.0, *) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        } else {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
        }
        
        // Schedule permission check after opening settings
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkPermissions()
        }
    }
    
    private func openAutomationSettings() {
        if #available(macOS 13.0, *) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
        } else {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
        }
        
        // Schedule permission check after opening settings
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkPermissions()
        }
    }
}

// MARK: - Permission Row
struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let onAction: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            ZStack {
                Circle()
                    .fill(isGranted ? Color.green.opacity(0.1) : Color(hex: "845CEF").opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isGranted ? Color.green : Color(hex: "845CEF"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "333333"))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "666666"))
            }
            
            Spacer()
            
            if isGranted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Granted")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "333333"))
                }
            } else {
                Button(action: onAction) {
                    Text("Grant Access")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: "845CEF"))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - AI Model Settings
struct AIModelSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedModel: String = ""
    @State private var animateItems: Bool = false
    
    let models = [
        AIModel(id: "@cf/meta/llama-3.3-70b-instruct-fp8-fast", name: "Llama 3", provider: "Meta AI", 
                description: "Powerful open model with great performance", 
                icon: "sparkles.square"),
        AIModel(id: "gpt-4o", name: "GPT-4", provider: "OpenAI", 
                description: "State-of-the-art language capabilities", 
                icon: "tornado"),
        AIModel(id: "gemini-pro", name: "Gemini Pro", provider: "Google", 
                description: "Fast and efficient text processing", 
                icon: "diamond")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Section header
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Model Selection")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "333333"))
                
                Text("Choose which AI model powers Kerlig's text assistance.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "666666"))
            }
            .padding(.bottom, 10)
            .opacity(animateItems ? 1 : 0)
            .offset(y: animateItems ? 0 : 20)
            
            // API Key input
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "333333"))
                
                Text("Some models may require an API key to function")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "666666"))
                
                TextField("Enter your API key here", text: $appState.apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 14))
                    .padding(.top, 6)
            }
            .padding(20)
            .background(Color(hex: "f5f7fa"))
            .cornerRadius(10)
            .opacity(animateItems ? 1 : 0)
            .offset(y: animateItems ? 0 : 20)
            
            // AI Models List
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Models")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "333333"))
                    .padding(.bottom, 6)
                
                VStack(spacing: 15) {
                    ForEach(models) { model in
                        ModelSelectionCard(
                            model: model,
                            isSelected: selectedModel == model.id,
                            onSelect: {
                                withAnimation(.spring()) {
                                    selectedModel = model.id
                                    appState.aiModel = model.id
                                }
                            }
                        )
                        .transition(.opacity)
                    }
                }
                .opacity(animateItems ? 1 : 0)
                .offset(y: animateItems ? 0 : 20)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            selectedModel = appState.aiModel
            
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                animateItems = true
            }
        }
    }
}

// Model Selection Card Component
struct ModelSelectionCard: View {
    let model: AIModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // Model icon
            ZStack {
                Circle()
                    .fill(isSelected ? 
                          LinearGradient(gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(gradient: Gradient(colors: [Color(hex: "f0f2f5"), Color(hex: "f0f2f5")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                
                Image(systemName: model.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : Color(hex: "845CEF"))
            }
            
            // Model info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "333333"))
                    
                    Text("by \(model.provider)")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "999999"))
                }
                
                Text(model.description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "666666"))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Selection indicator
            ZStack {
                Circle()
                    .stroke(isSelected ? Color(hex: "845CEF") : Color(hex: "dddddd"), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isSelected {
                    Circle()
                        .fill(Color(hex: "845CEF"))
                        .frame(width: 16, height: 16)
                }
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(isSelected ? 0.1 : 0.05), radius: isSelected ? 10 : 5, x: 0, y: isSelected ? 5 : 2)
        .scaleEffect(isSelected ? 1.02 : 1)
        .onTapGesture {
            onSelect()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Advanced Settings
struct AdvancedSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var animateItems: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Section header
            VStack(alignment: .leading, spacing: 8) {
                Text("Advanced Settings")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "333333"))
                
                Text("Customize Kerlig's behavior to fit your workflow.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "666666"))
            }
            .padding(.bottom, 10)
            .opacity(animateItems ? 1 : 0)
            .offset(y: animateItems ? 0 : 20)
            
            // Hotkey Settings
            VStack(alignment: .leading, spacing: 15) {
                Text("Keyboard Shortcuts")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "333333"))
                
                VStack(spacing: 16) {
                    ToggleRow(
                        title: "Enable Global Hotkey",
                        description: "Use Command+Space to activate Kerlig from any app",
                        isOn: $appState.hotkeyEnabled
                    )
                    
                    Divider()
                    
                    ToggleRow(
                        title: "Start With Blank Content",
                        description: "Show empty input when no text is selected",
                        isOn: $appState.startWithBlank
                    )
                    
                    Divider()
                    
                    ToggleRow(
                        title: "Pin Panel When Open",
                        description: "Keep the assistant panel open until manually closed",
                        isOn: $appState.isPinned
                    )
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .opacity(animateItems ? 1 : 0)
            .offset(y: animateItems ? 0 : 20)
            
            // Response Style Settings
            VStack(alignment: .leading, spacing: 15) {
                Text("Response Style")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "333333"))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose how Kerlig should respond to your text")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "666666"))
                    
                    RadioButtonGroup(
                        options: [
                            ("Concise", "Brief, to-the-point responses", ResponseStyle.concise), 
                            ("Balanced", "Moderate length with explanations", ResponseStyle.balanced),
                            ("Detailed", "In-depth, comprehensive responses", ResponseStyle.detailed)
                        ],
                        selectedOption: appState.responseStyle,
                        onSelect: { style in
                            appState.responseStyle = style
                        }
                    )
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .opacity(animateItems ? 1 : 0)
            .offset(y: animateItems ? 0 : 20)
            
            // Clear Data Section
            VStack(alignment: .leading, spacing: 15) {
                Text("Data Management")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "333333"))
                
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Clear History")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "333333"))
                        
                        Text("Remove all saved interactions")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "666666"))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        appState.clearHistory()
                    }) {
                        Text("Clear")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .opacity(animateItems ? 1 : 0)
            .offset(y: animateItems ? 0 : 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                animateItems = true
            }
        }
    }
}

// MARK: - Toggle Row Component
struct ToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "333333"))
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "666666"))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "845CEF")))
                .labelsHidden()
        }
    }
}

// MARK: - Radio Button Component
struct RadioButtonRow<T: Equatable>: View {
    let title: String
    let subtitle: String
    let value: T
    let selectedValue: T
    let onSelect: (T) -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Button(action: {
                onSelect(value)
            }) {
                ZStack {
                    Circle()
                        .stroke(Color(hex: "845CEF"), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if value == selectedValue {
                        Circle()
                            .fill(Color(hex: "845CEF"))
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: value == selectedValue ? .semibold : .regular))
                    .foregroundColor(Color(hex: "333333"))
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "666666"))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(value)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedValue)
    }
}

// Radio Button Group Component
struct RadioButtonGroup<T: Equatable>: View {
    let options: [(String, String, T)]
    let selectedOption: T
    let onSelect: (T) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<options.count, id: \.self) { index in
                RadioButtonRow(
                    title: options[index].0,
                    subtitle: options[index].1,
                    value: options[index].2,
                    selectedValue: selectedOption,
                    onSelect: onSelect
                )
                
                if index < options.count - 1 {
                    Divider()
                }
            }
        }
    }
}

