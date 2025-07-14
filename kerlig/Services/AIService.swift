import Combine
import Foundation
import SwiftUI
import os.log

// Import specific model files as needed
// This approach allows us to access the AIAction type that's defined in the project
// without causing redeclaration issues

// Simple Logger utility
class Logger {
  enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
  }

  static let shared = Logger()
  private let osLog = OSLog(
    subsystem: Bundle.main.bundleIdentifier ?? "com.streamline", category: "AIService")
  private var isDebugEnabled = true

  func log(
    _ message: String, level: LogLevel = .info, file: String = #file, function: String = #function,
    line: Int = #line
  ) {
    let fileName = (file as NSString).lastPathComponent
    let logMessage = "[\(level.rawValue)] [\(fileName):\(line) \(function)] \(message)"

    if isDebugEnabled || level != .debug {
      switch level {
      case .debug:
        os_log("%{public}@", log: osLog, type: .debug, logMessage)
      case .info:
        os_log("%{public}@", log: osLog, type: .info, logMessage)
      case .warning:
        os_log("%{public}@", log: osLog, type: .default, logMessage)
      case .error, .critical:
        os_log("%{public}@", log: osLog, type: .error, logMessage)
      }

      #if DEBUG
        print(logMessage)
      #endif
    }
  }
}

// Remove unneeded typealias that references AIAction
#if !IMPORTED_AIACTION
  private enum AIActionTemp {
    case fixSpellingGrammar
    case improveWriting
    case translate
    case makeShorter

    var systemPrompt: String {
      switch self {
      case .fixSpellingGrammar: return "Fix the spelling and grammar errors"
      case .improveWriting: return "Improve the writing quality"
      case .translate: return "Translate the text appropriately"
      case .makeShorter: return "Make the text more concise"
      }
    }
  }
#endif

class AIService {
  private let baseURL = "https://auto-comment.gokulakrishnanr812-492.workers.dev/"  // Streaming endpoint
  private let logger = Logger.shared
  private let geminiVisionService = GeminiVisionService()
  private var streamingTask: URLSessionDataTask?
  
  // Weak reference to AppState for streaming updates
  weak var appState: AppState?
  
  init(appState: AppState? = nil) {
    self.appState = appState
  }

  // Define actions directly in this class to avoid conflicts
  enum ActionType: String {
    case fixSpellingGrammar = "fixSpellingGrammar"
    case improveWriting = "improveWriting"
    case translate = "translate"
    case makeShorter = "makeShorter"
    case summarize = "summarize"
    case analyzeFile = "analyzeFile"  // Add file analysis action
    case analyzeImage = "analyzeImage"  // Add image analysis action

    // Default case for when the conversion fails
    static var defaultAction: ActionType {
      return .improveWriting
    }

    var systemPrompt: String {
      switch self {
      case .fixSpellingGrammar:
        return "Fix the spelling and grammar in the following text, without changing the meaning:"
      case .improveWriting:
        return
          "Improve the writing quality of the following text, making it clearer and more engaging:"
      case .translate:
        return
          "Translate the following text to English (or if it's already in English, translate to French):"
      case .makeShorter:
        return "Make the following text shorter and more concise, without losing the key points:"
      case .summarize:
        return "Summarize the following text, capturing the key points:"
      case .analyzeFile:
        return "Analyze the following file details and provide insights:"
      case .analyzeImage:
        return "Describe what you see in this image in detail:"
      }
    }
  }


  func aiEnhancePrompt(_ prompt: String) -> String {
    let semaphore = DispatchSemaphore(value: 0)
    var enhancedPrompt = ""
    
    let payload: [String: Any] = [
      "messages": [
        [
          "content": "Transform the user's input into a well-crafted system prompt that enhances clarity, intent, and usefulness for AI responses.",
          "role": "system"
        ],
        [
          "content": prompt,
          "role": "user"
        ]
      ],
      "instruction": "Transform the user's input into a well-crafted system prompt that enhances clarity, intent, and usefulness for AI responses. while giveing response give me only sentance no need any here is a prompt like this way ",
      "text": prompt,
      "stream": false
    ]

    guard let url = URL(string: baseURL) else {
      logger.log("Invalid URL for AI prompt enhancement", level: .error)
      return prompt
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    } catch {
      logger.log("Failed to serialize request: \(error.localizedDescription)", level: .error)
      return prompt
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
      defer { semaphore.signal() }
      
      if let error = error {
        self.logger.log("AI enhance prompt error: \(error.localizedDescription)", level: .error)
        return
      }
      
      guard let data = data else {
        self.logger.log("No data received from AI enhance prompt request", level: .error)
        return
      }


      //take value from data.response
      let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
      if let responseText = response?["response"] as? String {
        enhancedPrompt = responseText
      }
    }.resume()
    
    // Wait for response with timeout
    _ = semaphore.wait(timeout: .now() + 10)
    
    return enhancedPrompt.isEmpty ? prompt : enhancedPrompt
  }

  // MARK: - AI-Enhanced Task Generation
  func generateTaskDescriptionAndSubtasks(
    taskTitle: String,
    completion: @escaping (Result<TaskEnhancementData, Error>) -> Void
  ) {
    print("🚀 [AI-SERVICE] ==========================================")
    print("🚀 [AI-SERVICE] STEP 1: Starting AI task enhancement")
    print("🚀 [AI-SERVICE] Task Title: '\(taskTitle)'")
    print("🚀 [AI-SERVICE] Base URL: \(baseURL)")
    print("🚀 [AI-SERVICE] Timestamp: \(Date())")
    
    logger.log("🚀 [AI-TASK] Generating enhanced task data for: \(taskTitle)", level: .info)
    
    // Validate inputs
    guard !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      print("❌ [AI-SERVICE] STEP 1 FAILED: Empty task title")
      completion(.failure(URLError(.badURL)))
      return
    }
    
    guard !baseURL.isEmpty else {
      print("❌ [AI-SERVICE] STEP 1 FAILED: Empty base URL")
      completion(.failure(URLError(.badURL)))
      return
    }
    
    print("✅ [AI-SERVICE] STEP 1 COMPLETE: Input validation passed")
    print("🚀 [AI-SERVICE] STEP 2: Creating prompts and payload")
    
    let systemPrompt = """
    You are an expert task management assistant. Given a task title, provide a comprehensive analysis including:
    1. A detailed description of what the task involves
    2. Break down the task into 3-6 actionable subtasks
    3. Estimate time for each subtask
    4. Identify the priority level for each subtask
    
    Return the response in JSON format with the following structure:
    {
        "description": "Detailed description of the main task",
        "subtasks": [
            {
                "title": "Subtask title",
                "description": "Detailed description of the subtask",
                "estimatedDuration": 1800,
                "priority": "medium"
            }
        ]
    }
    
    Important guidelines:
    - Make subtasks specific and actionable
    - Estimated duration should be in seconds
    - Priority should be "low", "medium", or "high"
    - Each subtask should be achievable within 30 minutes
    - Focus on practical, real-world steps
    """
    
