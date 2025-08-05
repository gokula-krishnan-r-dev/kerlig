//
//  AuthView.swift
//  kerlig
//
//  Created for authentication UI components
//

import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedTab: AuthTab = .register
    @State private var animateIn = false

    // Form states
    @State private var loginForm = LoginForm()
    @State private var registerForm = RegisterForm()
    @State private var phoneNumber = ""

    // UI states
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false

    enum AuthTab: String, CaseIterable {
        case login = "Sign In"
        case register = "Sign Up"
    }

    // Color palette
    private let primaryBgColor = Color(hex: "#0A0A0B")
    private let secondaryBgColor = Color(hex: "#1C1C1E")
    private let cardBgColor = Color(hex: "#2C2C2E")
    private let accentColor = Color(hex: "#007AFF")
    private let successColor = Color(hex: "#34C759")
    private let errorColor = Color(hex: "#FF3B30")

    private let accentGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#007AFF"), Color(hex: "#0056CC")]),
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        ZStack {
            // Background with pattern
            // backgroundGradient

            // Centered modal card
            authModalCard
                .opacity(animateIn ? 1 : 0)
                .scaleEffect(animateIn ? 1 : 0.9)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateIn)

            // Loading overlay
            if authManager.isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateIn = true
            }
        }
        .alert("Authentication Error", isPresented: .constant(authManager.errorMessage != nil)) {
            Button("OK") {
                authManager.clearError()
            }
        } message: {
            Text(authManager.errorMessage ?? "")
        }
    }

    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color(red: 0.05, green: 0.05, blue: 0.2),
                Color(red: 0.1, green: 0.05, blue: 0.3),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Auth Modal Card
    private var authModalCard: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Spacer()

                Button(action: {
                    // Handle close action
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Title
            VStack(spacing: 8) {
                Text("Create an account")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 16)
            }

            // Tab selector
            tabSelector
                .padding(.top, 24)

            // Form content
            ScrollView {
                VStack(spacing: 20) {
                    if selectedTab == .register {
                        registerFormView
                    } else {
                        loginFormView
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
            }

            // Footer
            footerSection
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .frame(width: 500, height: selectedTab == .register ? 710 : 600)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "#1C1C1E"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(AuthTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                        // Clear forms when switching tabs
                        if tab == .login {
                            registerForm = RegisterForm()
                        } else {
                            loginForm = LoginForm()
                        }
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundColor(selectedTab == tab ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == tab ? Color(hex: "#333333") : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#2C2C2E"))
        )
        .padding(.horizontal, 32)
    }

    // MARK: - Login Form

    private var loginFormView: some View {
        VStack(spacing: 16) {
            // Email field
            TextField("Enter your email", text: $loginForm.email)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(16)
                .background(Color(hex: "#2C2C2E"))
                .cornerRadius(8)

            // Password field
            SecureField("Enter your password", text: $loginForm.password)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(16)
                .background(Color(hex: "#2C2C2E"))
                .cornerRadius(8)

            // Sign in button
            Button(action: {
                Task {
                    await authManager.signIn(email: loginForm.email, password: loginForm.password)
                }
            }) {
                Text("Sign In")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(authManager.isLoading)
            .padding(.top, 8)

            // Divider with "OR SIGN IN WITH"
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)

                Text("OR SIGN IN WITH")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical, 8)

            // Social login buttons
            // Google button
            Button(action: {

                // TODO: Implement Google Sign-In
                Task {
                    await authManager.signInWithGoogle(idToken: "", accessToken: "")
                }
            }) {
                HStack {
                    Image("google")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(.leading, 8)
                        .padding(.trailing, 8)
                    Text("Login With Google")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.trailing, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(hex: "#2C2C2E"))
            .cornerRadius(8)
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Register Form

    private var registerFormView: some View {
        VStack(spacing: 16) {
            // Name fields in horizontal layout
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("John", text: $registerForm.firstName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(Color(hex: "#2C2C2E"))
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 6) {
                    TextField("Last name", text: $registerForm.lastName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(16)
                        .background(Color(hex: "#2C2C2E"))
                        .cornerRadius(8)
                }
            }

            // Email field
            TextField("Enter your email", text: $registerForm.email)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(16)
                .background(Color(hex: "#2C2C2E"))
                .cornerRadius(8)

            // password field
            SecureField("Enter your password", text: $registerForm.password)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(16)
                .background(Color(hex: "#2C2C2E"))
                .cornerRadius(8)

            // confirm password field
            SecureField("Confirm your password", text: $registerForm.confirmPassword)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(16)
                .background(Color(hex: "#2C2C2E"))
                .cornerRadius(8)
            // Create account button
            Button(action: {
                Task {
                    await authManager.register(form: registerForm)
                }
            }) {
                Text("Create an account")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(authManager.isLoading)
            .padding(.top, 8)

            // Divider with "OR SIGN IN WITH"
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)

                Text("OR SIGN IN WITH")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.vertical, 8)

            // Social login buttons
            // Google button
            Button(action: {

                // TODO: Implement Google Sign-In
            }) {
                HStack {
                    Image("google")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(.leading, 8)
                        .padding(.trailing, 8)
                    Text("Login With Google")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.trailing, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(hex: "#2C2C2E"))
            .cornerRadius(8)
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                    .scaleEffect(1.2)

                Text("Authenticating...")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        Text("By creating an account, you agree to our Terms & Service")
            .font(.system(size: 12))
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }

}

// MARK: - Form Field Component

struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let errorMessage: String?
    var isSecure: Bool = false
    var showPasswordToggle: Bool = false
    @Binding var showPassword: Bool

    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        errorMessage: String? = nil,
        isSecure: Bool = false,
        showPasswordToggle: Bool = false,
        showPassword: Binding<Bool> = .constant(false)
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.errorMessage = errorMessage
        self.isSecure = isSecure
        self.showPasswordToggle = showPasswordToggle
        self._showPassword = showPassword
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            HStack {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .autocorrectionDisabled(true)
                }

                if showPasswordToggle {
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        errorMessage != nil ? Color.red.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: 1)
            )

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }
}

// MARK: - Color Extension (Using existing Color extension from utilities)
// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    AuthView()
}
