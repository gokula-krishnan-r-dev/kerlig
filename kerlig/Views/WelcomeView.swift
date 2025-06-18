import SwiftUI
import AppKit

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var logoScale: CGFloat = 0.6
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.8
    @State private var selectedOption: ActionOption = .fixSpelling
    
    private let animationDelay: Double = 0.3
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo
                AppIconImage()
                    .frame(width: 60, height: 60)
                    .cornerRadius(25)
                    .scaleEffect(logoScale)
                    .shadow(color: Color.purple.opacity(0.3), radius: 15, x: 0, y: 5)
                    .padding(.top, 60)
                    .onAppear {
                        withAnimation(.spring(response: 0.6)) {
                            logoScale = 1.0
                        }
                    }
                
                // Title and subtitle
                VStack(spacing: 12) {
                    Text("Welcome to Kerlig!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.white)
                        .opacity(titleOpacity)
                        .padding(.top, 10)
                    
                    Text("Your AI writing assistant for any app on macOS")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                        .opacity(subtitleOpacity)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8).delay(animationDelay)) {
                        titleOpacity = 1
                    }
                    withAnimation(.easeInOut(duration: 0.8).delay(animationDelay + 0.2)) {
                        subtitleOpacity = 1
                    }
                }
                
                // add image here
                Image("demo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 800, height: 220)
                    .padding(.horizontal, 20)
                
                
                // Get Started button
                Button(action: {
                    withAnimation {
                       appState.currentOnboardingStep = .permissions
                    }
                }) {
                    Text("Let's start!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 82)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(buttonScale)
                .opacity(buttonOpacity)
                .padding(.top, 20)
                .padding(.bottom, 40)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.7).delay(animationDelay + 1.2)) {
                        buttonOpacity = 1
                    }
                    withAnimation(.spring(response: 0.6).delay(animationDelay + 1.2)) {
                        buttonScale = 1
                    }
                }
                
                // License agreement text
                Text("By continuing you agree to the terms of the software license agreement")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .opacity(0.7)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: 600)
            .padding(.horizontal, 20)
        }
    }
}



// Action options enum
enum ActionOption {
    case fixSpelling
    case improveWriting
    case translate
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

#Preview {
    WelcomeView()
        .environment(\.colorScheme, .dark)
}