    let userPrompt = """
    Task: \(taskTitle)
    
    Please analyze this task and provide a comprehensive breakdown with description and subtasks.
    """
    
    print("📝 [AI-SERVICE] System Prompt Length: \(systemPrompt.count) characters")
    print("📝 [AI-SERVICE] User Prompt: '\(userPrompt)'")
    
    let payload: [String: Any] = [
      "messages": [
        [
          "content": systemPrompt,
          "role": "system"
        ],
        [
          "content": userPrompt,
          "role": "user"
        ]
      ],
      "instruction": systemPrompt,
      "text": userPrompt,
      "stream": false
    ]
    
    print("📦 [AI-SERVICE] Payload Structure:")
    print("   - Messages count: \((payload["messages"] as? [[String: Any]])?.count ?? 0)")
    print("   - Stream: \(payload["stream"] as? Bool ?? false)")
    print("   - Text: '\((payload["text"] as? String ?? "").prefix(50))...'")

    print("✅ [AI-SERVICE] STEP 2 COMPLETE: Prompts and payload created")
    print("🚀 [AI-SERVICE] STEP 3: Creating URL and request")

    guard let url = URL(string: baseURL) else {
      print("❌ [AI-SERVICE] STEP 3 FAILED: Invalid URL - '\(baseURL)'")
      logger.log("❌ [AI-TASK] Invalid URL for task enhancement", level: .error)
      completion(.failure(URLError(.badURL)))
      return
    }
    
    print("✅ [AI-SERVICE] URL Created: \(url.absoluteString)")
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 30.0
    
