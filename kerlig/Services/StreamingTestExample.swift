import SwiftUI
import Foundation

// MARK: - Streaming Test Example
/**
 This example demonstrates how the streaming API integration works with real-time updates
 
 ## API Response Format:
 ```
 data: {"response": "It", "tool_calls": [], "p": "abdefghijklmnoprstuv"}
 data: {"response": " seems like you", "tool_calls": [], "p": "abdefghijklmn"}  
 data: {"response": "'re", "tool_calls": [], "p": "abdefghijklmnoprstuv"}
 data: [DONE]
 ```
 
 ## Key Features:
 - Real-time text accumulation as chunks arrive
 - Progress tracking based on 'p' field length  
 - Professional UI updates with typing effects
 - Connection state management
 - Error handling and cancellation support
 
 ## Implementation Highlights:
 1. **Streaming Delegate**: Processes Server-Sent Events in real-time
 2. **AppState Management**: Handles state updates and UI synchronization  
 3. **Typing Effect**: Smooth character-by-character display
 4. **Progress Tracking**: Visual feedback during streaming
 5. **Professional UI**: Clean, responsive design with indicators
 */

struct StreamingTestView: View {
    @StateObject private var appState = AppState()
    @State private var aiService: AIService?
    @State private var testPrompt = "Explain what middleware is in Node.js"
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("🚀 AI Streaming Test")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Real-time streaming demonstration with professional UI")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Input Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Test Prompt:")
                    .font(.headline)
                
                TextField("Enter your test prompt", text: $testPrompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 40)
                
                HStack {
                    Button("🎯 Start Streaming Test") {
                        startStreamingTest()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(appState.isStreaming)
                    
                    if appState.isStreaming {
                        Button("❌ Cancel") {
                            aiService?.cancelStreaming()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Status Section
            StreamingStatusView()
                .environmentObject(appState)
            
            // Response Section
            StreamingResponseView()
                .environmentObject(appState)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: 600, maxHeight: 800)
        .onAppear {
            setupAIService()
        }
    }
    
    private func setupAIService() {
        aiService = AIService(appState: appState)
    }
    
    private func startStreamingTest() {
        guard let aiService = aiService else { return }
        
        print("🎬 Starting streaming test with prompt: '\(testPrompt)'")
        
        aiService.generateStreamingResponse(
            prompt: testPrompt,
            systemPrompt: "You are a helpful assistant that provides clear, detailed explanations.",
            model: "llama-3.3-70b-instruct",
            completion: { result in
                switch result {
                case .success:
                    print("✅ Streaming test completed successfully")
                case .failure(let error):
                    print("❌ Streaming test failed: \(error.localizedDescription)")
                }
            }
        )
    }
}

// MARK: - Status View
struct StreamingStatusView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Streaming Status")
                .font(.headline)
            
            HStack {
                // Connection Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    
                    Text(appState.connectionState.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Progress
                if appState.streamingProgress > 0 {
                    HStack(spacing: 8) {
                        Text("\(Int(appState.streamingProgress * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                        
                        ProgressView(value: appState.streamingProgress)
                            .frame(width: 100)
                    }
                }
            }
            
            // Token Information
            if appState.actualTokens > 0 {
                HStack {
                    Text("Tokens: \(appState.actualTokens)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if appState.isTyping {
                        HStack(spacing: 4) {
                            Text("Typing")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            // Animated typing dots
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 4, height: 4)
                                    .scaleEffect(appState.isTyping ? 1.0 : 0.5)
                                    .animation(
                                        .easeInOut(duration: 0.6)
                                            .repeatForever()
                                            .delay(Double(index) * 0.2),
                                        value: appState.isTyping
                                    )
                            }
                        }
                    }
                }
            }
            
            // Error Display
            if let error = appState.streamingError {
                Text("❌ Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch appState.connectionState {
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .connected, .streaming:
            return .blue
        case .completed:
            return .green
        case .error:
            return .red
        case .cancelled:
            return .yellow
        }
    }
}

// MARK: - Response View
struct StreamingResponseView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💬 AI Response")
                    .font(.headline)
                
                Spacer()
                
                if !appState.displayedResponse.isEmpty {
                    Text("\(appState.displayedResponse.count) chars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if appState.displayedResponse.isEmpty && !appState.isStreaming {
                        // Empty state
                        VStack(spacing: 12) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.5))
                            
                            Text("No response yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Response text
                        Text(appState.displayedResponse)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        
                        // Typing cursor
                        if appState.isTyping {
                            HStack {
                                Spacer()
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: 2, height: 20)
                                    .opacity(appState.isTyping ? 1 : 0)
                                    .animation(
                                        .easeInOut(duration: 0.8)
                                            .repeatForever(autoreverses: true),
                                        value: appState.isTyping
                                    )
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .frame(minHeight: 150)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct StreamingTestView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingTestView()
    }
}

// MARK: - Usage Instructions
/**
 ## How to Test:
 
 1. **Add to your SwiftUI view hierarchy:**
 ```swift
 NavigationView {
     StreamingTestView()
         .navigationTitle("Streaming Test")
 }
 ```
 
 2. **Or create a dedicated test window:**
 ```swift
 let testWindow = NSWindow(
     contentRect: NSRect(x: 0, y: 0, width: 700, height: 900),
     styleMask: [.titled, .closable, .resizable],
     backing: .buffered,
     defer: false
 )
 testWindow.contentView = NSHostingView(rootView: StreamingTestView())
 testWindow.center()
 testWindow.makeKeyAndOrderFront(nil)
 ```
 
 3. **Test the streaming functionality:**
 - Enter a prompt in the text field
 - Click "Start Streaming Test"
 - Watch real-time updates as response chunks arrive
 - Monitor connection status and progress
 - Test cancellation functionality
 
 ## Expected Behavior:
 - Status changes: Disconnected → Connecting → Connected → Streaming → Completed
 - Real-time text accumulation with typing effect
 - Progress bar updates based on API response
 - Token counting and display
 - Professional error handling
 - Smooth UI animations and transitions
 */ 