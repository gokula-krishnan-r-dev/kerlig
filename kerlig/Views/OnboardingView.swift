import SwiftUI


struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Namespace private var animation
    @Environment(\.colorScheme) var colorScheme
    @State private var animateBackground = false
    
    var body: some View {
        ZStack {
            // Animated background
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "2A1E5C").opacity(0.7),
                    Color(hex: "0D0221")
                ]),
                center: .topLeading,
                startRadius: animateBackground ? 100 : 50,
                endRadius: 600
            )
            .ignoresSafeArea()
            .hueRotation(.degrees(animateBackground ? 10 : 0))
            .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateBackground)
            .onAppear {
                animateBackground = true
            }
            
            // Floating elements
            ZStack {
                // Decorative circles
                Circle()
                    .fill(Color(hex: "845CEF").opacity(0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .offset(x: -150, y: -200)
                
                Circle()
                    .fill(Color(hex: "7E45E3").opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 170, y: 200)
            }
            
            // Glass container
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                        Capsule()
                            .fill(step == appState.currentOnboardingStep ? 
                                  Color(hex: "845CEF") : 
                                  Color(hex: "845CEF").opacity(0.3))
                            .frame(width: step == appState.currentOnboardingStep ? 20 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: appState.currentOnboardingStep)
                    }
                }
                .padding(.top, 20)
                
                // Step title with animation
                Text(titleForStep(appState.currentOnboardingStep))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    .padding(.top, 30)
                    .padding(.bottom, 5)
                    .matchedGeometryEffect(id: "title", in: animation)
                    .transition(.opacity)

                Text(subTitleForStep(appState.currentOnboardingStep))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "666666"))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .matchedGeometryEffect(id: "subtitle", in: animation)
                
                // Current step view
                ZStack {
                    switch appState.currentOnboardingStep {
                    case .permissions:
                        PermissionsStepView()
                            .environmentObject(appState)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                )
                            )
                    case .modelSelection:
                        ModelSelectionStepView()
                            .environmentObject(appState)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                )
                            )
                    case .appOverview:
                        AppOverviewStepView()
                            .environmentObject(appState)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                )
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Navigation buttons
                HStack {
                    // Skip button
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            appState.skipOnboarding()
                        }
                    }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "666666"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.5)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Spacer()
                    
                    // Next button
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            appState.nextOnboardingStep()
                        }
                    }) {
                        HStack {
                            Text(isLastStep ? "Get Started" : "Next")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            if !isLastStep {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                // Shine effect
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .opacity(0.5)
                            }
                        )
                        .shadow(color: Color(hex: "845CEF").opacity(0.3), radius: 15, x: 0, y: 5)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .padding(20)
            .frame(maxWidth: 800)
        }
    }
    
    // Helper to get title for current step
    private func titleForStep(_ step: OnboardingStep) -> String {
        switch step {
        case .permissions:
            return "Accessibility Permission"
        case .modelSelection:
            return "Choose Your AI Model"
        case .appOverview:
            return "How Kerlig Works"
        }
    }

    //subTitleForStep
    private func subTitleForStep(_ step: OnboardingStep) -> String {
        switch step {
        case .permissions:
            return "These permissions are required to use Kerlig to be able to capture text from any app."
        case .modelSelection:
            return "Select the AI model that best fits your needs for the most accurate and helpful responses."
        case .appOverview:
            return "Learn how Kerlig can seamlessly integrate into your workflow to enhance productivity."
        }
    }
    
    
    // Check if we're on the last step
    private var isLastStep: Bool {
        appState.currentOnboardingStep == OnboardingStep.allCases.last
    }
}

// MARK: - Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Permissions Step View
struct PermissionsStepView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAccessibilityPermission: Bool = false
    @State private var animateItems: Bool = false
    @State private var pulsateCircle: Bool = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 40) {
            // Animated icon
            ZStack {
                // Outer circles
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "845CEF").opacity(0.7),
                                    Color(hex: "7E45E3").opacity(0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 120 + CGFloat(i * 30), height: 120 + CGFloat(i * 30))
                        .opacity(animateItems ? 0.6 : 0)
                        .rotationEffect(.degrees(rotationAngle + Double(i * 10)))
                }
                
                // Lock icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "845CEF").opacity(0.8),
                                    Color(hex: "7E45E3")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color(hex: "845CEF").opacity(0.5), radius: 15, x: 0, y: 5)
