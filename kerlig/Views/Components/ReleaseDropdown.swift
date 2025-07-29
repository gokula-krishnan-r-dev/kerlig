import SwiftUI

struct ReleaseDropdownItem {
    let id: String
    let version: String
    let name: String
    let status: DropdownReleaseStatus
}

struct DropdownReleaseStatus {
    let iconName: String
    let color: Color
    
    static let inProgress = DropdownReleaseStatus(iconName: "clock", color: .orange)
    static let completed = DropdownReleaseStatus(iconName: "checkmark.circle.fill", color: .green)
    static let planned = DropdownReleaseStatus(iconName: "calendar", color: .blue)
    static let onHold = DropdownReleaseStatus(iconName: "pause.circle", color: .red)
}

struct ReleaseDropdown: View {
    @Binding var selectedRelease: ReleaseDropdownItem?
    let releases: [ReleaseDropdownItem]
    let accentColor: Color
    let placeholder: String
    let onSelectionChanged: ((ReleaseDropdownItem?) -> Void)?
    
    @State private var isExpanded = false
    @State private var hoverIndex: Int? = nil
    
    init(
        selectedRelease: Binding<ReleaseDropdownItem?>,
        releases: [ReleaseDropdownItem],
        accentColor: Color = .blue,
        placeholder: String = "Select Release",
        onSelectionChanged: ((ReleaseDropdownItem?) -> Void)? = nil
    ) {
        self._selectedRelease = selectedRelease
        self.releases = releases
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
                releaseIconView(for: selectedRelease)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let release = selectedRelease {
                        Text("v\(release.version)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(release.name)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(placeholder)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
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
        .disabled(releases.isEmpty)
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
            ForEach(Array(releases.enumerated()), id: \.element.id) { index, release in
                releaseRow(release: release, index: index)
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
    
    private func releaseRow(release: ReleaseDropdownItem, index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedRelease = release
                isExpanded = false
            }
            onSelectionChanged?(release)
        }) {
            HStack(spacing: 12) {
                // Status icon with enhanced styling
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                release.status.color.opacity(0.2),
                                release.status.color.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: release.status.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(release.status.color)
                    )
                    .overlay(
                        Circle()
                            .stroke(release.status.color.opacity(0.3), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("v\(release.version)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(release.name)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if selectedRelease?.id == release.id {
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
    
    private func releaseIconView(for release: ReleaseDropdownItem?) -> some View {
        Group {
            if let release = release {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                release.status.color.opacity(0.3),
                                release.status.color.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: release.status.iconName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(release.status.color)
                    )
                    .overlay(
                        Circle()
                            .stroke(release.status.color.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(
                        color: release.status.color.opacity(0.3),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "tag")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}

// MARK: - Preview
struct ReleaseDropdown_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ReleaseDropdown(
                selectedRelease: .constant(nil),
                releases: [
                    ReleaseDropdownItem(
                        id: "1",
                        version: "2.1.0",
                        name: "Performance Update",
                        status: DropdownReleaseStatus.inProgress
                    ),
                    ReleaseDropdownItem(
                        id: "2",
                        version: "2.0.0",
                        name: "Major Release",
                        status: DropdownReleaseStatus.completed
                    ),
                    ReleaseDropdownItem(
                        id: "3",
                        version: "2.2.0",
                        name: "Feature Expansion",
                        status: DropdownReleaseStatus.planned
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
