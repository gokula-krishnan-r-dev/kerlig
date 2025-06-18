import SwiftUI
import Combine

// MARK: - Streaming AI Service Usage Example

/**
 * This example demonstrates how to use the new streaming AI service
 * with real-time response updates in SwiftUI.
 */

struct StreamingExample: View {
    @StateObject private var appState = AppState()
    @State private var aiService: AIService?
    @State private var userInput = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Streaming AI Service Demo")
                .font(.title)
                .fontWeight(.bold)
            
            // Input Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter your question:")
                    .font(.headline)
                
                TextEditor(text: $userInput)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Start Streaming") {
                    startStreamingDemo()
                }
                .disabled(userInput.isEmpty || appState.isStreaming)
                .buttonStyle(.borderedProminent)
                
                Button("Simulate Demo") {
                    simulateStreamingDemo()
                }
                .disabled(userInput.isEmpty || appState.isStreaming)
                .buttonStyle(.bordered)
                
                Button("Cancel") {
                    cancelStreaming()
                }
                .disabled(!appState.isStreaming)
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            
            // Status Display
            statusView
            
            // Response Display
            responseDisplayView
        }
        .padding()
        .onAppear {
            setupAIService()
        }
    }
    
    // MARK: - Setup
    
    private func setupAIService() {
        aiService = AIService(appState: appState)
    }
    
    // MARK: - Streaming Actions
    
    private func startStreamingDemo() {
        guard let aiService = aiService else { return }
        
        // Clear previous responses
        appState.resetStreamingState()
        
        // Start streaming with the AI service
        aiService.generateStreamingResponse(
            prompt: userInput,
            systemPrompt: "You are a helpful assistant. Provide detailed and informative responses.",
            model: "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
        ) { result in
            switch result {
            case .success:
                print("Streaming completed successfully")
            case .failure(let error):
                print("Streaming failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func simulateStreamingDemo() {
        guard let aiService = aiService else { return }
        
        // Clear previous responses
        appState.resetStreamingState()
        
        // Simulate streaming response
        aiService.simulateStreamingResponse(
            text: userInput,
            action: "improvewriting"
        ) { result in
            switch result {
            case .success:
                print("Simulation completed successfully")
            case .failure(let error):
                print("Simulation failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func cancelStreaming() {
        aiService?.cancelStreaming()
    }
    
    // MARK: - UI Components
    
    private var statusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)
            
            HStack {
                Text("Connection:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(appState.connectionState.rawValue)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
            }
            
            if appState.isStreaming {
                HStack {
                    Text("Progress:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(appState.streamingProgress * 100))%")
                        .fontWeight(.medium)
                }
                
                ProgressView(value: appState.streamingProgress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            
            if let error = appState.streamingError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var responseDisplayView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Response")
                    .font(.headline)
                
                Spacer()
                
                if appState.isTyping {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 4, height: 4)
                        }
                        Text("Typing...").font(.caption)
                    }
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if !appState.displayedResponse.isEmpty {
                        Text(appState.displayedResponse)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .animation(.easeOut(duration: 0.1), value: appState.displayedResponse)
                    } else if appState.isStreaming {
                        Text("Waiting for response...")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Text("No response yet. Click 'Start Streaming' to begin.")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .frame(height: 200)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var statusColor: Color {
        switch appState.connectionState {
        case .connected, .streaming:
            return .green
        case .completed:
            return .blue
        case .error, .cancelled:
            return .red
        case .connecting:
            return .orange
        case .disconnected:
            return .gray
        }
    }
}

// MARK: - Preview

struct StreamingExample_Previews: PreviewProvider {
    static var previews: some View {
        StreamingExample()
    }
}

// MARK: - Usage Documentation

/**
 # Streaming AI Service Usage Guide
 
 ## Overview
 The new streaming AI service provides real-time response generation with professional state management.
 
 ## Key Features
 - **Real-time streaming**: Responses appear as they're generated
 - **Professional state management**: Comprehensive connection and error handling
 - **Typing effects**: Smooth character-by-character display
 - **Progress tracking**: Visual progress indicators
 - **Cancellation support**: Stop streaming at any time
 - **Error handling**: Robust error recovery
 
 ## Basic Usage
 
 ### 1. Setup AIService with AppState
 ```swift
 @StateObject private var appState = AppState()
 private var aiService: AIService?
 
 private func setupAIService() {
     aiService = AIService(appState: appState)
 }
 ```
 
 ### 2. Start Streaming
 ```swift
 aiService?.generateStreamingResponse(
     prompt: "Your question here",
     systemPrompt: "You are a helpful assistant",
     model: "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
 ) { result in
     switch result {
     case .success:
         print("Streaming completed")
     case .failure(let error):
         print("Error: \(error)")
     }
 }
 ```
 
 ### 3. Monitor State
 ```swift
 // Connection state
 appState.connectionState // .connecting, .streaming, .completed, etc.
 
 // Streaming content
 appState.displayedResponse // Real-time response text
 appState.isStreaming // True while streaming
 appState.streamingProgress // Progress 0.0 to 1.0
 
 // Error handling
 appState.streamingError // Error message if any
 ```
 
 ### 4. UI Integration
 ```swift
 // Display streaming response
 Text(appState.displayedResponse)
     .animation(.easeOut(duration: 0.1), value: appState.displayedResponse)
 
 // Show streaming indicator
 if appState.isStreaming {
     ProgressView(value: appState.streamingProgress)
         .progressViewStyle(LinearProgressViewStyle())
 }
 ```
 
 ## Advanced Features
 
 ### Cancel Streaming
 ```swift
 aiService?.cancelStreaming()
 ```
 
 ### Simulate Streaming (for testing)
 ```swift
 aiService?.simulateStreamingResponse(
     text: "Test input",
     action: "improvewriting"
 ) { result in
     // Handle result
 }
 ```
 
 ### File Processing with Streaming
 ```swift
 aiService?.generateStreamingResponse(
     prompt: "Analyze this file: /path/to/file.pdf",
     systemPrompt: "Analyze the file content",
     model: "gpt-4",
     type: "file"
 ) { result in
     // Handle result
 }
 ```
 
 ## Error Handling
 
 The service provides comprehensive error handling:
 - Network errors
 - API errors
 - Parsing errors
 - Connection timeouts
 - Cancellation handling
 
 ## State Management
 
 The AppState class manages all streaming-related state:
 - Connection status
 - Response content
 - Error states
 - Progress tracking
 - Typing effects
 
 This ensures a smooth, professional user experience with real-time updates.
 */ 