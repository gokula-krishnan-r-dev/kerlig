import SwiftUI

struct ProjectDropdownItem {
    let id: String
    let title: String
    let description: String
    let logoImageData: Data?
    let color: Color?
}

struct ProjectDropdown: View {
    @Binding var selectedProject: ProjectDropdownItem?
    let projects: [ProjectDropdownItem]
    let accentColor: Color
    let placeholder: String
    let onSelectionChanged: ((ProjectDropdownItem?) -> Void)?
    
    @State private var isExpanded = false
    @State private var hoverIndex: Int? = nil
    
    init(
        selectedProject: Binding<ProjectDropdownItem?>,
        projects: [ProjectDropdownItem],
        accentColor: Color = .blue,
        placeholder: String = "Select Project",
        onSelectionChanged: ((ProjectDropdownItem?) -> Void)? = nil
    ) {
        self._selectedProject = selectedProject
        self.projects = projects
        self.accentColor = accentColor
        self.placeholder = placeholder
        self.onSelectionChanged = onSelectionChanged
    }
    
    var body: some View {
        VStack(spacing: 0) {
            dropdownButton
            
            if isExpanded {
                dropdownContent
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95, anchor: .top)
                            .combined(with: .opacity)
                            .combined(with: .move(edge: .top)),
                        removal: .scale(scale: 0.95, anchor: .top)
                            .combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
    
    private var dropdownButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 12) {
                projectImageView(for: selectedProject, size: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedProject?.title ?? placeholder)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedProject != nil ? .primary : .secondary)
                    
                    if let description = selectedProject?.description {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(dropdownButtonBackground)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(projects.isEmpty)
    }
    
    private var dropdownButtonBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.04)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(0.08),
                radius: 8,
                x: 0,
                y: 4
            )
    }
    
    private var dropdownContent: some View {
        VStack(spacing: 4) {
            ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                projectRow(project: project, index: index)
            }
        }
        .padding(.vertical, 8)
        .background(dropdownContentBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(
            color: Color.black.opacity(0.15),
            radius: 20,
            x: 0,
            y: 8
        )
        .padding(.top, 4)
    }
    
    private var dropdownContentBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    private func projectRow(project: ProjectDropdownItem, index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedProject = project
                isExpanded = false
            }
            onSelectionChanged?(project)
        }) {
            HStack(spacing: 12) {
                projectImageView(for: project, size: 36)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(project.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(project.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if selectedProject?.id == project.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(accentColor)
                        .scaleEffect(1.1)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        hoverIndex == index ?
                        Color.white.opacity(0.12) :
                        Color.clear
                    )
                    .animation(.easeInOut(duration: 0.2), value: hoverIndex)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoverIndex = isHovering ? index : nil
            }
        }
    }
    
    private func projectImageView(for project: ProjectDropdownItem?, size: CGFloat) -> some View {
        Group {
            if let project = project {
                if let logoData = project.logoImageData, let nsImage = NSImage(data: logoData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.2),
                            radius: 3,
                            x: 0,
                            y: 2
                        )
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    (project.color ?? .blue).opacity(0.9),
                                    (project.color ?? .blue)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)
                        .overlay(
                            Text(String(project.title.prefix(1)).uppercased())
                                .font(.system(size: size * 0.4, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.2),
                            radius: 3,
                            x: 0,
                            y: 2
                        )
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "folder")
                            .font(.system(size: size * 0.4))
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}

// MARK: - Preview
struct ProjectDropdown_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProjectDropdown(
                selectedProject: .constant(nil),
                projects: [
                    ProjectDropdownItem(
                        id: "1",
                        title: "Mac Write App",
                        description: "macOS productivity app",
                        logoImageData: nil,
                        color: .blue
                    ),
                    ProjectDropdownItem(
                        id: "2",
                        title: "Design System",
                        description: "UI component library",
                        logoImageData: nil,
                        color: .purple
                    ),
                    ProjectDropdownItem(
                        id: "3",
                        title: "API Backend",
                        description: "Node.js REST API",
                        logoImageData: nil,
                        color: .green
                    )
                ],
                accentColor: .blue
            )
            .frame(width: 300)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
} 