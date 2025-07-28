import Foundation
import SwiftUI

/// A service that manages task timing and notifications
class TaskTimerNotificationService {
    // MARK: - Singleton
    static let shared = TaskTimerNotificationService()
    
    // MARK: - Properties
    private var taskTimer: Timer?
    private var taskStartTime: Date?
    private var taskDuration: TimeInterval = 0
    private var taskName: String = ""
    
    // Reference to AppState
    @ObservedObject private var appState = (NSApplication.shared.delegate as? AppDelegate)?.appState ?? AppState()
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start a timer for a specific task
    /// - Parameters:
    ///   - taskName: The name of the task being timed
    ///   - duration: The duration of the task in minutes
    func startTaskTimer(taskName: String, durationMinutes: Double) {
        // Stop any existing timer
        stopTaskTimer()
        
        // Set task properties
        self.taskName = taskName
        self.taskDuration = durationMinutes * 60 // Convert to seconds
        self.taskStartTime = Date()
        
        // Schedule timer to fire when task is complete
        taskTimer = Timer.scheduledTimer(withTimeInterval: self.taskDuration, repeats: false) { [weak self] _ in
            self?.taskTimerCompleted()
        }
    }
    
    /// Stop the current task timer
    func stopTaskTimer() {
        taskTimer?.invalidate()
        taskTimer = nil
        taskStartTime = nil
    }
    
    /// Check if a task timer is currently running
    /// - Returns: True if a timer is active, false otherwise
    func isTaskTimerRunning() -> Bool {
        return taskTimer != nil && taskTimer!.isValid
    }
    
    /// Get the remaining time for the current task
    /// - Returns: Remaining time in seconds, or nil if no timer is running
    func getRemainingTime() -> TimeInterval? {
        guard let startTime = taskStartTime, isTaskTimerRunning() else {
            return nil
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let remainingTime = max(0, taskDuration - elapsedTime)
        
        return remainingTime
    }
    
    // MARK: - Private Methods
    
    private func taskTimerCompleted() {
        // Check if notifications are enabled in app settings
        if !appState.taskTimerEnabled || !appState.showTaskCompletionNotification {
            stopTaskTimer()
            return
        }
        
        // Format minutes for the notification message
        let minutes = Int(taskDuration / 60)
        let minutesText = minutes == 1 ? "minute" : "minutes"
        
        // Create notification message
        let message = "\(minutes) \(minutesText) finished for \(taskName) — just a reminder to stay focused and wrap it up soon."
        
        // Play sound and show notification
        TickSoundService.shared.startTicking(interval: 600.0, message: message)
        
        // Stop the timer after notification
        stopTaskTimer()
    }
} 