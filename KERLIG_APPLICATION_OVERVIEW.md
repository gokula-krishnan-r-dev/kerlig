# Kerlig - AI-Powered Productivity Assistant for macOS

## 🎯 What is Kerlig?

**Kerlig** is a sophisticated macOS productivity application that combines AI-powered text processing, task management, and workspace organization into a seamless, always-available productivity companion. Built with SwiftUI, Kerlig operates as both a background utility and a full-featured productivity suite, designed to enhance your workflow without disrupting it.

## 🌟 Core Purpose & Vision

Kerlig serves as your **intelligent writing and productivity assistant** that:

- **Enhances text** from any application using AI (GPT, Gemini, Whisper)
- **Manages projects and tasks** with advanced task management features
- **Captures and processes content** from anywhere on your Mac
- **Operates seamlessly in the background** without cluttering your dock
- **Provides instant access** through global hotkeys and menu bar integration

## 🔥 Key Features Overview

### 🤖 AI-Powered Text Processing

- **Multi-AI Integration**: Supports OpenAI GPT, Google Gemini, and Cloudflare Whisper
- **Text Enhancement**: Fix grammar, improve writing, translate, summarize, and make text concise
- **Smart Text Capture**: Capture text from any application using Option+Space hotkey
- **Voice-to-Text**: Advanced voice recording and transcription using Whisper AI
- **Custom AI Actions**: Create and customize AI prompts for specific workflows
- **Streaming Responses**: Real-time AI response streaming with typing effects

### 📋 Advanced Task & Project Management

- **Project Organization**: Create and manage multiple projects with releases and versions
- **Kanban-Style Boards**: Visual task management with drag-and-drop functionality
- **Task Dependencies**: Link tasks with dependencies and blocking relationships
- **Time Tracking**: Built-in timer with pomodoro integration
- **Sprint Planning**: Agile methodology support with sprint management
- **Team Collaboration**: Assign tasks to team members and track progress
- **Notes & Documentation**: Rich note-taking integrated with task management

### 🗂️ Workspace & File Management

- **VSCode/Cursor Integration**: Detect and manage development workspaces
- **File Analysis**: AI-powered file content analysis and insights
- **Project Detection**: Automatically discover and organize coding projects
- **Workspace Switching**: Quick access to frequently used development environments

### 🎯 Background Operation & System Integration

- **Menu Bar App**: Runs quietly in the background with menu bar access
- **Global Hotkeys**: System-wide keyboard shortcuts (Option+Space, Cmd+Shift+R)
- **Launch at Login**: Automatic startup on system boot
- **Accessibility Integration**: Deep macOS accessibility API integration
- **Clipboard Monitoring**: Track and manage clipboard history

### 🔧 Developer & Power User Tools

- **Port Monitoring**: Real-time network port scanning and monitoring
- **Development Workflow**: Integration with Terminal, Cursor, and other dev tools
- **System Services**: macOS Services integration for context menu access
- **AppleScript Support**: Scriptable automation capabilities

## 💻 User Interface & Experience

### Main Application Modes

**1. Full Application Mode**

- Complete SwiftUI interface with sidebar navigation
- Dashboard, Task Management, Clipboard History, and Settings
- Project and workspace management views
- Comprehensive settings and customization options

**2. Background Agent Mode**

- Minimal menu bar presence
- Floating AI panels for quick text processing
- Global hotkey access from any application
- No dock icon - truly background operation

**3. Floating Panels**

- Context-aware AI processing panels
- Text capture and enhancement interfaces
- Quick task creation and management
- Notification panels for important updates

### Design Philosophy

- **macOS Native**: Built using SwiftUI with native macOS design patterns
- **Accessibility First**: Full VoiceOver and accessibility support
- **Light/Dark Mode**: Automatic adaptation to system appearance
- **Responsive Design**: Adapts to different window sizes and screen configurations

## 🎯 Primary Use Cases

### 1. **Content Creators & Writers**

- Enhance blog posts, articles, and social media content
- Fix grammar and improve writing quality instantly
- Translate content for international audiences
- Generate summaries and abstracts

### 2. **Software Developers**

- Manage development projects and sprints
- Track coding tasks and technical documentation
- Monitor local development servers and ports
- Organize workspace and project files

### 3. **Business Professionals**

- Improve email and document writing
- Manage client projects and deliverables
- Track time spent on different tasks
- Create professional presentations and reports

### 4. **Students & Researchers**

- Enhance academic writing and papers
- Organize research projects and notes
- Track study sessions and deadlines
- Transcribe lectures and interviews

### 5. **Teams & Collaboration**

- Coordinate team projects and sprints
- Assign and track task completion
- Share AI-enhanced content and documentation
- Monitor project progress and deadlines

## 🏗️ Technical Architecture

### Core Technologies

- **Platform**: macOS 13+ (Ventura and later)
- **Framework**: SwiftUI with AppKit integration
- **Language**: Swift 5.9+
- **AI Services**: OpenAI API, Google Gemini, Cloudflare Workers AI
- **Data Storage**: UserDefaults, local file system, Core Data

