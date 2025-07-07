import SwiftUI

// MARK: - Screenshot Analysis Demo View
struct ScreenshotAnalysisDemo: View {
    @StateObject private var screenshotService = ScreenshotCaptureService.shared
    @StateObject private var panelController = ScreenshotPanelController.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("Screenshot Analysis")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Capture screenshots and analyze them with AI")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Demo actions
            VStack(spacing: 16) {
                // Full screen capture
                Button(action: {
                    panelController.captureScreenshot()
                }) {
                    HStack {
                        Image(systemName: "camera")
                            .font(.system(size: 18))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Capture Full Screen")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("Take a screenshot of the entire screen")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("⌘~")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primary.opacity(0.1))
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Area capture
                Button(action: {
                    panelController.captureScreenshotArea()
                }) {
                    HStack {
                        Image(systemName: "crop")
                            .font(.system(size: 18))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Capture Screenshot Area")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("Select a specific area to capture")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("Interactive")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primary.opacity(0.1))
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Show existing panel
                if panelController.currentScreenshot != nil {
                    Button(action: {
                        if let screenshot = panelController.currentScreenshot {
                            panelController.showPanel(with: screenshot)
                        }
                    }) {
                        HStack {
                            Image(systemName: "eye")
                                .font(.system(size: 18))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Show Analysis Panel")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("View the last captured screenshot")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(maxWidth: 400)
            
            // Features overview
            VStack(spacing: 12) {
                Text("Features")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    FeatureRowView(
                        icon: "sparkles",
                        title: "AI Analysis",
                        description: "Ask questions about your screenshots"
                    )
                    
                    FeatureRowView(
                        icon: "magnifyingglass",
                        title: "Image Inspection",
                        description: "Zoom and examine screenshot details"
                    )
                    
                    FeatureRowView(
                        icon: "doc.on.doc",
                        title: "Quick Actions",
                        description: "Copy, save, and share screenshots"
                    )
                    
                    FeatureRowView(
                        icon: "keyboard",
                        title: "Global Hotkeys",
                        description: "Command+~ for instant screenshots"
                    )
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

// MARK: - Feature Row Component
struct FeatureRowView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ScreenshotAnalysisDemo()
        .frame(width: 600, height: 700)
} 