//                        .scaleEffect(pulsateCircle ? 1.05 : 1)
                    
                    Image(systemName: hasAccessibilityPermission ? "checkmark.shield.fill" : "lock.shield.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
//                        .symbolEffect(hasAccessibilityPermission ? .bounce.down.byLayer : .pulse, options: .repeating)
                }
                .offset(y: animateItems ? 0 : 30)
                .opacity(animateItems ? 1 : 0)
            }
            .frame(height: 200)
            
            // Permission card
            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    Circle()
                        .fill(hasAccessibilityPermission ? Color.green : Color(hex: "845CEF"))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: hasAccessibilityPermission ? "checkmark" : "arrowshape.turn.up.right")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: (hasAccessibilityPermission ? Color.green : Color(hex: "845CEF")).opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(hasAccessibilityPermission ? "Accessibility Permission Granted" : "Accessibility Permission Required")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                        
                        Text(hasAccessibilityPermission ? "All set! You're ready to go." : "Click to open System Settings")
                            .font(.system(size: 16))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "666666"))
                    }
                }
                
                if !hasAccessibilityPermission {
                    Button(action: {
                        openAccessibilitySettings()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                                .font(.system(size: 16))
                            Text("Open System Settings")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "845CEF").opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 10)
                }
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
            .offset(y: animateItems ? 0 : 30)
            .opacity(animateItems ? 1 : 0)
            .onTapGesture {
                if !hasAccessibilityPermission {
                    openAccessibilitySettings()
                }
            }
        }
        .padding(.horizontal, 40)
        .onAppear {
            // Check current permission status
            checkAccessibilityPermission()
            
            // Animate items
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateItems = true
            }
            
            // Start pulsating animation
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulsateCircle = true
            }
            
            // Start rotation animation
            withAnimation(Animation.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
    
    // Open system accessibility settings
    private func openAccessibilitySettings() {
        if #available(macOS 13.0, *) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        } else {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
        }
        
        // Schedule permission check after opening settings
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkAccessibilityPermission()
        }
    }
    
    // Check if app has accessibility permission
    private func checkAccessibilityPermission() {
        // This is a simplified check - in a real app, use a proper accessibility permission check
        let checkOptions = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: false]
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(checkOptions as CFDictionary)
    }
}