### Key Services & Components

**AI & Processing Services**

- `AIService`: Main AI orchestration and API management
- `GeminiVisionService`: Google Gemini AI integration
- `WhisperAIService`: Voice transcription and processing
- `TextCaptureService`: Cross-application text capture
- `VoiceRecordingService`: Audio recording and processing

**Task & Project Management**

- `WorkspaceService`: Development workspace detection
- `VSCodeProjectsService`: IDE integration
- `TaskTimerNotificationService`: Time tracking and notifications
- `CustomActionsStorage`: User-defined AI actions

**System Integration**

- `BackgroundAppManager`: Background operation management
- `HotkeyManager`: Global keyboard shortcut handling
- `MenuBarController`: Menu bar interface
- `LaunchAtLoginManager`: System startup integration
- `PortScannerService`: Network monitoring

### Data Models

- `AppState`: Central application state management
- `NoteModel` & `WorkspaceModel`: Content and project data
- `ChatInteraction`: AI conversation history
- `CustomAction`: User-defined AI workflows

## 🔐 Security & Privacy

### Data Protection

- **Local Processing**: Most data stays on your device
- **API Key Security**: Encrypted storage of AI service credentials
- **No Tracking**: No analytics or user behavior tracking
- **Sandboxed Operation**: Standard macOS app sandboxing

### Permissions Required

- **Accessibility**: For text capture from other applications
- **Microphone**: For voice recording and transcription
- **Apple Events**: For automation and integration with other apps
- **Input Monitoring**: For global hotkey detection

## 🚀 Getting Started

### Installation

1. Download Kerlig from the official source
2. Move to Applications folder
3. Launch and complete onboarding setup
4. Grant required permissions (accessibility, microphone)
5. Configure AI service API keys in settings

### Initial Setup

1. **Permissions**: Grant accessibility and microphone access
2. **AI Configuration**: Add OpenAI, Gemini, or Cloudflare API keys
3. **Hotkey Setup**: Configure global shortcuts (default: Option+Space)
4. **Background Mode**: Choose whether to run in background
5. **Project Setup**: Create your first project or import existing workspaces

### Quick Usage

- **Text Enhancement**: Select text anywhere, press Option+Space
- **Voice Recording**: Press Cmd+Shift+R to start voice recording
- **Task Management**: Open main app for full project management
- **Quick Access**: Click menu bar icon for instant actions

## 🎨 Customization & Extensions

### AI Customization

- Create custom AI prompts and actions
- Configure response styles (formal, casual, technical)
- Set up project-specific AI workflows
- Train custom shortcuts for frequent tasks

### UI Customization

- Light/dark mode following system preferences
- Customizable hotkeys and shortcuts
- Adjustable floating panel behavior
- Configurable notification settings

### Workflow Integration

- Terminal and IDE integration
- Custom AppleScript automation
- File type associations
- Context menu extensions

## 📈 Advanced Features

### Analytics & Insights

- Task completion tracking and analytics
- Time spent analysis and productivity insights
- AI usage statistics and optimization
- Project progress and milestone tracking

### Automation Capabilities

- Scheduled task notifications and reminders
- Automated project backups and sync
- Smart text capture and processing rules
- Custom workflow triggers and actions

### Collaboration Tools

- Team member assignment and tracking
- Shared project spaces and resources
- Activity feeds and progress updates
- Export capabilities for external tools

## 🔄 Future Roadmap

### Planned Enhancements

- iOS companion app for mobile access
- Advanced team collaboration features
- Machine learning for personalized suggestions
- Integration with more development tools
- Enhanced voice command processing
- Cloud sync and backup options

### Community & Support

- Open-source components and extensions
- Plugin architecture for third-party integrations
- Community templates and workflows
- Comprehensive documentation and tutorials

## 📊 Performance & Requirements

### System Requirements

- **macOS**: 13.0 (Ventura) or later
- **RAM**: Minimum 8GB recommended
- **Storage**: 500MB for application and data
- **Network**: Internet connection for AI services

### Performance Characteristics

- **Startup Time**: < 2 seconds cold start
- **Memory Usage**: ~100MB typical, ~200MB with active AI processing
- **Battery Impact**: Minimal when running in background
- **Responsiveness**: Sub-second text capture and processing

## 🎉 Why Choose Kerlig?

**Kerlig stands out because it:**

1. **Integrates Seamlessly**: Works with your existing workflow without disruption
2. **Truly Background**: Operates efficiently without cluttering your workspace
3. **AI-First Design**: Built around modern AI capabilities, not retrofitted
4. **macOS Native**: Feels like a natural part of your Mac experience
5. **Privacy Focused**: Keeps your data local and secure
6. **Highly Customizable**: Adapts to your specific needs and workflows
7. **Professional Grade**: Suitable for individual use and team collaboration

Whether you're a writer looking to enhance your content, a developer managing complex projects, or a professional seeking to streamline your workflow, Kerlig provides the intelligent assistance you need, exactly when and where you need it.

---

_Kerlig transforms how you interact with text and manage productivity on macOS, making AI assistance as natural as typing itself._
