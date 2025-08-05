import SwiftUI
import AppKit

// MARK: - App Color System
extension Color {
    
    // MARK: - Primary Brand Colors
    static let kerligPrimary = Color("KerligPrimary", bundle: nil) ?? Color(nsColor: .controlAccentColor)
    static let kerligSecondary = Color("KerligSecondary", bundle: nil) ?? Color.accentColor
    
    // MARK: - Background Colors (Dynamic)
    static let kerligBackground = Color(nsColor: .windowBackgroundColor)
    static let kerligSecondaryBackground = Color(nsColor: .controlBackgroundColor)
    static let kerligTertiaryBackground = Color(nsColor: .underPageBackgroundColor)
    
    // MARK: - Surface Colors
    static let kerligSurface = Color(nsColor: .controlBackgroundColor)
    static let kerligSurfaceElevated = Color(nsColor: .windowBackgroundColor)
    
    // MARK: - Text Colors (Dynamic)
    static let kerligPrimaryText = Color(nsColor: .labelColor)
    static let kerligSecondaryText = Color(nsColor: .secondaryLabelColor)
    static let kerligTertiaryText = Color(nsColor: .tertiaryLabelColor)
    static let kerligPlaceholderText = Color(nsColor: .placeholderTextColor)
    
    // MARK: - Accent Colors
    static let kerligAccent = Color(nsColor: .controlAccentColor)
    static let kerligAccentSecondary = Color(nsColor: .controlAccentColor).opacity(0.8)
    
    // MARK: - Button Colors
    static let kerligButtonBackground = Color(nsColor: .controlAccentColor)
    static let kerligButtonBackgroundPressed = Color(nsColor: .controlAccentColor).opacity(0.8)
    static let kerligButtonText = Color.white
    
    // MARK: - Semantic Colors
    static let kerligSuccess = Color.green
    static let kerligWarning = Color.orange
    static let kerligError = Color.red
    static let kerligInfo = Color.blue
    
    // MARK: - Border Colors
    static let kerligBorder = Color(nsColor: .separatorColor)
    static let kerligBorderSecondary = Color(nsColor: .gridColor)
    
    // MARK: - Shadow Colors
    static let kerligShadow = Color.black.opacity(0.1)
    static let kerligShadowElevated = Color.black.opacity(0.2)
    
    // MARK: - Custom Brand Gradients
    static let kerligGradientPrimary = LinearGradient(
        gradient: Gradient(colors: [
            Color(nsColor: .controlAccentColor),
            Color(nsColor: .controlAccentColor).opacity(0.8)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let kerligGradientBackground = LinearGradient(
        gradient: Gradient(colors: [
            Color(nsColor: .windowBackgroundColor),
            Color(nsColor: .controlBackgroundColor)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
//    // MARK: - Hex Color Initializer (Enhanced)
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: // RGB (12-bit)
//            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//        case 6: // RGB (24-bit)
//            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//        case 8: // ARGB (32-bit)
//            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//        default:
//            (a, r, g, b) = (1, 1, 1, 0)
//        }
//
//        self.init(
//            .sRGB,
//            red: Double(r) / 255,
//            green: Double(g) / 255,
//            blue: Double(b) / 255,
//            opacity: Double(a) / 255
//        )
//    }
//    
    // MARK: - Dynamic Color Helper
    static func dynamicColor(light: Color, dark: Color) -> Color {
        return Color(NSColor.controlAccentColor)
    }
}

// MARK: - Button Styles
struct KerligButtonStyle: ButtonStyle {
    var variant: ButtonVariant = .primary
    var size: ButtonSize = .medium
    
    enum ButtonVariant {
        case primary, secondary, tertiary
    }
    
    enum ButtonSize {
        case small, medium, large
        
        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .medium:
                return EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
            case .large:
                return EdgeInsets(top: 14, leading: 28, bottom: 14, trailing: 28)
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 14
            case .large: return 16
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size.fontSize, weight: .semibold))
            .foregroundColor(foregroundColor)
            .padding(size.padding)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return .kerligButtonText
        case .secondary:
            return .kerligAccent
        case .tertiary:
            return .kerligPrimaryText
        }
    }
    
    private func backgroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            return isPressed ? .kerligButtonBackgroundPressed : .kerligButtonBackground
        case .secondary:
            return isPressed ? .kerligAccent.opacity(0.1) : .kerligAccent.opacity(0.05)
        case .tertiary:
            return isPressed ? .kerligTertiaryBackground : .clear
        }
    }
}

// MARK: - Card Style
struct KerligCardStyle: ViewModifier {
    var elevation: CardElevation = .medium
    
    enum CardElevation {
        case none, low, medium, high
        
        var shadowRadius: CGFloat {
            switch self {
            case .none: return 0
            case .low: return 2
            case .medium: return 8
            case .high: return 16
            }
        }
        
        var shadowOpacity: Double {
            switch self {
            case .none: return 0
            case .low: return 0.05
            case .medium: return 0.1
            case .high: return 0.2
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background(Color.kerligSurface)
            .cornerRadius(16)
            .shadow(
                color: .kerligShadow.opacity(elevation.shadowOpacity),
                radius: elevation.shadowRadius,
                x: 0,
                y: elevation.shadowRadius / 2
            )
    }
}

extension View {
    func kerligCard(elevation: KerligCardStyle.CardElevation = .medium) -> some View {
        self.modifier(KerligCardStyle(elevation: elevation))
    }
    
    func kerligButton(variant: KerligButtonStyle.ButtonVariant = .primary, size: KerligButtonStyle.ButtonSize = .medium) -> some View {
        self.buttonStyle(KerligButtonStyle(variant: variant, size: size))
    }
}

