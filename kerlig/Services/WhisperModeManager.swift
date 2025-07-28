import Foundation
import AppKit
import AVFoundation

class WhisperModeManager {
    static let shared = WhisperModeManager()
    
    private var voiceRecordingService: VoiceRecordingService?
    private var whisperAIService: WhisperAIService?
    private var panelController: WhisperModePanelController?
    private var hotkeyManager: HotkeyManager?
    
    private var isRecording = false
    private var isProcessing = false
    
    private init() {
        setupServices()
    }
    
    private func setupServices() {
        voiceRecordingService = VoiceRecordingService()
        whisperAIService = WhisperAIService()
        panelController = WhisperModePanelController()
        
        // Set up voice recording callbacks
        voiceRecordingService?.onRecordingStarted = { [weak self] in
            self?.handleRecordingStarted()
        }
        
        voiceRecordingService?.onRecordingCompleted = { [weak self] audioData in
            self?.handleRecordingCompleted(audioData: audioData)
        }
        
        voiceRecordingService?.onRecordingError = { [weak self] error in
            self?.handleRecordingError(error: error)
        }
    }
    
    // MARK: - Public Methods
    
    func registerHotkey(with hotkeyManager: HotkeyManager) {
        self.hotkeyManager = hotkeyManager
        NSLog("🎙️ WhisperModeManager registered with HotkeyManager")
    }
    
    func activateWhisperMode() {
        guard !isRecording && !isProcessing else { return }
        
        NSLog("🎙️ Activating Whisper Mode")
        
        // Check for microphone permission
        checkMicrophonePermission { [weak self] granted in
            if granted {
                self?.showPanelAndStartRecording()
            } else {
                self?.showMicrophonePermissionDialog()
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        NSLog("🛑 Stopping voice recording")
        voiceRecordingService?.stopRecording()
        isRecording = false
        
        // Update panel to show processing state
        panelController?.showProcessingState()
    }
    
    // MARK: - Private Methods
    
    private func showPanelAndStartRecording() {
        DispatchQueue.main.async { [weak self] in
            // Show the floating panel
            self?.panelController?.showPanel { [weak self] in
                // Start recording once panel is visible
                self?.startRecording()
            }
        }
    }
    
    private func startRecording() {
        guard !isRecording else { return }
        
        NSLog("▶️ Starting voice recording")
        isRecording = true
        
        voiceRecordingService?.startRecording()
        panelController?.showRecordingState()
    }
    
    private func handleRecordingStarted() {
        DispatchQueue.main.async { [weak self] in
            NSLog("✅ Recording started successfully")
            self?.panelController?.updateRecordingAnimation(isRecording: true)
        }
    }
    
    private func handleRecordingCompleted(audioData: Data) {
        DispatchQueue.main.async { [weak self] in
            NSLog("✅ Recording completed, processing with Whisper AI")
            self?.isRecording = false
            self?.isProcessing = true
            
            self?.panelController?.showProcessingState()
            self?.processWithWhisperAI(audioData: audioData)
        }
    }
    
    private func handleRecordingError(error: Error) {
        DispatchQueue.main.async { [weak self] in
            NSLog("❌ Recording error: \(error.localizedDescription)")
            self?.isRecording = false
            self?.isProcessing = false
            
            self?.panelController?.showError(message: "Recording failed: \(error.localizedDescription)")
            
            // Auto-close panel after showing error
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self?.panelController?.hidePanel()
            }
        }
    }
    
    private func processWithWhisperAI(audioData: Data) {
        whisperAIService?.transcribeAudio(audioData: audioData) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                switch result {
                case .success(let transcription):
                    self?.handleTranscriptionSuccess(transcription: transcription)
                case .failure(let error):
                    self?.handleTranscriptionError(error: error)
                }
            }
        }
    }
    
    private func handleTranscriptionSuccess(transcription: String) {
        NSLog("✅ Transcription successful: \(transcription)")
        
        // Hide the panel first
        panelController?.hidePanel()
        
        // Try to paste to active input field or show toast
        if let hotkeyManager = hotkeyManager {
            if pasteToActiveInputField(text: transcription, hotkeyManager: hotkeyManager) {
                NSLog("✅ Text pasted to active input field")
            } else {
                showToastMessage("Message copied. You can paste it anywhere you want.")
                copyToClipboard(text: transcription)
            }
        } else {
            showToastMessage("Message copied. You can paste it anywhere you want.")
            copyToClipboard(text: transcription)
        }
    }
    
    private func handleTranscriptionError(error: Error) {
        NSLog("❌ Transcription error: \(error.localizedDescription)")
        
        panelController?.showError(message: "Transcription failed: \(error.localizedDescription)")
        
        // Auto-close panel after showing error
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.panelController?.hidePanel()
        }
    }
    
    private func pasteToActiveInputField(text: String, hotkeyManager: HotkeyManager) -> Bool {
        // Try to paste using the hotkey manager's paste functionality
        return hotkeyManager.pasteText(text)
    }
    
    private func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func showToastMessage(_ message: String) {
        ToastNotificationView.show(message: message)
    }
    
    // MARK: - Permission Handling
    
    private func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        // On macOS, check microphone permission using AVCaptureDevice
        let authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch authStatus {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    private func showMicrophonePermissionDialog() {
        let alert = NSAlert()
        alert.messageText = "Microphone Access Required"
        alert.informativeText = "Whisper Mode needs microphone access to record your voice. Please grant permission in System Settings."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let settingsUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(settingsUrl)
            }
        }
    }
}

// MARK: - Panel Delegate Methods
extension WhisperModeManager {
    func panelDidRequestStopRecording() {
        stopRecording()
    }
    
    func panelDidRequestCancel() {
        if isRecording {
            voiceRecordingService?.stopRecording()
            isRecording = false
        }
        isProcessing = false
        panelController?.hidePanel()
    }
} 