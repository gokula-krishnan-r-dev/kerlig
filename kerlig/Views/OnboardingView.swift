import SwiftUI


struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Namespace private var animation
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Glass effect overlay
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
                
                // Step title
                Text(titleForStep(appState.currentOnboardingStep))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    .padding(.top, 30)
                    .padding(.bottom, 10)
                    .matchedGeometryEffect(id: "title", in: animation)



                    Text(subTitleForStep(appState.currentOnboardingStep))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "666666"))
                        .padding(.bottom, 20)
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
                        appState.skipOnboarding()
                    }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "666666"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    // Next button
                    Button(action: {
                        withAnimation {
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
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: Color(hex: "845CEF").opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .padding()
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
            return "Choose Your AI Model"
        case .appOverview:
            return "How Kerlig Works"
        }
    }
    
    
    // Check if we're on the last step
    private var isLastStep: Bool {
        appState.currentOnboardingStep == OnboardingStep.allCases.last
    }
}

// MARK: - Permissions Step View
struct PermissionsStepView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAccessibilityPermission: Bool = false
    @State private var animateItems: Bool = false
    @State private var pulsateCircle: Bool = false
    
    var body: some View {
        VStack(spacing: 30) {
           
            VStack(spacing: 16) {
              //add image permission
              Image("permission")
                .resizable()
                .frame(width: 600, height: 160)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "666666"))
            }
                        // Permission status
            HStack(spacing: 15) {
                Circle()
                    .fill(hasAccessibilityPermission ? Color.green : Color(hex: "845CEF"))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: hasAccessibilityPermission ? "checkmark" : "arrowshape.turn.up.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(hasAccessibilityPermission ? "Accessibility Permission Granted" : "Accessibility Permission Required")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                    
                    Text(hasAccessibilityPermission ? "All set! You're ready to go." : "Click to open System Settings")
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "666666"))
                }
                
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.2 : 0.5),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 40)
            .offset(y: animateItems ? 0 : 20)
            .opacity(animateItems ? 1 : 0)
            .onTapGesture {
                if !hasAccessibilityPermission {
                    openAccessibilitySettings()
                }
            }
        }
        .onAppear {
            // Check current permission status
            checkAccessibilityPermission()
            
            // Animate items
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateItems = true
            }
            
            // Start pulsating animation
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulsateCircle = true
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
        VStack(spacing: 20) {
            Text("Select the AI model you'd like to use")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : Color(hex: "666666"))
                .padding(.top, 20)
            
            // Rotating neural network animation
            ZStack {
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
                            lineWidth: 1
                        )
                        .frame(width: 80 + CGFloat(i * 30), height: 80 + CGFloat(i * 30))
                        .rotationEffect(.degrees(rotationAngle + Double(i * 10)))
                }
                
                Image(systemName: "brain")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "845CEF"))
                    .symbolEffect(.pulse, options: .repeating)
            }
            .frame(height: 100)
            .padding(.bottom, 10)
            
            VStack(spacing: 15) {
                // Llama model
                ModelCard(
                    model: models[0],
                    isSelected: selectedModel == models[0].id,
                    colorScheme: colorScheme,
                    onSelect: {
                        withAnimation(.spring()) {
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
                        withAnimation(.spring()) {
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
                        withAnimation(.spring()) {
                            selectedModel = models[2].id
                            appState.aiModel = models[2].id
                        }
                    }
                )
                .offset(x: showGemini ? 0 : -200)
                .opacity(showGemini ? 1 : 0)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
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
        }
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
    
    var body: some View {
        VStack(spacing: 30) {
            // Video player placeholder
            ZStack {
                // Video thumbnail/placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? 
                          Color(hex: "25222F") : 
                          Color(hex: "f0f2f5"))
                    .overlay(
                        VStack {
                            if !isPlaying {
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
                                    }
                                    
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(Color(hex: "845CEF"))
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                                        .padding(.bottom, 10)
                                }
                                
                                Text("Watch how Kerlig works")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : Color(hex: "666666"))
                            } else {
                                // App demonstration animation
                                AppDemonstrationView(currentStep: $currentStep, colorScheme: colorScheme)
                            }
                        }
                    )
                    .onTapGesture {
                        withAnimation {
                            isPlaying = true
                        }
                    }
            }
            .frame(height: 300)
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .opacity(showAnimation ? 1 : 0)
            .offset(y: showAnimation ? 0 : 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "845CEF").opacity(0.3),
                                Color(hex: "7E45E3").opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .opacity(showAnimation ? 1 : 0)
            )
            
            // App description points
            VStack(alignment: .leading, spacing: 20) {
                FeaturePoint(
                    icon: "1.circle.fill",
                    title: "Select text in any app",
                    description: "Use the keyboard shortcut to select text you want to work with",
                    isActive: currentStep == 1,
                    colorScheme: colorScheme
                )
                
                FeaturePoint(
                    icon: "2.circle.fill",
                    title: "Choose your action",
                    description: "Choose how you want Kerlig to help with the selected text",
                    isActive: currentStep == 2,
                    colorScheme: colorScheme
                )
                
                FeaturePoint(
                    icon: "3.circle.fill",
                    title: "Get AI-powered results",
                    description: "Review and use the AI suggestions in your workflow",
                    isActive: currentStep == 3,
                    colorScheme: colorScheme
                )
                
                // Additional feature point
                FeaturePoint(
                    icon: "4.circle.fill",
                    title: "Customize your experience",
                    description: "Adjust settings to personalize how Kerlig works for you",
                    isActive: false,
                    colorScheme: colorScheme
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.2 : 0.5),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
            .padding(.horizontal, 40)
            .offset(y: showAnimation ? 0 : 20)
            .opacity(showAnimation ? 1 : 0)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showAnimation = true
            }
            
            // Animate sparkles
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.3)) {
                sparkleOpacity = 0.8
            }
            
            // Auto-advance through steps for demo
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
            withAnimation {
                currentStep = (currentStep % 3) + 1
            }
        }
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

