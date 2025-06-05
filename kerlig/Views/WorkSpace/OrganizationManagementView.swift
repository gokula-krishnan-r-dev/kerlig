import SwiftUI

struct OrganizationManagementView: View {
    @ObservedObject var organizationService: OrganizationService
    let allWorkspaces: [WorkspaceInfo]
    let onDismiss: () -> Void
    let onOpenWorkspace: (WorkspaceInfo) -> Void
    
    @State private var searchText = ""
    @State private var selectedOrganization: Organization?
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var organizationToDelete: Organization?
    
    private var filteredOrganizations: [Organization] {
        if searchText.isEmpty {
            return organizationService.organizations
        }
        
        let lowercased = searchText.lowercased()
        return organizationService.organizations.filter { org in
            org.name.lowercased().contains(lowercased) ||
            (org.organizationId?.lowercased().contains(lowercased) ?? false) ||
            (org.description?.lowercased().contains(lowercased) ?? false)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Organizations")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(organizationService.organizations.count) organizations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Done") {
                    onDismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search organizations...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.textBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Organizations list with proper constraints
            if filteredOrganizations.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: organizationService.organizations.isEmpty ? "building.2" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text(organizationService.organizations.isEmpty ? "No Organizations" : "No Results")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if organizationService.organizations.isEmpty {
                        Text("Create your first organization by selecting workspaces")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredOrganizations, id: \.id) { organization in
                            OrganizationCard(
                                organization: organization,
                                workspaces: organizationService.getWorkspaces(for: organization, from: allWorkspaces),
                                isSelected: selectedOrganization?.id == organization.id,
                                onTap: {
                                    selectedOrganization = organization
                                },
                                onEdit: {
                                    selectedOrganization = organization
                                    showingEditSheet = true
                                },
                                onDelete: {
                                    organizationToDelete = organization
                                    showingDeleteAlert = true
                                },
                                onOpenWorkspace: onOpenWorkspace
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
                .clipped()
            }
        }
        .frame(width: 500, height: 600)
        .background(Color(.windowBackgroundColor))
        .sheet(isPresented: $showingEditSheet) {
            if let org = selectedOrganization {
                EditOrganizationSheet(
                    organization: org,
                    isPresented: $showingEditSheet,
                    onUpdate: { updatedOrg in
                        organizationService.updateOrganization(updatedOrg)
                    }
                )
            }
        }
        .alert("Delete Organization", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let org = organizationToDelete {
                    organizationService.removeOrganization(org)
                }
            }
        } message: {
            if let org = organizationToDelete {
                Text("Are you sure you want to delete '\(org.name)'? This action cannot be undone.")
            }
        }
    }
}

struct OrganizationCard: View {
    let organization: Organization
    let workspaces: [WorkspaceInfo]
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onOpenWorkspace: (WorkspaceInfo) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                // Organization icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "building.2")
                        .font(.system(size: 18))
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(organization.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text("\(workspaces.count) workspaces")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let orgId = organization.organizationId {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(orgId)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation(.spring(response: 0.4)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Menu {
                        Button("Edit", action: onEdit)
                        Divider()
                        Button("Delete", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.controlBackgroundColor).opacity(isSelected ? 0.8 : 0.3))
            .onTapGesture {
                onTap()
                withAnimation(.spring(response: 0.4)) {
                    isExpanded.toggle()
                }
            }
            
            // Expanded content with scroll view for workspaces
            if isExpanded {
                VStack(spacing: 8) {
                    if let description = organization.description, !description.isEmpty {
                        HStack {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Workspaces with scrolling if many
                    if workspaces.count > 6 {
                        VStack(alignment: .leading, spacing: 4) {
                            ScrollView {
                                LazyVStack(spacing: 4) {
                                    ForEach(workspaces, id: \.id) { workspace in
                                        OrganizationWorkspaceRow(
                                            workspace: workspace,
                                            onOpen: { onOpenWorkspace(workspace) }
                                        )
                                    }
                                }
                            }
                            .frame(maxHeight: 150)
                            .background(Color(.windowBackgroundColor).opacity(0.3))
                            .cornerRadius(6)
                        }
                        .padding(.horizontal, 16)
                    } else {
                        LazyVStack(spacing: 4) {
                            ForEach(workspaces, id: \.id) { workspace in
                                OrganizationWorkspaceRow(
                                    workspace: workspace,
                                    onOpen: { onOpenWorkspace(workspace) }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Organization metadata
                    HStack {
                        Text("Created \(organization.createdDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if organization.lastModified != organization.createdDate {
                            Text("Modified \(organization.lastModified, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .background(Color(.windowBackgroundColor).opacity(0.5))
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct OrganizationWorkspaceRow: View {
    let workspace: WorkspaceInfo
    let onOpen: () -> Void
    
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
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(workspace.path.components(separatedBy: "/").suffix(2).joined(separator: "/"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(workspace.projectType.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(workspace.projectType.color.opacity(0.1))
                    .foregroundColor(workspace.projectType.color)
                    .cornerRadius(3)
                
                Button(action: onOpen) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
        .onTapGesture {
            onOpen()
        }
    }
}

// Edit organization sheet
struct EditOrganizationSheet: View {
    @State var organization: Organization
    @Binding var isPresented: Bool
    let onUpdate: (Organization) -> Void
    
    @State private var name: String
    @State private var organizationId: String
    @State private var description: String
    
    init(organization: Organization, isPresented: Binding<Bool>, onUpdate: @escaping (Organization) -> Void) {
        self.organization = organization
        self._isPresented = isPresented
        self.onUpdate = onUpdate
        self._name = State(initialValue: organization.name)
        self._organizationId = State(initialValue: organization.organizationId ?? "")
        self._description = State(initialValue: organization.description ?? "")
    }
    
    private var isValidForm: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (organizationId.isEmpty || (organizationId.contains(".") && organizationId.split(separator: ".").count >= 2))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Edit Organization")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.headline)
                    
                    TextField("Organization name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Organization ID")
                        .font(.headline)
                    
                    TextField("com.company.app (optional)", text: $organizationId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.headline)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...5)
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                
                Button("Save") {
                    var updatedOrg = organization
                    updatedOrg.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    updatedOrg.organizationId = organizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : organizationId.trimmingCharacters(in: .whitespacesAndNewlines)
                    updatedOrg.description = description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    onUpdate(updatedOrg)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidForm)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

#Preview {
    OrganizationManagementView(
        organizationService: OrganizationService(),
        allWorkspaces: [
            WorkspaceInfo(name: "React App", path: "/path/to/react", lastOpened: Date(), projectType: .react),
            WorkspaceInfo(name: "Swift Project", path: "/path/to/swift", lastOpened: Date(), projectType: .swift)
        ],
        onDismiss: {},
        onOpenWorkspace: { _ in }
    )
} 