// MARK: - Model Selection Step View
struct ModelSelectionStepView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedModel: String = "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
    @State private var showLlama: Bool = false
    @State private var showGPT: Bool = false
    @State private var showGemini: Bool = false
    @State private var rotationAngle: Double = 0
    @State private var animateGlow: Bool = false
    
    let models = [
        AIModel(id: "@cf/meta/llama-3.3-70b-instruct-fp8-fast", name: "Llama 3", provider: "Meta AI", 
                description: "Powerful open model with great performance", 
                icon: "sparkles.square"),
        AIModel(id: "gpt-4o", name: "GPT-4", provider: "OpenAI", 
                description: "State-of-the-art language capabilities", 
                icon: "tornado"),
        AIModel(id: "gemini-pro", name: "Gemini Pro", provider: "Google", 
                description: "Fast and efficient text processing", 
                icon: "diamond")
    ]
    
    var body: some View {
        VStack(spacing: 25) {
            // Neural network animation
            ZStack {
                // Animated glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "845CEF").opacity(0.7),
                                Color(hex: "845CEF").opacity(0)
                            ]),
                            center: .center,
                            startRadius: animateGlow ? 50 : 30,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .opacity(animateGlow ? 0.8 : 0.4)
                
                // Rotating neural connections
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "845CEF").opacity(0.7),
                                    Color(hex: "7E45E3").opacity(0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 80 + CGFloat(i * 30), height: 80 + CGFloat(i * 30))
                        .rotationEffect(.degrees(rotationAngle + Double(i * 10)))
                }
                
                // Particles
                ForEach(0..<6) { i in
                    let angle = Double(i) * .pi / 3
                    let distance: CGFloat = 60
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4, height: 4)
                        .offset(
                            x: cos(angle + rotationAngle / 30) * distance,
                            y: sin(angle + rotationAngle / 30) * distance
                        )
                        .opacity(0.7)
                }
                
                // Brain icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "845CEF"))
                    .symbolEffect(.pulse.byLayer, options: .repeating)
            }
            .frame(height: 150)
            .padding(.bottom, 10)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Llama model
                    ModelCard(
                        model: models[0],
                        isSelected: selectedModel == models[0].id,
                        colorScheme: colorScheme,
                        onSelect: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedModel = models[0].id
                                appState.aiModel = models[0].id
                            }
                        }
                    )
                    .offset(x: showLlama ? 0 : -200)
                    .opacity(showLlama ? 1 : 0)
                    
                    // GPT-4 model
                    ModelCard(
                        model: models[1],
                        isSelected: selectedModel == models[1].id,
                        colorScheme: colorScheme,
                        onSelect: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedModel = models[1].id
                                appState.aiModel = models[1].id
                            }
                        }
                    )
                    .offset(x: showGPT ? 0 : -200)
                    .opacity(showGPT ? 1 : 0)
                    
                    // Gemini model
                    ModelCard(
                        model: models[2],
                        isSelected: selectedModel == models[2].id,
                        colorScheme: colorScheme,
                        onSelect: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedModel = models[2].id
                                appState.aiModel = models[2].id
                            }
                        }
                    )
                    .offset(x: showGemini ? 0 : -200)
                    .opacity(showGemini ? 1 : 0)
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: 300)
        }
        .padding(.horizontal, 20)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                    showLlama = true
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    showGPT = true
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                    showGemini = true
                }
            }
            
            // Set initial selected model from app state
            selectedModel = appState.aiModel
            
            // Start rotation animation
            withAnimation(Animation.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            
            // Start glow animation
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }
}

