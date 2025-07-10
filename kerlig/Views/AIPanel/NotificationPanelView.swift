import SwiftUI

struct NotificationPanelView: View {
    let message: String
    
    @State private var gradientRotation: Double = 0
    @State private var isVisible: Bool = false
    
    var body: some View {
        VStack {
            Text(message)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Blurred background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.6))
                    .blur(radius: 0.5)
                
                // Animated gradient border
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.purple,
                                Color.pink,
                                Color.orange,
                                Color.yellow,
                                Color.green,
                                Color.blue
                            ]),
                            center: .center,
                            angle: .degrees(gradientRotation)
                        ),
                        lineWidth: 2
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0)
        .onAppear {
            // Start animations when view appears
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
            
            // Start rotating gradient
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                gradientRotation = 360
            }
        }
    }
}

// Preview provider
struct NotificationPanelView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPanelView(message: "10 minutes finished for this task — just a reminder to stay focused and wrap it up soon.")
            .frame(width: 600, height: 80)
            .background(Color.gray.opacity(0.3))
    }
} 