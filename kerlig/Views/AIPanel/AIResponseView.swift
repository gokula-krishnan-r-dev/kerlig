import SwiftUI
import AppKit

// Update the extension to use our glass effect
extension View {
    func backgroundGradient() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        )
    }
}

struct AIResponseView: View {
    @EnvironmentObject var appState: AppState
    
    // State management
    @Binding var isProcessing: Bool
    @Binding var isAnimating: Bool
    @Binding var insertionStatus: KerligStylePanelView.InsertionStatus
    @Binding var isInserting: Bool
    @Binding var insertAttempts: Int
    @Binding var selectedAction: AIAction?
    
    // Callback functions
    var onCopy: (String) -> Void
    var onInsert: (String) -> Void
    var onRegenerate: () -> Void
    
    // Loading animation timing
    private let animationDelays = [0.2, 0.4, 0.6]
    
    var body: some View {
        responseContainer
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: !appState.aiResponse.isEmpty || isProcessing)
            .onAppear {
                self.isAnimating = true
            }
    }
    
    // Main container for the response section
    private var responseContainer: some View {
        VStack(alignment: .leading, spacing: 12) {
            responseHeader
            responseContent
            
            if !appState.aiResponse.isEmpty {
                Divider()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .opacity(0.5)
                
                actionButtons
            }
        }
        .glassCard()
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
    
    // Header with title and processing indicator
    private var responseHeader: some View {
        HStack {
            Text("Response")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            if isProcessing {
                processingIndicator
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // Animated processing indicator with dots
    private var processingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                animatedDot(delay: animationDelays[index])
            }
            
            Text("Processing...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    // Individual animated dot for processing indicator
    private func animatedDot(delay: Double) -> some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(Color.blue, lineWidth: 1)
                    .scaleEffect(isAnimating ? 2 : 0.1)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: 1)
                            .repeatForever(autoreverses: false)
                            .delay(delay),
                        value: isAnimating
                    )
            )
    }
    
    // Main content area that switches between loading skeleton and response
    private var responseContent: some View {
        Group {
            if isProcessing && appState.aiResponse.isEmpty {
                skeletonLoadingView
            } else {
                if !appState.aiResponse.isEmpty {
                    FormattedTextView(appState.aiResponse)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                        .padding(.horizontal, 16)
                } else {
                    emptyResponseView
                }
            }
        }
    }
    
    // Skeleton loading placeholder
    private var skeletonLoadingView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header section
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 30, height: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonLine(width: 140)
                    SkeletonLine(width: 80, height: 10)
                }
            }
            
            // Main content
            ForEach(0..<3) { section in
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<3) { line in
                        SkeletonLine(width: section == 2 && line == 2 ? 200 : nil)
                    }
                    if section != 2 {
                        SkeletonLine(width: section == 0 ? 250 : 180)
                    }
                }
                
                if section != 2 {
                    Spacer(minLength: 8)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 16)
        .transition(.opacity)
    }
    
    // View shown when no response is available
    private var emptyResponseView: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No response available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Ask a question or select an action to get started")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 16)
    }
    
    // Action buttons displayed below the response
    private var actionButtons: some View {
        HStack(spacing: 18) {
            Spacer()
            
            // Copy button
            Button(action: {
                if !appState.aiResponse.isEmpty {
                    onCopy(appState.aiResponse)
                    showToast("Copied to clipboard")
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                    
                    Text("Copy")
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Insert button
            Button(action: {
                if !appState.aiResponse.isEmpty {
                    onInsert(appState.aiResponse)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 12))
                    
                    Text("Insert")
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Regenerate button
            Button(action: {
                onRegenerate()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                    
                    Text("Regenerate")
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // Helper for toast messages
    private func showToast(_ message: String) {
        let notification = NSUserNotification()
        notification.title = message
        notification.soundName = nil
        NSUserNotificationCenter.default.deliver(notification)
    }
}