// Model card with enhanced design
struct ModelCard: View {
    let model: AIModel
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onSelect: () -> Void
    @State private var hovered: Bool = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Model icon with animated background
            ZStack {
                // Background
                Circle()
                    .fill(isSelected ? 
                          LinearGradient(gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                          (colorScheme == .dark ? 
                           LinearGradient(gradient: Gradient(colors: [Color(hex: "2A2A2A"), Color(hex: "222222")]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                           LinearGradient(gradient: Gradient(colors: [Color(hex: "f8f8f8"), Color(hex: "f0f2f5")]), startPoint: .topLeading, endPoint: .bottomTrailing)))
                    .frame(width: 60, height: 60)
                
                // Shine effect
                if isSelected {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .frame(width: 60, height: 60)
                        .blur(radius: 2)
                }
                
                // Icon
                Image(systemName: model.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : Color(hex: "845CEF"))
                    
            }
            .shadow(color: isSelected ? Color(hex: "845CEF").opacity(0.5) : Color.black.opacity(0.05), 
                    radius: isSelected ? 10 : 5, x: 0, y: isSelected ? 5 : 2)
            
            // Model info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    
                    Text("by \(model.provider)")
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : Color(hex: "999999"))
                }
                
                Text(model.description)
                    .font(.system(size: 14))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : Color(hex: "666666"))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Selection indicator
            ZStack {
                Circle()
                    .stroke(isSelected ? Color(hex: "845CEF") : (colorScheme == .dark ? Color.white.opacity(0.3) : Color(hex: "dddddd")), lineWidth: 2)
                    .frame(width: 26, height: 26)
                
                if isSelected {
                    Circle()
                        .fill(Color(hex: "845CEF"))
                        .frame(width: 18, height: 18)
                }
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(isSelected ? 0.5 : (colorScheme == .dark ? 0.2 : 0.4)),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isSelected ? 1.5 : 0.5
                )
        )
        .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0.05), radius: isSelected ? 15 : 5, x: 0, y: isSelected ? 8 : 2)
        .scaleEffect(isSelected ? 1.02 : (hovered ? 1.01 : 1))
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hovered = hovering
            }
        }
        .onTapGesture {
            onSelect()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - App Overview Step View
struct AppOverviewStepView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var isPlaying: Bool = false
    @State private var currentStep: Int = 1
    @State private var showAnimation: Bool = false
    @State private var sparkleOpacity: Double = 0
    @State private var animateFlow: Bool = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Video player / demo container
            ZStack {
                // Background with subtle animation
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? 
                          Color(hex: "25222F").opacity(0.7) : 
                          Color(hex: "f0f2f5").opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "845CEF").opacity(0.1),
                                        Color(hex: "7E45E3").opacity(0.05)
                                    ]),
                                    startPoint: animateFlow ? .topLeading : .bottomTrailing,
                                    endPoint: animateFlow ? .bottomTrailing : .topLeading
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "845CEF").opacity(0.5),
                                        Color(hex: "7E45E3").opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                
                // Content
                if !isPlaying {
                    // Play button state
                    VStack(spacing: 20) {
                        ZStack {
                            // Sparkle effects around the play button
                            ForEach(0..<8) { i in
                                let angle = Double(i) * .pi / 4
                                let distance: CGFloat = 50
                                
                                Image(systemName: "sparkle")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "845CEF"))
                                    .offset(
                                        x: cos(angle) * distance,
                                        y: sin(angle) * distance
                                    )
                                    .opacity(sparkleOpacity)
                                    .rotationEffect(.degrees(Double.random(in: -15...15)))
                            }
                            
                            // Play button with shine effect
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color(hex: "845CEF").opacity(0.5), radius: 15, x: 0, y: 5)
                                
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .center
                                    ))
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 2)
                                
                                Image(systemName: "play.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .offset(x: 2)
                            }
                            .scaleEffect(sparkleOpacity > 0.5 ? 1.05 : 1)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: sparkleOpacity)
                        }
                        
                        Text("Watch how Kerlig works")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : Color(hex: "666666"))
                    }
                } else {
                    // App demonstration animation
                    AppDemonstrationView(currentStep: $currentStep, colorScheme: colorScheme)
                }
            }
            .frame(height: 320)
            .padding(.horizontal, 30)
            .padding(.top, 10)
            .opacity(showAnimation ? 1 : 0)
            .offset(y: showAnimation ? 0 : 30)
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isPlaying = true
                }
            }
            
            // Feature steps with animated highlights
            VStack(alignment: .leading, spacing: 20) {
                // Section title
                Text("Key Features")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    .padding(.leading, 15)
                    .padding(.bottom, 5)
                    .opacity(showAnimation ? 1 : 0)
                    .offset(y: showAnimation ? 0 : 20)
                
                // Feature points
                VStack(spacing: 16) {
                    FeaturePoint(
                        icon: "1.circle.fill",
                        title: "Select text in any app",
                        description: "Use the keyboard shortcut to select text you want to work with",
                        isActive: currentStep == 1,
                        colorScheme: colorScheme
                    )
                    .offset(y: showAnimation ? 0 : 20)
                    .opacity(showAnimation ? 1 : 0)
                    
                    FeaturePoint(
                        icon: "2.circle.fill",
                        title: "Choose your action",
                        description: "Choose how you want Kerlig to help with the selected text",
                        isActive: currentStep == 2,
                        colorScheme: colorScheme
                    )
                    .offset(y: showAnimation ? 0 : 30)
                    .opacity(showAnimation ? 1 : 0)
                    
                    FeaturePoint(
                        icon: "3.circle.fill",
                        title: "Get AI-powered results",
                        description: "Review and use the AI suggestions in your workflow",
                        isActive: currentStep == 3,
                        colorScheme: colorScheme
                    )
                    .offset(y: showAnimation ? 0 : 40)
                    .opacity(showAnimation ? 1 : 0)
                    
                    // Additional feature point
                    FeaturePoint(
                        icon: "4.circle.fill",
                        title: "Customize your experience",
                        description: "Adjust settings to personalize how Kerlig works for you",
                        isActive: false,
                        colorScheme: colorScheme
                    )
                    .offset(y: showAnimation ? 0 : 50)
                    .opacity(showAnimation ? 1 : 0)
                }
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.3 : 0.5),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .onAppear {
            // Show animation elements
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                showAnimation = true
            }
            
            // Animate sparkles
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.3)) {
                sparkleOpacity = 0.8
            }
            
            // Animate background flow
            withAnimation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animateFlow = true
            }
            
            // Auto-advance through steps for demo if playing
            if isPlaying {
                startStepAnimation()
            }
        }
        .onChange(of: isPlaying) { newValue in
            if newValue {
                startStepAnimation()
            }
        }
    }
    
    private func startStepAnimation() {
        // Auto-advance through demonstration steps
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                currentStep = (currentStep % 3) + 1
            }
        }
    }
}

