import Foundation
import AVFoundation
import AppKit

class VoiceRecordingService {
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var isRecording = false
    
    private var recordingStartTime: Date?
    private var recordingTimer: Timer?
    private var maxRecordingDuration: TimeInterval = 60.0 // 60 seconds max
    
    // Callbacks
    var onRecordingStarted: (() -> Void)?
    var onRecordingCompleted: ((Data) -> Void)?
    var onRecordingError: ((Error) -> Void)?
    var onRecordingProgress: ((TimeInterval) -> Void)?
    
    private var audioData: Data = Data()
    
    init() {
        setupAudioSession()
    }
    
    deinit {
        cleanupRecording()
    }
    
    // MARK: - Public Methods
    
    func startRecording() {
        guard !isRecording else {
            NSLog("⚠️ Already recording")
            return
        }
        
        NSLog("🎙️ Starting voice recording")
        
        do {
            try setupAudioEngine()
            try audioEngine?.start()
            
            isRecording = true
            recordingStartTime = Date()
            audioData = Data()
            
            // Start progress timer
            startProgressTimer()
            
            onRecordingStarted?()
            
        } catch {
            NSLog("❌ Failed to start recording: \(error)")
            onRecordingError?(error)
        }
    }
    
    func stopRecording() {
        guard isRecording else {
            NSLog("⚠️ Not currently recording")
            return
        }
        
        NSLog("🛑 Stopping voice recording")
        
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        // Process the recorded audio data
        processRecordedAudio()
    }
    
    func getCurrentRecordingDuration() -> TimeInterval {
        guard let startTime = recordingStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        // On macOS, audio session setup is handled differently
        // AVAudioEngine will handle the audio session automatically
        NSLog("✅ Audio session setup (macOS)")
    }
    
    private func setupAudioEngine() throws {
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else {
            throw RecordingError.audioEngineInitializationFailed
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Validate format
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            throw RecordingError.invalidAudioFormat
        }
        
        // Install a tap to capture audio data
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer)
        }
        
        audioEngine.prepare()
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelDataPointer = channelData.pointee
        let frameLength = Int(buffer.frameLength)
        
        // Convert audio buffer to Data
        let audioBuffer = Data(bytes: channelDataPointer, count: frameLength * MemoryLayout<Float>.size)
        audioData.append(audioBuffer)
    }
    
    private func startProgressTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let currentDuration = self.getCurrentRecordingDuration()
            self.onRecordingProgress?(currentDuration)
            
            // Auto-stop if max duration reached
            if currentDuration >= self.maxRecordingDuration {
                self.stopRecording()
            }
        }
    }
    
    private func processRecordedAudio() {
        guard !audioData.isEmpty else {
            NSLog("⚠️ No audio data recorded")
            onRecordingError?(RecordingError.noAudioData)
            return
        }
        
        NSLog("✅ Processing recorded audio data (\(audioData.count) bytes)")
        
        // Convert the raw audio data to a format suitable for Whisper
        convertToWhisperFormat { [weak self] result in
            switch result {
            case .success(let convertedData):
                self?.onRecordingCompleted?(convertedData)
            case .failure(let error):
                self?.onRecordingError?(error)
            }
        }
    }
    
    private func convertToWhisperFormat(completion: @escaping (Result<Data, Error>) -> Void) {
        // For Whisper, we need to convert to a standard format (e.g., WAV)
        // This is a simplified conversion - in production, you might want more sophisticated audio processing
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let convertedData = try self.createWAVData(from: self.audioData)
                DispatchQueue.main.async {
                    completion(.success(convertedData))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func createWAVData(from rawAudioData: Data) throws -> Data {
        // Create a basic WAV header for the audio data
        let sampleRate: UInt32 = 44100
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        
        let dataSize = UInt32(rawAudioData.count)
        let fileSize = dataSize + 36
        
        var wavData = Data()
        
        // RIFF header
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: fileSize.littleEndian) { Data($0) })
        wavData.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // chunk size
        wavData.append(withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // audio format (PCM)
        wavData.append(withUnsafeBytes(of: channels.littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        
        let byteRate = sampleRate * UInt32(channels) * UInt32(bitsPerSample) / 8
        wavData.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        
        let blockAlign = channels * bitsPerSample / 8
        wavData.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        
        // data chunk
        wavData.append("data".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })
        wavData.append(rawAudioData)
        
        return wavData
    }
    
    private func cleanupRecording() {
        if isRecording {
            stopRecording()
        }
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioEngine = nil
        audioFile = nil
    }
}

// MARK: - Error Types
extension VoiceRecordingService {
    enum RecordingError: LocalizedError {
        case audioEngineInitializationFailed
        case invalidAudioFormat
        case noAudioData
        case conversionFailed
        
        var errorDescription: String? {
            switch self {
            case .audioEngineInitializationFailed:
                return "Failed to initialize audio engine"
            case .invalidAudioFormat:
                return "Invalid audio format"
            case .noAudioData:
                return "No audio data was recorded"
            case .conversionFailed:
                return "Failed to convert audio data"
            }
        }
    }
} 