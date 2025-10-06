import SwiftUI

struct DashboardView: View {
    @State private var currentTime = Date()
    @State private var timeTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Header Section
                headerSection
                
                
                
                // Quick Actions
                quickActionsSection
                
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(NSColor.controlBackgroundColor),
                    Color(NSColor.controlBackgroundColor).opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onReceive(timeTimer) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(greetingText)")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currentTime, style: .time)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(currentTime, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                // MacWrite Button
                Button(action: showMacWrite) {
                    ActionCard(
                        title: "Mac Write",
                        subtitle: "Start writing and capture tasks",
                        icon: "pencil.circle.fill",
                        color: .green,
                        isProminent: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
            }
        }
    }
    
    
    
    // MARK: - Helper Properties
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Night"
        }
    }
    
    
    // MARK: - Helper Functions
    private func showMacWrite() {
        // Close any existing windows first
        if let existingWindow = NSApp.windows.first(where: { $0.isVisible }) {
            existingWindow.close()
        }
    }
}

// MARK: - Supporting Views

struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isProminent: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isProminent ? .white : color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isProminent ? .white : .primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(isProminent ? .white.opacity(0.8) : .secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "arrow.right.circle.fill")
                .font(.title3)
                .foregroundColor(isProminent ? .white.opacity(0.8) : color.opacity(0.7))
        }
        .padding(16)
        .background(
            isProminent ? 
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [color.opacity(0.1), color.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isProminent ? Color.clear : color.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isProminent ? 1.02 : 1.0)
        .shadow(color: isProminent ? color.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
    }
}

