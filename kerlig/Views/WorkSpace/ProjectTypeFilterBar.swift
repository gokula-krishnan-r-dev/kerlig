import SwiftUI

struct ProjectTypeFilterBar: View {
    @Binding var activeFilter: ProjectType?
    let onOrganizationTapped: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All projects filter
                FilterButton(title: "All", isSelected: activeFilter == nil) {
                    activeFilter = nil
                }
                
                // Main project type filters
                FilterButton(
                    title: "React", 
                    iconName: ProjectType.react.iconName,
                    color: ProjectType.react.color,
                    isSelected: activeFilter == .react
                ) {
                    activeFilter = .react
                }
                
                FilterButton(
                    title: "Next.js", 
                    iconName: ProjectType.nextjs.iconName,
                    color: ProjectType.nextjs.color,
                    isSelected: activeFilter == .nextjs
                ) {
                    activeFilter = .nextjs
                }
                
                FilterButton(
                    title: "Swift", 
                    iconName: ProjectType.swift.iconName,
                    color: ProjectType.swift.color,
                    isSelected: activeFilter == .swift
                ) {
                    activeFilter = .swift
                }
                
                FilterButton(
                    title: "Python", 
                    iconName: ProjectType.python.iconName,
                    color: ProjectType.python.color,
                    isSelected: activeFilter == .python
                ) {
                    activeFilter = .python
                }
                
                FilterButton(
                    title: "Node", 
                    iconName: ProjectType.node.iconName,
                    color: ProjectType.node.color,
                    isSelected: activeFilter == .node
                ) {
                    activeFilter = .node
                }
                
                // Separator
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 20)
                    .padding(.horizontal, 4)
                
                // Organization button
                OrganizationFilterButton(action: onOrganizationTapped)
            }
            .padding(.horizontal, 4)
        }
    }
}

struct FilterButton: View {
    let title: String
    var iconName: String? = nil
    var color: Color = .accentColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = iconName {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundColor(isSelected ? color : .primary)
            .background(isSelected ? color.opacity(0.1) : Color.clear)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OrganizationFilterButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "building.2")
                    .font(.system(size: 12))
                
                Text("Organization")
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .help("Create an organization from selected workspaces")
    }
} 