// Enhanced feature point with better animations
struct FeaturePoint: View {
    let icon: String
    let title: String
    let description: String
    let isActive: Bool
    let colorScheme: ColorScheme
    @State private var hovered: Bool = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon with animated background
            ZStack {
                Circle()
                    .fill(isActive ?
                         LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                         ) :
                         LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color(hex: "2A2A2A").opacity(0.5) : Color(hex: "f0f2f5").opacity(0.7),
                                colorScheme == .dark ? Color(hex: "2A2A2A").opacity(0.5) : Color(hex: "f0f2f5").opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                         ))
                    .frame(width: 46, height: 46)
                    .shadow(color: isActive ? Color(hex: "845CEF").opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isActive ? .white : (colorScheme == .dark ? Color.white.opacity(0.5) : Color(hex: "999999")))
//                    .symbolEffect(isActive ? .bounce.down : .none)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isActive ? 
                                    (colorScheme == .dark ? .white : Color(hex: "333333")) : 
                                    (colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "666666")))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : Color(hex: "666666"))
                    .opacity(isActive ? 1 : 0.7)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isActive ? 
                     (colorScheme == .dark ? Color(hex: "845CEF").opacity(0.15) : Color(hex: "845CEF").opacity(0.08)) : 
                     (hovered ? (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.02)) : Color.clear))
        )
        .scaleEffect(hovered && !isActive ? 1.01 : 1)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hovered = hovering
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

// MARK: - Helper Views

// AI Model card
struct AIModel: Identifiable {
    let id: String
    let name: String
    let provider: String
    let description: String
    let icon: String
}

// Enhanced App demonstration animation
struct AppDemonstrationView: View {
    @Binding var currentStep: Int
    let colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            // Step 1: Text selection
            if currentStep == 1 {
                DemoStep1View(colorScheme: colorScheme)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
            }
            
            // Step 2: Action selection
            if currentStep == 2 {
                DemoStep2View(colorScheme: colorScheme)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
            }
            
            // Step 3: Results
            if currentStep == 3 {
                DemoStep3View(colorScheme: colorScheme)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStep)
    }
}