    print("📨 [AI-SERVICE] Request Configuration:")
    print("   - Method: \(request.httpMethod ?? "Unknown")")
    print("   - Headers: \(request.allHTTPHeaderFields ?? [:])")
    print("   - Timeout: \(request.timeoutInterval) seconds")
    
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: payload)
      request.httpBody = jsonData
      print("✅ [AI-SERVICE] STEP 3 COMPLETE: Request body serialized (\(jsonData.count) bytes)")
    } catch {
      print("❌ [AI-SERVICE] STEP 3 FAILED: JSON serialization error - \(error.localizedDescription)")
      logger.log("❌ [AI-TASK] Failed to serialize request: \(error.localizedDescription)", level: .error)
      completion(.failure(error))
      return
    }

    print("🚀 [AI-SERVICE] STEP 4: Making network request...")
    let requestStartTime = Date()

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      let requestDuration = Date().timeIntervalSince(requestStartTime)
      print("📡 [AI-SERVICE] STEP 4 COMPLETE: Network request finished in \(String(format: "%.2f", requestDuration))s")
      
      guard let self = self else {
        print("❌ [AI-SERVICE] STEP 5 FAILED: Self is nil - creating fallback response")
        // Still call completion handler to prevent caller from hanging
        let fallbackData = TaskEnhancementData(
          description: "AI-enhanced analysis of: \(taskTitle). This is a comprehensive task that requires careful planning and execution.",
          subtasks: [
            TaskEnhancementData.SubtaskData(
              title: "Research and Planning",
              description: "Gather information and plan the approach for: \(taskTitle)",
              estimatedDuration: 900,
              priority: "medium"
            ),
            TaskEnhancementData.SubtaskData(
              title: "Implementation",
              description: "Execute the main components of: \(taskTitle)",
              estimatedDuration: 1800,
              priority: "high"
            ),
            TaskEnhancementData.SubtaskData(
              title: "Review and Finalize",
              description: "Review work and make final adjustments for: \(taskTitle)",
              estimatedDuration: 600,
              priority: "medium"
            )
          ]
        )
        completion(.success(fallbackData))
        return
      }
      
      print("🚀 [AI-SERVICE] STEP 5: Processing network response")
      
      // Check for network errors
      if let error = error {
        print("❌ [AI-SERVICE] STEP 5 FAILED: Network error")
        print("❌ [AI-SERVICE] Error Details:")
        print("   - Description: \(error.localizedDescription)")
        print("   - Type: \(type(of: error))")
        if let nsError = error as NSError? {
          print("   - Code: \(nsError.code)")
          print("   - Domain: \(nsError.domain)")
          print("   - User Info: \(nsError.userInfo)")
        }
        self.logger.log("❌ [AI-TASK] Network error: \(error.localizedDescription)", level: .error)
        completion(.failure(error))
        return
      }
      
      // Check HTTP response
      if let httpResponse = response as? HTTPURLResponse {
        print("📋 [AI-SERVICE] HTTP Response:")
        print("   - Status Code: \(httpResponse.statusCode)")
        print("   - Headers: \(httpResponse.allHeaderFields)")
        
        if httpResponse.statusCode != 200 {
          print("❌ [AI-SERVICE] STEP 5 FAILED: Non-200 status code")
          completion(.failure(URLError(.badServerResponse)))
          return
        }
      }
      
      guard let data = data else {
        print("❌ [AI-SERVICE] STEP 5 FAILED: No data received")
        self.logger.log("❌ [AI-TASK] No data received", level: .error)
        completion(.failure(URLError(.cannotParseResponse)))
        return
      }
      
      print("✅ [AI-SERVICE] STEP 5 COMPLETE: Data received (\(data.count) bytes)")
      print("🚀 [AI-SERVICE] STEP 6: Parsing response data")
      
      // Log raw response for debugging
      if let rawString = String(data: data, encoding: .utf8) {
        print("📋 [AI-SERVICE] Raw Response: '\(rawString.prefix(500))...'")
      }
      
      do {
        // Parse the response
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          print("❌ [AI-SERVICE] STEP 6 FAILED: Response is not a JSON object")
          completion(.failure(URLError(.cannotParseResponse)))
          return
        }
        
        print("📋 [AI-SERVICE] JSON Response Keys: \(jsonResponse.keys.joined(separator: ", "))")
        
        guard let responseText = jsonResponse["response"] as? String else {
          print("❌ [AI-SERVICE] STEP 6 FAILED: No 'response' field in JSON")
          print("❌ [AI-SERVICE] Available fields: \(jsonResponse.keys.joined(separator: ", "))")
          self.logger.log("❌ [AI-TASK] Invalid response format", level: .error)
          completion(.failure(URLError(.cannotParseResponse)))
          return
        }
        
        print("✅ [AI-SERVICE] STEP 6 COMPLETE: Found response text (\(responseText.count) chars)")
        print("📋 [AI-SERVICE] Response Text: '\(responseText.prefix(200))...'")
        
        self.logger.log("✅ [AI-TASK] Received AI response: \(responseText.prefix(200))...", level: .info)
        
        print("🚀 [AI-SERVICE] STEP 7: Parsing AI response as JSON")
        
        // Try to parse the JSON response text
        guard let jsonData = responseText.data(using: .utf8) else {
          print("❌ [AI-SERVICE] STEP 7 FAILED: Cannot convert response to UTF-8 data")
          self.createFallbackTaskData(responseText: responseText, completion: completion)
          return
        }
        
        do {
          let taskData = try JSONDecoder().decode(TaskEnhancementData.self, from: jsonData)
          print("✅ [AI-SERVICE] STEP 7 COMPLETE: Successfully parsed TaskEnhancementData")
          print("🎉 [AI-SERVICE] ==========================================")
          print("🎉 [AI-SERVICE] AI TASK ENHANCEMENT SUCCESS!")
          print("🎉 [AI-SERVICE] Description: '\(taskData.description.prefix(100))...'")
          print("🎉 [AI-SERVICE] Subtasks: \(taskData.subtasks.count)")
          for (index, subtask) in taskData.subtasks.enumerated() {
            print("🎉 [AI-SERVICE]   \(index + 1). '\(subtask.title)' (\(subtask.priority))")
          }
          print("🎉 [AI-SERVICE] ==========================================")
          
          self.logger.log("✅ [AI-TASK] Successfully parsed task enhancement data", level: .info)
          completion(.success(taskData))
        } catch {
          print("❌ [AI-SERVICE] STEP 7 FAILED: JSON decoding error")
          print("❌ [AI-SERVICE] Decoding Error: \(error.localizedDescription)")
          print("❌ [AI-SERVICE] JSON Data: '\(String(data: jsonData, encoding: .utf8) ?? "Cannot display")'")
          
          self.logger.log("⚠️ [AI-TASK] Failed to parse JSON, creating fallback data", level: .warning)
          self.createFallbackTaskData(responseText: responseText, completion: completion)
        }
      } catch {
        print("❌ [AI-SERVICE] STEP 6 FAILED: JSON parsing error")
        print("❌ [AI-SERVICE] Error: \(error.localizedDescription)")
        self.logger.log("❌ [AI-TASK] JSON parsing error: \(error.localizedDescription)", level: .error)
        
        // Create basic enhancement data as fallback
        self.createBasicFallbackData(taskTitle: taskTitle, completion: completion)
      }
    }.resume()
    
    print("🚀 [AI-SERVICE] STEP 4: Network request initiated (async)")
  }
  
  // MARK: - Fallback Data Creation
  private func createFallbackTaskData(responseText: String, completion: @escaping (Result<TaskEnhancementData, Error>) -> Void) {
    print("🔧 [AI-SERVICE] Creating fallback data from response text")
    
    let fallbackData = TaskEnhancementData(
      description: responseText,
      subtasks: []
    )
    print("✅ [AI-SERVICE] Fallback data created with response as description")
    completion(.success(fallbackData))
  }
  
  private func createBasicFallbackData(taskTitle: String, completion: @escaping (Result<TaskEnhancementData, Error>) -> Void) {
    print("🔧 [AI-SERVICE] Creating basic fallback data for: \(taskTitle)")
    
    let fallbackData = TaskEnhancementData(
      description: "AI-enhanced analysis of: \(taskTitle). This is a comprehensive task that requires careful planning and execution.",
      subtasks: [
        TaskEnhancementData.SubtaskData(
          title: "Research and Planning",
          description: "Gather information and plan the approach for: \(taskTitle)",
          estimatedDuration: 900,
          priority: "medium"
        ),
        TaskEnhancementData.SubtaskData(
          title: "Implementation",
          description: "Execute the main components of: \(taskTitle)",
          estimatedDuration: 1800,
          priority: "high"
        ),
        TaskEnhancementData.SubtaskData(
          title: "Review and Finalize",
          description: "Review work and make final adjustments for: \(taskTitle)",
          estimatedDuration: 600,
          priority: "medium"
        )
      ]
    )
    
    print("✅ [AI-SERVICE] Basic fallback data created:")
    print("   - Description: '\(fallbackData.description.prefix(100))...'")
    print("   - Subtasks: \(fallbackData.subtasks.count)")
    
    completion(.success(fallbackData))
  }

  // MARK: - Streaming Response Generation
  func generateStreamingResponse(
    prompt: String,
    systemPrompt: String,
    model: String,
    type: ContentTypeDetector.DetectedContent.ContentType = .text,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    logger.log("🚀 [STREAMING] Starting streaming response generation", level: .info)
    logger.log("🚀 [STREAMING] Model: \(model)", level: .info)
    logger.log("🚀 [STREAMING] Prompt length: \(prompt.count) chars", level: .info)
    logger.log("🚀 [STREAMING] System prompt: \(systemPrompt.prefix(100))...", level: .info)
    logger.log("🚀 [STREAMING] Type: \(type)", level: .info)
    
    // Check if type indicates a file and route to appropriate service
    if shouldUseGeminiVision(for: type) {
      logger.log("🚀 [STREAMING] Routing to Gemini Vision for file type: \(type)", level: .info)
      handleFileWithGeminiVisionStreaming(
        prompt: prompt,
        systemPrompt: systemPrompt,
        type: type,
        completion: completion
      )
      return
    }
    
    logger.log("🚀 [STREAMING] Using standard streaming API", level: .info)
    
    // Cancel any existing streaming task
    logger.log("🚀 [STREAMING] Canceling any existing streaming task", level: .info)
    cancelStreaming()
    
    // Start streaming session
    logger.log("🚀 [STREAMING] Starting streaming session in AppState", level: .info)
    appState?.startStreaming()
    
    guard let url = URL(string: baseURL) else {
      logger.log("❌ [STREAMING] Invalid URL: \(baseURL)", level: .error)
      appState?.handleStreamingError("Invalid API URL")
      completion(.failure(URLError(.badURL)))
      return
    }
    
    logger.log("🚀 [STREAMING] Created URL: \(url.absoluteString)", level: .info)
    
    // Create the request
    logger.log("🚀 [STREAMING] Creating HTTP request", level: .info)
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
    request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
    request.timeoutInterval = 60.0
    
    logger.log("🚀 [STREAMING] Request headers configured", level: .info)
    
    // Construct payload
    let selectedModel = UserDefaults.standard.string(forKey: "aiModel") ?? "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
    logger.log("🚀 [STREAMING] Using model: \(selectedModel)", level: .info)
    
    let payload: [String: Any] = [
      "messages": [
        [
          "content": systemPrompt.isEmpty ? "You are a helpful assistant that provides clear and concise responses. give me response as per this library https://github.com/gonzalezreal/swift-markdown-ui" : systemPrompt,
          "role": "system"
        ],
        [
          "content": prompt,
          "role": "user"
        ]
      ],
      "instruction": systemPrompt.isEmpty ? "You are a helpful assistant that provides clear and concise responses. give me response as per this library https://github.com/gonzalezreal/swift-markdown-ui" : systemPrompt,
      "text": prompt,
      "stream": true,
      // "model": selectedModel
    ]
    
    logger.log("🚀 [STREAMING] Payload created with keys: \(payload.keys.joined(separator: ", "))", level: .info)
    
    guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
      logger.log("❌ [STREAMING] Failed to serialize payload to JSON", level: .error)
      appState?.handleStreamingError("Failed to prepare request")
      completion(.failure(URLError(.cannotParseResponse)))
      return
    }
    request.httpBody = httpBody
    
    logger.log("🚀 [STREAMING] HTTP body serialized successfully, size: \(httpBody.count) bytes", level: .info)
    logger.log("🚀 [STREAMING] Ready to start streaming request to: \(url.absoluteString)", level: .info)
    
    // Set up streaming with custom delegate for real-time processing
    logger.log("🚀 [STREAMING] Setting up URLSession with custom delegate", level: .info)
    let delegate = StreamingDelegate(aiService: self)
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 60.0
    config.timeoutIntervalForResource = 300.0
    
    logger.log("🚀 [STREAMING] URLSession configuration created", level: .info)
    let session = URLSession(configuration: config, delegate: delegate, delegateQueue: .main)
    
    // Create streaming task with custom session for real-time processing
    logger.log("🚀 [STREAMING] Creating streaming task with custom session", level: .info)
    streamingTask = session.dataTask(with: request)
    
    logger.log("🚀 [STREAMING] Starting streaming task...", level: .info)
    streamingTask?.resume()
    
    logger.log("🚀 [STREAMING] Setting connection state to connected", level: .info)
    appState?.connectionState = .connected
    
    logger.log("✅ [STREAMING] Streaming setup complete - waiting for real-time response", level: .info)
    
         // Call completion to indicate the request was initiated successfully
     completion(.success(()))
   }
  
  
  
  // Cancel current streaming
  func cancelStreaming() {
    streamingTask?.cancel()
    streamingTask = nil
    appState?.cancelStreaming()
    logger.log("Streaming cancelled", level: .info)
  }

  // Modified to use our internal ActionType with streaming
  func processWithAction(
    text: String,
    action: ActionType,
    apiKey: String,
    model: String,
    metadata: [String: Any]? = nil,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    logger.log("Processing text with action: \(action.rawValue)", level: .info)

    // Check if this is a file analysis action and we have file details
    if action == .analyzeFile, let fileDetails = metadata?["fileDetails"] as? [String: Any] {
      // Use the prompt manager to create a specialized file analysis prompt
      let promptManager = PromptManager()
      let filePrompt = promptManager.createFileAnalysisPrompt(
        fileDetails: fileDetails, userRequest: text.isEmpty ? nil : text)

      logger.log("Using specialized file analysis prompt", level: .info)
      generateStreamingResponse(
        prompt: filePrompt,
        systemPrompt: "",
        model: model,
        completion: completion
      )
      return
    }

    // Standard processing for other action types
    generateStreamingResponse(
      prompt: text,
      systemPrompt: action.systemPrompt,
      model: model, type: ContentTypeDetector.DetectedContent.ContentType.text, 
      completion: completion
    )
  }



  // Adapter method to convert from AIAction to our internal ActionType
  // This allows the existing code to keep working with AIAction
  func processWithAIAction(
    text: String,
    action: String,
    apiKey: String,
    model: String,
    metadata: [String: Any]? = nil,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    // Convert string action to our internal action type
    let actionType: ActionType
    switch action.lowercased() {
    case "fixspellinggrammar":
      actionType = .fixSpellingGrammar
    case "improvewriting":
      actionType = .improveWriting
    case "translate":
      actionType = .translate
    case "makeshorter":
      actionType = .makeShorter
    case "analyzefile":
      actionType = .analyzeFile
    case "analyzeimage":
      actionType = .analyzeImage
    default:
      actionType = .improveWriting  // Default action
    }

    processWithAction(
      text: text,
      action: actionType,
      apiKey: apiKey,
      model: model,
      metadata: metadata,
      completion: completion
    )
  }

  // Simulate streaming response for demo/testing
  func simulateStreamingResponse(
    text: String,
    action: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    // Convert string action to our internal action type
    let actionType: ActionType
    switch action.lowercased() {
    case "fixspellinggrammar":
      actionType = .fixSpellingGrammar
    case "improvewriting":
      actionType = .improveWriting
    case "translate":
      actionType = .translate
    case "makeshorter":
      actionType = .makeShorter
    case "analyzeimage":
      actionType = .analyzeImage
    default:
      actionType = .improveWriting  // Default action
    }

    simulateStreamingResponseForAction(text: text, action: actionType, completion: completion)
  }
  
  // Simulate streaming response for testing/demo purposes
  private func simulateStreamingResponseForAction(
    text: String,
    action: ActionType,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    logger.log("Simulating streaming response for action: \(action.rawValue)", level: .info)
    
    appState?.startStreaming()
    
    // Generate simulated response
    let response: String
    switch action {
    case .fixSpellingGrammar:
      response = "I've fixed the spelling and grammar issues in your text:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
    case .improveWriting:
      response = "Here's an improved version of your text with better clarity and engagement:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
    case .translate:
      let isEnglish = text.range(of: "[^a-zA-Z0-9\\s.,?!]", options: .regularExpression) == nil
      if isEnglish {
        response = "Voici la traduction en français:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
      } else {
        response = "Here's the English translation:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
      }
    case .makeShorter:
      let words = text.split(separator: " ")
      let shortenedCount = max(3, Int(Double(words.count) * 0.6))
      response = "Here's a more concise version:\n\n" + words.prefix(shortenedCount).joined(separator: " ")
    case .summarize:
      response = "Here's a summary of your text:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
    case .analyzeFile:
      response = "File analysis complete. The file contains structured content with various elements..."
    case .analyzeImage:
      response = "Image analysis complete. The image shows various visual elements and content..."
    }
    
    // Simulate streaming effect
    simulateStreamingForStaticResponse(response)
    completion(.success(()))
  }

  func generateInstructionTemplate(systemPrompt: String) -> String {
    return """
      You are a helpful assistant that can help with the following tasks:
      - Improve writing quality
      - Fix spelling and grammar errors
      - Improve writing quality
      - Translate text to English or French
      - Make text shorter
      - Summarize text
      - Generate a list of keywords from the text
      - Generate a list of questions from the text
      - write a doc for the text

      // MARK: - Documentation
      /**
       # Rich Text Formatter
       
       A powerful text formatter for SwiftUI that implements markdown-style formatting.
       
       ## Features
       - **Bold text** with double asterisks
       - _Italic text_ with underscores
       - `Code blocks` with backticks
       - Headers with # symbols (# ## ###)
       - Bullet lists (- * +) and numbered lists (1. 2.)
       - Block quotes (> text)
       - Horizontal rules (---)
       - Links ([text](url))
       - Line breaks (/n)
       
       ## Usage
       ```swift
       FormattedTextView("**Hello World**")
       ```
       
       ## Configuration
       You can customize font size, text color, alignment, and line spacing:
       ```swift
       FormattedTextView(
           text,
           fontSize: 16,
           textColor: .primary,
           alignment: .leading,
           lineSpacing: 6
       )
       ```
       */

      """
  }
  
  // MARK: - Gemini Vision Integration
  // Determine if we should use Gemini Vision for this file type
  private func shouldUseGeminiVision(for type: ContentTypeDetector.DetectedContent.ContentType) -> Bool {
    switch type {
    case .media(type: .image), .media(type: .audio), .media(type: .video), .document(type: .excel), .document(type: .pdf) , .document(type: .word):
      return true
    default:
      return false
    }
  }
  
  // Handle file processing with Gemini Vision
  private func handleFileWithGeminiVision(prompt: String, systemPrompt: String, type: String) -> AnyPublisher<String, Error> {
    logger.log("Processing file with Gemini Vision, type: \(type)", level: .info)
    
    return Future<String, Error> { [weak self] promise in
      guard let self = self else {
        promise(.failure(APIError.invalidResponse))
        return
      }
      
      // Extract file path from prompt
      let filePath = self.extractFilePathFromPrompt(prompt)
      
      guard !filePath.isEmpty else {
        promise(.failure(FileProcessingError.noFilePathFound))
        return
      }
      
      // Create comprehensive prompt combining system prompt and user request
      let visionPrompt = self.createVisionPrompt(systemPrompt: systemPrompt, userPrompt: prompt, filePath: filePath)
      
             // Process file with appropriate handler
       self.processFileWithGeminiVision(filePath: filePath, prompt: visionPrompt, completion: promise)
      
    }.eraseToAnyPublisher()
  }
  
  // Extract file path from prompt text
  private func extractFilePathFromPrompt(_ prompt: String) -> String {
    let lines = prompt.components(separatedBy: .newlines)
    
    for line in lines {
      let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
      
      // Check if this line looks like a file path
      if isValidFilePath(trimmedLine) {
        return trimmedLine
      }
    }
    
    return ""
  }
  
  // Validate if a string is a valid file path
  private func isValidFilePath(_ path: String) -> Bool {
    guard path.contains("/") || path.contains("\\") else { return false }
    
    let components = path.components(separatedBy: ".")
    guard components.count > 1, let ext = components.last, !ext.isEmpty else { return false }
    
    // Check if extension is reasonable (2-4 characters)
    return ext.count >= 2 && ext.count <= 4
  }
  
  // Create a comprehensive prompt for vision processing
  private func createVisionPrompt(systemPrompt: String, userPrompt: String, filePath: String) -> String {
    var visionPrompt = ""
    
    // Add system context if provided
    if !systemPrompt.isEmpty {
      visionPrompt += "Context: \(systemPrompt)\n\n"
    }
    
    // Add user request, filtering out the file path
    let userRequest = userPrompt.replacingOccurrences(of: filePath, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    if !userRequest.isEmpty {
      visionPrompt += "User Request: \(userRequest)\n\n"
    }
    
    // Add default instruction if no specific request
    if userRequest.isEmpty {
      visionPrompt += "Please analyze this file and provide detailed insights about its content, structure, and any relevant information.\n\n"
    }
    
    return visionPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  // Process files with Gemini Vision (images, PDFs, documents, etc.)
  private func processFileWithGeminiVision(filePath: String, prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
    logger.log("Processing file: \(filePath)", level: .info)
    
    // Convert path to URL
    let fileURL = URL(fileURLWithPath: expandFilePath(filePath))
    
    geminiVisionService.processFile(fileURL: fileURL, prompt: prompt) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success(let response):
          print("response: \(response)")
          self?.logger.log("Successfully processed file with Gemini Vision", level: .info)
          completion(.success(response))
        case .failure(let error):
          self?.logger.log("Failed to process file: \(error.localizedDescription)", level: .error)
          completion(.failure(error))
        }
      }
    }
  }
  
  // Streaming version for Gemini Vision file processing
  private func handleFileWithGeminiVisionStreaming(
    prompt: String,
    systemPrompt: String,
    type: ContentTypeDetector.DetectedContent.ContentType,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    logger.log("Processing file with Gemini Vision streaming, type: \(type)", level: .info)
    
    // Start streaming session
    appState?.startStreaming()
    
    // Extract file path from prompt
    let filePath = extractFilePathFromPrompt(prompt)
    
    guard !filePath.isEmpty else {
      appState?.handleStreamingError("No valid file path found")
      completion(.failure(FileProcessingError.noFilePathFound))
      return
    }
    
    // Create comprehensive prompt combining system prompt and user request
    let visionPrompt = createVisionPrompt(systemPrompt: systemPrompt, userPrompt: prompt, filePath: filePath)
    
    // Convert path to URL
    let fileURL = URL(fileURLWithPath: expandFilePath(filePath))
    
    // Process file with Gemini Vision
    geminiVisionService.processFile(fileURL: fileURL, prompt: visionPrompt) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success(let response):
          self?.logger.log("Successfully processed file with Gemini Vision", level: .info)
          
          // Simulate streaming for Gemini Vision response
          self?.simulateStreamingForStaticResponse(response)
          completion(.success(()))
          
        case .failure(let error):
          self?.logger.log("Failed to process file: \(error.localizedDescription)", level: .error)
          self?.appState?.handleStreamingError(error.localizedDescription)
          completion(.failure(error))
        }
      }
    }
  }
  
  // Simulate streaming effect for static responses (like Gemini Vision)
  private func simulateStreamingForStaticResponse(_ response: String) {
    appState?.connectionState = .streaming
    
    let words = response.components(separatedBy: .whitespacesAndNewlines)
    let wordsPerChunk = max(1, words.count / 20) // Divide into ~20 chunks
    
    var wordIndex = 0
    let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
      guard let self = self else {
        timer.invalidate()
        return
      }
      
      let endIndex = min(wordIndex + wordsPerChunk, words.count)
      let chunk = words[wordIndex..<endIndex].joined(separator: " ")
      
      if !chunk.isEmpty {
        self.appState?.updateStreamingResponse(chunk + " ")
      }
      
      wordIndex = endIndex
      
      if wordIndex >= words.count {
        timer.invalidate()
        self.appState?.completeStreaming()
      }
    }
    
    // Ensure timer runs on main thread
    RunLoop.main.add(timer, forMode: .common)
  }


  // Helper to expand file paths (handle ~ and file:// URLs)
  private func expandFilePath(_ path: String) -> String {
    var expandedPath = path
    
    // Handle file:// URLs
    if expandedPath.hasPrefix("file://") {
      if let url = URL(string: expandedPath) {
        expandedPath = url.path
      }
    }
    
    // Expand tilde for home directory
    if expandedPath.hasPrefix("~") {
      expandedPath = NSString(string: expandedPath).expandingTildeInPath
    }
    
    return expandedPath
  }
  
  // Describe file type based on extension
  private func describeFileType(_ fileExtension: String) -> String {
    switch fileExtension.lowercased() {
    case "pdf": return "PDF document"
    case "doc", "docx": return "Microsoft Word document" 
    case "xls", "xlsx": return "Microsoft Excel spreadsheet"
    case "ppt", "pptx": return "Microsoft PowerPoint presentation"
    case "txt": return "text document"
    case "md": return "Markdown document"
    case "json": return "JSON data file"
    case "xml": return "XML document"
    case "csv": return "CSV data file"
    case "zip", "rar", "7z": return "compressed archive"
    case "mp3", "wav", "flac": return "audio file"
    case "mp4", "avi", "mov": return "video file"
    default: return "document"
    }
  }

  // MARK: - AI-Powered Task Reordering
  func reorderTasksWithAI(
    tasks: [Note],
    projectContext: String? = nil,
    releaseContext: String? = nil,
    completion: @escaping (Result<TaskReorderingData, Error>) -> Void
  ) {
    print("🔄 [AI-REORDER] ==========================================")
    print("🔄 [AI-REORDER] STEP 1: Starting AI task reordering")
    print("🔄 [AI-REORDER] Tasks count: \(tasks.count)")
    print("🔄 [AI-REORDER] Project context: \(projectContext ?? "None")")
    print("🔄 [AI-REORDER] Release context: \(releaseContext ?? "None")")
    print("🔄 [AI-REORDER] Timestamp: \(Date())")
    
    logger.log("🔄 [AI-REORDER] Starting task reordering for \(tasks.count) tasks", level: .info)
    
    // Validate inputs
    guard !tasks.isEmpty else {
      print("❌ [AI-REORDER] STEP 1 FAILED: No tasks provided")
      completion(.failure(URLError(.badURL)))
      return
    }
    
    guard !baseURL.isEmpty else {
      print("❌ [AI-REORDER] STEP 1 FAILED: Empty base URL")
      completion(.failure(URLError(.badURL)))
      return
    }
    
    print("✅ [AI-REORDER] STEP 1 COMPLETE: Input validation passed")
    print("🔄 [AI-REORDER] STEP 2: Creating reordering prompts")
    
    // Create context information
    let contextInfo = buildContextInfo(projectContext: projectContext, releaseContext: releaseContext)
    
    // Create task list for AI analysis
    let taskList = tasks.enumerated().map { index, task in
      let subtaskInfo = task.aiGeneratedSubtasks.isEmpty ? "" : " (Has \(task.aiGeneratedSubtasks.count) subtasks)"
      let estimatedTime = task.estimatedTime ?? "Unknown"
      let priority = task.priority.rawValue
      let scheduledInfo = task.isScheduled ? " (Scheduled)" : ""
      
      return """
      Task \(index + 1): "\(task.title)"
      - ID: \(task.id)
      - Estimated Time: \(estimatedTime)
      - Priority: \(priority)
      - Created: \(formatDateForAI(task.creationDate))
      - Description: \(task.aiGeneratedDescription ?? task.content)
      \(subtaskInfo)\(scheduledInfo)
      """
    }.joined(separator: "\n\n")
    
    let systemPrompt = """
    You are an expert task management and prioritization assistant. Your job is to intelligently reorder tasks based on:
    
    1. **Priority levels** (Urgent > High > Medium > Low)
    2. **Dependencies** (tasks that should be completed before others)
    3. **Estimated time** (balance quick wins with important long-term tasks)
    4. **Project context** (alignment with project goals)
    5. **Scheduling** (respect scheduled tasks and deadlines)
    6. **Logical workflow** (tasks that build upon each other)
    
    Context Information:
    \(contextInfo)
    
    Rules for reordering:
    - Maintain the original task IDs
    - Provide clear reasoning for the new order
    - Consider both urgent quick wins and important strategic tasks
    - Respect scheduled tasks and their timing
    - Group related tasks when beneficial
    - Balance workload distribution
    
    Return the response in JSON format with the following structure:
    {
        "reorderedTasks": [
            {
                "taskId": "UUID-string",
                "newPosition": 1,
                "priority": "high",
                "reasoning": "Why this task should be in this position"
            }
        ],
        "summary": "Overall explanation of the reordering strategy"
    }
    
    Important: All task IDs must be preserved exactly as provided. Only change the order and priority levels.
    """
    
    let userPrompt = """
    Please analyze and reorder these tasks for optimal productivity and project success:
    
    \(taskList)
    
    Current task count: \(tasks.count)
    
    Please provide an intelligent reordering that maximizes productivity while considering dependencies, priorities, and project context.
    """
    
    print("📝 [AI-REORDER] System Prompt Length: \(systemPrompt.count) characters")
    print("📝 [AI-REORDER] User Prompt Length: \(userPrompt.count) characters")
    print("📝 [AI-REORDER] Task List Preview: \(taskList.prefix(200))...")
    
    let payload: [String: Any] = [
      "messages": [
        [
          "content": systemPrompt,
          "role": "system"
        ],
        [
          "content": userPrompt,
          "role": "user"
        ]
      ],
      "instruction": systemPrompt,
      "text": userPrompt,
      "stream": false
    ]
    
    print("📦 [AI-REORDER] Payload Structure:")
    print("   - Messages count: \((payload["messages"] as? [[String: Any]])?.count ?? 0)")
    print("   - Stream: \(payload["stream"] as? Bool ?? false)")
    
    print("✅ [AI-REORDER] STEP 2 COMPLETE: Prompts and payload created")
    print("🔄 [AI-REORDER] STEP 3: Making API request")
    
    guard let url = URL(string: baseURL) else {
      print("❌ [AI-REORDER] STEP 3 FAILED: Invalid URL - '\(baseURL)'")
      completion(.failure(URLError(.badURL)))
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 30.0
    
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: payload)
      request.httpBody = jsonData
      print("✅ [AI-REORDER] STEP 3 COMPLETE: Request configured (\(jsonData.count) bytes)")
    } catch {
      print("❌ [AI-REORDER] STEP 3 FAILED: JSON serialization error")
      completion(.failure(error))
      return
    }
    
    print("🔄 [AI-REORDER] STEP 4: Executing network request...")
    let requestStartTime = Date()
    
    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      let requestDuration = Date().timeIntervalSince(requestStartTime)
      print("📡 [AI-REORDER] STEP 4 COMPLETE: Request finished in \(String(format: "%.2f", requestDuration))s")
      
      guard let self = self else {
        print("❌ [AI-REORDER] STEP 5 FAILED: Self is nil")
        completion(.failure(URLError(.unknown)))
        return
      }
      
      print("🔄 [AI-REORDER] STEP 5: Processing response")
      
      if let error = error {
        print("❌ [AI-REORDER] STEP 5 FAILED: Network error - \(error.localizedDescription)")
        completion(.failure(error))
        return
      }
      
      guard let data = data else {
        print("❌ [AI-REORDER] STEP 5 FAILED: No data received")
        completion(.failure(URLError(.cannotParseResponse)))
        return
      }
      
      print("✅ [AI-REORDER] STEP 5 COMPLETE: Data received (\(data.count) bytes)")
      
      do {
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          print("❌ [AI-REORDER] STEP 6 FAILED: Invalid JSON response")
          completion(.failure(URLError(.cannotParseResponse)))
          return
        }
        
        guard let responseText = jsonResponse["response"] as? String else {
          print("❌ [AI-REORDER] STEP 6 FAILED: No response field")
          completion(.failure(URLError(.cannotParseResponse)))
          return
        }
        
        print("🔄 [AI-REORDER] STEP 6: Parsing AI response")
        print("📋 [AI-REORDER] Response Preview: \(responseText.prefix(200))...")
        
        // Parse the AI response
        guard let responseData = responseText.data(using: .utf8) else {
          print("❌ [AI-REORDER] STEP 6 FAILED: Cannot convert response to data")
          self.createFallbackReorderingData(tasks: tasks, completion: completion)
          return
        }
        
        do {
          let reorderingData = try JSONDecoder().decode(TaskReorderingData.self, from: responseData)
          print("✅ [AI-REORDER] STEP 6 COMPLETE: Successfully parsed reordering data")
          print("🎉 [AI-REORDER] ==========================================")
          print("🎉 [AI-REORDER] AI TASK REORDERING SUCCESS!")
          print("🎉 [AI-REORDER] Reordered tasks: \(reorderingData.reorderedTasks.count)")
          print("🎉 [AI-REORDER] Strategy: \(reorderingData.summary.prefix(100))...")
          for (index, task) in reorderingData.reorderedTasks.prefix(5).enumerated() {
            print("🎉 [AI-REORDER]   \(index + 1). Position \(task.newPosition) - \(task.priority)")
          }
          print("🎉 [AI-REORDER] ==========================================")
          
          completion(.success(reorderingData))
        } catch {
          print("❌ [AI-REORDER] STEP 6 FAILED: JSON parsing error - \(error.localizedDescription)")
          print("❌ [AI-REORDER] Response data: \(responseText)")
          self.createFallbackReorderingData(tasks: tasks, completion: completion)
        }
      } catch {
        print("❌ [AI-REORDER] STEP 5 FAILED: JSON response parsing error")
        self.createFallbackReorderingData(tasks: tasks, completion: completion)
      }
    }.resume()
  }
  
  // MARK: - Helper Methods for Task Reordering
  private func buildContextInfo(projectContext: String?, releaseContext: String?) -> String {
    var context = ""
    
    if let project = projectContext {
      context += "Project: \(project)\n"
    }
    
    if let release = releaseContext {
      context += "Release/Version: \(release)\n"
    }
    
    if context.isEmpty {
      context = "No specific project or release context provided.\n"
    }
    
    return context
  }
  
  private func formatDateForAI(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }
  
  private func createFallbackReorderingData(tasks: [Note], completion: @escaping (Result<TaskReorderingData, Error>) -> Void) {
    print("🔧 [AI-REORDER] Creating fallback reordering data")
    
    // Create a basic priority-based reordering
    let sortedTasks = tasks.enumerated().sorted { first, second in
      let firstTask = first.element
      let secondTask = second.element
      
      // First, sort by priority
      let priorityOrder = ["urgent": 0, "high": 1, "medium": 2, "low": 3]
      let firstPriority = priorityOrder[firstTask.priority.rawValue.lowercased()] ?? 3
      let secondPriority = priorityOrder[secondTask.priority.rawValue.lowercased()] ?? 3
      
      if firstPriority != secondPriority {
        return firstPriority < secondPriority
      }
      
      // Then by creation date (newer first)
      return firstTask.creationDate > secondTask.creationDate
    }
    
    let reorderedTasks = sortedTasks.enumerated().map { index, taskInfo in
      TaskReorderingData.ReorderedTask(
        taskId: taskInfo.element.id.uuidString,
        newPosition: index + 1,
        priority: taskInfo.element.priority.rawValue.lowercased(),
        reasoning: "Ordered by priority (\(taskInfo.element.priority.rawValue)) and creation date"
      )
    }
    
    let fallbackData = TaskReorderingData(
      reorderedTasks: reorderedTasks,
      summary: "Tasks reordered using fallback priority-based sorting. High priority and recently created tasks are prioritized."
    )
    
    print("✅ [AI-REORDER] Fallback reordering data created with \(reorderedTasks.count) tasks")
    completion(.success(fallbackData))
  }
}

