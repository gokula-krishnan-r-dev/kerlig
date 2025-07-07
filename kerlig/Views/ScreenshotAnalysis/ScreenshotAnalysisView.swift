import SwiftUI
import AppKit

// MARK: - Screenshot Analysis View
struct ScreenshotAnalysisView: View {
    @ObservedObject var controller: ScreenshotPanelController
    @State private var isImageHovered = false
    @State private var showingImageInspector = false
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastScaleValue: CGFloat = 1.0
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Background with blur effect
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        // Screenshot display
                        screenshotView
                        
                        // User query input
                        queryInputView
                        
                        // AI response
                        responseView
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                // Footer with action buttons
                footerView
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .background(Color.clear)
        .onAppear {
            // Auto-focus text field when panel appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            // Title
            HStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Screenshot Analysis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Header actions
            HStack(spacing: 8) {
                // New screenshot button
                Button(action: {
                    controller.captureScreenshot()
                }) {
                    Image(systemName: "plus.viewfinder")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(HeaderButtonStyle())
                .help("Capture new screenshot")
                
                // Screenshot area button
                Button(action: {
                    controller.captureScreenshotArea()
                }) {
                    Image(systemName: "crop")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(HeaderButtonStyle())
                .help("Capture screenshot area")
                
                // Close button
                Button(action: {
                    controller.hidePanel()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(HeaderButtonStyle())
                .help("Close panel")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color.clear)
                .background(.ultraThinMaterial)
        )
    }
    
    // MARK: - Screenshot Display
    private var screenshotView: some View {
        Group {
            if let screenshot = controller.currentScreenshot {
                VStack(spacing: 12) {
                    // Screenshot info
                    HStack {
                        Text("Screenshot")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(screenshotInfoText(screenshot))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    // Screenshot image
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                        
                        Image(nsImage: screenshot)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(imageScale)
                            .offset(imageOffset)
                            .clipped()
                            .onHover { hovering in
                                isImageHovered = hovering
                            }
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        imageScale = lastScaleValue * value
                                    }
                                    .onEnded { value in
                                        lastScaleValue = imageScale
                                        
                                        // Constrain scale
                                        if imageScale < 0.5 {
                                            imageScale = 0.5
                                            lastScaleValue = 0.5
                                        } else if imageScale > 3.0 {
                                            imageScale = 3.0
                                            lastScaleValue = 3.0
                                        }
                                    }
                                    .simultaneously(with:
                                        DragGesture()
                                            .onChanged { value in
                                                imageOffset = value.translation
                                            }
                                            .onEnded { _ in
                                                // Reset offset when drag ends
                                                withAnimation(.spring()) {
                                                    imageOffset = .zero
                                                }
                                            }
                                    )
                            )
                    }
                    .frame(maxHeight: 300)
                    .overlay(
                        // Zoom controls overlay
                        VStack {
                            HStack {
                                Spacer()
                                
                                if isImageHovered {
                                    HStack(spacing: 4) {
                                        Button(action: {
                                            withAnimation(.spring()) {
                                                imageScale = max(0.5, imageScale - 0.2)
                                                lastScaleValue = imageScale
                                            }
                                        }) {
                                            Image(systemName: "minus.magnifyingglass")
                                                .font(.system(size: 12))
                                        }
                                        .buttonStyle(ZoomButtonStyle())
                                        
                                        Button(action: {
                                            withAnimation(.spring()) {
                                                imageScale = 1.0
                                                lastScaleValue = 1.0
                                                imageOffset = .zero
                                            }
                                        }) {
                                            Text("1:1")
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .buttonStyle(ZoomButtonStyle())
                                        
                                        Button(action: {
                                            withAnimation(.spring()) {
                                                imageScale = min(3.0, imageScale + 0.2)
                                                lastScaleValue = imageScale
                                            }
                                        }) {
                                            Image(systemName: "plus.magnifyingglass")
                                                .font(.system(size: 12))
                                        }
                                        .buttonStyle(ZoomButtonStyle())
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(.regularMaterial)
                                    )
                                    .transition(.opacity)
                                }
                            }
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                            
                            Spacer()
                        }
                    )
                    
                    // Screenshot actions
                    HStack(spacing: 12) {
                        Button(action: {
                            controller.copyScreenshotToClipboard()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 12))
                                Text("Copy")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(ActionButtonStyle())
                        
                        Button(action: {
                            controller.saveScreenshot()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 12))
                                Text("Save")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(ActionButtonStyle())
                        
                        Spacer()
                    }
                }
            } else {
                // No screenshot placeholder
                VStack(spacing: 16) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Screenshot")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Capture a screenshot to analyze")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        controller.captureScreenshot()
                    }) {
                        Text("Capture Screenshot")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Query Input
    private var queryInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Ask about this screenshot")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if controller.isAnalyzing {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Analyzing...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isTextFieldFocused ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: 1)
                    )
                
                // Placeholder text
                if controller.userQuery.isEmpty {
                    Text("What would you like to know about this screenshot?")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                        .allowsHitTesting(false)
                }
                
                // Text editor
                TextEditor(text: $controller.userQuery)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        if !controller.userQuery.isEmpty && !controller.isAnalyzing {
                            controller.analyzeScreenshot()
                        }
                    }
            }
            .frame(minHeight: 80)
            
            // Error message with improved styling
            if let error = controller.analysisError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Button(action: {
                        controller.analysisError = nil
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red, lineWidth: 1)
                        )
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: controller.analysisError != nil)
            }
            
            // Query actions
            HStack {
                Spacer()
                
                Button(action: {
                    controller.userQuery = ""
                    controller.analysisError = nil
                }) {
                    Text("Clear")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(controller.userQuery.isEmpty)
                
                Button(action: {
                    controller.analyzeScreenshot()
                }) {
                    HStack(spacing: 4) {
                        if controller.isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                        }
                        
                        Text(controller.isAnalyzing ? "Analyzing..." : "Analyze")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(controller.userQuery.isEmpty || controller.isAnalyzing ? Color.gray : Color.accentColor)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(controller.userQuery.isEmpty || controller.isAnalyzing)
            }
        }
    }
    
    // MARK: - AI Response
    private var responseView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !controller.aiResponse.isEmpty {
                HStack {
                    Text("AI Analysis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        controller.copyResponseToClipboard()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                            Text("Copy")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(ActionButtonStyle())
                }
                
                // Response content
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(controller.aiResponse)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
                .frame(maxHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Footer
    private var footerView: some View {
        HStack {
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(controller.currentScreenshot != nil ? Color.green : Color.gray)
                    .frame(width: 6, height: 6)
                
                Text(controller.currentScreenshot != nil ? "Screenshot loaded" : "No screenshot")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Shortcut hint
            HStack(spacing: 4) {
                Text("Press")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text("⌘~")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.primary.opacity(0.1))
                    )
                
                Text("for new screenshot")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(Color.clear)
                .background(.ultraThinMaterial)
        )
    }
    
    // MARK: - Helper Methods
    
    private func screenshotInfoText(_ image: NSImage) -> String {
        let size = image.size
        return String(format: "%.0f × %.0f pixels", size.width, size.height)
    }
}

// MARK: - Visual Effect View
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Button Styles
struct HeaderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.1) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.1) : Color.primary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ZoomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.2) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ScreenshotAnalysisView(controller: ScreenshotPanelController.shared)
        .frame(width: 600, height: 700)
} 