struct ModelCard: View {
    let model: AIModel
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // Model icon
            ZStack {
                Circle()
                    .fill(isSelected ? 
                          LinearGradient(gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                          (colorScheme == .dark ? 
                           LinearGradient(gradient: Gradient(colors: [Color(hex: "2A2A2A"), Color(hex: "222222")]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                           LinearGradient(gradient: Gradient(colors: [Color(hex: "f8f8f8"), Color(hex: "f0f2f5")]), startPoint: .topLeading, endPoint: .bottomTrailing)))
                    .frame(width: 60, height: 60)
                
                Image(systemName: model.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : Color(hex: "845CEF"))
                    .symbolEffect(.bounce, options: .repeating.speed(0.5), value: isSelected)
            }
            
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
                    .frame(width: 24, height: 24)
                
                if isSelected {
                    Circle()
                        .fill(Color(hex: "845CEF"))
                        .frame(width: 16, height: 16)
                }
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(isSelected ? 0.3 : (colorScheme == .dark ? 0.1 : 0.3)),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isSelected ? 1.5 : 0.5
                )
        )
        .shadow(color: Color.black.opacity(isSelected ? 0.1 : 0.05), radius: isSelected ? 10 : 5, x: 0, y: isSelected ? 5 : 2)
        .scaleEffect(isSelected ? 1.02 : 1)
        .onTapGesture {
            onSelect()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// Feature point for app overview
struct FeaturePoint: View {
    let icon: String
    let title: String
    let description: String
    let isActive: Bool
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isActive ? Color(hex: "845CEF") : (colorScheme == .dark ? Color.white.opacity(0.5) : Color(hex: "999999")))
                

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
        .padding(.vertical, 10)
        .padding(.horizontal, isActive ? 15 : 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? 
                     (colorScheme == .dark ? Color(hex: "845CEF").opacity(0.15) : Color(hex: "845CEF").opacity(0.08)) : 
                     Color.clear)
        )
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

// App demonstration animation
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
                        removal: .opacity
                    ))
            }
            
            // Step 2: Action selection
            if currentStep == 2 {
                DemoStep2View(colorScheme: colorScheme)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            
            // Step 3: Results
            if currentStep == 3 {
                DemoStep3View(colorScheme: colorScheme)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentStep)
    }
}

// Step 1: Text selection demo
struct DemoStep1View: View {
    @State private var isTextSelected: Bool = false
    let colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            // Keyboard shortcut indicator
            if isTextSelected {
                HStack(spacing: 8) {
                    Text("⌘")
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                    
                    Text("Space")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                }
                .offset(y: 70)
            }
        }
        .onAppear {
            // Simulate text selection after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    isTextSelected = true
                }
            }
        }
    }
}

