import SwiftUI
import AppKit

struct AboutView: View {
    @State private var selectedTab: AboutTab = .overview
    
    private enum AboutTab: String, CaseIterable {
        case overview = "Overview"
        case aiFeatures = "AI Features"
        case shortcuts = "Shortcuts"
        case support = "Support"
        
        var icon: String {
            switch self {
            case .overview: return "info.circle"
            case .aiFeatures: return "brain.head.profile"
            case .shortcuts: return "keyboard"
            case .support: return "questionmark.circle"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Tab Bar
            tabBarView
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .aiFeatures:
                        aiFeaturesContent
                    case .shortcuts:
                        shortcutsContent
                    case .support:
                        supportContent
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.textBackgroundColor))
        }
        .frame(width: 700, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            
            // App Name and Version
            VStack(spacing: 4) {
                Text("Kerlig")
                    .font(.title.bold())
                    .foregroundColor(.primary)
                
                Text("Version \(AppConfiguration.appVersion) (\(AppConfiguration.buildNumber))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Tagline
            Text("Intelligent Text Processing & AI Assistant")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 30)
        .padding(.bottom, 20)
    }
    
    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(AboutTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // App Description
            GroupBox(label: Text("About Kerlig").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kerlig is a powerful AI-powered text processing and productivity application for macOS. It seamlessly integrates with your workflow to enhance writing, translate text, analyze content, and boost productivity through intelligent automation.")
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Key Features:")
                        .font(.subheadline.bold())
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        AboutFeatureRow(icon: "brain.head.profile", text: "Advanced AI text processing with multiple models")
                        AboutFeatureRow(icon: "eye", text: "Gemini Vision for image and document analysis")
                        AboutFeatureRow(icon: "keyboard", text: "Global hotkeys for quick text capture")
                        AboutFeatureRow(icon: "menubar.rectangle", text: "Menu bar integration for seamless access")
                        AboutFeatureRow(icon: "note.text", text: "Smart note-taking and task management")
                        AboutFeatureRow(icon: "wand.and.rays", text: "Custom AI actions and workflows")
                        AboutFeatureRow(icon: "bolt", text: "Real-time streaming responses")
                        AboutFeatureRow(icon: "lock.shield", text: "Privacy-focused design with local processing")
                    }
                }
                .padding()
            }
            
