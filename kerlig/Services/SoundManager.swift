import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let soundNames = ["notification", "complete", "break", "skip"]
    
    private init() {
        prepareAudioPlayers()
    }
    
    private func prepareAudioPlayers() {
        // In a real implementation, these would be actual sound files in the bundle
        // For now, we'll use system sounds as placeholders
        
        // Create a simple beep sound for testing
        let soundIDs: [String: SystemSoundID] = [
            "notification": 1000, // Default system sound
            "complete": 1001,     // Another system sound
            "break": 1002,        // Another system sound
            "skip": 1003          // Another system sound
        ]
        
        for (name, soundID) in soundIDs {
            // Create a URL for the system sound
            if let soundURL = createSystemSoundURL(for: soundID) {
                do {
                    let player = try AVAudioPlayer(contentsOf: soundURL)
                    player.prepareToPlay()
                    audioPlayers[name] = player
                } catch {
                    print("Could not create audio player for \(name): \(error)")
                }
            }
        }
    }
    
    private func createSystemSoundURL(for soundID: SystemSoundID) -> URL? {
        // This is a placeholder - in a real app, you would have actual sound files
        // For now, we'll use a temporary file with a simple tone
        let fileName = "temp_sound_\(soundID).wav"
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        // Check if we already created this file
        if FileManager.default.fileExists(atPath: tempURL.path) {
            return tempURL
        }
        
        // Create a simple tone file (this is just a placeholder)
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        do {
            let audioFile = try AVAudioFile(forWriting: tempURL, settings: settings)
            let format = AVAudioFormat(settings: settings)!
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(44100 * 0.5))! // 0.5 second tone
            
            // Fill buffer with a simple sine wave
            for frame in 0..<buffer.frameLength {
                let sampleVal = sin(2.0 * .pi * Float(frame) * 440.0 / 44100.0) * 0.5
                buffer.floatChannelData?[0][Int(frame)] = sampleVal
                buffer.floatChannelData?[1][Int(frame)] = sampleVal
            }
            
            buffer.frameLength = AVAudioFrameCount(44100 * 0.5)
            try audioFile.write(from: buffer)
            
            return tempURL
        } catch {
            print("Could not create temporary sound file: \(error)")
            return nil
        }
    }
    
    func playSound(_ name: String) {
        guard let player = audioPlayers[name] else {
            print("No sound player found for \(name)")
            return
        }
        
        // Reset and play
        player.currentTime = 0
        player.play()
    }
} 