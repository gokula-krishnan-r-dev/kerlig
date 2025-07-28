import SwiftUI
import AppKit

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var logoScale: CGFloat = 0.6
    @State private var contentOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.8
    @State private var imageOffset: CGFloat = 50
    @State private var selectedOption: ActionOption = .fixSpelling
    
    private let animationDelay: Double = 0.2
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic background gradient
                Color.kerligGradientBackground
                    .ignoresSafeArea()
                
                // Content
                VStack(spacing: 0) {
                    // Header section
                    VStack(spacing: 24) {
                        // App Icon with enhanced animation
                        AppIconImage()
                            .frame(width: 80, height: 80)
                            .scaleEffect(logoScale)
                            .onAppear {
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                                    logoScale = 1.0
                                }
                            }
                        
                        // Title section with improved typography
                        VStack(spacing: 16) {
                            Text("Welcome to Kerlig")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.kerligPrimaryText)
                                .multilineTextAlignment(.center)
                            
                            Text("Enhance your writing with AI across all macOS applications")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.kerligSecondaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .opacity(contentOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.0).delay(animationDelay)) {
                                contentOpacity = 1
                            }
                        }
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 40)
                    
                    Spacer(minLength: 40)
                    
                    // Demo image with enhanced presentation
                    VStack(spacing: 0) {
                        Image("demo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: min(800, geometry.size.width - 80))
                            .kerligCard(elevation: .medium)
                            .offset(y: imageOffset)
                            .opacity(contentOpacity)
                            .onAppear {
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(animationDelay + 0.3)) {
                                    imageOffset = 0
                                }
                            }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer(minLength: 40)
                    
                    // Action section
                    VStack(spacing: 24) {
                        // Get Started button with new style
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                appState.currentOnboardingStep = .permissions
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Get Started")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.kerligButtonText)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.kerligButtonBackground)
                                    .shadow(color: .kerligShadow, radius: 8, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(buttonScale)
                        .opacity(buttonOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.8).delay(animationDelay + 0.6)) {
                                buttonOpacity = 1
                            }
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay + 0.6)) {
                                buttonScale = 1
                            }
                        }
                        .onHover { isHovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                buttonScale = isHovering ? 1.05 : 1.0
                            }
                        }
                        
                        // Legal text with improved styling
                        Text("By continuing, you agree to our terms of service and privacy policy")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.kerligTertiaryText)
                            .multilineTextAlignment(.center)
                            .opacity(buttonOpacity)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Action options enum
enum ActionOption {
    case fixSpelling
    case improveWriting
    case translate
}

// Enhanced App Icon with modern design
struct AppIconImage: View {
    @State private var isPulsing = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        Group {
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                Color.kerligAccent.opacity(0.3),
                                lineWidth: 2
                            )
                            .scaleEffect(isPulsing ? 1.1 : 1.0)
                            .opacity(isPulsing ? 0.6 : 0.3)
                    )
                    .shadow(color: .kerligShadowElevated, radius: 12, x: 0, y: 6)
                    .onAppear {
                        withAnimation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                        ) {
                            isPulsing = true
                        }
                    }
            } else {
                // Enhanced fallback icon
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.kerligAccent,
                                    Color.kerligAccentSecondary
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // App letter with improved styling
                    Text("K")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    
                    // Animated border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            Color.white.opacity(0.3),
                            lineWidth: 2
                        )
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                        .opacity(isPulsing ? 0.6 : 0.3)
                }
                .shadow(color: .kerligShadowElevated, radius: 12, x: 0, y: 6)
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                    ) {
                        isPulsing = true
                    }
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppState())
        .frame(width: 800, height: 700)
}
