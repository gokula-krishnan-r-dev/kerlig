import SwiftUI

struct InlineOrganizationCreator: View {
    let selectedWorkspaces: [WorkspaceInfo]
    let onCreateOrganization: (Organization) -> Void
    let onCancel: () -> Void
    
    @State private var organizationName: String = ""
    @State private var organizationId: String = ""
    @State private var description: String = ""
    @State private var isExpanded: Bool = false
    @State private var showAdvancedOptions: Bool = false
    
    @FocusState private var isNameFieldFocused: Bool
    
    // Validation
    private var isNameValid: Bool {
        !organizationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isIdValid: Bool {
        organizationId.isEmpty || (organizationId.contains(".") && organizationId.split(separator: ".").count >= 2)
    }
    
    private var isFormValid: Bool {
        isNameValid && isIdValid && selectedWorkspaces.count >= 2
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with create button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2")
                            .foregroundColor(.purple)
                        
                        Text("Create Organization")
                            .font(.headline)
                            .foregroundColor(.purple)
                    }
                    
                    Text("\(selectedWorkspaces.count) workspaces selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    
                    Button(isExpanded ? "Create" : "Next") {
                        if isExpanded {
                            createOrganization()
                        } else {
                            withAnimation(.spring(response: 0.5)) {
                                isExpanded = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isNameFieldFocused = true
                                }
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isExpanded && !isFormValid)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.purple.opacity(0.1))
            
            // Quick preview of selected workspaces (always visible)
            if !isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedWorkspaces.prefix(4), id: \.id) { workspace in
                            CompactWorkspaceCard(workspace: workspace)
                        }
                        
                        if selectedWorkspaces.count > 4 {
                            Text("+\(selectedWorkspaces.count - 4) more")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                .background(Color(.controlBackgroundColor).opacity(0.5))
            }
            
            // Expanded form with scroll view
            if isExpanded {
                ScrollView {
                    VStack(spacing: 16) {
                        // Organization name field
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Organization Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            
                            TextField("Enter organization name", text: $organizationName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($isNameFieldFocused)
                                .onSubmit {
                                    if isFormValid {
                                        createOrganization()
                                    }
                                }
                            
                            if !organizationName.isEmpty && !isNameValid {
                                Text("Organization name is required")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Advanced options toggle
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAdvancedOptions.toggle()
                            }
                        }) {
                            HStack {
                                Text("Advanced Options")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Image(systemName: showAdvancedOptions ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Advanced options
                        if showAdvancedOptions {
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Organization ID")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    TextField("com.company.app (optional)", text: $organizationId)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    if !organizationId.isEmpty && !isIdValid {
                                        Text("Should follow bundle format (e.g., com.company.app)")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    } else {
                                        Text("Optional: Bundle-style identifier")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Description")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    TextField("Optional description", text: $description, axis: .vertical)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .lineLimit(2...4)
                                }
                            }
                        }
                        
                        // Selected workspaces list
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Selected Workspaces")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            // Scroll view for workspaces if there are many
                            if selectedWorkspaces.count > 5 {
                                ScrollView {
                                    LazyVStack(spacing: 6) {
                                        ForEach(selectedWorkspaces, id: \.id) { workspace in
                                            ExpandedWorkspaceCard(workspace: workspace)
                                        }
                                    }
                                }
                                .frame(maxHeight: 200)
                                .background(Color(.controlBackgroundColor).opacity(0.3))
                                .cornerRadius(8)
                            } else {
                                LazyVStack(spacing: 6) {
                                    ForEach(selectedWorkspaces, id: \.id) { workspace in
                                        ExpandedWorkspaceCard(workspace: workspace)
                                    }
                                }
                            }
                        }
                        
                        // Quick actions
                        HStack(spacing: 12) {
                            Button(action: {
                                // Quick fill with suggested name
                                organizationName = generateSuggestedName()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "wand.and.rays")
                                        .font(.system(size: 12))
                                    Text("Auto-name")
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button(action: {
                                // Generate organization ID from name
                                if !organizationName.isEmpty {
                                    organizationId = generateOrganizationId(from: organizationName)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                        .font(.system(size: 12))
                                    Text("Generate ID")
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(organizationName.isEmpty)
                            
                            Spacer()
                            
                            Text("⌘↩ to create")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .frame(maxHeight: 250)
                .background(Color(.controlBackgroundColor).opacity(0.3))
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onKeyPress(.return) {
            if isFormValid {
                createOrganization()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.escape) {
            onCancel()
            return .handled
        }
    }
    
    private func createOrganization() {
        guard isFormValid else { return }
        
        let workspaceIds = selectedWorkspaces.map { $0.id }
        let trimmedName = organizationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedId = organizationId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let organization = Organization(
            name: trimmedName,
            organizationId: trimmedId.isEmpty ? nil : trimmedId,
            workspaceIds: workspaceIds,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription
        )
        
        onCreateOrganization(organization)
    }
    
    private func generateSuggestedName() -> String {
        let projectTypes = Array(Set(selectedWorkspaces.map { $0.projectType.displayName }))
        if projectTypes.count == 1 {
            return "\(projectTypes.first!) Projects"
        } else {
            return "Mixed Projects Organization"
        }
    }
    
    private func generateOrganizationId(from name: String) -> String {
        let cleanName = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
        
        return "com.organization.\(cleanName)"
    }
}

// Compact workspace card for quick preview
struct CompactWorkspaceCard: View {
    let workspace: WorkspaceInfo
    
    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(workspace.projectType.color.opacity(0.2))
                    .frame(width: 20, height: 20)
                
                Image(systemName: workspace.projectType.iconName)
                    .font(.system(size: 10))
                    .foregroundColor(workspace.projectType.color)
            }
            
            Text(workspace.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
    }
}

// Expanded workspace card for detailed view
struct ExpandedWorkspaceCard: View {
    let workspace: WorkspaceInfo
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(workspace.projectType.color.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                Image(systemName: workspace.projectType.iconName)
                    .font(.system(size: 12))
                    .foregroundColor(workspace.projectType.color)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(workspace.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(workspace.path.components(separatedBy: "/").last ?? workspace.path)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(workspace.projectType.displayName)
                .font(.system(size: 9, weight: .medium))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(workspace.projectType.color.opacity(0.1))
                .foregroundColor(workspace.projectType.color)
                .cornerRadius(3)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
    }
}

#Preview {
    InlineOrganizationCreator(
        selectedWorkspaces: [
            WorkspaceInfo(name: "React App", path: "/path/to/react", lastOpened: Date(), projectType: .react),
            WorkspaceInfo(name: "Swift Project", path: "/path/to/swift", lastOpened: Date(), projectType: .swift),
            WorkspaceInfo(name: "Python API", path: "/path/to/python", lastOpened: Date(), projectType: .python)
        ],
        onCreateOrganization: { _ in },
        onCancel: {}
    )
    .padding()
} 