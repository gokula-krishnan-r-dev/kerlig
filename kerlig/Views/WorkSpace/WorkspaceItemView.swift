import SwiftUI

struct WorkspaceItemView: View {
    let workspace: WorkspaceInfo
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Project type icon
            ZStack {
                Circle()
                    .fill(workspace.projectType.color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: workspace.projectType.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(workspace.projectType.color)
            }
            .padding(.trailing, 4)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(workspace.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    // Framework/language badge
                    Text(workspace.projectType.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(workspace.projectType.color.opacity(0.1))
                        .foregroundColor(workspace.projectType.color)
                        .cornerRadius(4)
                }
                
                Text(workspace.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            // Right side info
            VStack(alignment: .trailing, spacing: 2) {
                if let lastOpened = workspace.lastOpened {
                    Text(timeAgo(from: lastOpened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Tags view if available
                if !workspace.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(workspace.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(3)
                        }
                        
                        if workspace.tags.count > 2 {
                            Text("+\(workspace.tags.count - 2)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Favorite star if marked as favorite
            if workspace.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 14))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
    }
    
    // Format the time ago string
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month], from: date, to: now)
        
        if let month = components.month, month > 0 {
            return month == 1 ? "1 month ago" : "\(month) months ago"
        } else if let week = components.weekOfYear, week > 0 {
            return week == 1 ? "1 week ago" : "\(week) weeks ago"
        } else if let day = components.day, day > 0 {
            return day == 1 ? "Yesterday" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else {
            return "Just now"
        }
    }
} 