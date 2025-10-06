//
//  LocalStorageHelper.swift
//  kerlig
//
//  Created for secure local storage using UserDefaults
//

import Foundation

/// Helper class for storing authentication data in UserDefaults
/// Provides persistent storage that survives app restarts
class LocalStorageHelper {
    static let shared = LocalStorageHelper()

    private init() {}

    // MARK: - Constants
    private let userDefaults = UserDefaults.standard

    enum StorageError: Error {
        case itemNotFound
        case invalidData
        case storageFailure

        var localizedDescription: String {
            switch self {
            case .itemNotFound:
                return "Item not found in storage"
            case .invalidData:
                return "Invalid data format"
            case .storageFailure:
                return "Failed to store data"
            }
        }
    }

    // MARK: - Storage Keys
    private enum AuthKeys {
        static let accessToken = "kerlig_access_token"
        static let refreshToken = "kerlig_refresh_token"
        static let userEmail = "kerlig_user_email"
        static let userId = "kerlig_user_id"
        static let userFirstName = "kerlig_user_first_name"
        static let userLastName = "kerlig_user_last_name"
        static let userUsername = "kerlig_user_username"
        static let isVerified = "kerlig_user_verified"
        static let profileImageUrl = "kerlig_profile_image_url"
        static let createdAt = "kerlig_user_created_at"
        static let updatedAt = "kerlig_user_updated_at"

        // Session management
        static let lastLogin = "kerlig_last_login"
        static let expiresAt = "kerlig_expires_at"
        static let sessionActive = "kerlig_session_active"
        static let tokenExpirationDate = "kerlig_token_expiration"
    }

    // MARK: - Generic Storage Methods

    /// Store a string value in UserDefaults
    func store(_ value: String, forKey key: String) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    /// Store a boolean value in UserDefaults
    func store(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    /// Store a date value in UserDefaults
    func store(_ value: Date, forKey key: String) {
        userDefaults.set(value, forKey: key)
        userDefaults.synchronize()
    }

    /// Retrieve a string value from UserDefaults
    func retrieveString(forKey key: String) -> String? {
        return userDefaults.string(forKey: key)
    }

    /// Retrieve a boolean value from UserDefaults
    func retrieveBool(forKey key: String) -> Bool {
        return userDefaults.bool(forKey: key)
    }

    /// Retrieve a date value from UserDefaults
    func retrieveDate(forKey key: String) -> Date? {
        return userDefaults.object(forKey: key) as? Date
    }

    /// Remove a value from UserDefaults
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
        userDefaults.synchronize()
    }

    /// Check if a key exists in UserDefaults
    func exists(forKey key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }

    // MARK: - Authentication Token Methods

    // Access Token
    func storeAccessToken(_ token: String) {
        store(token, forKey: AuthKeys.accessToken)
        NSLog("🔐 [LocalStorage] Stored access token")
    }

    func getAccessToken() -> String? {
        return retrieveString(forKey: AuthKeys.accessToken)
    }

    func deleteAccessToken() {
        remove(forKey: AuthKeys.accessToken)
        NSLog("🔐 [LocalStorage] Deleted access token")
    }

    // Refresh Token
    func storeRefreshToken(_ token: String) {
        store(token, forKey: AuthKeys.refreshToken)
        NSLog("🔐 [LocalStorage] Stored refresh token")
    }

    func getRefreshToken() -> String? {
        return retrieveString(forKey: AuthKeys.refreshToken)
    }

    func deleteRefreshToken() {
        remove(forKey: AuthKeys.refreshToken)
        NSLog("🔐 [LocalStorage] Deleted refresh token")
    }

    // MARK: - User Information Methods

    // User Email
    func storeUserEmail(_ email: String) {
        store(email, forKey: AuthKeys.userEmail)
        NSLog("🔐 [LocalStorage] Stored user email")
    }

    func getUserEmail() -> String? {
        return retrieveString(forKey: AuthKeys.userEmail)
    }

    func deleteUserEmail() {
        remove(forKey: AuthKeys.userEmail)
    }

    // User ID
    func storeUserId(_ userId: String) {
        store(userId, forKey: AuthKeys.userId)
        NSLog("🔐 [LocalStorage] Stored user ID")
    }

    func getUserId() -> String? {
        return retrieveString(forKey: AuthKeys.userId)
    }

    func deleteUserId() {
        remove(forKey: AuthKeys.userId)
    }

    // User Details
    func storeUserFirstName(_ firstName: String) {
        store(firstName, forKey: AuthKeys.userFirstName)
    }

    func getUserFirstName() -> String? {
        return retrieveString(forKey: AuthKeys.userFirstName)
    }

    func storeUserLastName(_ lastName: String) {
        store(lastName, forKey: AuthKeys.userLastName)
    }

    func getUserLastName() -> String? {
        return retrieveString(forKey: AuthKeys.userLastName)
    }

    func storeUserUsername(_ username: String) {
        store(username, forKey: AuthKeys.userUsername)
    }

    func getUserUsername() -> String? {
        return retrieveString(forKey: AuthKeys.userUsername)
    }

