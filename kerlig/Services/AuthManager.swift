//
//  AuthManager.swift
//  kerlig
//
//  Created for authentication management and API integration
//

import Combine
import Foundation
import SwiftUI

/// Main authentication manager that handles all auth operations
@MainActor
class AuthManager: ObservableObject {

    // MARK: - Published Properties
    @Published var authState: AuthState = .idle
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let localStorage = LocalStorageHelper.shared
    private let networkManager = AuthNetworkManager()
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private var tokenExpirationDate: Date?

    // MARK: - Configuration
    private let refreshIntervalMinutes: Double = 5  // Check every 5 minutes
    private let refreshThresholdMinutes: Double = 10  // Refresh if token expires in 10 minutes

    // MARK: - Singleton
    static let shared = AuthManager()

    private init() {
        checkAuthenticationStatus()
        setupErrorHandling()
    }

    // MARK: - Public Properties
    var isAuthenticated: Bool {
        return authState.isAuthenticated
    }

    var currentUser: User? {
        return authState.user
    }

    // MARK: - Authentication Methods

    /// Check if user is authenticated on app launch
    func checkAuthenticationStatus() {
        NSLog("🔐 [AuthManager] Checking authentication status...")

        NSLog("🔐 [LocalStorage] Auth info: \(localStorage.getAuthInfo())")

        // First check if session is still valid (within 1 year)
        guard localStorage.isSessionValid() else {
            NSLog("🔐 [AuthManager] Session expired (over 1 year old)")
            authState = .unauthenticated
            return
        }

        // Check if we have stored tokens
        guard let accessToken = localStorage.getAccessToken(),
            !accessToken.isEmpty
        else {
            NSLog("🔐 [AuthManager] No access token found")
            authState = .unauthenticated
            return
        }

        // Try to get stored user data
        if let storedUser = localStorage.getStoredUser() {
            NSLog("🔐 [AuthManager] Restored user from localStorage: \(storedUser.email)")
            authState = .authenticated(storedUser)

            // Restore token expiration if available
            tokenExpirationDate = localStorage.getTokenExpirationDate()

            // Start background refresh
            startBackgroundRefresh()

            // Validate token in background
            Task {
                await validateStoredToken()
            }
        } else {
            NSLog("🔐 [AuthManager] No complete user data found, clearing session")
            localStorage.clearAuthData()
            authState = .unauthenticated
        }
    }

