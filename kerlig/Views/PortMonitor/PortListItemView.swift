import SwiftUI

struct PortListItemView: View {
    let port: PortInfo
    let onStop: () -> Void
    let onRestart: () -> Void
    let onOpenInVSCode: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                // Process icon
                ZStack {
                    Circle()
                        .fill(port.processColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: port.processIcon)
                        .font(.system(size: 18))
                        .foregroundColor(port.processColor)
                }
                
                // Port and process info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Port \(port.port)")
                            .font(.system(size: 15, weight: .semibold))
                        
                        // Protocol badge
                        Text(port.protocol.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(port.statusColor.opacity(0.15))
                            .foregroundColor(port.statusColor)
                            .cornerRadius(4)
                        
                        // Status badge
                        Text(port.status.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(port.statusColor.opacity(0.15))
                            .foregroundColor(port.statusColor)
                            .cornerRadius(4)
                    }
                    
                    // Process name and PID
                    HStack(spacing: 4) {
                        Text(port.processName)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                        
                        Text("(\(port.command))")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Text("• PID: \(port.pid)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Text("• User: \(port.user)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Project badge if detected
                if let projectInfo = port.projectInfo {
                    HStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(projectInfo.color.opacity(0.15))
                                .frame(height: 24)
                            
                            HStack(spacing: 4) {
                                Image(systemName: projectInfo.icon)
                                    .font(.system(size: 12))
                                
                                Text(projectInfo.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .foregroundColor(projectInfo.color)
                        }
                    }
                }
                
                // Action buttons
                HStack(spacing: 8) {
                    // Stop button
                    Button(action: onStop) {
                        Image(systemName: "stop.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .help("Stop Process")
                    
                    // Restart button (only for known project types)
                    if let projectInfo = port.projectInfo, projectInfo.type != .unknown {
                        Button(action: onRestart) {
                            Image(systemName: "arrow.clockwise.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .help("Restart Service")
                    }
                    
                    // Open in VS Code button (only for projects with paths)
                    if let projectInfo = port.projectInfo, projectInfo.path != nil {
                        Button(action: onOpenInVSCode) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 16))
                                .foregroundColor(.purple)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .help("Open in VS Code")
                    }
                }
                .padding(.leading, 8)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isHovered ? Color(.systemGray).opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .onHover { hover in
                withAnimation {
                    isHovered = hover
                }
            }
            
            Divider()
        }
    }
} 