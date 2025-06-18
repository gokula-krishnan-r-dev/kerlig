import SwiftUI
import AppKit
import AVFoundation

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

// Custom view for highlighted text during speech
struct HighlightedTextView: View {
    let text: String
    let highlightedRange: NSRange?
    
    var body: some View {
        let attributedText = createAttributedText()
        
        Text(AttributedString(attributedText))
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.easeInOut(duration: 0.2), value: highlightedRange)
    }
    
    private func createAttributedText() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        
        // Default text color
        attributedString.addAttribute(.foregroundColor, 
                                    value: NSColor.labelColor, 
                                    range: NSRange(location: 0, length: text.count))
        
        // Highlight the current word/phrase
        if let range = highlightedRange,
           range.location >= 0 && range.location + range.length <= text.count {
            attributedString.addAttribute(.backgroundColor, 
                                        value: NSColor.systemBlue.withAlphaComponent(0.3), 
                                        range: range)
            attributedString.addAttribute(.foregroundColor, 
                                        value: NSColor.white, 
                                        range: range)
        }
        
        return attributedString
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
    
    // Speech synthesis state
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var isSpeaking = false
    @State private var currentHighlightRange: NSRange?
    @State private var speechText = ""
    
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
                setupSpeechSynthesizer()
            }
    }
    
    // Setup speech synthesizer delegate
    private func setupSpeechSynthesizer() {
        speechSynthesizer.delegate = SpeechDelegate(
            onWordBoundary: { range in
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentHighlightRange = range
                }
            },
            onFinish: {
                withAnimation(.easeOut(duration: 0.3)) {
                    isSpeaking = false
                    currentHighlightRange = nil
                }
            }
        )
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
         .padding(.horizontal, 16)
        .padding(.bottom, 8)
 .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
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
            } else if isSpeaking {
                speakingIndicator
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // Speaking indicator
    private var speakingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                animatedSpeakingDot(delay: animationDelays[index])
            }
            
            Text("Speaking...")
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
                        .strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    // Individual animated dot for speaking indicator
    private func animatedSpeakingDot(delay: Double) -> some View {
        Circle()
            .fill(Color.green.opacity(0.2))
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(Color.green, lineWidth: 1)
                    .scaleEffect(isSpeaking ? 2 : 0.1)
                    .opacity(isSpeaking ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: 1)
                            .repeatForever(autoreverses: false)
                            .delay(delay),
                        value: isSpeaking
                    )
            )
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
                    .padding(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    emptyResponseView
                }
            }
        }
    }
    
    // Text-to-speech functionality
    private func startSpeaking() {
        guard !appState.aiResponse.isEmpty else { return }
        
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
            withAnimation(.easeOut(duration: 0.3)) {
                isSpeaking = false
                currentHighlightRange = nil
            }
            return
        }
        
        speechText = appState.aiResponse
        let utterance = AVSpeechUtterance(string: speechText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        withAnimation(.easeIn(duration: 0.3)) {
            isSpeaking = true
        }
        
        speechSynthesizer.speak(utterance)
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
        HStack(spacing: 12) {
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
                          //show a shortcut key
                Text("⌘C")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .contentShape(Rectangle())

              
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut("c", modifiers: .command)
            
            // Speak button
            Button(action: {
                startSpeaking()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isSpeaking ? "stop.circle" : "speaker.wave.2")
                        .font(.system(size: 12))
                    
                    Text(isSpeaking ? "Stop" : "Speak")
                        .font(.system(size: 13))

                //show a shortcut key
                Text("⌘S")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSpeaking ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                .cornerRadius(8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .animation(.easeInOut(duration: 0.2), value: isSpeaking)
            .keyboardShortcut("s", modifiers: .command)
            
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

                //show a shortcut key
                Text("⌘I")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut("i", modifiers: .command)

            // Regenerate button
            Button(action: {
                onRegenerate()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                    
                    Text("Regenerate")
                        .font(.system(size: 13))

                //show a shortcut key
                Text("⌘R")
                        .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut("r", modifiers: .command)
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

// Speech synthesizer delegate
class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let onWordBoundary: (NSRange) -> Void
    let onFinish: () -> Void
    
    init(onWordBoundary: @escaping (NSRange) -> Void, onFinish: @escaping () -> Void) {
        self.onWordBoundary = onWordBoundary
        self.onFinish = onFinish
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.onWordBoundary(characterRange)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.onFinish()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.onFinish()
        }
    }
}