    /// Validate stored token using the validate endpoint
    private func validateStoredToken() async {
        guard let accessToken = localStorage.getAccessToken() else {
            NSLog("🔐 [AuthManager] No access token found")
            // await signOut()
            return
        }

        do {
            NSLog("🔐 [AuthManager] Validating stored token...")
            let validationResponse = try await networkManager.validateToken(
                accessToken: accessToken)

            if validationResponse.valid {
                // Token is valid, get user profile
                await fetchUserProfile()

                // Start background refresh
                startBackgroundRefresh()

                NSLog("🔐 [AuthManager] Token validated successfully")
            } else {
                // Token invalid, try to refresh
                NSLog("🔐 [AuthManager] Token invalid, attempting refresh...")
                await refreshTokenIfNeeded()
            }
        } catch {
            NSLog("🔐 [AuthManager] Token validation failed: \(error.localizedDescription)")
            // Try refresh as fallback
            await refreshTokenIfNeeded()
        }
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async {
        NSLog("🔐 [AuthManager] Attempting sign in for: \(email)")

        isLoading = true
        errorMessage = nil
        authState = .loading

        defer {
            isLoading = false
        }

        do {
            let loginRequest = LoginRequest(email: email, password: password)
            let authResponse = try await networkManager.login(loginRequest)

            // Store tokens securely
            localStorage.storeAccessToken(authResponse.accessToken)
            localStorage.storeRefreshToken(authResponse.refreshToken)

            // Store complete user data
            localStorage.storeUser(authResponse.user)

            // Store expiration time
            if let expiresIn = authResponse.expiresIn {
                tokenExpirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
                localStorage.storeTokenExpirationDate(tokenExpirationDate!)
                localStorage.storeAuthSession(expiresAt: tokenExpirationDate)
            } else {
                localStorage.storeAuthSession(expiresAt: nil)
            }

            // Update auth state
            authState = .authenticated(authResponse.user)

            // Start background refresh
            startBackgroundRefresh()

            NSLog("🔐 [AuthManager] Sign in successful for: \(email)")

        } catch let error as AuthError {
            NSLog("🔐 [AuthManager] Sign in failed: \(error.message)")
            errorMessage = error.message
            authState = .error(error.message)
        } catch {
            NSLog("🔐 [AuthManager] Sign in failed: \(error.localizedDescription)")
            let message = "Failed to sign in. Please try again."
            errorMessage = message
            authState = .error(message)
        }
    }

    /// Register new user account
    func register(form: RegisterForm) async {
        NSLog("🔐 [AuthManager] Attempting registration for: \(form.email)")

        isLoading = true
        errorMessage = nil
        authState = .loading

        defer {
            isLoading = false
        }

        do {
            let registerRequest = form.toRegisterRequest()
            let authResponse = try await networkManager.register(registerRequest)

            // Store tokens securely
            localStorage.storeAccessToken(authResponse.accessToken)
            localStorage.storeRefreshToken(authResponse.refreshToken)

            // Store complete user data
            localStorage.storeUser(authResponse.user)

            // Store expiration time
            if let expiresIn = authResponse.expiresIn {
                tokenExpirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
                localStorage.storeTokenExpirationDate(tokenExpirationDate!)
                localStorage.storeAuthSession(expiresAt: tokenExpirationDate)
            } else {
                localStorage.storeAuthSession(expiresAt: nil)
            }

            // Update auth state
            authState = .authenticated(authResponse.user)

            // Start background refresh
            startBackgroundRefresh()

            NSLog("🔐 [AuthManager] Registration successful for: \(form.email)")

        } catch let error as AuthError {
            NSLog("🔐 [AuthManager] Registration failed: \(error.message)")
            errorMessage = error.message
            authState = .error(error.message)
        } catch {
            NSLog("🔐 [AuthManager] Registration failed: \(error.localizedDescription)")
            let message = "Failed to create account. Please try again."
            errorMessage = message
            authState = .error(message)
        }
    }

    /// Sign in with Google
    func signInWithGoogle(idToken: String, accessToken: String) async {
        NSLog("🔐 [AuthManager] Attempting Google sign in")

        isLoading = true
        errorMessage = nil
        authState = .loading

        defer {
            isLoading = false
        }

        do {
            let googleRequest = GoogleAuthRequest(idToken: idToken, accessToken: accessToken)
            let authResponse = try await networkManager.googleAuth(googleRequest)

            // Store tokens securely
            localStorage.storeAccessToken(authResponse.accessToken)
            localStorage.storeRefreshToken(authResponse.refreshToken)

            // Store complete user data
            localStorage.storeUser(authResponse.user)

            // Store expiration time
            if let expiresIn = authResponse.expiresIn {
                tokenExpirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
                localStorage.storeTokenExpirationDate(tokenExpirationDate!)
                localStorage.storeAuthSession(expiresAt: tokenExpirationDate)
            } else {
                localStorage.storeAuthSession(expiresAt: nil)
            }

            // Update auth state
            authState = .authenticated(authResponse.user)

            // Start background refresh
            startBackgroundRefresh()

            NSLog("🔐 [AuthManager] Google sign in successful")

        } catch let error as AuthError {
            NSLog("🔐 [AuthManager] Google sign in failed: \(error.message)")
            errorMessage = error.message
            authState = .error(error.message)
        } catch {
            NSLog("🔐 [AuthManager] Google sign in failed: \(error.localizedDescription)")
            let message = "Failed to sign in with Google. Please try again."
            errorMessage = message
            authState = .error(message)
        }
    }

    /// Sign out user
    func signOut() async {
        NSLog("🔐 [AuthManager] Signing out user")

        // Stop background refresh
        stopBackgroundRefresh()

        // Call logout API if we have a token
        if let accessToken = localStorage.getAccessToken() {
            do {
                try await networkManager.logout(accessToken: accessToken)
                NSLog("🔐 [AuthManager] Server logout successful")
            } catch {
                NSLog("🔐 [AuthManager] Server logout failed: \(error.localizedDescription)")
            }
        }

        // Clear stored tokens and state
        localStorage.clearAuthData()

        // Clear local state
        tokenExpirationDate = nil

        // Update auth state
        authState = .unauthenticated
        errorMessage = nil

        NSLog("🔐 [AuthManager] Sign out completed")
    }

    /// Fetch current user profile
    private func fetchUserProfile() async {
        guard let accessToken = localStorage.getAccessToken() else {
            NSLog("🔐 [AuthManager] No access token for profile fetch")
            // await signOut()
            return
        }

        do {
            let user = try await networkManager.getUserProfile(accessToken: accessToken)
            authState = .authenticated(user)
            NSLog("🔐 [AuthManager] User profile fetched successfully")
        } catch {
            NSLog("🔐 [AuthManager] Failed to fetch user profile: \(error.localizedDescription)")
            // await signOut()
        }
    }

    /// Refresh access token
    func refreshTokenIfNeeded() async {
        guard let refreshToken = localStorage.getRefreshToken() else {
            NSLog("🔐 [AuthManager] No refresh token available")
            // await signOut()
            return
        }

        do {
            NSLog("🔐 [AuthManager] Refreshing token...")
            let refreshResponse = try await networkManager.refreshToken(refreshToken)

            // Store new tokens
            localStorage.storeAccessToken(refreshResponse.accessToken)
            if let newRefreshToken = refreshResponse.refreshToken {
                localStorage.storeRefreshToken(newRefreshToken)
            }

            // Update expiration time
            if let expiresIn = refreshResponse.expiresIn {
                tokenExpirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
                localStorage.storeTokenExpirationDate(tokenExpirationDate!)
            }

            // Ensure we have valid user state
            if case .unauthenticated = authState {
                await fetchUserProfile()
            }

            NSLog("🔐 [AuthManager] Token refreshed successfully")
        } catch {
            NSLog("🔐 [AuthManager] Token refresh failed: \(error.localizedDescription)")
            // await signOut()
        }
    }

    /// Start background token refresh
    private func startBackgroundRefresh() {
        stopBackgroundRefresh()

        NSLog("🔐 [AuthManager] Starting background token refresh")

        DispatchQueue.main.async {
            self.refreshTimer = Timer.scheduledTimer(
                withTimeInterval: self.refreshIntervalMinutes * 60, repeats: true
            ) { _ in
                Task {
                    await self.checkAndRefreshToken()
                }
            }
        }
    }

    /// Stop background token refresh
    private func stopBackgroundRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// Check if token needs refresh and refresh if needed
    private func checkAndRefreshToken() async {
        guard let accessToken = localStorage.getAccessToken() else {
            // await signOut()
            return
        }

        // Check if we have expiration time
        if let expirationDate = tokenExpirationDate {
            let refreshThreshold = Date().addingTimeInterval(refreshThresholdMinutes * 60)

            if expirationDate <= refreshThreshold {
                NSLog("🔐 [AuthManager] Token expiring soon, refreshing...")
                await refreshTokenIfNeeded()
                return
            }
        }

        // Validate token with API if no local expiration info
        do {
            let validationResponse = try await networkManager.validateToken(
                accessToken: accessToken)
            if !validationResponse.valid {
                NSLog("🔐 [AuthManager] Token validation failed, refreshing...")
                await refreshTokenIfNeeded()
            }
        } catch {
            NSLog("🔐 [AuthManager] Token validation error: \(error.localizedDescription)")
            await refreshTokenIfNeeded()
        }
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
        if case .error = authState {
            authState = .unauthenticated
        }
    }

    // MARK: - Private Methods

    private func setupErrorHandling() {
        // Monitor network errors and handle token expiration
        networkManager.authErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                Task { @MainActor in
                    if case .tokenExpired = error {
                        await self?.refreshTokenIfNeeded()
                    } else {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Network Manager

private class AuthNetworkManager: ObservableObject {

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // Error publisher for token expiration handling
    let authErrorPublisher = PassthroughSubject<AuthNetworkError, Never>()

    enum AuthNetworkError: Error {
        case tokenExpired
        case unauthorized
        case networkError(Error)
        case invalidResponse
        case decodingError(Error)

        var localizedDescription: String {
            switch self {
            case .tokenExpired:
                return "Session expired. Please sign in again."
            case .unauthorized:
                return "Unauthorized access. Please sign in again."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from server."
            case .decodingError:
                return "Failed to process server response."
            }
        }
    }

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfiguration.timeout
        config.timeoutIntervalForResource = APIConfiguration.timeout

        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - API Methods

    func login(_ request: LoginRequest) async throws -> AuthResponse {
        let url = URL(string: APIConfiguration.baseURL + APIConfiguration.Endpoints.login)!
        return try await performRequest(url: url, method: "POST", body: request)
    }

    func register(_ request: RegisterRequest) async throws -> AuthResponse {
        let url = URL(string: APIConfiguration.baseURL + APIConfiguration.Endpoints.register)!
        return try await performRequest(url: url, method: "POST", body: request)
    }

    func refreshToken(_ refreshToken: String) async throws -> RefreshTokenResponse {
        let url = URL(string: APIConfiguration.baseURL + APIConfiguration.Endpoints.refresh)!
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        return try await performRequest(url: url, method: "POST", body: request)
    }

    func googleAuth(_ request: GoogleAuthRequest) async throws -> AuthResponse {
        let url = URL(string: APIConfiguration.baseURL + APIConfiguration.Endpoints.googleAuth)!
        return try await performRequest(url: url, method: "POST", body: request)
    }

    func getUserProfile(accessToken: String) async throws -> User {
        let url = URL(string: APIConfiguration.baseURL + APIConfiguration.Endpoints.me)!
        return try await performAuthenticatedRequest(
            url: url, method: "GET", accessToken: accessToken)
    }

    func validateToken(accessToken: String) async throws -> TokenValidationResponse {
        let url = URL(string: APIConfiguration.baseURL + APIConfiguration.Endpoints.validate)!
        return try await performAuthenticatedRequest(
            url: url, method: "GET", accessToken: accessToken)
    }

    func logout(accessToken: String) async throws {
        let url = URL(string: APIConfiguration.baseURL + APIConfiguration.Endpoints.logout)!
        let _: [String: String] = try await performAuthenticatedRequest(
            url: url, method: "POST", accessToken: accessToken)
    }

    // MARK: - Private Request Methods

    private func performRequest<T: Codable, U: Codable>(
        url: URL,
        method: String,
        body: T? = nil
    ) async throws -> U {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        return try await executeRequest(request)
    }

    private func performAuthenticatedRequest<T: Codable>(
        url: URL,
        method: String,
        accessToken: String,
        body: T? = nil
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        return try await executeRequest(request)
    }

    private func executeRequest<T: Codable>(_ request: URLRequest) async throws -> T {
        do {
            NSLog("🌐 [AuthNetwork] Making request to: \(request.url?.absoluteString ?? "unknown")")

            // Log request body for debugging
            if let httpBody = request.httpBody,
                let bodyString = String(data: httpBody, encoding: .utf8)
            {
                NSLog("🌐 [AuthNetwork] Request body: \(bodyString)")
            }

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthNetworkError.invalidResponse
            }

            NSLog("🌐 [AuthNetwork] Response status: \(httpResponse.statusCode)")

            // Log response body for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                NSLog("🌐 [AuthNetwork] Response body: \(responseString)")
            }

            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success - decode response
                do {
                    let result = try decoder.decode(T.self, from: data)
                    return result
                } catch {
                    NSLog("🌐 [AuthNetwork] Decoding error: \(error)")
                    NSLog("🌐 [AuthNetwork] Expected type: \(T.self)")

                    // Try to parse as a more flexible response
                    if T.self == AuthResponse.self {
                        do {
                            let flexibleResult = try parseFlexibleAuthResponse(from: data)
                            return flexibleResult as! T
                        } catch {
                            NSLog("🌐 [AuthNetwork] Flexible parsing also failed: \(error)")
                        }
                    }

                    throw AuthNetworkError.decodingError(error)
                }

            case 401:
                // Unauthorized - likely token expired
                authErrorPublisher.send(.tokenExpired)
                throw AuthNetworkError.unauthorized

            case 400...499:
                // Client error - try to decode error response
                NSLog(
                    "🌐 [AuthNetwork] Client error response: \(String(data: data, encoding: .utf8) ?? "no body")"
                )

                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw errorResponse.error
                } else if let basicError = try? JSONSerialization.jsonObject(with: data)
                    as? [String: Any],
                    let message = basicError["message"] as? String ?? basicError["error"] as? String
                {
                    throw AuthError(code: "api_error", message: message, details: nil)
                } else {
                    throw AuthError(
                        code: "client_error",
                        message: "Request failed with status \(httpResponse.statusCode)",
                        details: nil)
                }

            case 500...599:
                // Server error
                throw AuthError(
                    code: "server_error", message: "Server error occurred. Please try again later.",
                    details: nil)

            default:
                throw AuthError(
                    code: "unknown_error", message: "Unknown error occurred", details: nil)
            }

        } catch let error as AuthError {
            throw error
        } catch let error as AuthNetworkError {
            throw error
        } catch {
            NSLog("🌐 [AuthNetwork] Network error: \(error)")
            authErrorPublisher.send(.networkError(error))
            throw AuthNetworkError.networkError(error)
        }
    }

    // Parse flexible auth response to handle different API formats
    private func parseFlexibleAuthResponse(from data: Data) throws -> AuthResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthNetworkError.invalidResponse
        }

