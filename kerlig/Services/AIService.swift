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
  private let baseURL = "http://localhost:8080/ai/generate"  // Update with your actual API URL
  private let logger = Logger.shared
  private let geminiVisionService = GeminiVisionService()  // Add Gemini Vision service
  @EnvironmentObject var appState: AppState

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

  func generateResponse(prompt: String, systemPrompt: String, model: String , type: String? = nil) -> AnyPublisher<
    String, Error
  > {
    logger.log("Generating response with \(systemPrompt) model: \(model)", level: .info)

    // Check if type indicates a file and route to appropriate service
    if let fileType = type, shouldUseGeminiVision(for: fileType) {
      return handleFileWithGeminiVision(prompt: prompt, systemPrompt: systemPrompt, type: fileType)
    }
    
    // Standard text processing
    guard let url = URL(string: baseURL) else {
      logger.log("Invalid URL: \(baseURL)", level: .error)
      return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
    }

    // Create the request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    // Construct a dynamic payload with model preference from UserDefaults
    // and structured instruction template for AI responses
    let payload: [String: Any] = [
      "model": UserDefaults.standard.string(forKey: "aiModel")
        ?? "@cf/meta/llama-3.3-70b-instruct-fp8-fast",
      "text": prompt,
      "instruction": generateInstructionTemplate(systemPrompt: systemPrompt),
    ]

    logger.log("Payload prepared: \(payload)", level: .debug)

    // Convert payload to JSON
    guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
      logger.log("Failed to serialize payload to JSON", level: .error)
      return Fail(error: URLError(.cannotParseResponse)).eraseToAnyPublisher()
    }
    request.httpBody = httpBody

    // Make the API call
    logger.log("Making API request to: \(url.absoluteString)", level: .debug)

    return URLSession.shared.dataTaskPublisher(for: request)
      .tryMap { [weak self] data, response -> Data in
        guard let self = self else { throw APIError.invalidResponse }
        guard let httpResponse = response as? HTTPURLResponse else {
          self.logger.log("Invalid HTTP response", level: .error)
          throw APIError.invalidResponse
        }

        let responseData = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        self.logger.log(
          "Received API response with status code: \(httpResponse.statusCode)", level: .debug)
        self.logger.log("Response body: \(responseData)", level: .debug)

        if !(200...299).contains(httpResponse.statusCode) {
          self.logger.log(
            "API error: Status \(httpResponse.statusCode) - \(responseData)", level: .error)
          throw APIError.serverError(statusCode: httpResponse.statusCode, message: responseData)
        }

        return data
      }
      .decode(type: AIResponse.self, decoder: JSONDecoder())
      .map { [weak self] response in
        self?.logger.log(
          "Successfully decoded response with \(response.usage?.totalTokens ?? 0) tokens",
          level: .info)
        if let toolCalls = response.toolCalls, !toolCalls.isEmpty {
          self?.logger.log("Response includes tool calls", level: .debug)
        }
        return response.response
      }
      .catch { [weak self] error -> AnyPublisher<String, Error> in
        self?.logger.log("API Error: \(error.localizedDescription)", level: .error)
        if let apiError = error as? APIError {
          self?.logger.log(
            "Detailed API error: \(apiError.errorDescription ?? "Unknown error")", level: .error)
        }
        return Fail(error: error).eraseToAnyPublisher()
      }
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }

  // Modified to use our internal ActionType
  func processWithAction(
    text: String, action: ActionType, apiKey: String, model: String, metadata: [String: Any]? = nil
  ) -> AnyPublisher<String, Error> {
    logger.log("Processing text with action: \(action.rawValue)", level: .info)

    // Check if this is a file analysis action and we have file details
    if action == .analyzeFile, let fileDetails = metadata?["fileDetails"] as? [String: Any] {
      // Use the prompt manager to create a specialized file analysis prompt
      let promptManager = PromptManager()
      let filePrompt = promptManager.createFileAnalysisPrompt(
        fileDetails: fileDetails, userRequest: text.isEmpty ? nil : text)

      logger.log("Using specialized file analysis prompt", level: .info)
      return generateResponse(prompt: filePrompt, systemPrompt: "", model: model)
    }

    // Standard processing for other action types
    return generateResponse(
      prompt: text,
      systemPrompt: action.systemPrompt,
      model: model
    )
  }

  // Quick simulated response for when API key isn't set up
  func simulateResponseForAction(text: String, action: ActionType) -> AnyPublisher<String, Error> {
    logger.log("Simulating response for action", level: .info)

    return Future<String, Error> { [weak self] promise in
      // Add a short delay to simulate processing
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        let response: String

        switch action {
        case .fixSpellingGrammar:
          response =
            "I've fixed the spelling and grammar issues in your text:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"

        case .improveWriting:
          response =
            "Here's an improved version of your text with better clarity and engagement:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"

        case .translate:
          let isEnglish = text.range(of: "[^a-zA-Z0-9\\s.,?!]", options: .regularExpression) == nil
          if isEnglish {
            response =
              "Voici la traduction en français:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
          } else {
            response =
              "Here's the English translation:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
          }

        case .makeShorter:
          let words = text.split(separator: " ")
          let shortenedCount = max(3, Int(Double(words.count) * 0.6))
          response =
            "Here's a more concise version:\n\n"
            + words.prefix(shortenedCount).joined(separator: " ")
        case .summarize:
          response =
            "Here's a summary of your text:\n\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
        case .analyzeFile:
          response = "Analyzing file details..."
        case .analyzeImage:
          response = "Analyzing image details..."
        }

        self?.logger.log("Generated simulated response", level: .debug)
        promise(.success(response))
      }
    }.eraseToAnyPublisher()
  }

  // Adapter method to convert from AIAction to our internal ActionType
  // This allows the existing code to keep working with AIAction
  func processWithAIAction(
    text: String, action: String, apiKey: String, model: String, metadata: [String: Any]? = nil
  ) -> AnyPublisher<String, Error> {
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

    return processWithAction(
      text: text, action: actionType, apiKey: apiKey, model: model, metadata: metadata)
  }

  // Adapter for simulate method
  func simulateResponseForAIAction(text: String, action: String) -> AnyPublisher<String, Error> {
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

    return simulateResponseForAction(text: text, action: actionType)
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
          self?.logger.log("Successfully processed file with Gemini Vision", level: .info)
          completion(.success(response))
        case .failure(let error):
          self?.logger.log("Failed to process file: \(error.localizedDescription)", level: .error)
          completion(.failure(error))
        }
      }
    }
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
