import AppKit
import Foundation
import CoreGraphics
import ScreenCaptureKit
import UniformTypeIdentifiers

// MARK: - Screenshot Capture Service
class ScreenshotCaptureService: ObservableObject {
    static let shared = ScreenshotCaptureService()
    
    @Published var isCapturing = false
    @Published var lastScreenshot: NSImage?
    @Published var lastScreenshotData: Data?
    
    private init() {}
    
    // MARK: - Screenshot Capture Methods
    
    /// Capture the entire screen
    func captureFullScreen(completion: @escaping (Result<NSImage, ScreenshotError>) -> Void) {
        isCapturing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let image = try self.captureScreen()
                
                DispatchQueue.main.async {
                    self.isCapturing = false
                    self.lastScreenshot = image
                    self.lastScreenshotData = image.tiffRepresentation
                    completion(.success(image))
                }
            } catch {
                DispatchQueue.main.async {
                    self.isCapturing = false
                    completion(.failure(error as? ScreenshotError ?? .captureFailure))
                }
            }
        }
    }
    
    /// Capture a specific area of the screen (interactive selection)
    func captureScreenArea(completion: @escaping (Result<NSImage, ScreenshotError>) -> Void) {
        isCapturing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let image = try self.captureScreenInteractive()
                
                DispatchQueue.main.async {
                    self.isCapturing = false
                    self.lastScreenshot = image
                    self.lastScreenshotData = image.tiffRepresentation
                    completion(.success(image))
                }
            } catch {
                DispatchQueue.main.async {
                    self.isCapturing = false
                    completion(.failure(error as? ScreenshotError ?? .captureFailure))
                }
            }
        }
    }
    
    /// Capture using the new ScreenCaptureKit (macOS 12.3+)
    @available(macOS 12.3, *)
    func captureUsingScreenCaptureKit(completion: @escaping (Result<NSImage, ScreenshotError>) -> Void) {
        isCapturing = true
        
        Task {
            do {
                let image = try await captureWithScreenCaptureKit()
                
                await MainActor.run {
                    self.isCapturing = false
                    self.lastScreenshot = image
                    self.lastScreenshotData = image.tiffRepresentation
                    completion(.success(image))
                }
            } catch {
                await MainActor.run {
                    self.isCapturing = false
                    completion(.failure(error as? ScreenshotError ?? .captureFailure))
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func captureScreen() throws -> NSImage {
        guard let screen = NSScreen.main else {
            throw ScreenshotError.noScreenFound
        }
        
        let screenRect = screen.frame
        
        // Use command line tool for reliable cross-platform capture
        return try captureUsingCommandLine()
    }
    
    private func captureUsingCommandLine() throws -> NSImage {
        // Use the built-in macOS screenshot utility for reliable capture
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        
        // Create a temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("fullscreen_\(UUID().uuidString).png")
        
        task.arguments = ["-x", tempURL.path] // No sound, capture full screen
        
        do {
            try task.run()
            task.waitUntilExit()
            
            guard let image = NSImage(contentsOf: tempURL) else {
                throw ScreenshotError.captureFailure
            }
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
            
            return image
        } catch {
            throw ScreenshotError.captureFailure
        }
    }
    
    private func captureScreenInteractive() throws -> NSImage {
        // Use the built-in macOS screenshot utility for interactive selection
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        
        // Create a temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("screenshot_\(UUID().uuidString).png")
        
        task.arguments = ["-i", "-x", tempURL.path] // Interactive mode, no sound
        
        do {
            try task.run()
            task.waitUntilExit()
            
            // Check if the file was created (user didn't cancel)
            if FileManager.default.fileExists(atPath: tempURL.path) {
                guard let image = NSImage(contentsOf: tempURL) else {
                    throw ScreenshotError.captureFailure
                }
                
                // Clean up temp file
                try? FileManager.default.removeItem(at: tempURL)
                
                return image
            } else {
                throw ScreenshotError.userCancelled
            }
        } catch {
            throw ScreenshotError.captureFailure
        }
    }
    
    @available(macOS 12.3, *)
    private func captureWithScreenCaptureKit() async throws -> NSImage {
        let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        guard let display = availableContent.displays.first else {
            throw ScreenshotError.noScreenFound
        }
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        let configuration = SCStreamConfiguration()
        configuration.width = Int(display.width)
        configuration.height = Int(display.height)
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.showsCursor = false
        
        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
        
        let cgImage = image
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        
        return nsImage
    }
    
    // MARK: - Utility Methods
    
    /// Save screenshot to clipboard
    func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    /// Save screenshot to file
    func saveToFile(_ image: NSImage, url: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            throw ScreenshotError.saveFailure
        }
        
        let pngData = bitmapRep.representation(using: .png, properties: [:])
        try pngData?.write(to: url)
    }
    
    /// Get screenshot as Data for AI processing
    func getScreenshotData(_ image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmapRep.representation(using: .png, properties: [:])
    }
    
    /// Check if screen recording permission is granted
    func checkScreenRecordingPermission() -> Bool {
        if #available(macOS 10.15, *) {
            let runningApplication = NSRunningApplication.current
            let processIdentifier = runningApplication.processIdentifier
            
            guard let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: AnyObject]] else {
                return false
            }
            
            for window in windows {
                let windowProcessIdentifier = (window[String(kCGWindowOwnerPID)] as? Int) ?? 0
                if windowProcessIdentifier != processIdentifier {
                    let windowBounds = window[String(kCGWindowBounds)] as? [String: Any]
                    if let bounds = windowBounds, bounds.count > 0 {
                        return true
                    }
                }
            }
            return false
        }
        return true
    }
    
    /// Request screen recording permission
    func requestScreenRecordingPermission() {
        // Use ScreenCaptureKit for modern permission request or fallback to command line
        if #available(macOS 12.3, *) {
            // Use ScreenCaptureKit permission request
            Task {
                do {
                    try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                } catch {
                    print("Screen recording permission denied")
                }
            }
        } else {
            // Fallback: trigger permission dialog by attempting a minimal screenshot
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            task.arguments = ["-x", "/dev/null"] // Capture to null device to trigger permission
            try? task.run()
        }
    }
}

// MARK: - Screenshot Errors
enum ScreenshotError: Error, LocalizedError {
    case noScreenFound
    case captureFailure
    case userCancelled
    case saveFailure
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .noScreenFound:
            return "No screen found for capture"
        case .captureFailure:
            return "Failed to capture screenshot"
        case .userCancelled:
            return "Screenshot capture was cancelled"
        case .saveFailure:
            return "Failed to save screenshot"
        case .permissionDenied:
            return "Screen recording permission denied"
        }
    }
}

// MARK: - Screenshot Data Model
struct ScreenshotData {
    let image: NSImage
    let captureDate: Date
    let screenBounds: CGRect
    let devicePixelRatio: CGFloat
    
    var imageData: Data? {
        return ScreenshotCaptureService.shared.getScreenshotData(image)
    }
    
    init(image: NSImage, screenBounds: CGRect = CGRect.zero) {
        self.image = image
        self.captureDate = Date()
        self.screenBounds = screenBounds
        self.devicePixelRatio = NSScreen.main?.backingScaleFactor ?? 1.0
    }
} 