// Step 1: Enhanced text selection demo
struct DemoStep1View: View {
    @State private var isTextSelected: Bool = false
    @State private var cursorAnimation: Bool = false
    @State private var showKeyboard: Bool = false
    let colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            // Background app window mockup
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(hex: "1E1E1E").opacity(0.7) : Color.white.opacity(0.8))
                .overlay(
                    VStack(alignment: .leading, spacing: 10) {
                        // Window toolbar
                        HStack {
                            Circle()
                                .fill(Color.red.opacity(0.8))
                                .frame(width: 12, height: 12)
                            Circle()
                                .fill(Color.yellow.opacity(0.8))
                                .frame(width: 12, height: 12)
                            Circle()
                                .fill(Color.green.opacity(0.8))
                                .frame(width: 12, height: 12)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                        
                        // Content mockup
                        VStack(alignment: .leading, spacing: 10) {
                            // Title
                            RoundedRectangle(cornerRadius: 3)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                                .frame(width: 180, height: 14)
                                
                            // Text content with highlight
                            HStack(spacing: 0) {
                                Text("This text needs ")
                                    .font(.system(size: 14))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                
                                Text("improvement")
                                    .font(.system(size: 14))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .padding(.horizontal, 4)
                                    .background(
                                        isTextSelected ? 
                                            Color(hex: "845CEF").opacity(0.3) : 
                                            Color.clear
                                    )
                                    .cornerRadius(3)
                                
                                if cursorAnimation && !isTextSelected {
                                    Rectangle()
                                        .fill(Color(hex: "845CEF"))
                                        .frame(width: 2, height: 16)
                                        .opacity(cursorAnimation ? 1 : 0)
                                }
                            }
                            
                            // Paragraph mockup
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(0..<3) { _ in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                                        .frame(height: 10)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        
                        Spacer()
                    }
                )
                .frame(width: 280, height: 200)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            // Keyboard shortcut indicator
            if showKeyboard {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Command key
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0.2)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            Text("⌘")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                        }
                        .frame(width: 36, height: 36)
                        
                        // Space key
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0.2)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            Text("Space")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                        }
                        .frame(width: 80, height: 36)
                    }
                    .offset(y: -50)
                }
            }
        }
        .onAppear {
            // Animate cursor blinking
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                cursorAnimation = true
            }
            
            // Simulate text selection after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isTextSelected = true
                }
                
                // Show keyboard shortcut
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showKeyboard = true
                    }
                }
            }
        }
    }
}

// Step 2: Enhanced action selection demo
struct DemoStep2View: View {
    @State private var showPanel: Bool = false
    @State private var selectedAction: Bool = false
    @State private var animateShine: Bool = false
    let colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            // Background app window
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(hex: "1E1E1E").opacity(0.5) : Color.white.opacity(0.5))
                .frame(width: 280, height: 200)
                .overlay(
                    VStack(alignment: .leading, spacing: 10) {
                        // Window toolbar
                        HStack {
                            Circle()
                                .fill(Color.red.opacity(0.7))
                                .frame(width: 12, height: 12)
                            Circle()
                                .fill(Color.yellow.opacity(0.7))
                                .frame(width: 12, height: 12)
                            Circle()
                                .fill(Color.green.opacity(0.7))
                                .frame(width: 12, height: 12)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                        
                        // Content mockup (dimmed)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("This text needs improvement")
                                .font(.system(size: 14))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(hex: "845CEF").opacity(0.3))
                                .cornerRadius(3)
                                .opacity(0.5)
                            
                            ForEach(0..<3) { _ in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                                    .frame(height: 10)
                                    .opacity(0.5)
                            }
                        }
                        .padding(.horizontal, 12)
                        
                        Spacer()
                    }
                )
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                .blur(radius: showPanel ? 1 : 0)
            
            // Kerlig panel
            if showPanel {
                VStack(spacing: 0) {
                    // Panel header
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "845CEF"))
                        
                        Text("Kerlig")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)),
                        alignment: .bottom
                    )
                    
                    // Text preview
                    Text("This text needs improvement")
                        .font(.system(size: 12))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : Color(hex: "666666"))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color(hex: "f5f5f5").opacity(0.8))
                    
                    // Actions
                    VStack(spacing: 2) {
                        // Improve Writing action
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 14))
                                .foregroundColor(selectedAction ? Color.white : Color(hex: "845CEF"))
                            
                            Text("Improve Writing")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedAction ? Color.white : (colorScheme == .dark ? .white : Color(hex: "333333")))
                            
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .background(
                            ZStack {
                                if selectedAction {
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    
                                    // Animated shine effect
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 20)
                                        .blur(radius: 5)
                                        .rotationEffect(.degrees(70))
                                        .offset(x: animateShine ? 230 : -50)
                                }
                            }
                        )
                        
                        // Rewrite action (dimmed)
                        HStack {
                            Image(systemName: "rectangle.and.pencil.and.ellipsis")
                                .font(.system(size: 14))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color(hex: "999999"))
                            
                            Text("Rewrite Completely")
                                .font(.system(size: 14))
                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color(hex: "666666"))
                            
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .opacity(selectedAction ? 0.5 : 1)
                    }
                }
                .frame(width: 220)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.3 : 0.5),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                .offset(y: -10)
            }
        }
        .onAppear {
            // Simulate panel appearing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showPanel = true
                }
            }
            
            // Simulate option selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    selectedAction = true
                }
                
                // Animate shine effect
                withAnimation(Animation.easeInOut(duration: 1).delay(0.2)) {
                    animateShine = true
                }
            }
        }
    }
}

