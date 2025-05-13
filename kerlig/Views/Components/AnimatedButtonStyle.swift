import SwiftUI

// Add this animated button style
struct AnimatedButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var textColor: Color
    var showPulse: Bool = false
    var isFocused: Bool = false
    @State private var isPulsing: Bool = false
    @State private var outerPulse: Bool = false
    
    // Initialize with default values for backward compatibility
    init(backgroundColor: Color = .clear, textColor: Color = .blue, showPulse: Bool = false, isFocused: Bool = false) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.showPulse = showPulse
        self.isFocused = isFocused
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(configuration.isPressed ? (backgroundColor != .clear ? backgroundColor : Color.blue.opacity(0.15)) : backgroundColor)
                    
                    // Focus ring
                    if isFocused {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(textColor.opacity(0.8), lineWidth: 1.5)
                    }
                    
                    // Pulse animation when showPulse is true
                    if showPulse {
                        // Inner pulse
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(textColor.opacity(0.5), lineWidth: 1.5)
                            .scaleEffect(isPulsing ? 1.2 : 1.0)
                            .opacity(isPulsing ? 0.0 : 0.5)
                        
                        // Middle pulse with delay
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(textColor.opacity(0.3), lineWidth: 1)
                            .scaleEffect(isPulsing ? 1.1 : 1.0)
                            .opacity(isPulsing ? 0.0 : 0.3)
                        
                        // Outer pulse with longer delay and different timing
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(textColor.opacity(0.2), lineWidth: 0.5)
                            .scaleEffect(outerPulse ? 1.3 : 1.0)
                            .opacity(outerPulse ? 0.0 : 0.2)
                    }
                }
            )
            .foregroundColor(textColor)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
            .onAppear {
                if showPulse {
                    startPulseAnimation()
                }
            }
            .onChange(of: showPulse) { _, newValue in
                if newValue {
                    startPulseAnimation()
                } else {
                    isPulsing = false
                    outerPulse = false
                }
            }
    }
    
    private func startPulseAnimation() {
        // Start main pulse
        withAnimation(Animation.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
            isPulsing = true
        }
        
        // Start outer pulse with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                outerPulse = true
            }
        }
    }
}