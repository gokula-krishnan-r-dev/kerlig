import SwiftUI

// MARK: - Pattern Background
struct PatternBackground: View {
    var phase: CGFloat
    var scale: CGFloat
    
    var body: some View {
        ZStack {
            // First pattern layer
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let spacing: CGFloat = 60 * scale
                    
                    for x in stride(from: 0, through: width, by: spacing) {
                        for y in stride(from: 0, through: height, by: spacing) {
                            let offsetX = sin(phase * .pi + y/50) * 15
                            path.addEllipse(in: CGRect(x: x + offsetX, y: y, width: 4, height: 4))
                        }
                    }
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            
            // Second pattern layer
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let spacing: CGFloat = 80 * scale
                    
                    for x in stride(from: 0, through: width, by: spacing) {
                        for y in stride(from: 0, through: height, by: spacing) {
                            let offsetX = cos(phase * .pi + x/50) * 20
                            path.addEllipse(in: CGRect(x: x, y: y + offsetX, width: 3, height: 3))
                        }
                    }
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.6)]),
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
            }
        }
    }
}