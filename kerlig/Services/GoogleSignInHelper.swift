//
//  GoogleSignInHelper.swift
//  kerlig
//
//  Created for Google Sign-In integration
//

import Foundation
import SwiftUI
import AppKit

// Note: This implementation assumes you have added GoogleSignIn SDK to your project
// Add to your Package.swift dependencies: 
// .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0")

/*
 IMPORTANT: To use Google Sign-In, you need to:
 
 1. Add GoogleSignIn to your project dependencies
 2. Configure your Google Cloud Console project
 3. Download GoogleService-Info.plist and add to your project
 4. Add URL schemes to your Info.plist
 5. Initialize GoogleSignIn in your AppDelegate
 
 For detailed setup instructions, visit:
 https://developers.google.com/identity/sign-in/ios/start-integrating
*/

#if canImport(GoogleSignIn)
import GoogleSignIn

@MainActor
class GoogleSignInHelper: ObservableObject {
    
    static let shared = GoogleSignInHelper()
    
    @Published var isConfigured = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        configureGoogleSignIn()
    }
    
    // MARK: - Configuration
    
    private func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plistData = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
              let clientId = plist["CLIENT_ID"] as? String else {
            NSLog("🔐 [GoogleSignIn] GoogleService-Info.plist not found or CLIENT_ID missing")
            isConfigured = false
            return
        }
        
        guard let config = GIDConfiguration(clientID: clientId) else {
            NSLog("🔐 [GoogleSignIn] Failed to create GIDConfiguration")
            isConfigured = false
            return
        }
        
        GIDSignIn.sharedInstance.configuration = config
        isConfigured = true
        
        NSLog("🔐 [GoogleSignIn] Successfully configured with client ID: \(clientId.prefix(10))...")
    }
    
    // MARK: - Sign In Methods
    
    func signIn() async -> GoogleSignInResult? {
        guard isConfigured else {
            errorMessage = "Google Sign-In not properly configured"
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            guard let presentingWindow = NSApp.keyWindow else {
                throw GoogleSignInError.noPresentingWindow
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow)
            
            guard let user = result.user.profile,
                  let idToken = result.user.idToken?.tokenString else {
                throw GoogleSignInError.missingUserData
            }
            
            let accessToken = result.user.accessToken.tokenString
            
            let googleUser = GoogleUser(
                id: user.userID ?? "",
                email: user.email,
                name: user.name,
                givenName: user.givenName ?? "",
                familyName: user.familyName ?? "",
                profileImageUrl: user.imageURL(withDimension: 200)?.absoluteString
            )
            
            NSLog("🔐 [GoogleSignIn] Sign in successful for: \(user.email)")
            
            return GoogleSignInResult(
                idToken: idToken,
                accessToken: accessToken,
                user: googleUser
            )
            
        } catch {
            NSLog("🔐 [GoogleSignIn] Sign in failed: \(error.localizedDescription)")
            errorMessage = handleGoogleSignInError(error)
            return nil
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        NSLog("🔐 [GoogleSignIn] User signed out")
    }
    
    // MARK: - Error Handling
    
    private func handleGoogleSignInError(_ error: Error) -> String {
        if let gidError = error as? GIDSignInError {
            switch gidError.code {
            case .canceled:
                return "Sign in was canceled"
            case .EMM:
                return "Enterprise Mobility Management error"
            case .hasNoAuthInKeychain:
                return "No previous sign in found"
            case .keychain:
                return "Keychain error occurred"
            case .network:
                return "Network error. Please check your connection"
            case .scopeRequestFailed:
                return "Failed to request required permissions"
            case .unknown:
                return "An unknown error occurred"
            @unknown default:
                return "An unexpected error occurred"
            }
        }
        
        return error.localizedDescription
    }
    
    // MARK: - Utility Methods
    
    func restorePreviousSignIn() async -> GoogleSignInResult? {
        guard isConfigured else { return nil }
        
        do {
            let result = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            
            guard let user = result.profile,
                  let idToken = result.idToken?.tokenString else {
                return nil
            }
            
            let accessToken = result.accessToken.tokenString
            
            let googleUser = GoogleUser(
                id: user.userID ?? "",
                email: user.email,
                name: user.name,
                givenName: user.givenName ?? "",
                familyName: user.familyName ?? "",
                profileImageUrl: user.imageURL(withDimension: 200)?.absoluteString
            )
            
            NSLog("🔐 [GoogleSignIn] Previous sign in restored for: \(user.email)")
            
            return GoogleSignInResult(
                idToken: idToken,
                accessToken: accessToken,
                user: googleUser
            )
            
        } catch {
            NSLog("🔐 [GoogleSignIn] Failed to restore previous sign in: \(error.localizedDescription)")
            return nil
        }
    }
    
    var isSignedIn: Bool {
        return GIDSignIn.sharedInstance.currentUser != nil
    }
    
    var currentUser: GIDGoogleUser? {
        return GIDSignIn.sharedInstance.currentUser
    }
}

