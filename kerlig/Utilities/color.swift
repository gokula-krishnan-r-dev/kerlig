import SwiftUI


// Define the custom color extension
extension Color {
    static let customDarkGray = Color(NSColor(red: 32/255, green: 32/255, blue: 32/255, alpha: 1.0))
    static  let customLightGray = Color(NSColor(red: 235/255, green: 222/255, blue: 240/255, alpha: 1.0))
    
    // Gradient colors for dark mode
    static let darkGradientTop = Color(red: 50/255, green: 17/255, blue: 87/255)
    static let darkGradientBottom = Color(red: 28/255, green: 10/255, blue: 50/255)
    
    // Gradient colors for light mode
    static let lightGradientTop = Color(red: 235/255, green: 222/255, blue: 240/255)
    static let lightGradientBottom = Color(red: 203/255, green: 187/255, blue: 220/255)
}

// Helper to get appropriate gradient based on color scheme
struct BackgroundGradient: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
               Color(NSColor.windowBackgroundColor)
            )
    }
}

