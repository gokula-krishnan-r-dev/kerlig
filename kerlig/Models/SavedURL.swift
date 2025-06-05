import Foundation

// MARK: - URL Management Models

struct SavedURL: Codable, Identifiable, Hashable {
    let id = UUID()
    let url: String
    let title: String
    let dateAdded: Date
    let isGitHubRepo: Bool
    var githubData: GitHubRepoData?
    
    init(url: String, title: String? = nil, isGitHubRepo: Bool = false, githubData: GitHubRepoData? = nil) {
        self.url = url
        self.title = title ?? url
        self.dateAdded = Date()
        self.isGitHubRepo = isGitHubRepo
        self.githubData = githubData
    }
}

struct GitHubRepoData: Codable, Hashable {
    let repositoryName: String
    let organizationName: String
    let description: String?
    let avatarURL: String?
    let starCount: Int?
    let forkCount: Int?
    let language: String?
    let isPrivate: Bool
    let htmlURL: String
    let defaultBranch: String?
    
    init(repositoryName: String, organizationName: String, description: String? = nil, 
         avatarURL: String? = nil, starCount: Int? = nil, forkCount: Int? = nil, 
         language: String? = nil, isPrivate: Bool = false, htmlURL: String, 
         defaultBranch: String? = nil) {
        self.repositoryName = repositoryName
        self.organizationName = organizationName
        self.description = description
        self.avatarURL = avatarURL
        self.starCount = starCount
        self.forkCount = forkCount
        self.language = language
        self.isPrivate = isPrivate
        self.htmlURL = htmlURL
        self.defaultBranch = defaultBranch
    }
}

// MARK: - GitHub API Response Models

struct GitHubRepository: Codable {
    let id: Int
    let name: String
    let fullName: String
    let owner: GitHubOwner
    let description: String?
    let htmlURL: String
    let stargazersCount: Int
    let forksCount: Int
    let language: String?
    let isPrivate: Bool
    let defaultBranch: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, language, owner
        case fullName = "full_name"
        case htmlURL = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case isPrivate = "private"
        case defaultBranch = "default_branch"
    }
}

struct GitHubOwner: Codable {
    let login: String
    let avatarURL: String
    let type: String
    
    private enum CodingKeys: String, CodingKey {
        case login, type
        case avatarURL = "avatar_url"
    }
} 