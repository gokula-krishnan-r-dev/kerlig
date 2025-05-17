import SwiftUI


// Define the custom color extension
extension Color {
    static let customDarkGray = Color(NSColor(red: 32/255, green: 32/255, blue: 32/255, alpha: 1.0))
    static let customLightGray = Color(NSColor(red: 235/255, green: 222/255, blue: 240/255, alpha: 1.0))
    
    // Gradient colors for dark mode
    static let darkGradientTop = Color(red: 50/255, green: 17/255, blue: 87/255)
    static let darkGradientBottom = Color(red: 28/255, green: 10/255, blue: 50/255)
    
    // Gradient colors for light mode
    static let lightGradientTop = Color(red: 235/255, green: 222/255, blue: 240/255)
    static let lightGradientBottom = Color(red: 203/255, green: 187/255, blue: 220/255)
    
    // Glass background colors
    static let glassBackground = Color.white.opacity(0.15)
    static let glassBorder = Color.white.opacity(0.3)
}

// Helper to get appropriate gradient based on color scheme
struct BackgroundGradient: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.glassBorder, lineWidth: 0.5)
                    )
            )
    }
}

// Extension to make it easy to apply the gradient
extension View {

    
    // Glass effect for card-like elements
    func glassCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

