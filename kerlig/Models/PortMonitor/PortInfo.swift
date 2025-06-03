import Foundation
import SwiftUI

// Model to represent a port and its associated process
struct PortInfo: Identifiable, Equatable {
    let id = UUID()
    let port: Int
    let pid: Int
    let processName: String
    let command: String
    let user: String
    let `protocol`: PortProtocol
    let status: PortStatus
    let projectInfo: ProjectInfo?
    
    // Enum for port protocols
    enum PortProtocol: String {
        case tcp = "TCP"
        case udp = "UDP"
        case unknown = "Unknown"
    }
    
    // Enum for port status
    enum PortStatus: String {
        case listening = "LISTEN"
        case established = "ESTABLISHED"
        case other = "OTHER"
    }
    
    // Display color based on protocol and status
    var statusColor: Color {
        switch status {
        case .listening: return .green
        case .established: return .blue
        case .other: return .gray
        }
    }
    
    // Process icon based on name
    var processIcon: String {
        switch processName.lowercased() {
        case _ where processName.lowercased().contains("node"):
            return "n.square.fill"
        case _ where processName.lowercased().contains("python"):
            return "p.square.fill"
        case _ where processName.lowercased().contains("ruby"):
            return "r.square.fill"
        case _ where processName.lowercased().contains("java"):
            return "j.square.fill"
        case _ where processName.lowercased().contains("nginx"):
            return "n.square.fill"
        case _ where processName.lowercased().contains("apache"):
            return "a.square.fill"
        case _ where processName.lowercased().contains("docker"):
            return "d.square.fill"
        case _ where processName.lowercased().contains("postgres"):
            return "server.rack"
        case _ where processName.lowercased().contains("mysql"):
            return "server.rack"
        default:
            return "circle.fill"
        }
    }
    
    // Process color based on name
    var processColor: Color {
        switch processName.lowercased() {
        case _ where processName.lowercased().contains("node"):
            return .green
        case _ where processName.lowercased().contains("python"):
            return .blue
        case _ where processName.lowercased().contains("ruby"):
            return .red
        case _ where processName.lowercased().contains("java"):
            return .orange
        case _ where processName.lowercased().contains("nginx"):
            return .green
        case _ where processName.lowercased().contains("apache"):
            return .red
        case _ where processName.lowercased().contains("docker"):
            return .blue
        case _ where processName.lowercased().contains("postgres"):
            return .blue
        case _ where processName.lowercased().contains("mysql"):
            return .orange
        default:
            return .gray
        }
    }
    
    // Format the port number with protocol
    var portDisplay: String {
        return "\(port) (\(self.protocol.rawValue))"
    }
    
    // Equatable implementation
    static func == (lhs: PortInfo, rhs: PortInfo) -> Bool {
        return lhs.port == rhs.port && lhs.pid == rhs.pid
    }
}

// Model to represent project information detected from a port
struct ProjectInfo {
    let name: String
    let type: ProjectType
    let path: String?
    
    // Get icon and color from project type
    var icon: String {
        return type.iconName
    }
    
    var color: Color {
        return type.color
    }
} 