        NSLog("🌐 [AuthNetwork] Trying flexible parsing with JSON: \(json)")

        // Check if tokens are nested in a "data" object (common API pattern)
        let tokenSource: [String: Any]
        if let dataObject = json["data"] as? [String: Any] {
            NSLog("🌐 [AuthNetwork] Found nested 'data' object, using it for token extraction")
            tokenSource = dataObject
        } else {
            tokenSource = json
        }

        // Try different possible key formats
        let accessToken =
            tokenSource["access_token"] as? String ?? tokenSource["accessToken"] as? String
            ?? tokenSource["token"] as? String ?? json["access_token"] as? String ?? json[
                "accessToken"] as? String ?? json["token"] as? String

        let refreshToken =
            tokenSource["refresh_token"] as? String ?? tokenSource["refreshToken"] as? String
            ?? json["refresh_token"] as? String ?? json["refreshToken"] as? String

        guard let accessToken = accessToken else {
            NSLog("🌐 [AuthNetwork] No access token found in tokenSource: \(tokenSource)")
            NSLog("🌐 [AuthNetwork] No access token found in root json: \(json)")
            throw AuthError(
                code: "missing_token", message: "Access token not found in response", details: nil)
        }

        NSLog("🌐 [AuthNetwork] Successfully extracted access_token: \(accessToken.prefix(20))...")

