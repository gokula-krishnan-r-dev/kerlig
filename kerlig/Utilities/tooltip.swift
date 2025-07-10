import SwiftUI

struct Tooltip<TooltipContent: View>: ViewModifier {
    let content: TooltipContent
    @State private var isVisible = false
    let cornerRadius: CGFloat
    let backgroundColor: Color
    let textColor: Color
    let arrowPosition: ArrowPosition
    let dismissAfter: Double?
    let maxWidth: CGFloat
    let animation: Animation
    let trigger: TriggerMode
    let padding: EdgeInsets
    
    enum ArrowPosition {
        case top, bottom, none
    }
    
    enum TriggerMode {
        case hover, tap, both
    }
    
    init(
        content: TooltipContent,
        cornerRadius: CGFloat = 8,
        backgroundColor: Color? = nil,
        textColor: Color? = nil,
        arrowPosition: ArrowPosition = .top,
        dismissAfter: Double? = nil,
        maxWidth: CGFloat = 200,
        animation: Animation = .spring(response: 0.3, dampingFraction: 0.7),
        trigger: TriggerMode = .hover,
        padding: EdgeInsets = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
    ) {
        self.content = content
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor ?? Color(.sRGB, white: 0.1, opacity: 0.75)
        self.textColor = textColor ?? .white
        self.arrowPosition = arrowPosition
        self.dismissAfter = dismissAfter
        self.maxWidth = maxWidth
        self.animation = animation
        self.trigger = trigger
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
                .onHover { hovering in
                    if trigger == .hover || trigger == .both {
                        withAnimation(animation) {
                            self.isVisible = hovering
                        }
                        
                        handleAutoDismiss(hovering)
                    }
                }
                .onTapGesture {
                    if trigger == .tap || trigger == .both {
                        withAnimation(animation) {
                            self.isVisible.toggle()
                        }
                        
                        if self.isVisible {
                            handleAutoDismiss(true)
                        }
                    }
                }
            
            if isVisible {
                GeometryReader { geometry in
                    tooltipView()
                        .position(
                            x: geometry.size.width / 2,
                            y: arrowPosition == .top ? 
                                geometry.size.height + 15 : 
                                -15
                        )
                }
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)).animation(animation),
                        removal: .opacity.animation(.easeOut(duration: 0.2))
                    )
                )
            }
        }
    }
    
    private func handleAutoDismiss(_ active: Bool) {
        // Auto-dismiss if specified
        if active, let dismissAfter = dismissAfter {
            DispatchQueue.main.asyncAfter(deadline: .now() + dismissAfter) {
                if self.isVisible {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.isVisible = false
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func tooltipView() -> some View {
        VStack(spacing: 0) {
            if arrowPosition == .top {
                tooltipArrow()
                    .fill(backgroundColor)
                    .frame(width: 12, height: 6)
                    .zIndex(1)
                    .offset(y: 1)
            }
            
            tooltipContent()
            
            if arrowPosition == .bottom {
                tooltipArrow(pointingUp: false)
                    .fill(backgroundColor)
                    .frame(width: 12, height: 6)
                    .zIndex(1)
                    .offset(y: -1)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func tooltipContent() -> some View {
        self.content
            .foregroundColor(textColor)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: maxWidth)
            .padding(padding)
            .background(
                ZStack {
                    // True glass effect with blur
                    if #available(macOS 12.0, *) {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(backgroundColor.opacity(0.5))
                            )
                    } else {
                        // Fallback for older macOS versions
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(backgroundColor)
                    }
                    
                    // Border overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                }
            )
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
    
    private func tooltipArrow(pointingUp: Bool = true) -> some Shape {
        Arrow(pointingUp: pointingUp)
    }
}

struct Arrow: Shape {
    let pointingUp: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if pointingUp {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        } else {
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.closeSubpath()
        }
        
        return path
    }
}

// Extension to make it easy to apply the tooltip with text content
extension View {
    func tooltip(
        _ content: String,
        cornerRadius: CGFloat = 8,
        backgroundColor: Color? = nil,
        textColor: Color? = nil,
        arrowPosition: Tooltip<Text>.ArrowPosition = .top,
        dismissAfter: Double? = nil,
        maxWidth: CGFloat = 200,
        animation: Animation = .spring(response: 0.3, dampingFraction: 0.7),
        trigger: Tooltip<Text>.TriggerMode = .hover
    ) -> some View {
        self.modifier(
            Tooltip(
                content: Text(content)
                    .font(.system(size: 12, weight: .medium)),
                cornerRadius: cornerRadius,
                backgroundColor: backgroundColor,
                textColor: textColor,
                arrowPosition: arrowPosition,
                dismissAfter: dismissAfter,
                maxWidth: maxWidth,
                animation: animation,
                trigger: trigger
            )
        )
    }
    
    // Overload for custom content
    func tooltipView<Content: View>(
        @ViewBuilder content: @escaping () -> Content,
        cornerRadius: CGFloat = 8,
        backgroundColor: Color? = nil,
        textColor: Color? = nil,
        arrowPosition: Tooltip<Content>.ArrowPosition = .top,
        dismissAfter: Double? = nil,
        maxWidth: CGFloat = 200,
        animation: Animation = .spring(response: 0.3, dampingFraction: 0.7),
        trigger: Tooltip<Content>.TriggerMode = .hover,
        padding: EdgeInsets = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
    ) -> some View {
        self.modifier(
            Tooltip(
                content: content(),
                cornerRadius: cornerRadius,
                backgroundColor: backgroundColor,
                textColor: textColor,
                arrowPosition: arrowPosition,
                dismissAfter: dismissAfter,
                maxWidth: maxWidth,
                animation: animation,
                trigger: trigger,
                padding: padding
            )
        )
    }
}