// Step 3: Enhanced results demo
struct DemoStep3View: View {
    @State private var isTyping: Bool = false
    @State private var typingProgress: CGFloat = 0
    @State private var completedText: String = ""
    @State private var fullText: String = "This text has been improved with clear language and proper grammar."
    @State private var showCopyFeedback: Bool = false
    @State private var animatePulse: Bool = false
    let colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            // Kerlig panel with results
            VStack(spacing: 0) {
                // Header with animation
                HStack {
                    Image(systemName: "wand.and.stars.inverse")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "845CEF"))
//                        .symbolEffect(isTyping ? .pulse : .none, options: .repeating)
                    
                    Text("Improved Writing")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    
                    Spacer()
                    
                    // Success indicator
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 22, height: 22)
                            .opacity(animatePulse ? 0.7 : 1)
                            .scaleEffect(animatePulse ? 1.2 : 1)
                            .animation(
                                Animation.easeInOut(duration: 1)
                                    .repeatCount(3, autoreverses: true),
                                value: animatePulse
                            )
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)),
                    alignment: .bottom
                )
                
                // AI generated result with typing animation
                VStack(alignment: .leading, spacing: 10) {
                    ZStack(alignment: .leading) {
                        // Background placeholder
                        Text(fullText)
                            .font(.system(size: 14))
                            .foregroundColor(.clear)
                            .padding(1) // Ensure consistent height
                        
                        // Animated text
                        Text(completedText)
                            .font(.system(size: 14))
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                        
                        // Cursor
                        if isTyping {
                            Rectangle()
                                .fill(Color(hex: "845CEF"))
                                .frame(width: 2, height: 16)
                                .offset(x: 1)
                                .opacity(isTyping ? 1 : 0)
                                .animation(Animation.easeInOut(duration: 0.6).repeatForever(), value: isTyping)
                        }
                    }
                    
                    // Progress indicator
                    if isTyping {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background track
                                Rectangle()
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                                    .frame(height: 2)
                                    .cornerRadius(1)
                                
                                // Progress fill
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * typingProgress, height: 2)
                                    .cornerRadius(1)
                            }
                        }
                        .frame(height: 2)
                    }
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                
                // Action buttons
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            showCopyFeedback = true
                            
                            // Reset the feedback after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    showCopyFeedback = false
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            if showCopyFeedback {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "845CEF"))
                            } else {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "845CEF"))
                                
                                Text("Copy")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(hex: "845CEF"))
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color(hex: "f5f5f5"))
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Spacer()
                    
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                            
                            Text("Apply")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: Color(hex: "845CEF").opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(15)
            }
            .frame(width: 270)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.3 : 0.5),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
        .onAppear {
            // Start animation sequence
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTyping = true
                
                // Animate completion badge
                withAnimation {
                    animatePulse = true
                }
                
                // Simulate typing effect
                var currentIndex = 0
                let totalCharacters = fullText.count
                
                Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                    if currentIndex < totalCharacters {
                        let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
                        completedText += String(fullText[index])
                        currentIndex += 1
                        
                        // Update progress
                        withAnimation {
                            typingProgress = CGFloat(currentIndex) / CGFloat(totalCharacters)
                        }
                    } else {
                        isTyping = false
                        timer.invalidate()
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark) // Preview in dark mode
}

