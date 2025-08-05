//
//  AuthModels.swift
//  kerlig
//
//  Created for authentication data models
//

import Foundation
import SwiftUI

// MARK: - User Model

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let username: String
    let firstName: String
    let lastName: String
    let createdAt: Date
    let updatedAt: Date
    let isVerified: Bool
    let profileImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isVerified = "is_verified"
        case profileImageUrl = "profile_image_url"
    }

    var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
}

// MARK: - Authentication Response Models
struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
        case expiresIn = "expires_in"
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let confirmPassword: String
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case email
        case password
        case confirmPassword = "confirm_password"
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

struct TokenValidationResponse: Codable {
    let valid: Bool
    let expiresAt: String?
    let user: User?

    enum CodingKeys: String, CodingKey {
        case valid
        case expiresAt = "expires_at"
        case user
    }
}

struct UserProfileResponse: Codable {
    let user: User
    let authMethods: AuthMethods?
    let securityInfo: SecurityInfo?

    enum CodingKeys: String, CodingKey {
        case user
        case authMethods = "auth_methods"
        case securityInfo = "security_info"
    }
}

struct AuthMethods: Codable {
    let passwordEnabled: Bool
    let oauthProviders: [String]

    enum CodingKeys: String, CodingKey {
        case passwordEnabled = "password_enabled"
        case oauthProviders = "oauth_providers"
    }
}

struct SecurityInfo: Codable {
    let lastLogin: Date?
    let loginCount: Int?
    let activeSessions: Int?

    enum CodingKeys: String, CodingKey {
        case lastLogin = "last_login"
        case loginCount = "login_count"
        case activeSessions = "active_sessions"
    }
}

// MARK: - Error Models

struct AuthError: Codable, Error {
    let code: String
    let message: String
    let details: [String: String]?

    var localizedDescription: String {
        return message
    }
}

struct APIErrorResponse: Codable {
    let error: AuthError
}

// MARK: - Authentication State

enum AuthState: Equatable {
    case idle
    case loading
    case authenticated(User)
    case unauthenticated
    case error(String)

    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }

    var user: User? {
        if case .authenticated(let user) = self {
            return user
        }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}

// MARK: - Form Validation

struct LoginForm {
    var email: String = ""
    var password: String = ""

    var isValid: Bool {
        return isValidEmail && isValidPassword
    }

    var isValidEmail: Bool {
        return !email.isEmpty && email.contains("@") && email.contains(".")
    }

    var isValidPassword: Bool {
        return password.count >= 6
    }

    var emailError: String? {
        if email.isEmpty {
            return nil
        }
        return isValidEmail ? nil : "Please enter a valid email address"
    }

    var passwordError: String? {
        if password.isEmpty {
            return nil
        }
        return isValidPassword ? nil : "Password must be at least 6 characters"
    }
}

struct RegisterForm {
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var firstName: String = ""
    var lastName: String = ""

    var isValid: Bool {
        return isValidEmail && isValidPassword && isValidConfirmPassword
            && isValidFirstName && isValidLastName
    }

    var isValidEmail: Bool {
        return !email.isEmpty && email.contains("@") && email.contains(".")
    }

    var isValidPassword: Bool {
        return password.count >= 8 && password.rangeOfCharacter(from: .uppercaseLetters) != nil
            && password.rangeOfCharacter(from: .lowercaseLetters) != nil
            && password.rangeOfCharacter(from: .decimalDigits) != nil
    }

    var isValidConfirmPassword: Bool {
        return !confirmPassword.isEmpty && password == confirmPassword
    }

    var isValidFirstName: Bool {
        return !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isValidLastName: Bool {
        return !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // Error messages
    var emailError: String? {
        if email.isEmpty { return nil }
        return isValidEmail ? nil : "Please enter a valid email address"
    }

    var passwordError: String? {
        if password.isEmpty { return nil }
        if password.count < 8 {
            return "Password must be at least 8 characters"
        }
        if password.rangeOfCharacter(from: .uppercaseLetters) == nil {
            return "Password must contain at least one uppercase letter"
        }
        if password.rangeOfCharacter(from: .lowercaseLetters) == nil {
            return "Password must contain at least one lowercase letter"
        }
        if password.rangeOfCharacter(from: .decimalDigits) == nil {
            return "Password must contain at least one number"
        }
        return nil
    }

    var confirmPasswordError: String? {
        if confirmPassword.isEmpty { return nil }
        return isValidConfirmPassword ? nil : "Passwords do not match"
    }

    var firstNameError: String? {
        if firstName.isEmpty { return nil }
        return isValidFirstName ? nil : "First name is required"
    }

    var lastNameError: String? {
        if lastName.isEmpty { return nil }
        return isValidLastName ? nil : "Last name is required"
    }

    func toRegisterRequest() -> RegisterRequest {
        return RegisterRequest(
            email: email.trimmingCharacters(in: .whitespaces),
            password: password,
            confirmPassword: confirmPassword,
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
        )
    }
}

// MARK: - Google Sign-In Models

struct GoogleSignInResult {
    let idToken: String
    let accessToken: String
    let user: GoogleUser
}

struct GoogleUser {
    let id: String
    let email: String
    let name: String
    let givenName: String
    let familyName: String
    let profileImageUrl: String?
}

struct GoogleAuthRequest: Codable {
    let idToken: String
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
        case accessToken = "access_token"
    }
}

// MARK: - Networking Configuration

struct APIConfiguration {
    static let baseURL = "http://localhost:8080"
    static let timeout: TimeInterval = 30.0

    enum Endpoints {
        // Authentication
        static let login = "/api/v1/auth/login"
        static let register = "/api/v1/auth/register"
        static let refresh = "/api/v1/auth/refresh"
        static let validate = "/api/v1/auth/validate"
        static let logout = "/api/v1/auth/logout"

        // User Management
        static let me = "/api/v1/auth/me"
        static let profile = "/api/v1/auth/profile"
        static let changePassword = "/api/v1/auth/change-password"

        // OAuth
        static let googleAuth = "/api/v1/auth/google"
        static let googleCallback = "/api/v1/auth/google/callback"
        static let oauthProviders = "/api/v1/auth/oauth/providers"
        static let oauthAccounts = "/api/v1/auth/oauth/accounts"

        // Validation
        static let checkEmail = "/api/v1/auth/check-email"
        static let checkUsername = "/api/v1/auth/check-username"

        // System
        static let health = "/health"
        static let docs = "/docs/"
    }
}