// MARK: - File Processing Errors
enum FileProcessingError: Error, LocalizedError {
  case noFilePathFound
  case unsupportedFileType(String)
  case fileNotFound(String)
  
  var errorDescription: String? {
    switch self {
    case .noFilePathFound:
      return "No valid file path found in the request"
    case .unsupportedFileType(let type):
      return "Unsupported file type: \(type)"
    case .fileNotFound(let path):
      return "File not found at path: \(path)"
    }
  }
}

// MARK: - Response Models
struct AIResponse: Decodable {
  let response: String
  let toolCalls: [ToolCall]?
  let usage: Usage?

  enum CodingKeys: String, CodingKey {
    case response
    case toolCalls = "tool_calls"
    case usage
  }

  struct ToolCall: Decodable {
    // Add properties as needed based on your API response
  }

  struct Usage: Decodable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
      case promptTokens = "prompt_tokens"
      case completionTokens = "completion_tokens"
      case totalTokens = "total_tokens"
    }
  }
}

// MARK: - Error Handling

enum APIError: Error, LocalizedError {
  case invalidResponse
  case serverError(statusCode: Int, message: String)

  var errorDescription: String? {
    switch self {
    case .invalidResponse:
      return "Invalid response from server"
    case .serverError(let statusCode, let message):
      return "Server error (code \(statusCode)): \(message)"
    }
  }
}