    func storeIsVerified(_ isVerified: Bool) {
        store(isVerified, forKey: AuthKeys.isVerified)
    }

    func getIsVerified() -> Bool {
        return retrieveBool(forKey: AuthKeys.isVerified)
    }

    func storeProfileImageUrl(_ url: String?) {
        if let url = url {
            store(url, forKey: AuthKeys.profileImageUrl)
        } else {
            remove(forKey: AuthKeys.profileImageUrl)
        }
    }

    func getProfileImageUrl() -> String? {
        return retrieveString(forKey: AuthKeys.profileImageUrl)
    }

    func storeCreatedAt(_ date: Date) {
        store(date, forKey: AuthKeys.createdAt)
    }

    func getCreatedAt() -> Date? {
        return retrieveDate(forKey: AuthKeys.createdAt)
    }

    func storeUpdatedAt(_ date: Date) {
        store(date, forKey: AuthKeys.updatedAt)
    }

    func getUpdatedAt() -> Date? {
        return retrieveDate(forKey: AuthKeys.updatedAt)
    }

    // MARK: - Session Management

   


    /// Store auth session info with expiration
    func storeAuthSession(expiresAt: Date?) {
        store(Date(), forKey: AuthKeys.lastLogin)
        if let expiresAt = expiresAt {
            store(expiresAt, forKey: AuthKeys.expiresAt)
            store(expiresAt, forKey: AuthKeys.tokenExpirationDate)
        }
        store(true, forKey: AuthKeys.sessionActive)
        NSLog(
            "🔐 [LocalStorage] Stored auth session with expiration: \(expiresAt?.description ?? "none")"
        )
    }

    /// Get auth session info
    func getAuthSession() -> (lastLogin: Date?, expiresAt: Date?, isActive: Bool) {
        let lastLogin = retrieveDate(forKey: AuthKeys.lastLogin)
        let expiresAt = retrieveDate(forKey: AuthKeys.expiresAt)
        let isActive = retrieveBool(forKey: AuthKeys.sessionActive)
        return (lastLogin, expiresAt, isActive)
    }

    /// Get token expiration date
    func getTokenExpirationDate() -> Date? {
        return retrieveDate(forKey: AuthKeys.tokenExpirationDate)
    }

    /// Store token expiration date
    func storeTokenExpirationDate(_ date: Date) {
        store(date, forKey: AuthKeys.tokenExpirationDate)
    }

    /// Clear auth session info
    func clearAuthSession() {
        remove(forKey: AuthKeys.lastLogin)
        remove(forKey: AuthKeys.expiresAt)
        remove(forKey: AuthKeys.tokenExpirationDate)
        store(false, forKey: AuthKeys.sessionActive)
        NSLog("🔐 [LocalStorage] Cleared auth session")
    }

    /// Check if session is still valid (within 1 year)
    func isSessionValid() -> Bool {
        let session = getAuthSession()
        guard session.isActive, let lastLogin = session.lastLogin else {
            NSLog("🔐 [LocalStorage] Session inactive or no login date")
            return false
        }

        // Check if session is within 1 year
        let oneYearLater = Calendar.current.date(byAdding: .year, value: 1, to: lastLogin) ?? Date()
        let isValid = Date() < oneYearLater

        NSLog("🔐 [LocalStorage] Session validity check: \(isValid ? "valid" : "expired")")
        return isValid
    }

    /// Clear all auth data
    func clearAuthData() {
        deleteAccessToken()
        deleteRefreshToken()
        deleteUserEmail()
        deleteUserId()
        remove(forKey: AuthKeys.userFirstName)
        remove(forKey: AuthKeys.userLastName)
        remove(forKey: AuthKeys.userUsername)
        remove(forKey: AuthKeys.isVerified)
        remove(forKey: AuthKeys.profileImageUrl)
        remove(forKey: AuthKeys.createdAt)
        remove(forKey: AuthKeys.updatedAt)
        clearAuthSession()
        NSLog("🔐 [LocalStorage] Cleared all auth data")
    }

    // Check if user is logged in
    var isLoggedIn: Bool {
        let hasToken = getAccessToken() != nil
        let sessionValid = isSessionValid()
        let isLoggedIn = hasToken && sessionValid

        NSLog(
            "🔐 [LocalStorage] Login status - hasToken: \(hasToken), sessionValid: \(sessionValid), isLoggedIn: \(isLoggedIn)"
        )
        return isLoggedIn
    }

    /// Get all stored authentication info for debugging
    func getAuthInfo() -> [String: Any] {
        let session = getAuthSession()
        return [
            "hasAccessToken": getAccessToken() != nil,
            "hasRefreshToken": getRefreshToken() != nil,
            "userEmail": getUserEmail() ?? "none",
            "userId": getUserId() ?? "none",
            "lastLogin": session.lastLogin?.description ?? "none",
            "expiresAt": session.expiresAt?.description ?? "none",
            "isActive": session.isActive,
            "isSessionValid": isSessionValid(),
            "isLoggedIn": isLoggedIn,
        ]
    }
}
