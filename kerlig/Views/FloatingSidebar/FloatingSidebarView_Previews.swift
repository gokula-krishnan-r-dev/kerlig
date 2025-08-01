import SwiftUI

#Preview("Sidebar Layout") {
    VStack{
        Text("FloatingSidebar Layout")
            .font(.title2)
            .fontWeight(.bold)
    }
    FloatingSidebarView(controller: FloatingSidebarController(), onClose: {})
    .environmentObject(AppState())
    .frame(width: 400, height: 900, alignment: .center)
}