// MARK: - Error Types

enum GoogleSignInError: Error, LocalizedError {
    case noPresentingWindow
    case missingUserData
    case configurationError
    
    var errorDescription: String? {
        switch self {
        case .noPresentingWindow:
            return "No window available for sign in"
        case .missingUserData:
            return "Missing required user data"
        case .configurationError:
            return "Google Sign-In configuration error"
        }
    }
}

#else

// Fallback implementation when GoogleSignIn is not available
@MainActor
class GoogleSignInHelper: ObservableObject {
    
    static let shared = GoogleSignInHelper()
    
    @Published var isConfigured = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        NSLog("🔐 [GoogleSignIn] GoogleSignIn SDK not available. Add GoogleSignIn dependency to enable Google authentication.")
        isConfigured = false
    }
    
    func signIn() async -> GoogleSignInResult? {
        errorMessage = "Google Sign-In not available. Please add GoogleSignIn SDK to your project."
        return nil
    }
    
    func signOut() {
        // No-op
    }
    
    func restorePreviousSignIn() async -> GoogleSignInResult? {
        return nil
    }
    
    var isSignedIn: Bool {
        return false
    }
}

enum GoogleSignInError: Error, LocalizedError {
    case noPresentingWindow
    case missingUserData
    case configurationError
    case sdkNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .noPresentingWindow:
            return "No window available for sign in"
        case .missingUserData:
            return "Missing required user data"
        case .configurationError:
            return "Google Sign-In configuration error"
        case .sdkNotAvailable:
            return "Google Sign-In SDK not available"
        }
    }
}

#endif

// MARK: - SwiftUI Integration

struct GoogleSignInButton: View {
    @StateObject private var googleSignIn = GoogleSignInHelper.shared
    @StateObject private var authManager = AuthManager.shared
    
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Task {
                if let result = await googleSignIn.signIn() {
                    await authManager.signInWithGoogle(
                        idToken: result.idToken,
                        accessToken: result.accessToken
                    )
                    action()
                }
            }
        }) {
            HStack(spacing: 12) {
                if googleSignIn.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 16))
                }
                
                Text(googleSignIn.isLoading ? "Signing in..." : "Continue with Google")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(googleSignIn.isLoading || !googleSignIn.isConfigured)
        .opacity(googleSignIn.isConfigured ? 1.0 : 0.6)
        .alert("Google Sign-In Error", isPresented: .constant(googleSignIn.errorMessage != nil)) {
            Button("OK") {
                googleSignIn.errorMessage = nil
            }
        } message: {
            Text(googleSignIn.errorMessage ?? "")
        }
    }
}

// MARK: - AppDelegate Integration

/*
 Add this to your AppDelegate or main app file:
 
 import GoogleSignIn
 
 func applicationDidFinishLaunching(_ notification: Notification) {
     // Other setup code...
     
     // Configure Google Sign-In
     GoogleSignInHelper.shared.configureGoogleSignIn()
 }
 
 // Handle URL schemes for Google Sign-In
 func application(_ app: NSApplication, open urls: [URL]) {
     for url in urls {
         if GIDSignIn.sharedInstance.handle(url) {
             return
         }
     }
 }
*/

// MARK: - Info.plist Configuration

/*
 Add these URL schemes to your Info.plist:
 
 <key>CFBundleURLTypes</key>
 <array>
     <dict>
         <key>CFBundleURLName</key>
         <string>GoogleSignIn</string>
         <key>CFBundleURLSchemes</key>
         <array>
             <!-- Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
             <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
         </array>
     </dict>
 </array>
*/