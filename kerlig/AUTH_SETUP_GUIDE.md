# 🔐 Authentication Setup Guide

This guide will help you configure the authentication system for the Task Management page in Kerlig.

## 📋 Overview

The authentication system includes:

- ✅ Secure token storage using macOS Keychain
- ✅ Email/password authentication
- ✅ Google OAuth integration (with SDK)
- ✅ Auto-login with token refresh
- ✅ Professional SwiftUI interface
- ✅ Real-time authentication state management
- ✅ Form validation and error handling

## 🚀 Quick Start

### 1. Configure API Base URL

Update the `APIConfiguration` in `kerlig/Models/AuthModels.swift`:

```swift
struct APIConfiguration {
    static let baseURL = "https://your-actual-api-url.com" // Replace with your API
    static let timeout: TimeInterval = 30.0

    // Endpoints are already configured for your API structure
}
```

### 2. Google Sign-In Setup (Optional but Recommended)

#### A. Add GoogleSignIn SDK

Add to your `Package.swift` or Xcode project:

```swift
.package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0")
```

#### B. Configure Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Google Sign-In API
4. Create OAuth 2.0 credentials for macOS app
5. Download `GoogleService-Info.plist`

#### C. Add GoogleService-Info.plist

1. Download the config file from Google Cloud Console
2. Add `GoogleService-Info.plist` to your Xcode project
3. Make sure it's included in your target

#### D. Configure URL Schemes

Add to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>GoogleSignIn</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

#### E. Initialize Google Sign-In

Add to your `AppDelegate.swift` or main app file:

```swift
import GoogleSignIn

func applicationDidFinishLaunching(_ notification: Notification) {
    // Configure Google Sign-In (automatic with GoogleService-Info.plist)
    GoogleSignInHelper.shared.configureGoogleSignIn()
}
```

### 3. Test the System

#### Development Mode

The system includes a "Mock Sign In" button in debug builds that allows you to test the UI without a backend:

```swift
#if DEBUG
// Mock sign in creates a demo user for testing
await authManager.mockSignIn()
#endif
```

#### Production Mode

1. Set up your backend API with the expected endpoints
2. Update the `baseURL` in `APIConfiguration`
3. Test with real credentials

## 🎯 Features Breakdown

### 🔒 Secure Storage

- Uses macOS Keychain for token storage
- Automatic token refresh
- Secure credential management

### 🎨 Professional UI

- Dark theme matching Kerlig's design
- Smooth animations and transitions
- Form validation with real-time feedback
- Loading states and error handling

### 🔄 State Management

- Real-time authentication state updates
- Automatic UI updates based on auth status
- Persistent login sessions

### 🌐 API Integration

- Comprehensive error handling
- Network retry logic
- Token expiration handling

## 📱 API Endpoints

Your backend should implement these endpoints:

### Registration

```
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "username": "testuser",
  "first_name": "Test",
  "last_name": "User"
}

Response: {
  "access_token": "jwt_token",
  "refresh_token": "refresh_token",
  "user": { user_object },
  "expires_in": 3600
}
```

### Login

```
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}

Response: {
  "access_token": "jwt_token",
  "refresh_token": "refresh_token",
  "user": { user_object },
  "expires_in": 3600
}
```

### Token Refresh

```
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "refresh_token"
}

Response: {
  "access_token": "new_jwt_token",
  "expires_in": 3600
}
```

### Google OAuth

```
POST /api/v1/auth/google
Content-Type: application/json

{
  "id_token": "google_id_token",
  "access_token": "google_access_token"
}

Response: {
  "access_token": "jwt_token",
  "refresh_token": "refresh_token",
  "user": { user_object },
  "expires_in": 3600
}
```

### Get Profile

```
GET /api/v1/auth/profile
Authorization: Bearer jwt_token

Response: { user_object }
```

## 🔧 Customization

### Colors and Styling

Update colors in `AuthView.swift`:

```swift
private let primaryBgColor = Color(hex: "#0A0A0B")
private let accentColor = Color(hex: "#007AFF")
// ... other colors
```

### Validation Rules

Modify validation in `AuthModels.swift`:

```swift
var isValidPassword: Bool {
    return password.count >= 8 &&
           // Add your custom password rules
}
```

### Error Messages

Customize error handling in `AuthManager.swift`:

```swift
private func handleGoogleSignInError(_ error: Error) -> String {
    // Add custom error message logic
}
```

## 🐛 Troubleshooting

### Common Issues

1. **Google Sign-In not working**

   - Check `GoogleService-Info.plist` is in project
   - Verify URL schemes in `Info.plist`
   - Ensure Google API is enabled

2. **Keychain errors**

   - Check app entitlements
   - Verify keychain access groups

3. **Network errors**
   - Verify API base URL
   - Check network permissions
   - Test with mock data first

### Debug Logging

The system includes comprehensive logging:

```
🔐 [AuthManager] - Authentication operations
🌐 [AuthNetwork] - Network requests
🔑 [KeychainHelper] - Keychain operations
```

## 🎉 You're All Set!

The authentication system is now integrated into your Task Management page. Users will see the login screen when they first access the page, and the full task management interface once authenticated.

## 🔧 Recent Fixes & Improvements

### ✅ Enhanced API Response Handling

The system now includes **flexible response parsing** to handle various API response formats:

- **Multiple token key formats**: `access_token`, `accessToken`, `token`
- **Flexible user data extraction**: Handles both nested user objects and flat responses
- **Fallback user creation**: Creates user objects even with minimal data
- **Enhanced error logging**: Full request/response debugging

### ✅ Improved Error Messages

- Detailed network request/response logging
- Better parsing error descriptions
- Flexible JSON structure handling
- Graceful degradation for missing fields

### ✅ Development Features

- Mock sign-in for testing without backend
- Comprehensive debug logging
- Response format validation
- Error recovery mechanisms

### 📝 API Response Format Support

Your API can return data in various formats, and the system will handle them automatically:

**Format 1 (Recommended):**

```json
{
  "access_token": "jwt_here",
  "refresh_token": "refresh_here",
  "user": { "id": "1", "email": "user@example.com", ... }
}
```

**Format 2 (Alternative):**

```json
{
  "accessToken": "jwt_here",
  "email": "user@example.com",
  "firstName": "John"
}
```

**Format 3 (Minimal):**

```json
{
  "token": "jwt_here",
  "id": "1",
  "email": "user@example.com"
}
```

The system will automatically detect and parse any of these formats!

### Next Steps

1. Set up your backend API
2. Configure Google Sign-In (optional)
3. Test with real users
4. Monitor authentication metrics

Happy coding! 🚀
