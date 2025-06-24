import SwiftUI

struct FocusCardView: View {
    @State private var timeRemaining: TimeInterval = 0 // Start with 0 minutes
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var isHovered = false
    let controller: FocusCardController
    
    var body: some View {
        VStack(spacing: 0) {
            // Main timer row
            HStack(spacing: 12) {
                // Task indicator and time
                HStack(spacing: 8) {
                    Circle()
                        .fill(isRunning ? Color.green : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: isRunning)
                    
                    Text(timeString(from: timeRemaining))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                
                // Estimated time input when not running
                if !isRunning {
                    TextField("EST", text: Binding(
                        get: { String(Int(timeRemaining) / 60) },
                        set: { newValue in
                            if let minutes = Int(newValue) {
                                timeRemaining = TimeInterval(minutes * 60)
                            }
                        }
                    ))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(width: 40)
                    .textFieldStyle(PlainTextFieldStyle())
                }
                
                Spacer()
                
                // Play/Pause button always visible
                Button(action: toggleTimer) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isRunning ? .white : .green)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            // Action buttons row (visible on hover)
            if isHovered {
                Divider()
                    .background(Color.gray.opacity(0.2))
                
                HStack(spacing: 12) {
                    // Copy button
                    ActionButton(
                        icon: "doc.on.doc",
                        action: { /* Copy action */ }
                    )
                    
                    // Link button
                    ActionButton(
                        icon: "link",
                        action: { /* Link action */ }
                    )
                    
                    // Back button
                    ActionButton(
                        icon: "arrow.left",
                        action: { /* Back action */ }
                    )
                    
                    // Forward button
                    ActionButton(
                        icon: "arrow.right",
                        action: { /* Forward action */ }
                    )
                    
                    Spacer()
                    
                    // Close button
                    ActionButton(
                        icon: "xmark",
                        action: { controller.hideFocusCard() }
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "#1C1C1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func toggleTimer() {
        if isRunning {
            timer?.invalidate()
            timer = nil
        } else {
            if timeRemaining == 0 {
                // Default to 25 minutes if no time is set
                timeRemaining = 25 * 60
            }
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                    timer = nil
                    isRunning = false
                }
            }
        }
        withAnimation {
            isRunning.toggle()
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// Helper view for action buttons
struct ActionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}

