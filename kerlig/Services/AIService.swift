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

  // MARK: - Streaming Response Generation
  
  func generateStreamingResponse(
    prompt: String,
    systemPrompt: String,
    model: String,
    type: String? = nil,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    logger.log("🚀 [STREAMING] Starting streaming response generation", level: .info)
    logger.log("🚀 [STREAMING] Model: \(model)", level: .info)
    logger.log("🚀 [STREAMING] Prompt length: \(prompt.count) chars", level: .info)
    logger.log("🚀 [STREAMING] System prompt: \(systemPrompt.prefix(100))...", level: .info)
    logger.log("🚀 [STREAMING] Type: \(type ?? "nil")", level: .info)
    
    // Check if type indicates a file and route to appropriate service
    if let fileType = type, shouldUseGeminiVision(for: fileType) {
      logger.log("🚀 [STREAMING] Routing to Gemini Vision for file type: \(fileType)", level: .info)
      handleFileWithGeminiVisionStreaming(
        prompt: prompt,
        systemPrompt: systemPrompt,
        type: fileType,
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
          "content": systemPrompt.isEmpty ? "You are a helpful assistant that provides clear and concise responses." : systemPrompt,
          "role": "system"
        ],
        [
          "content": prompt,
          "role": "user"
        ]
      ],
      "instruction": systemPrompt,
      "text": prompt,
      "stream": true,
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
      model: model,
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
  private func shouldUseGeminiVision(for type: String) -> Bool {
    let visionSupportedTypes = ["image", "pdf", "document", "text", "archive", "audio", "video", "file"]
    return visionSupportedTypes.contains(type.lowercased())
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
    type: String,
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
    print("📦 [DELEGATE] Received data chunk: \(data)")
    
    receivedData.append(data)
    print("📦 [DELEGATE] Total buffered data: \(receivedData)")
    
    // Process complete lines from the received data
    if let string = String(data: receivedData, encoding: .utf8) {
      print("📦 [DELEGATE] Decoded string: \(string.prefix(200))...")
      
      // Check if this looks like a complete JSON response (non-streaming)
      if string.hasPrefix("{") && string.hasSuffix("}") && !string.contains("\n") {
        print("📦 [DELEGATE] Detected complete JSON response (non-streaming)")
        processCompleteJsonResponse(string)
        receivedData = Data() // Clear buffer
        return
      }
      
      // Process as Server-Sent Events (streaming)
      let lines = string.components(separatedBy: .newlines)
      print("📦 [DELEGATE] Split into \(lines.count) lines for SSE processing")
      
      // Keep the last incomplete line in the buffer
      if lines.count > 1 {
        let completeLines = lines.dropLast()
        let incompleteData = lines.last?.data(using: .utf8) ?? Data()
        
        receivedData = incompleteData
        print("📦 [DELEGATE] Processing \(completeLines.count) complete SSE lines")
        
        // Process complete lines
        for (index, line) in completeLines.enumerated() {
          print("📦 [DELEGATE] Processing SSE line \(index + 1): \(line.prefix(100))...")
          processStreamingLine(line)
        }
      } else {
        print("📦 [DELEGATE] No complete SSE lines to process yet")
      }
    } else {
      print("❌ [DELEGATE] Failed to decode data as UTF-8 string")
    }
  }
  
  // Handle complete JSON response (fallback for non-streaming APIs)
  private func processCompleteJsonResponse(_ jsonString: String) {
    print("📋 [DELEGATE] Processing complete JSON response")
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { 
        print("❌ [DELEGATE] Self is nil in processCompleteJsonResponse")
        return 
      }
      
      if let data = jsonString.data(using: .utf8) {
        do {
          if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("📋 [DELEGATE] JSON parsed successfully: \(json.keys.joined(separator: ", "))")
            
            // Check for different response formats
            if let response = json["response"] as? String {
              print("✅ [DELEGATE] Found 'response' field: '\(response.prefix(50))...'")
              self.aiService?.appState?.updateStreamingResponse(response)
              
              // Update token counts if available
              if let usage = json["usage"] as? [String: Any] {
                if let totalTokens = usage["total_tokens"] as? Int {
                  self.aiService?.appState?.actualTokens = totalTokens
                  print("📊 [DELEGATE] Updated token count: \(totalTokens)")
                }
              }
              
              self.aiService?.appState?.completeStreaming()
            } else if let text = json["text"] as? String {
              print("✅ [DELEGATE] Found 'text' field: '\(text.prefix(50))...'")
              self.aiService?.appState?.updateStreamingResponse(text)
              self.aiService?.appState?.completeStreaming()
            } else {
              print("⚠️ [DELEGATE] No recognized text field in JSON: \(json)")
              self.aiService?.appState?.handleStreamingError("Unexpected response format")
            }
          } else {
            print("❌ [DELEGATE] Failed to parse complete JSON")
            self.aiService?.appState?.handleStreamingError("Invalid JSON response")
          }
        } catch {
          print("❌ [DELEGATE] JSON parsing error: \(error.localizedDescription)")
          self.aiService?.appState?.handleStreamingError("JSON parsing failed: \(error.localizedDescription)")
        }
      } else {
        print("❌ [DELEGATE] Failed to create data from complete JSON string")
        self.aiService?.appState?.handleStreamingError("Failed to process response")
      }
    }
  }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didCompleteWithError error: Error?) {
    print("🏁 [DELEGATE] URLSession task completed")
    DispatchQueue.main.async { [weak self] in
      if let error = error {
        print("❌ [DELEGATE] Streaming completed with error: \(error.localizedDescription)")
        self?.aiService?.appState?.handleStreamingError(error.localizedDescription)
      } else {
        print("✅ [DELEGATE] Streaming completed successfully")
      
        self?.aiService?.appState?.completeStreaming()
      }
    }
  }
  
  private func processStreamingLine(_ line: String) {
    print("🔍 [LINE] Processing line: '\(line)'")
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { 
        print("❌ [LINE] Self is nil, cannot process line")
        return 
      }
      
      if line.hasPrefix("data: ") {
        let jsonString = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
        print("📋 [LINE] Found data line, JSON: '\(jsonString)'")
        
        // Handle completion signal
        if jsonString == "[DONE]" || jsonString.contains("[DONE") {
          print("🏁 [LINE] Received [DONE] signal")
          self.aiService?.appState?.completeStreaming()
          return
        }
        
        if jsonString.isEmpty {
          print("⚠️ [LINE] Empty JSON string, skipping")
          return
        }
        
        if let data = jsonString.data(using: .utf8) {
          print("📋 [LINE] JSON data created successfully")
          do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
              print("📋 [LINE] JSON parsed successfully: \(json.keys.joined(separator: ", "))")
              
              // Look for 'response' field (your API format)
              if let chunk = json["response"] as? String {
                print("✅ [LINE] Found response chunk: '\(chunk)'")
                if !chunk.isEmpty {
                  self.aiService?.appState?.updateStreamingResponse(chunk)
                }
                
                // Update token counts if available
                if let usage = json["usage"] as? [String: Any] {
                  if let totalTokens = usage["total_tokens"] as? Int {
                    self.aiService?.appState?.actualTokens = totalTokens
                    print("📊 [LINE] Updated token count: \(totalTokens)")
                  }
                }
                
                // Update progress indicator based on 'p' field length
                if let progressString = json["p"] as? String {
                  let progress = min(Double(progressString.count) / 50.0, 1.0) // Normalize to 0-1
                  self.aiService?.appState?.streamingProgress = progress
                  print("📈 [LINE] Updated progress: \(progress)")
                }
              } else {
                print("⚠️ [LINE] No 'response' field in JSON: \(json)")
                
                // Fallback: check for other possible text fields
                if let text = json["text"] as? String {
                  print("✅ [LINE] Found fallback text field: '\(text)'")
                  if !text.isEmpty {
                    self.aiService?.appState?.updateStreamingResponse(text)
                  }
                }
              }
            } else {
              print("❌ [LINE] Failed to parse JSON object")
            }
          } catch {
            print("❌ [LINE] JSON parsing error: \(error.localizedDescription)")
          }
        } else {
          print("❌ [LINE] Failed to create data from JSON string")
        }
      } else if line.hasPrefix("event: error") {
        print("❌ [LINE] Received error event")
        self.aiService?.appState?.handleStreamingError("Streaming error occurred")
      } else if line.hasPrefix("event: ") {
        print("ℹ️ [LINE] Received event: '\(line)'")
      } else if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        print("⚠️ [LINE] Unknown line format: '\(line)'")
      }
    }
  }
}