            // System Requirements
            GroupBox(label: Text("System Requirements").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• macOS 12.0 or later")
                    Text("• 64-bit Intel or Apple Silicon processor")
                    Text("• 4GB RAM minimum, 8GB recommended")
                    Text("• Internet connection for AI features")
                    Text("• Accessibility permissions for global hotkeys")
                }
                .padding()
            }
            
            // Developer Info
            GroupBox(label: Text("Developer").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Developed with ❤️ for productivity enthusiasts")
                    Text("Built using SwiftUI and modern macOS technologies")
                    Text("Committed to user privacy and data security")
                }
                .padding()
            }
        }
    }
    
    private var aiFeaturesContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // AI Models
            GroupBox(label: Text("Supported AI Models").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kerlig supports multiple AI providers and models:")
                        .font(.subheadline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        AboutModelCard(provider: "OpenAI", models: ["GPT-4o", "GPT-4o Mini"], icon: "sparkles", color: .green)
                        AboutModelCard(provider: "Anthropic", models: ["Claude 3 Opus", "Claude 3 Sonnet", "Claude 3 Haiku"], icon: "wand.and.stars", color: .purple)
                        AboutModelCard(provider: "Google", models: ["Gemini Pro", "Gemini Vision"], icon: "g.circle", color: .orange)
                        AboutModelCard(provider: "Cloudflare", models: ["Llama 3.3", "Stable Diffusion"], icon: "cloud", color: .blue)
                    }
                }
                .padding()
            }
            
            // Text Processing Features
            GroupBox(label: Text("Text Processing Features").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    AIFeatureRow(icon: "checkmark.circle", title: "Grammar & Spelling", description: "Automatically fix grammar and spelling errors")
                    AIFeatureRow(icon: "pencil.line", title: "Writing Enhancement", description: "Improve clarity, tone, and engagement")
                    AIFeatureRow(icon: "globe", title: "Translation", description: "Translate between multiple languages")
                    AIFeatureRow(icon: "scissors", title: "Text Summarization", description: "Create concise summaries of long text")
                    AIFeatureRow(icon: "questionmark.circle", title: "Content Analysis", description: "Analyze tone, sentiment, and structure")
                    AIFeatureRow(icon: "wand.and.rays", title: "Custom Actions", description: "Create personalized AI workflows")
                }
                .padding()
            }
            
            // Vision Features
            GroupBox(label: Text("Vision & Document Analysis").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    AIFeatureRow(icon: "photo", title: "Image Analysis", description: "Describe and analyze images with Gemini Vision")
                    AIFeatureRow(icon: "doc.text", title: "Document Processing", description: "Extract text and analyze PDF documents")
                    AIFeatureRow(icon: "table", title: "Spreadsheet Analysis", description: "Process Excel and CSV files")
                    AIFeatureRow(icon: "music.note", title: "Audio Processing", description: "Transcribe audio using Whisper")
                    AIFeatureRow(icon: "video", title: "Video Analysis", description: "Extract frames and analyze video content")
                }
                .padding()
            }
            
            // Streaming & Performance
            GroupBox(label: Text("Performance Features").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    AIFeatureRow(icon: "bolt", title: "Real-time Streaming", description: "See responses as they're generated")
                    AIFeatureRow(icon: "clock", title: "Fast Processing", description: "Optimized for quick responses")
                    AIFeatureRow(icon: "memorychip", title: "Memory Efficient", description: "Smart caching and resource management")
                    AIFeatureRow(icon: "network", title: "Adaptive Networking", description: "Handles network interruptions gracefully")
                }
                .padding()
            }
        }
    }
    
    private var shortcutsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Global Shortcuts
            GroupBox(label: Text("Global Shortcuts").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    ShortcutRow(shortcut: "⌥ Space", description: "Capture selected text and open AI panel")
                    ShortcutRow(shortcut: "⌘ M", description: "Open Mac Write floating sidebar")
                    ShortcutRow(shortcut: "⌘ P", description: "Open Project Workspace")
                    ShortcutRow(shortcut: "⌥⌘ C", description: "Capture text from current application")
                    ShortcutRow(shortcut: "⌥⌘ M", description: "Show main application window")
                }
                .padding()
            }
            
            // Panel Shortcuts
            GroupBox(label: Text("Panel & Interface").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    ShortcutRow(shortcut: "⌘ N", description: "Start new blank conversation")
                    ShortcutRow(shortcut: "⌘ ,", description: "Open Settings")
                    ShortcutRow(shortcut: "⌘ Q", description: "Quit application")
                    ShortcutRow(shortcut: "Escape", description: "Cancel current action or close panel")
                    ShortcutRow(shortcut: "Tab", description: "Toggle AI model selection menu")
                    ShortcutRow(shortcut: "Return", description: "Submit prompt or execute action")
                }
                .padding()
            }
            
            // Navigation Shortcuts
            GroupBox(label: Text("Navigation").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    ShortcutRow(shortcut: "↑ ↓", description: "Navigate through AI actions list")
                    ShortcutRow(shortcut: "⌘ ↑", description: "Move to top of list")
                    ShortcutRow(shortcut: "⌘ ↓", description: "Move to bottom of list")
                    ShortcutRow(shortcut: "⌘ [", description: "Go back in navigation")
                    ShortcutRow(shortcut: "⌘ ]", description: "Go forward in navigation")
                }
                .padding()
            }
            
            // Text Editing Shortcuts
            GroupBox(label: Text("Text Editing").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    ShortcutRow(shortcut: "⌘ B", description: "Bold text formatting")
                    ShortcutRow(shortcut: "⌘ I", description: "Italic text formatting")
                    ShortcutRow(shortcut: "⌘ U", description: "Underline text formatting")
                    ShortcutRow(shortcut: "⌘ L", description: "Insert bullet point")
                    ShortcutRow(shortcut: "⌘ K", description: "Insert checkbox")
                    ShortcutRow(shortcut: "⌘ Z", description: "Undo last action")
                    ShortcutRow(shortcut: "⌘ ⇧ Z", description: "Redo last action")
                }
                .padding()
            }
            
            // Custom Action Shortcuts
            GroupBox(label: Text("Custom AI Actions").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    ShortcutRow(shortcut: "⌘ A", description: "Ask - General AI question")
                    ShortcutRow(shortcut: "⌘ E", description: "Enhance - Improve sentence quality")
                    ShortcutRow(shortcut: "⌘ T", description: "Translate - Translate text")
                    ShortcutRow(shortcut: "⌘ G", description: "Grammar - Fix grammar issues")
                    ShortcutRow(shortcut: "⌘ S", description: "Summarize - Create text summary")
                    ShortcutRow(shortcut: "⌘ X", description: "Explain - Explain complex text")
                    
                    Text("Note: Custom actions can be configured with your own keyboard shortcuts in Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding()
            }
        }
    }
    
    private var supportContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Quick Help
            GroupBox(label: Text("Quick Help").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    HelpRow(icon: "1.circle", title: "Getting Started", description: "Grant accessibility permissions, select your AI model, and start using Option+Space to capture text.")
                    HelpRow(icon: "2.circle", title: "Custom Actions", description: "Create personalized AI workflows in Settings > Actions to match your specific needs.")
                    HelpRow(icon: "3.circle", title: "Productivity Tips", description: "Use the menu bar icon for quick access, pin panels for reference, and set up custom shortcuts.")
                }
                .padding()
            }
            
            // Troubleshooting
            GroupBox(label: Text("Troubleshooting").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    HelpRow(icon: "exclamationmark.triangle", title: "Hotkeys Not Working", description: "Ensure accessibility permissions are granted in System Preferences > Security & Privacy > Accessibility.")
                    HelpRow(icon: "wifi.slash", title: "Connection Issues", description: "Check your internet connection and verify API keys are correctly configured.")
                    HelpRow(icon: "questionmark.diamond", title: "AI Not Responding", description: "Try switching to a different AI model or check if the service is experiencing downtime.")
                }
                .padding()
            }
            
            // Contact & Support
            GroupBox(label: Text("Support & Feedback").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            SupportButton(title: "Report Bug", url: AppConfiguration.URLs.reportBug, icon: "ladybug")
                            SupportButton(title: "Request Feature", url: AppConfiguration.URLs.requestChange, icon: "lightbulb")
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            SupportButton(title: "Documentation", url: AppConfiguration.URLs.documentation, icon: "book")
                            SupportButton(title: "Write Review", url: AppConfiguration.URLs.writeReview, icon: "star")
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            SupportButton(title: "Privacy Policy", url: AppConfiguration.URLs.privacyPolicy, icon: "lock.shield")
                            SupportButton(title: "Terms of Service", url: AppConfiguration.URLs.termsOfService, icon: "doc.text")
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            SupportButton(title: "Check Updates", url: AppConfiguration.URLs.checkForUpdates, icon: "arrow.down.circle")
                            SupportButton(title: "Visit Website", url: AppConfiguration.URLs.baseURL, icon: "globe")
                        }
                    }
                }
                .padding()
            }
            
            // Version Information
            GroupBox(label: Text("Version Information").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("App Version: \(AppConfiguration.appVersion)")
                    Text("Build Number: \(AppConfiguration.buildNumber)")
                    Text("macOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)")
                    Text("System Architecture: \(ProcessInfo.processInfo.machineHardwareName ?? "Unknown")")
                }
                .font(.system(.body, design: .monospaced))
                .padding()
            }
        }
    }
}

// MARK: - Helper Views

struct AboutFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 14))
        }
    }
}

struct AboutModelCard: View {
    let provider: String
    let models: [String]
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(provider)
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(models, id: \.self) { model in
                    Text("• \(model)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct AIFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ShortcutRow: View {
    let shortcut: String
    let description: String
    
    var body: some View {
        HStack {
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .frame(width: 100, alignment: .leading)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct HelpRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct SupportButton: View {
    let title: String
    let url: String
    let icon: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 13))
            }
            .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            if isHovered {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Extensions

extension ProcessInfo {
    var machineHardwareName: String? {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
    }
}

#Preview {
    AboutView()
} 