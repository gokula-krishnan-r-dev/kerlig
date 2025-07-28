import SwiftUI

struct WhisperModePanel: View {
    @State private var isRecording = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var recordingDuration: TimeInterval = 0
    @State private var waveformAmplitudes: [CGFloat] = Array(repeating: 0.3, count: 20)
    @State private var animationTimer: Timer?
    
    // Recording animation
    @State private var pulseScale: CGFloat = 1.0
    @State private var microphoneRotation: Double = 0
    
    let onStopRecording: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Main content based on state
            Group {
                if let errorMessage = errorMessage {
                    errorStateView(message: errorMessage)
                } else if isProcessing {
                    processingStateView
                } else if isRecording {
                    recordingStateView
                } else {
                    idleStateView
                }
            }
            .frame(height: 120)
            
            // Controls
            controlsView
        }
        .padding(24)
        .background(glassmorphismBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .frame(width: 320)
        .onAppear {
            setupInitialState()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Image(systemName: "waveform")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Whisper Mode")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                // Add hover effect
            }
        }
    }
    
    // MARK: - State Views
    private var idleStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseScale)
            
            Text("Ready to record")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Press Enter to start recording")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
        }
        .onAppear {
            pulseScale = 1.1
        }
    }
    
    private var recordingStateView: some View {
        VStack(spacing: 16) {
            // Animated microphone with pulse effect
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseScale)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(microphoneRotation))
            }
            
            // Waveform visualization
            waveformView
            
            // Recording duration and status
            VStack(spacing: 4) {
                Text("Recording...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(formatDuration(recordingDuration))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .monospacedDigit()
            }
        }
        .onAppear {
            startRecordingAnimation()
        }
    }
    
    private var processingStateView: some View {
        VStack(spacing: 16) {
            // Processing animation
            ZStack {
                Circle()
                    .trim(from: 0.0, to: 0.8)
                    .stroke(Color.blue.opacity(0.8), lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(microphoneRotation))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: microphoneRotation)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text("Processing with AI...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text("Transcribing your voice")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
        }
        .onAppear {
            startProcessingAnimation()
        }
    }
    
    private func errorStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.red.opacity(0.8))
            
            Text("Error")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
    }
    
    // MARK: - Waveform View
    private var waveformView: some View {
        HStack(spacing: 2) {
            ForEach(0..<waveformAmplitudes.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 3, height: max(4, waveformAmplitudes[index] * 30))
                    .animation(.easeInOut(duration: 0.1), value: waveformAmplitudes[index])
            }
        }
        .frame(height: 30)
    }
    
    // MARK: - Controls View
    private var controlsView: some View {
        HStack(spacing: 16) {
            if isRecording {
                // Stop recording button
                Button(action: onStopRecording) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Stop & Process")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.7))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut(.return, modifiers: [])
                
                // Duration indicator
                Text("Press Enter to stop")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            } else if isProcessing {
                // Processing indicator
                Text("Processing...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                // Start recording button
                Button(action: startRecording) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Start Recording")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.7))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut(.return, modifiers: [])
            }
        }
    }
    
    // MARK: - Background
    private var glassmorphismBackground: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Blur effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.8)
            
            // Subtle border
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        }
    }
    
    // MARK: - Animation Methods
    private func setupInitialState() {
        pulseScale = 1.0
        microphoneRotation = 0
    }
    
    private func startRecordingAnimation() {
        pulseScale = 1.2
        
        // Start waveform animation
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateWaveform()
        }
    }
    
    private func startProcessingAnimation() {
        microphoneRotation = 360
        
        // Continue rotation for processing
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            microphoneRotation += 360
        }
    }
    
    private func updateWaveform() {
        for i in 0..<waveformAmplitudes.count {
            waveformAmplitudes[i] = CGFloat.random(in: 0.2...1.0)
        }
    }
    
    private func cleanup() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    // MARK: - Helper Methods
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func startRecording() {
        // This would be handled by the parent controller
        // For now, just update the UI state
        isRecording = true
        isProcessing = false
        errorMessage = nil
        recordingDuration = 0
    }
}

// MARK: - Public State Management
extension WhisperModePanel {
    func updateRecordingState(isRecording: Bool) {
        self.isRecording = isRecording
        if isRecording {
            startRecordingAnimation()
        } else {
            cleanup()
        }
    }
    
    func updateProcessingState(isProcessing: Bool) {
        self.isProcessing = isProcessing
        if isProcessing {
            startProcessingAnimation()
        } else {
            cleanup()
        }
    }
    
    func updateErrorState(message: String?) {
        self.errorMessage = message
        if message != nil {
            cleanup()
        }
    }
    
    func updateRecordingDuration(_ duration: TimeInterval) {
        self.recordingDuration = duration
    }
}

// MARK: - Preview
struct WhisperModePanel_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Idle state
            WhisperModePanel(
                onStopRecording: {},
                onCancel: {}
            )
            .previewDisplayName("Idle State")
            
            // Recording state
            WhisperModePanel(
                onStopRecording: {},
                onCancel: {}
            )
            .onAppear {
                // Simulate recording state
            }
            .previewDisplayName("Recording State")
            
            // Processing state
            WhisperModePanel(
                onStopRecording: {},
                onCancel: {}
            )
            .onAppear {
                // Simulate processing state
            }
            .previewDisplayName("Processing State")
        }
        .frame(width: 400, height: 300)
        .background(Color.gray.opacity(0.3))
    }
} 