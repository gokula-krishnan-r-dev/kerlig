import Foundation

// Organization model to group workspaces together
struct Organization: Identifiable, Codable {
    let id = UUID()
    var name: String
    var organizationId: String?
    var workspaceIds: [UUID]
    var createdDate: Date
    var lastModified: Date
    var description: String?
    
    init(name: String, organizationId: String? = nil, workspaceIds: [UUID] = [], description: String? = nil) {
        self.name = name
        self.organizationId = organizationId
        self.workspaceIds = workspaceIds
        self.description = description
        self.createdDate = Date()
        self.lastModified = Date()
    }
    
    // Computed property to check if organization has a valid bundle-style ID
    var hasValidBundleId: Bool {
        guard let orgId = organizationId else { return false }
        return orgId.contains(".") && orgId.split(separator: ".").count >= 2
    }
    
    // Get display ID with fallback
    var displayId: String {
        return organizationId ?? "No ID"
    }
    
    // Update the organization (useful for tracking modifications)
    mutating func updateLastModified() {
        self.lastModified = Date()
    }
}

// Organization service to manage organizations
class OrganizationService: ObservableObject {
    @Published var organizations: [Organization] = []
    
    private let userDefaults = UserDefaults.standard
    private let organizationsKey = "SavedOrganizations"
    
    init() {
        loadOrganizations()
    }
    
    // Load organizations from UserDefaults
    func loadOrganizations() {
        if let data = userDefaults.data(forKey: organizationsKey),
           let decoded = try? JSONDecoder().decode([Organization].self, from: data) {
            organizations = decoded
        }
    }
    
    // Save organizations to UserDefaults
    func saveOrganizations() {
        if let encoded = try? JSONEncoder().encode(organizations) {
            userDefaults.set(encoded, forKey: organizationsKey)
        }
    }
    
    // Add a new organization
    func addOrganization(_ organization: Organization) {
        organizations.append(organization)
        saveOrganizations()
    }
    
    // Remove an organization
    func removeOrganization(_ organization: Organization) {
        organizations.removeAll { $0.id == organization.id }
        saveOrganizations()
    }
    
    // Update an organization
    func updateOrganization(_ organization: Organization) {
        if let index = organizations.firstIndex(where: { $0.id == organization.id }) {
            var updatedOrg = organization
            updatedOrg.updateLastModified()
            organizations[index] = updatedOrg
            saveOrganizations()
        }
    }
    
    // Get workspaces for an organization
    func getWorkspaces(for organization: Organization, from allWorkspaces: [WorkspaceInfo]) -> [WorkspaceInfo] {
        return allWorkspaces.filter { workspace in
            organization.workspaceIds.contains(workspace.id)
        }
    }
    
    // Check if workspace is part of any organization
    func isWorkspaceInOrganization(_ workspace: WorkspaceInfo) -> Bool {
        return organizations.contains { organization in
            organization.workspaceIds.contains(workspace.id)
        }
    }
} 