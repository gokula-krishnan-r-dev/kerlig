import Foundation
import AVFoundation

/// A service that plays notification sounds at regular intervals
class TickSoundService {
    // MARK: - Singleton
    static let shared = TickSoundService()
    
    // MARK: - Properties
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var isPlaying = false
    private let soundFileName = "notification"
    private let soundFileExtension = "mp3"
    private var soundFilePath: URL?
    
    // MARK: - Initialization
    private init() {
        loadSoundFile()
        prepareAudioPlayer()
    }
    
    // MARK: - Public Methods
    
    /// Start playing notification sounds at the specified interval
    /// - Parameter interval: Time interval between notifications in seconds (default: 3.0)
    func startTicking(interval: TimeInterval = 3.0) {
        guard !isPlaying else { return }
        
        // Stop any existing timer
        stopTicking()
        
        // Play sound immediately
        playSound()
        
        // Schedule timer for repeated playback
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.playSound()
        }
        
        isPlaying = true
    }
    
    /// Stop playing notification sounds
    func stopTicking() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
    }
    
    /// Check if the service is currently playing notification sounds
    /// - Returns: True if playing, false otherwise
    func isTicking() -> Bool {
        return isPlaying
    }
    
    /// Play the notification sound once for testing purposes
    func playTestSound() {
        playSound()
    }
    
    /// Debug function to check the status of the sound file
    func debugSoundFileStatus() -> String {
        if let path = soundFilePath {
            let exists = FileManager.default.fileExists(atPath: path.path)
            return "Sound file path: \(path)\nExists: \(exists ? "Yes" : "No")"
        } else {
            return "No sound file path set"
        }
    }
    
    /// Copy the notification sound file from the bundle to the app's Documents directory
    /// This can be useful if the file is not being properly bundled with the app
    func copyTickSoundToDocuments() -> Bool {
        let fileManager = FileManager.default
        
        // Get the bundle resource path
        guard let sourcePath = Bundle.main.url(forResource: soundFileName, withExtension: soundFileExtension, subdirectory: "Resources/Sounds") else {
            print("Could not locate \(soundFileName).\(soundFileExtension) in bundle")
            return false
        }
        
        // Get the documents directory
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access documents directory")
            return false
        }
        
        // Destination path in Documents
        let destinationPath = documentsDirectory.appendingPathComponent("\(soundFileName).\(soundFileExtension)")
        
        // Remove existing file if it exists
        if fileManager.fileExists(atPath: destinationPath.path) {
            do {
                try fileManager.removeItem(at: destinationPath)
            } catch {
                print("Could not remove existing sound file: \(error)")
                return false
            }
        }
        
        // Copy the file
        do {
            try fileManager.copyItem(at: sourcePath, to: destinationPath)
            print("Successfully copied \(soundFileName).\(soundFileExtension) to Documents directory: \(destinationPath.path)")
            
            // Update the sound file path
            self.soundFilePath = destinationPath
            prepareAudioPlayer()
            
            return true
        } catch {
            print("Failed to copy sound file: \(error)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func playSound() {
        // Reset to beginning and play
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
    
    private func prepareAudioPlayer() {
        guard let soundPath = soundFilePath else {
            print("Error: Could not find sound file")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundPath)
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 0.5 // Set default volume
        } catch {
            print("Error initializing audio player: \(error)")
        }
    }
    
    private func loadSoundFile() {
        // Try multiple possible locations for the sound file
        
        // 1. Try direct path in bundle Resources/Sounds directory
        if let bundlePath = Bundle.main.url(forResource: soundFileName, withExtension: soundFileExtension, subdirectory: "Resources/Sounds") {
            self.soundFilePath = bundlePath
            print("Found \(soundFileName).\(soundFileExtension) in bundle at: \(bundlePath)")
            return
        }
        
        // 2. Try without subdirectory (in case it's at the root of the bundle)
        if let bundlePath = Bundle.main.url(forResource: soundFileName, withExtension: soundFileExtension) {
            self.soundFilePath = bundlePath
            print("Found \(soundFileName).\(soundFileExtension) at bundle root: \(bundlePath)")
            return
        }
        
        // 3. Try with just Sounds subdirectory
        if let bundlePath = Bundle.main.url(forResource: soundFileName, withExtension: soundFileExtension, subdirectory: "Sounds") {
            self.soundFilePath = bundlePath
            print("Found \(soundFileName).\(soundFileExtension) in Sounds directory: \(bundlePath)")
            return
        }
        
        // 4. Try in the Documents directory
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let documentsPath = documentsDirectory.appendingPathComponent("\(soundFileName).\(soundFileExtension)")
            if FileManager.default.fileExists(atPath: documentsPath.path) {
                self.soundFilePath = documentsPath
                print("Found \(soundFileName).\(soundFileExtension) in Documents directory: \(documentsPath)")
                return
            }
        }
        
        // If still not found, create a fallback sound
        print("Could not find \(soundFileName).\(soundFileExtension) in any location, creating fallback sound")
        self.soundFilePath = createFallbackSound()
    }
    
    private func createFallbackSound() -> URL? {
        // Create a temporary file for the sound
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(soundFileName).\(soundFileExtension)")
        
        // Check if we already created this file
        if FileManager.default.fileExists(atPath: tempURL.path) {
            return tempURL
        }
        
        // Create a simple notification sound file
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        do {
            let audioFile = try AVAudioFile(forWriting: tempURL, settings: settings)
            let format = AVAudioFormat(settings: settings)!
            // Create a short notification sound (0.3 seconds)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(44100 * 0.3))!
            
            // Generate a simple notification sound waveform
            for frame in 0..<buffer.frameLength {
                let progress = Float(frame) / Float(buffer.frameLength)
                // Create a quick attack and decay envelope
                let envelope = progress < 0.1 ? progress * 10 : (1.0 - progress) * 1.1
                // Higher frequency for a notification sound (2200Hz)
                let sampleVal = sin(2.0 * .pi * Float(frame) * 2200.0 / 44100.0) * envelope
                buffer.floatChannelData?[0][Int(frame)] = sampleVal
            }
            
            buffer.frameLength = AVAudioFrameCount(44100 * 0.3)
            try audioFile.write(from: buffer)
            
            return tempURL
        } catch {
            print("Could not create fallback sound file: \(error)")
            return nil
        }
    }
    
    // MARK: - Deinitializer
    deinit {
        stopTicking()
    }
} 