// MARK: - Streaming Delegate

class StreamingDelegate: NSObject, URLSessionDataDelegate {
  weak var aiService: AIService?
  private var receivedData = Data()
  
  init(aiService: AIService) {
    self.aiService = aiService
    super.init()
  }
  
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    // print("📦 [DELEGATE] Received data chunk: \(data)")
    
    receivedData.append(data)
    // print("📦 [DELEGATE] Total buffered data: \(receivedData)")
    
    // Process complete lines from the received data
    if let string = String(data: receivedData, encoding: .utf8) {
      // print("📦 [DELEGATE] Decoded string: \(string.prefix(200))...")
      
      // Check if this looks like a complete JSON response (non-streaming)
      if string.hasPrefix("{") && string.hasSuffix("}") && !string.contains("\n") {
        // print("📦 [DELEGATE] Detected complete JSON response (non-streaming)")
        processCompleteJsonResponse(string)
        receivedData = Data() // Clear buffer
        return
      }
      
      // Process as Server-Sent Events (streaming)
      let lines = string.components(separatedBy: .newlines)
      // print("📦 [DELEGATE] Split into \(lines.count) lines for SSE processing")
      
      // Keep the last incomplete line in the buffer
      if lines.count > 1 {
        let completeLines = lines.dropLast()
        let incompleteData = lines.last?.data(using: .utf8) ?? Data()
        
        receivedData = incompleteData
        // print("📦 [DELEGATE] Processing \(completeLines.count) complete SSE lines")
        
        // Process complete lines
        for (index, line) in completeLines.enumerated() {
          // print("📦 [DELEGATE] Processing SSE line \(index + 1): \(line.prefix(100))...")
          processStreamingLine(line)
        }
      } else {
        // print("📦 [DELEGATE] No complete SSE lines to process yet")
      }
    } else {
      // print("❌ [DELEGATE] Failed to decode data as UTF-8 string")
    }
  }
  
  // Handle complete JSON response (fallback for non-streaming APIs)
  private func processCompleteJsonResponse(_ jsonString: String) {
   
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { 
        print("❌ [DELEGATE] Self is nil in processCompleteJsonResponse")
        return 
      }
      
      if let data = jsonString.data(using: .utf8) {
        do {
          if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // print("📋 [DELEGATE] JSON parsed successfully: \(json.keys.joined(separator: ", "))")
            
            // Check for different response formats
            if let response = json["response"] as? String {
              // print("✅ [DELEGATE] Found 'response' field: '\(response.prefix(50))...'")
              self.aiService?.appState?.updateStreamingResponse(response)
              
              // Update token counts if available
              if let usage = json["usage"] as? [String: Any] {
                if let totalTokens = usage["total_tokens"] as? Int {
                  self.aiService?.appState?.actualTokens = totalTokens
                  // print("📊 [DELEGATE] Updated token count: \(totalTokens)")
                }
              }
              
              self.aiService?.appState?.completeStreaming()
            } else if let text = json["text"] as? String {
              // print("✅ [DELEGATE] Found 'text' field: '\(text.prefix(50))...'")
              self.aiService?.appState?.updateStreamingResponse(text)
              self.aiService?.appState?.completeStreaming()
            } else {
              // print("⚠️ [DELEGATE] No recognized text field in JSON: \(json)")
              self.aiService?.appState?.handleStreamingError("Unexpected response format")
            }
          } else {
            // print("❌ [DELEGATE] Failed to parse complete JSON")
            self.aiService?.appState?.handleStreamingError("Invalid JSON response")
          }
        } catch {
          // print("❌ [DELEGATE] JSON parsing error: \(error.localizedDescription)")
          self.aiService?.appState?.handleStreamingError("JSON parsing failed: \(error.localizedDescription)")
        }
      } else {
        // print("❌ [DELEGATE] Failed to create data from complete JSON string")
        self.aiService?.appState?.handleStreamingError("Failed to process response")
      }
    }
  }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didCompleteWithError error: Error?) {
    // print("🏁 [DELEGATE] URLSession task completed")
    DispatchQueue.main.async { [weak self] in
      if let error = error {
        // print("❌ [DELEGATE] Streaming completed with error: \(error.localizedDescription)")
        self?.aiService?.appState?.handleStreamingError(error.localizedDescription)
      } else {
        // print("✅ [DELEGATE] Streaming completed successfully")
      
        self?.aiService?.appState?.completeStreaming()
      }
    }
  }
  
  private func processStreamingLine(_ line: String) {
    // print("🔍 [LINE] Processing line: '\(line)'")
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { 
        // print("❌ [LINE] Self is nil, cannot process line")
        return 
      }
      
      if line.hasPrefix("data: ") {
        let jsonString = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
        // print("📋 [LINE] Found data line, JSON: '\(jsonString)'")
        
        // Handle completion signal
        if jsonString == "[DONE]" || jsonString.contains("[DONE") {
          //    print("🏁 [LINE] Received [DONE
          self.aiService?.appState?.completeStreaming()
          return
        }
        
        if jsonString.isEmpty {
          // print("⚠️ [LINE] Empty JSON string, skipping")
          return
        }
        
        if let data = jsonString.data(using: .utf8) {
          // print("📋 [LINE] JSON data created successfully")
          do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
              // print("📋 [LINE] JSON parsed successfully: \(json.keys.joined(separator: ", "))")
              
              // Look for 'response' field (your API format)
              if let chunk = json["response"] as? String {
                // print("✅ [LINE] Found response chunk: '\(chunk)'")
                if !chunk.isEmpty {
                  self.aiService?.appState?.updateStreamingResponse(chunk)
                }
                
                // Update token counts if available
                if let usage = json["usage"] as? [String: Any] {
                  if let totalTokens = usage["total_tokens"] as? Int {
                    self.aiService?.appState?.actualTokens = totalTokens
                    // print("📊 [LINE] Updated token count: \(totalTokens)")
                  }
                }
                
                // Update progress indicator based on 'p' field length
                if let progressString = json["p"] as? String {
                  let progress = min(Double(progressString.count) / 50.0, 1.0) // Normalize to 0-1
                  self.aiService?.appState?.streamingProgress = progress
                  //print("📈 [LINE] Updated progress: \(progress)")
                }
              } else {
                //print("⚠️ [LINE] No 'response' field in JSON: \(json)")
                
                // Fallback: check for other possible text fields
                if let text = json["text"] as? String {
                  // print("✅ [LINE] Found fallback text field: '\(text)'")
                  if !text.isEmpty {
                    self.aiService?.appState?.updateStreamingResponse(text)
                  }
                }
              }
            } else {
              // print("❌ [LINE] Failed to parse JSON object")
            }
          } catch {
            // print("❌ [LINE] JSON parsing error: \(error.localizedDescription)")
          }
        } else {
          // print("❌ [LINE] Failed to create data from JSON string")
        }
      } else if line.hasPrefix("event: error") {
        // print("❌ [LINE] Received error event")
        self.aiService?.appState?.handleStreamingError("Streaming error occurred")
      } else if line.hasPrefix("event: ") {
        // print("ℹ️ [LINE] Received event: '\(line)'")
      } else if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        // print("⚠️ [LINE] Unknown line format: '\(line)'")
      }
    }
  }
}

// MARK: - Task Enhancement Data Models
struct TaskEnhancementData: Codable {
    let description: String
    let subtasks: [SubtaskData]
    
    struct SubtaskData: Codable {
        let title: String
        let description: String?
        let estimatedDuration: TimeInterval // in seconds
        let priority: String // "low", "medium", or "high"
        
        // Convert to Subtask model
        func toSubtask(order: Int) -> Subtask {
            let subtaskPriority: SubtaskPriority
            switch priority.lowercased() {
            case "low":
                subtaskPriority = .low
            case "high":
                subtaskPriority = .high
            default:
                subtaskPriority = .medium
            }
            
            return Subtask(
                title: title,
                description: description,
                isCompleted: false,
                estimatedDuration: estimatedDuration,
                priority: subtaskPriority,
                order: order
            )
        }
    }
  }
  
  // MARK: - Task Reordering Data Models
struct TaskReorderingData: Codable {
    let reorderedTasks: [ReorderedTask]
    let summary: String
    
    struct ReorderedTask: Codable {
        let taskId: String
        let newPosition: Int
        let priority: String
        let reasoning: String
    }
}
