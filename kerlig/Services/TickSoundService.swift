import Foundation
import AVFoundation

/// A service that plays a tick sound at regular intervals
class TickSoundService {
    // MARK: - Singleton
    static let shared = TickSoundService()
    
    // MARK: - Properties
    private var tickPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var isPlaying = false
    private let soundFileName = "tick.wav"
    private var soundFilePath: URL?
    
    // MARK: - Initialization
    private init() {
        // Load the tick sound from the bundle
        loadSoundFile()
        prepareAudioPlayer()
    }
    
    // MARK: - Public Methods
    
    /// Start playing tick sounds at the specified interval
    /// - Parameter interval: Time interval between ticks in seconds (default: 3.0)
    func startTicking(interval: TimeInterval = 3.0) {
        guard !isPlaying else { return }
        print("Starting tick sound")
        
        // Stop any existing timer
        stopTicking()
        
        // Play sound immediately
        playTickSound()
        print("Playing tick sound")
        
        // Schedule timer for repeated playback
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.playTickSound()
        }
        
        isPlaying = true
    }
    
    /// Stop playing tick sounds
    func stopTicking() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
    }
    
    /// Check if the service is currently playing tick sounds
    /// - Returns: True if ticking, false otherwise
    func isTicking() -> Bool {
        return isPlaying
    }
    
    /// Play the tick sound once for testing purposes
    func playTestSound() {
        print("Playing test tick sound")
        playTickSound()
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
    
    /// Copy the tick.wav file from the project directory to the app's Documents directory
    /// This can be useful if the file is not being properly bundled with the app
    func copyTickSoundToDocuments() -> Bool {
        let fileManager = FileManager.default
        
        // Source path in project
        let sourcePath = URL(fileURLWithPath: "/Users/gokul/Documents/swiftui/kerlig/kerlig/Resources/Sounds/tick.wav")
        
        // Get the documents directory
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access documents directory")
            return false
        }
        
        // Destination path in Documents
        let destinationPath = documentsDirectory.appendingPathComponent(soundFileName)
        
        // Check if source file exists
        guard fileManager.fileExists(atPath: sourcePath.path) else {
            print("Source tick.wav file does not exist at: \(sourcePath.path)")
            return false
        }
        
        // Remove existing file if it exists
        if fileManager.fileExists(atPath: destinationPath.path) {
            do {
                try fileManager.removeItem(at: destinationPath)
            } catch {
                print("Could not remove existing tick.wav file: \(error)")
                return false
            }
        }
        
        // Copy the file
        do {
            try fileManager.copyItem(at: sourcePath, to: destinationPath)
            print("Successfully copied tick.wav to Documents directory: \(destinationPath.path)")
            
            // Update the sound file path
            self.soundFilePath = destinationPath
            prepareAudioPlayer()
            
            return true
        } catch {
            print("Failed to copy tick.wav file: \(error)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func playTickSound() {
        // Reset to beginning and play
        tickPlayer?.currentTime = 0
        tickPlayer?.play()
    }
    
    private func prepareAudioPlayer() {
        guard let soundPath = soundFilePath else {
            print("Error: Could not find tick sound file")
            return
        }
        
        do {
            tickPlayer = try AVAudioPlayer(contentsOf: soundPath)
            tickPlayer?.prepareToPlay()
            tickPlayer?.volume = 0.5 // Set default volume
        } catch {
            print("Error initializing tick sound player: \(error)")
        }
    }
    
    private func loadSoundFile() {
        // Try multiple possible locations for the sound file
        
        // 1. Try direct path in bundle Resources/Sounds directory
        if let bundlePath = Bundle.main.url(forResource: "tick", withExtension: "wav", subdirectory: "Resources/Sounds") {
            self.soundFilePath = bundlePath
            print("Found tick.wav in bundle at: \(bundlePath)")
            return
        }
        
        // 2. Try without subdirectory (in case it's at the root of the bundle)
        if let bundlePath = Bundle.main.url(forResource: "tick", withExtension: "wav") {
            self.soundFilePath = bundlePath
            print("Found tick.wav at bundle root: \(bundlePath)")
            return
        }
        
        // 3. Try with just Sounds subdirectory
        if let bundlePath = Bundle.main.url(forResource: "tick", withExtension: "wav", subdirectory: "Sounds") {
            self.soundFilePath = bundlePath
            print("Found tick.wav in Sounds directory: \(bundlePath)")
            return
        }
        
        // 4. Try in the Documents directory
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let documentsPath = documentsDirectory.appendingPathComponent(soundFileName)
            if FileManager.default.fileExists(atPath: documentsPath.path) {
                self.soundFilePath = documentsPath
                print("Found tick.wav in Documents directory: \(documentsPath)")
                return
            }
        }
        
        // 5. Try to access the file directly from the project directory
        let projectPath = URL(fileURLWithPath: Bundle.main.bundlePath)
            .deletingLastPathComponent()
            .appendingPathComponent("kerlig/Resources/Sounds/tick.wav")
        
        if FileManager.default.fileExists(atPath: projectPath.path) {
            self.soundFilePath = projectPath
            print("Found tick.wav in project directory: \(projectPath)")
            return
        }
        
        // 6. Check if the file exists at the absolute path from the file system
        let absolutePath = URL(fileURLWithPath: "/Users/gokul/Documents/swiftui/kerlig/kerlig/Resources/Sounds/tick.wav")
        if FileManager.default.fileExists(atPath: absolutePath.path) {
            self.soundFilePath = absolutePath
            print("Found tick.wav at absolute path: \(absolutePath)")
            return
        }
        
        // If still not found, create a fallback sound
        print("Could not find tick.wav in any location, creating fallback sound")
        self.soundFilePath = createFallbackTickSound()
    }
    
    private func createFallbackTickSound() -> URL? {
        // Create a temporary file for the tick sound
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(soundFileName)
        
        // Check if we already created this file
        if FileManager.default.fileExists(atPath: tempURL.path) {
            return tempURL
        }
        
        // Create a simple tick sound file
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
            // Create a short tick sound (0.1 seconds)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(44100 * 0.1))!
            
            // Generate a simple tick sound waveform
            for frame in 0..<buffer.frameLength {
                let progress = Float(frame) / Float(buffer.frameLength)
                // Create a quick attack and decay envelope
                let envelope = progress < 0.1 ? progress * 10 : (1.0 - progress) * 1.1
                // Higher frequency for a tick sound (1800Hz)
                let sampleVal = sin(2.0 * .pi * Float(frame) * 1800.0 / 44100.0) * envelope
                buffer.floatChannelData?[0][Int(frame)] = sampleVal
            }
            
            buffer.frameLength = AVAudioFrameCount(44100 * 0.1)
            try audioFile.write(from: buffer)
            
            return tempURL
        } catch {
            print("Could not create tick sound file: \(error)")
            return nil
        }
    }
    
    // MARK: - Deinitializer
    deinit {
        stopTicking()
    }
} 
