import SwiftUI

struct FocusCardView: View {
    @State private var timeRemaining: TimeInterval = 25 * 60 // 25 minutes in seconds
    @State private var timer: Timer?
    @State private var isRunning = false
    let controller: FocusCardController
    
    var body: some View {
        HStack(spacing: 16) {
            // Timer display
            Text(timeString(from: timeRemaining))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
                .frame(width: 100)
            
            // Controls
            HStack(spacing: 12) {
                Button(action: toggleTimer) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
                
                Button(action: resetTimer) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Button(action: { controller.hideFocusCard() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1C1C1E"))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
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
        isRunning.toggle()
    }
    
    private func resetTimer() {
        timeRemaining = 25 * 60
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

