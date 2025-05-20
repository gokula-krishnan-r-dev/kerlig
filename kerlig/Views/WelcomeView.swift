import SwiftUI
import AppKit

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var logoScale: CGFloat = 0.6
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var featureOpacity: [Double] = [0, 0, 0]
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.8
    
    private let animationDelay: Double = 0.3
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "f4f6f8"), Color(hex: "e2e6ea")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo
                AppIconImage()
                    .frame(width: 120, height: 120)
                    .cornerRadius(25)
                    .scaleEffect(logoScale)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.top, 60)
                    .onAppear {
                        withAnimation(.spring(response: 0.6)) {
                            logoScale = 1.0
                        }
                    }
                
                // Title and subtitle
                VStack(spacing: 12) {
                    Text("Welcome to Kerlig!")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(Color(hex: "333333"))
                        .opacity(titleOpacity)
                        .padding(.top, 10)
                    
                    Text("Your AI writing assistant for any app on macOS")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "666666"))
                        .multilineTextAlignment(.center)
                        .opacity(subtitleOpacity)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8).delay(animationDelay)) {
                        titleOpacity = 1
                    }
                    withAnimation(.easeInOut(duration: 0.8).delay(animationDelay + 0.2)) {
                        subtitleOpacity = 1
                    }
                }
                
                // Features
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(
                        icon: "text.cursor",
                        title: "Smart Text Capture",
                        description: "Capture text from any app with a simple keyboard shortcut",
                        opacity: featureOpacity[0]
                    )
                    
                    FeatureRow(
                        icon: "sparkles",
                        title: "AI-Powered Assistance",
                        description: "Get spelling corrections, rewrites, and creative suggestions",
                        opacity: featureOpacity[1]
                    )
                    
                    FeatureRow(
                        icon: "app.connected.to.app.below.fill",
                        title: "Works Everywhere",
                        description: "Seamlessly integrates with all your favorite apps",
                        opacity: featureOpacity[2]
                    )
                }
                .padding(.horizontal, 40)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.7).delay(animationDelay + 0.5)) {
                        featureOpacity[0] = 1
                    }
                    withAnimation(.easeInOut(duration: 0.7).delay(animationDelay + 0.7)) {
                        featureOpacity[1] = 1
                    }
                    withAnimation(.easeInOut(duration: 0.7).delay(animationDelay + 0.9)) {
                        featureOpacity[2] = 1
                    }
                }
                
                // Get Started button
                Button(action: {
                    withAnimation {
//                        appState.currentOnboardingStep = .permissions
                    }
                }) {
                    Text("Let's Start!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: Color(hex: "845CEF").opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(buttonScale)
                .opacity(buttonOpacity)
                .padding(.top, 20)
                .padding(.bottom, 60)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.7).delay(animationDelay + 1.2)) {
                        buttonOpacity = 1
                    }
                    withAnimation(.spring(response: 0.6).delay(animationDelay + 1.2)) {
                        buttonScale = 1
                    }
                }
                .onHover { isHovered in
                    withAnimation(.spring(response: 0.3)) {
                        buttonScale = isHovered ? 1.05 : 1.0
                    }
                }
            }
            .frame(maxWidth: 600)
            .padding(.horizontal, 20)
        }
    }
}

// Custom view to display the app icon
struct AppIconImage: View {
    @State private var isPulsing = false
    
    var body: some View {
        Group {
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3").opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .scaleEffect(isPulsing ? 1.1 : 1.0)
                            .opacity(isPulsing ? 0.5 : 0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isPulsing
                            )
                    )
                    .onAppear {
                        isPulsing = true
                    }
            } else {
                // Fallback gradient icon
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("K")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                        
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3").opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                        .opacity(isPulsing ? 0.5 : 0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                }
                .onAppear {
                    isPulsing = true
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let opacity: Double
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "f0f2f5"))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "845CEF"))
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "333333"))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "666666"))
                    .lineSpacing(2)
            }
        }
        .opacity(opacity)
    }
}

// Helper for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