// Step 2: Action selection demo
struct DemoStep2View: View {
    @State private var showPanel: Bool = false
    @State private var selectedAction: Bool = false
    let colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            // Background app window (dimmed)
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color(hex: "1E1E1E").opacity(0.5) : Color.white.opacity(0.5))
                .frame(width: 280, height: 180)
                .overlay(
                    VStack(alignment: .leading, spacing: 10) {
                        // Window toolbar
                        HStack {
                            Circle()
                                .fill(Color.red.opacity(0.7))
                                .frame(width: 10, height: 10)
                            Circle()
                                .fill(Color.yellow.opacity(0.7))
                                .frame(width: 10, height: 10)
                            Circle()
                                .fill(Color.green.opacity(0.7))
                                .frame(width: 10, height: 10)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                        
                        // Content mockup (dimmed)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("This text needs improvement")
                                .font(.system(size: 12))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .cornerRadius(3)
                                .opacity(0.5)
                            
                            ForEach(0..<3) { _ in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                                    .frame(height: 10)
                                    .opacity(0.5)
                            }
                        }
                        .padding(.horizontal, 10)
                        
                        Spacer()
                    }
                )
            
            // Kerlig panel
            if showPanel {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .frame(width: 220, height: 140)
                    .overlay(
                        VStack(alignment: .leading, spacing: 10) {
                            // Text preview
                            Text("This text needs improvement")
                                .font(.system(size: 10))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "666666"))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color(hex: "f5f5f5"))
                                .cornerRadius(6)
                            
                            // Actions
                            HStack {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 12))
                                    .foregroundColor(selectedAction ? Color.white : Color(hex: "845CEF"))
                                
                                Text("Improve Writing")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(selectedAction ? Color.white : (colorScheme == .dark ? .white : Color(hex: "333333")))
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(selectedAction ? 
                                        LinearGradient(gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]), startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(gradient: Gradient(colors: [Color.clear, Color.clear]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(6)
                            
                            // Other actions (dimmed)
                            HStack {
                                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                                    .font(.system(size: 12))
                                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color(hex: "999999"))
                                
                                Text("Rewrite Completely")
                                    .font(.system(size: 12))
                                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color(hex: "666666"))
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .opacity(selectedAction ? 0.5 : 1)
                        }
                        .padding(10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.3),
                                        Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
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
                withAnimation {
                    selectedAction = true
                }
            }
        }
    }
}

// Step 3: Results demo
struct DemoStep3View: View {
    @State private var isTyping: Bool = false
    @State private var completedText: String = ""
    @State private var fullText: String = "This text has been improved with clear language and proper grammar."
    @State private var showCopyFeedback: Bool = false
    let colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            // Kerlig panel with results
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(width: 260, height: 160)
                .overlay(
                    VStack(alignment: .leading, spacing: 10) {
                        // Header
                        HStack {
                            Image(systemName: "wand.and.stars.inverse")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "845CEF"))
                                .symbolEffect(.pulse, options: .repeating, value: isTyping)
                            
                            Text("Improved Writing")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.green)
                        }
                        
                        Divider()
                            .background(colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.2))
                        
                        // AI generated result
                        VStack(alignment: .leading, spacing: 8) {
                            Text(completedText)
                                .font(.system(size: 13))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "333333"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if isTyping {
                                Text("|")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "845CEF"))
                                    .opacity(isTyping ? 1 : 0)
                                    .animation(Animation.easeInOut(duration: 0.6).repeatForever(), value: isTyping)
                            }
                        }
                        
                        Spacer()
                        
                        // Action buttons
                        HStack {
                            Button(action: {
                                withAnimation {
                                    showCopyFeedback = true
                                    
                                    // Reset the feedback after a delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation {
                                            showCopyFeedback = false
                                        }
                                    }
                                }
                            }) {
                                HStack(spacing: 4) {
                                    if showCopyFeedback {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(hex: "845CEF"))
                                    } else {
                                        Text("Copy")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color(hex: "845CEF"))
                                    }
                                }
                                .padding(.vertical, 5)
                                .padding(.horizontal, 12)
                                .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color(hex: "f5f5f5"))
                                .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Text("Apply")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 12)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color(hex: "845CEF"), Color(hex: "7E45E3")]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(15)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.2 : 0.3),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
        }
        .onAppear {
            // Simulate typing effect
            isTyping = true
            var currentIndex = 0
            
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                if currentIndex < fullText.count {
                    let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
                    completedText += String(fullText[index])
                    currentIndex += 1
                } else {
                    isTyping = false
                    timer.invalidate()
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

