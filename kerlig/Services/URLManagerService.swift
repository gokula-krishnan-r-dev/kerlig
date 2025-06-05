import Foundation
import AppKit
import Network

class URLManagerService: ObservableObject {
    @Published var savedURLs: [SavedURL] = []
    @Published var isLoadingGitHub = false
    @Published var errorMessage: String? = nil
    
    private let userDefaultsKey = "savedURLs"
    private let session = URLSession.shared
    
    init() {
        loadSavedURLs()
    }
    
    // MARK: - URL Management
    
    func saveURL(_ urlString: String) {
        guard let url = URL(string: urlString), url.scheme != nil else {
            errorMessage = "Invalid URL format"
            return
        }
        
        // Check if URL already exists
        if savedURLs.contains(where: { $0.url == urlString }) {
            errorMessage = "URL already saved"
            return
        }
        
        // Check if it's a GitHub repository
        if isGitHubRepositoryURL(urlString) {
            fetchGitHubRepoData(from: urlString) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let githubData):
                        let savedURL = SavedURL(
                            url: urlString,
                            title: "\(githubData.organizationName)/\(githubData.repositoryName)",
                            isGitHubRepo: true,
                            githubData: githubData
                        )
                        self?.addURLToStorage(savedURL)
                        
                    case .failure(let error):
                        print("Failed to fetch GitHub data: \(error)")
                        // Still save as regular URL
                        let savedURL = SavedURL(url: urlString, title: urlString)
                        self?.addURLToStorage(savedURL)
                    }
                }
            }
        } else {
            // Save as regular URL
            let savedURL = SavedURL(url: urlString, title: extractDomainFromURL(urlString))
            addURLToStorage(savedURL)
        }
    }
    
    func removeURL(_ url: SavedURL) {
        savedURLs.removeAll { $0.id == url.id }
        saveToPersistence()
    }
    
    func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        // Try to open in Chrome first, then fallback to default browser
        let chromeURL = "googlechrome://\(urlString)"
        if let chromeAppURL = URL(string: chromeURL),
           NSWorkspace.shared.urlForApplication(toOpen: chromeAppURL) != nil {
            NSWorkspace.shared.open(chromeAppURL)
        } else {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - GitHub Integration
    
    private func isGitHubRepositoryURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.host?.lowercased() == "github.com" && 
               url.pathComponents.count >= 3 &&
               !url.pathComponents[2].isEmpty
    }
    
    private func fetchGitHubRepoData(from urlString: String, completion: @escaping (Result<GitHubRepoData, Error>) -> Void) {
        guard let url = URL(string: urlString),
              url.pathComponents.count >= 3 else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        let owner = url.pathComponents[1]
        let repo = url.pathComponents[2]
        
        // GitHub API endpoint
        let apiURL = "https://api.github.com/repos/\(owner)/\(repo)"
        guard let githubAPIURL = URL(string: apiURL) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        isLoadingGitHub = true
        
        var request = URLRequest(url: githubAPIURL)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Kerlig-URLManager/1.0", forHTTPHeaderField: "User-Agent")
        
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoadingGitHub = false
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                let githubRepo = try JSONDecoder().decodeFromData(GitHubRepository.self, from: data)
                let githubData = GitHubRepoData(
                    repositoryName: githubRepo.name,
                    organizationName: githubRepo.owner.login,
                    description: githubRepo.description,
                    avatarURL: githubRepo.owner.avatarURL,
                    starCount: githubRepo.stargazersCount,
                    forkCount: githubRepo.forksCount,
                    language: githubRepo.language,
                    isPrivate: githubRepo.isPrivate,
                    htmlURL: githubRepo.htmlURL,
                    defaultBranch: githubRepo.defaultBranch
                )
                completion(.success(githubData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    
    private func extractDomainFromURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return urlString
        }
        
        // Remove www. prefix if present
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return domain.capitalized
    }
    
    private func addURLToStorage(_ url: SavedURL) {
        savedURLs.insert(url, at: 0) // Add to beginning for chronological order
        saveToPersistence()
        errorMessage = nil
    }
    
    // MARK: - Persistence
    
    private func loadSavedURLs() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        
        do {
            savedURLs = try JSONDecoder().decode([SavedURL].self, from: data)
        } catch {
            print("Failed to load saved URLs: \(error)")
            savedURLs = []
        }
    }
    
    private func saveToPersistence() {
        do {
            let data = try JSONEncoder().encode(savedURLs)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save URLs: \(error)")
        }
    }
}

// MARK: - Extensions

extension JSONDecoder {
    func decodeFromData<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        return try self.decode(type, from: data)
    }
} 