        // Try to extract user data from various locations
        let userData: [String: Any]
        if let user = json["user"] as? [String: Any] {
            userData = user
        } else if let user = tokenSource["user"] as? [String: Any] {
            userData = user
        } else if let dataObject = json["data"] as? [String: Any],
            let user = dataObject["user"] as? [String: Any]
        {
            userData = user
        } else {
            // Extract user info from JWT token if available
            userData = extractUserInfoFromJWT(accessToken) ?? tokenSource
        }

        // Create a mock user if we can't parse the full user data
        let user = try parseUserFromJSON(userData) ?? createMockUser(from: userData)

        // Extract expires_in from either location
        let expiresIn =
            tokenSource["expires_in"] as? Int ?? json["expires_in"] as? Int ?? tokenSource[
                "expiresIn"] as? Int ?? json["expiresIn"] as? Int

        NSLog("🌐 [AuthNetwork] Successfully created AuthResponse with user: \(user.email)")

        return AuthResponse(
            accessToken: accessToken,
            refreshToken: refreshToken ?? "",
            user: user,
            expiresIn: expiresIn
        )
    }

    private func parseUserFromJSON(_ json: [String: Any]) throws -> User? {
        do {
            let userData = try JSONSerialization.data(withJSONObject: json)
            return try decoder.decode(User.self, from: userData)
        } catch {
            NSLog("🌐 [AuthNetwork] Failed to parse user from JSON: \(error)")
            return nil
        }
    }

    private func createMockUser(from json: [String: Any]) -> User {
        let email = json["email"] as? String ?? "unknown@example.com"
        let username = json["username"] as? String ?? "user"
        let firstName = json["first_name"] as? String ?? json["firstName"] as? String ?? "User"
        let lastName = json["last_name"] as? String ?? json["lastName"] as? String ?? ""
        let id = json["id"] as? String ?? json["user_id"] as? String ?? UUID().uuidString

        return User(
            id: id,
            email: email,
            username: username,
            firstName: firstName,
            lastName: lastName,
            createdAt: Date(),
            updatedAt: Date(),
            isVerified: json["is_verified"] as? Bool ?? json["isVerified"] as? Bool ?? false,
            profileImageUrl: json["profile_image_url"] as? String ?? json["profileImageUrl"]
                as? String
        )
    }

    // Extract user information from JWT token payload
    private func extractUserInfoFromJWT(_ token: String) -> [String: Any]? {
        NSLog("🌐 [AuthNetwork] Attempting to extract user info from JWT token")

        let parts = token.split(separator: ".")
        guard parts.count >= 2 else {
            NSLog("🌐 [AuthNetwork] Invalid JWT format")
            return nil
        }

        let payload = String(parts[1])

        // Add padding if needed for base64 decoding
        var paddedPayload = payload
        let remainder = paddedPayload.count % 4
        if remainder > 0 {
            paddedPayload += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: paddedPayload),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            NSLog("🌐 [AuthNetwork] Failed to decode JWT payload")
            return nil
        }

        NSLog("🌐 [AuthNetwork] Extracted JWT payload: \(json)")

        // Map JWT claims to user data format
        var userData: [String: Any] = [:]

        if let userId = json["user_id"] as? String ?? json["sub"] as? String {
            userData["id"] = userId
            userData["user_id"] = userId
        }

        if let email = json["email"] as? String {
            userData["email"] = email
        }

        if let username = json["username"] as? String {
            userData["username"] = username
        }

        // Try to extract name information
        if let name = json["name"] as? String {
            let nameParts = name.split(separator: " ")
            if nameParts.count >= 1 {
                userData["firstName"] = String(nameParts[0])
                userData["first_name"] = String(nameParts[0])
            }
            if nameParts.count >= 2 {
                userData["lastName"] = String(nameParts[1])
                userData["last_name"] = String(nameParts[1])
            }
        }

        NSLog("🌐 [AuthNetwork] Mapped user data from JWT: \(userData)")
        return userData.isEmpty ? nil : userData
    }
}

// MARK: - Mock Implementation for Development

#if DEBUG
    extension AuthManager {
        /// Mock sign in for development/testing
        func mockSignIn() async {
            NSLog("🔐 [AuthManager] Mock sign in")

            isLoading = true
            authState = .loading

            // Simulate network delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            let mockUser = User(
                id: "mock-user-id",
                email: "demo@kerlig.com",
                username: "demouser",
                firstName: "Demo",
                lastName: "User",
                createdAt: Date(),
                updatedAt: Date(),
                isVerified: true,
                profileImageUrl: nil
            )

            // Store mock tokens
            localStorage.storeAccessToken("mock-access-token")
            localStorage.storeRefreshToken("mock-refresh-token")
            localStorage.storeUser(mockUser)
            localStorage.storeAuthSession(expiresAt: nil)

            authState = .authenticated(mockUser)
            isLoading = false

            NSLog("🔐 [AuthManager] Mock sign in completed")
        }
    }
#endif
