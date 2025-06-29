import Foundation
import SwiftUI
import UserNotifications
import AppKit

class ScheduledTaskNotificationService: ObservableObject {
    static let shared = ScheduledTaskNotificationService()
    
    @Published var showingScheduledAlert = false
    @Published var currentScheduledTask: Note?
    
    private var checkTimer: Timer?
    private weak var noteStore: NoteStore?
    
    private init() {
        requestNotificationPermission()
        startPeriodicCheck()
    }
    
    func setNoteStore(_ noteStore: NoteStore) {
        self.noteStore = noteStore
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func startPeriodicCheck() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.checkForScheduledTasks()
        }
    }
    
    private func checkForScheduledTasks() {
        guard let noteStore = noteStore else { return }
        
        let upcomingTasks = noteStore.getUpcomingScheduledNotes(within: 1) // Check for tasks due in 1 minute
        let overdueTasks = noteStore.getOverdueScheduledNotes()
        
        // Handle overdue tasks first
        for task in overdueTasks {
            if !task.hasBeenNotified {
                showTaskAlert(for: task, isOverdue: true)
                markTaskAsNotified(task)
            }
        }
        
        // Handle upcoming tasks
        for task in upcomingTasks {
            if !task.hasBeenNotified {
                showTaskAlert(for: task, isOverdue: false)
                markTaskAsNotified(task)
            }
        }
    }
    
    private func showTaskAlert(for task: Note, isOverdue: Bool) {
        DispatchQueue.main.async {
            self.currentScheduledTask = task
            self.showingScheduledAlert = true
            
            // Also show system notification
            self.sendNotification(for: task, isOverdue: isOverdue)
            
            // Play alert sound
            NSSound.beep()
        }
    }
    
    private func sendNotification(for task: Note, isOverdue: Bool) {
        let content = UNMutableNotificationContent()
        
        if isOverdue {
            content.title = "⚠️ Task Overdue"
            content.body = "'\(task.title)' was scheduled and is now overdue. Please complete it as soon as possible."
        } else {
            let estimatedTimeText = task.estimatedTime ?? "the allocated time"
            content.title = "⏰ Time to Start Task"
            content.body = "It's time to start '\(task.title)'. It's important to complete it within \(estimatedTimeText)."
        }
        
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func markTaskAsNotified(_ task: Note) {
        guard let noteStore = noteStore else { return }
        
        var updatedTask = task
        updatedTask.hasBeenNotified = true
        noteStore.updateNote(updatedTask)
    }
    
    func dismissAlert() {
        showingScheduledAlert = false
        currentScheduledTask = nil
    }
    
    deinit {
        checkTimer?.invalidate()
    }
}

// MARK: - Scheduled Task Alert View
struct ScheduledTaskAlertView: View {
    let task: Note
    let onDismiss: () -> Void
    let onStartTask: () -> Void
    let onSnooze: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: task.priority.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(task.priority.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time to Start Task")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(formatScheduledTime())
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Task Details
            VStack(alignment: .leading, spacing: 12) {
                Text(task.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                HStack {
                    Label("Priority", systemImage: task.priority.iconName)
                        .font(.system(size: 12))
                        .foregroundColor(task.priority.color)
                    
                    Spacer()
                    
                    if let estimatedTime = task.estimatedTime {
                        Label("Est. Time: \(estimatedTime)", systemImage: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Task Image (if available)
            if let imageData = task.imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 120)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                // Snooze Options
                Menu {
                    Button("Snooze 5 minutes") { onSnooze(5) }
                    Button("Snooze 15 minutes") { onSnooze(15) }
                    Button("Snooze 30 minutes") { onSnooze(30) }
                    Button("Snooze 1 hour") { onSnooze(60) }
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Snooze")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#2C2C2E"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Start Task Button
                Button(action: onStartTask) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Task")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#4CAF50"), Color(hex: "#45A049")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#1E1E20"), Color(hex: "#1A1A1C")]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .frame(width: 400)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private func formatScheduledTime() -> String {
        guard let scheduledDate = task.scheduledDate,
              let scheduledTime = task.scheduledTime else {
            return "No scheduled time"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        return "\(dateFormatter.string(from: scheduledDate)) at \(timeFormatter.string(from: scheduledTime))"
    }
} 