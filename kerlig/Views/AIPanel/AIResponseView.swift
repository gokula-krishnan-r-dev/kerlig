import SwiftUI
import AppKit

// Add this extension if backgroundGradient() is used in the view
extension View {
    func backgroundGradient() -> some View {
        self.background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(NSColor.controlBackgroundColor).opacity(0.97),
                    Color(NSColor.controlBackgroundColor).opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
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
                
                actionButtons
            }
        }
    }
    
    // Header with title and processing indicator
    private var responseHeader: some View {
        HStack {
            Text("Response")
                .font(.headline)
                .foregroundColor(.secondary)
            
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
                .fill(Color.gray.opacity(0.1))
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
                        .backgroundGradient()
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
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
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
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
            
            Text("Submit a prompt or select an action to generate a response")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
    }
    
    // Action buttons for copy, insert, regenerate
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Spacer()
            
            // Copy button
            actionButton(
                label: "Copy",
                systemImage: "doc.on.doc", isFocused: true,

                shortcutLetter: "C",
                action: { onCopy(appState.aiResponse) }
            )

            
            // Insert button with dynamic states
            Button(action: {
                onInsert(appState.aiResponse)
            }) {
                HStack(spacing: 4) {
                    if isInserting {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 14, height: 14)
                        Text(insertAttempts > 1 ? "Retrying..." : "Inserting...")
                            .font(.footnote)
                    } else if insertionStatus == .success {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Inserted")
                            .font(.footnote)
                    } else if insertionStatus == .failed {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("Insert Failed")
                            .font(.footnote)
                    } else {
                        Image(systemName: "arrow.right.doc.on.clipboard")
                        Text("Insert")
                            .font(.footnote)
                    }
                }
            }

            .disabled(isInserting)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            

        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // Reusable action button
    private func actionButton(
        label: String,
        systemImage: String,
        isFocused: Bool,
        shortcutLetter: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(label, systemImage: systemImage)
                .font(.footnote)
        }
        .buttonStyle(AnimatedButtonStyle(
            backgroundColor: isFocused ? Color.blue.opacity(0.1) : Color.clear,
            isFocused: isFocused
        ))
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .overlay(
            Group {
                if isFocused {
                    shortcutBadge(letter: shortcutLetter)
                }
            }
        )
    }
    
    // Keyboard shortcut badge
    private func shortcutBadge(letter: String) -> some View {
        Text(letter)
            .font(.system(size: 9, weight: .bold))
            .padding(4)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Circle())
            .offset(x: -32, y: -10)
    }
}

