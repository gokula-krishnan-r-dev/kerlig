import SwiftUI

struct TaskTimerDemoView: View {
    @EnvironmentObject var appState: Macwrite.AppState
    @State private var taskName: String = "Current Task"
    @State private var durationMinutes: Double = 10
    @State private var isTimerRunning: Bool = false
    @State private var remainingTime: String = "Not started"
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Task Timer")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Task Name")
                    .font(.headline)
                
                TextField("Enter task name", text: $taskName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                
                Text("Duration (minutes)")
                    .font(.headline)
                
                HStack {
                    Slider(value: $durationMinutes, in: 1...60, step: 1)
                        .disabled(isTimerRunning)
                    
                    Text("\(Int(durationMinutes))")
                        .frame(width: 30)
                }
                
                Text("Remaining Time: \(remainingTime)")
                    .font(.subheadline)
                    .padding(.top, 5)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            
            HStack(spacing: 20) {
                Button(action: startTimer) {
                    Text("Start Timer")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(isTimerRunning)
                
                Button(action: stopTimer) {
                    Text("Stop Timer")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .disabled(!isTimerRunning)
                
                Button(action: testNotification) {
                    Text("Test Notification")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            
            // Settings toggle
            Toggle("Enable task notifications", isOn: $appState.taskTimerEnabled)
                .padding(.top, 20)
                .onChange(of: appState.taskTimerEnabled) { newValue in
                    appState.saveTaskTimerSettings()
                }
        }
        .padding()
        .frame(width: 400, height: 380)
        .onReceive(timer) { _ in
            updateRemainingTime()
        }
        .onAppear {
            // Initialize with app state values
            durationMinutes = appState.defaultTaskDuration
        }
    }
    
    private func startTimer() {
        // Save the current duration as default
        appState.defaultTaskDuration = durationMinutes
        appState.saveTaskTimerSettings()
        
        // Start the timer
        TaskTimerNotificationService.shared.startTaskTimer(taskName: taskName, durationMinutes: durationMinutes)
        isTimerRunning = true
        updateRemainingTime()
    }
    
    private func stopTimer() {
        TaskTimerNotificationService.shared.stopTaskTimer()
        isTimerRunning = false
        remainingTime = "Not started"
    }
    
    private func testNotification() {
        let message = "\(Int(durationMinutes)) minutes finished for \(taskName) — just a reminder to stay focused and wrap it up soon."
        TickSoundService.shared.showNotificationWithMessage(message: message)
    }
    
    private func updateRemainingTime() {
        if let remaining = TaskTimerNotificationService.shared.getRemainingTime() {
            let minutes = Int(remaining) / 60
            let seconds = Int(remaining) % 60
            remainingTime = String(format: "%02d:%02d", minutes, seconds)
            
            // Update timer status
            isTimerRunning = TaskTimerNotificationService.shared.isTaskTimerRunning()
            if !isTimerRunning {
                remainingTime = "Completed"
            }
        } else if isTimerRunning {
            isTimerRunning = false
            remainingTime = "Not running"
        }
    }
}

struct TaskTimerDemoView_Previews: PreviewProvider {
    static var previews: some View {
        TaskTimerDemoView()
            .environmentObject(AppState())
    }
} 
