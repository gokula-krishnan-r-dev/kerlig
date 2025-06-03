import SwiftUI

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