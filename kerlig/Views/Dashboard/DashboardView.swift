import SwiftUI

struct DashboardView: View {
    @State private var showTaskTimerDemo = false
    
    var body: some View {
 VStack(spacing: 20) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Dashboard")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Dashboard functionality - Coming Soon!")
                .foregroundColor(.secondary)
            
            Button(action: {
                showTaskTimerDemo = true
            }) {
                HStack {
                    Image(systemName: "timer")
                    Text("Task Timer Demo")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
        .sheet(isPresented: $showTaskTimerDemo) {
            TaskTimerDemoView()
        }
    }
}