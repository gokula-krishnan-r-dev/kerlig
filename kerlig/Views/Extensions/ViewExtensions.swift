import SwiftUI
import AppKit

// Extension to enable double-click functionality
extension View {
    func onDoubleClick(perform action: @escaping () -> Void) -> some View {
        self.gesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    action()
                }
        )
    }
}

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
    
    func hoverEffect(_ effect: HoverEffect = .highlight) -> some View {
        modifier(HoverEffectModifier(effect: effect))
    }
}

// MARK: - Hover Effect
enum HoverEffect {
    case highlight
    case lift
    case scale
    case glow
}

struct HoverEffectModifier: ViewModifier {
    let effect: HoverEffect
    @State private var isHovering = false
    
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            .opacity(isHovering ? (effect == .highlight ? 0.8 : 1.0) : 1.0)
            .scaleEffect(isHovering && (effect == .scale || effect == .lift) ? 1.05 : 1.0)
            .shadow(
                color: isHovering && (effect == .glow || effect == .lift) ? 
                    Color.white.opacity(0.2) : Color.clear,
                radius: 5
            )
    }
}

// MARK: - Rounded Corner Shape
enum RectCorner {
    case topLeft, topRight, bottomLeft, bottomRight, allCorners
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = corners == .topLeft || corners == .allCorners
        let topRight = corners == .topRight || corners == .allCorners
        let bottomLeft = corners == .bottomLeft || corners == .allCorners
        let bottomRight = corners == .bottomRight || corners == .allCorners
        
        let width = rect.width
        let height = rect.height
        
        // Ensure radius doesn't exceed half the shorter side
        let safeTLRadius = min(min(radius, width/2), height/2)
        
        // Top left corner
        if topLeft {
            path.move(to: CGPoint(x: safeTLRadius, y: 0))
        } else {
            path.move(to: CGPoint(x: 0, y: 0))
        }
        
        // Top right corner
        if topRight {
            path.addLine(to: CGPoint(x: width - safeTLRadius, y: 0))
            path.addArc(center: CGPoint(x: width - safeTLRadius, y: safeTLRadius),
                        radius: safeTLRadius,
                        startAngle: Angle(degrees: -90),
                        endAngle: Angle(degrees: 0),
                        clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: width, y: 0))
        }
        
        // Bottom right corner
        if bottomRight {
            path.addLine(to: CGPoint(x: width, y: height - safeTLRadius))
            path.addArc(center: CGPoint(x: width - safeTLRadius, y: height - safeTLRadius),
                        radius: safeTLRadius,
                        startAngle: Angle(degrees: 0),
                        endAngle: Angle(degrees: 90),
                        clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: width, y: height))
        }
        
        // Bottom left corner
        if bottomLeft {
            path.addLine(to: CGPoint(x: safeTLRadius, y: height))
            path.addArc(center: CGPoint(x: safeTLRadius, y: height - safeTLRadius),
                        radius: safeTLRadius,
                        startAngle: Angle(degrees: 90),
                        endAngle: Angle(degrees: 180),
                        clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: 0, y: height))
        }
        
        // Top left corner (closing the path)
        if topLeft {
            path.addLine(to: CGPoint(x: 0, y: safeTLRadius))
            path.addArc(center: CGPoint(x: safeTLRadius, y: safeTLRadius),
                        radius: safeTLRadius,
                        startAngle: Angle(degrees: 180),
                        endAngle: Angle(degrees: 270),
                        clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: 0, y: 0))
        }
        
        return path
    }
} 
