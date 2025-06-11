import Foundation

/// A structured approach to generating AI prompts based on different scenarios and needs
class PromptManager {

  // MARK: - Prompt Template Model

  /// Represents a single prompt template with conditions for when to apply it
  struct PromptTemplate {
    let name: String
    let systemPrompt: String
    let promptBuilder: (String, String?) -> String
    let matcher: (String, String?) -> Bool

    init(
      name: String,
      systemPrompt: String,
      matcher: @escaping (String, String?) -> Bool,
      promptBuilder: @escaping (String, String?) -> String
    ) {
      self.name = name
      self.systemPrompt = systemPrompt
      self.matcher = matcher
      self.promptBuilder = promptBuilder
    }
  }

  // MARK: - Properties

  /// Collection of available prompt templates
  private let templates: [PromptTemplate]

  // MARK: - Initialization

  init() {
    // Register all available prompt templates
    self.templates = [
      // Rewriting template
      PromptTemplate(
        name: "Text Rewriting",
        systemPrompt: """
          You are a precise text optimization tool. Your only job is to rewrite the provided text to be clearer and more concise while preserving all meaning. 
          Output ONLY the rewritten text - no explanations, no labels, no variations, no extra information. 
          Return exactly ONE optimized version with no markup unless it appeared in the original.
          """,
        matcher: { query, _ in
          query.lowercased().contains("rewrite") || query.lowercased().contains("revise")
            || query.lowercased().contains("improve") || query.lowercased().contains("better")
            || query.lowercased().contains("enhance")
        },
        promptBuilder: { query, selectedText in
          if let text = selectedText, !text.isEmpty {
            return """
              INSTRUCTION: \(query)

              TEXT TO REWRITE:
              \(text)
              """
          } else {
            return "REWRITE: \(query)"
          }
        }
      ),

      // Code modification template
      PromptTemplate(
        name: "Code Editing",
        systemPrompt: """
          You are a code expert. Return ONLY the modified code or solution without any explanations or comments outside the code. 
          Format the code properly but don't include any text before or after the code block.
          """,
        matcher: { query, selectedText in
          let codePatterns = ["code", "function", "api", "import", "class", "method", "bug", "fix"]
          let codeKeywords = [
            "import ", "func ", "class ", "struct ", "enum ", "protocol ", "extension ",
            "def ", "function ", "var ", "let ", "const ", "public ", "private ",
          ]

          // Check if query contains code-related terms
          let queryHasCodeTerms = codePatterns.contains { query.lowercased().contains($0) }

          // Check if selected text contains code patterns
          let textHasCodePatterns =
            if let text = selectedText {
              codeKeywords.contains { keyword in
                text.contains(keyword)
              }
            } else {
              false
            }

          return queryHasCodeTerms || textHasCodePatterns
        },
        promptBuilder: { query, selectedText in
          if let text = selectedText, !text.isEmpty {
            return """
              INSTRUCTION: \(query)

              CODE:
              ```
              \(text)
              ```
              """
          } else {
            return "CODE TASK: \(query)"
          }
        }
      ),

      // Translation template
      PromptTemplate(
        name: "Translation",
        systemPrompt: """
          You are a language translation tool. Translate the provided text accurately and nothing else.
          Output ONLY the translated text without any explanations, notes, or clarifications.
          """,
        matcher: { query, _ in
          query.lowercased().contains("translate") || query.lowercased().contains("translation")
            || query.lowercased().contains("in spanish") || query.lowercased().contains("in french")
            || query.lowercased().contains("in german")
            || query.lowercased().contains("in japanese")
            || query.lowercased().contains("in chinese")
        },
        promptBuilder: { query, selectedText in
          if let text = selectedText, !text.isEmpty {
            return """
              INSTRUCTION: \(query)

              TEXT TO TRANSLATE:
              \(text)
              """
          } else {
            return "TRANSLATE: \(query)"
          }
        }
      ),

      // Writing template
      PromptTemplate(
        name: "Writing",
        systemPrompt: """
          You are a professional writing assistant. Create well-written content exactly as requested.
          Provide ONLY the requested text without explanations, introductions, or additional commentary.
          """,
        matcher: { query, _ in
          query.lowercased().contains("write") || query.lowercased().contains("compose")
            || query.lowercased().contains("draft") || query.lowercased().contains("create")
            || query.lowercased().contains("generate text")
        },
        promptBuilder: { query, selectedText in
          if let text = selectedText, !text.isEmpty {
            return """
              INSTRUCTION: \(query)

              CONTEXT:
              \(text)
              """
          } else {
            return "WRITING TASK: \(query)"
          }
        }
      ),

      // Summarization template
      PromptTemplate(
        name: "Summarization",
        systemPrompt: """
          You are a summarization tool. Provide only a concise summary of the given text.
          The summary should be clear, accurate, and contain only the key points.
          Output ONLY the summary without any explanations or additional text.
          """,
        matcher: { query, _ in
          query.lowercased().contains("summarize") || query.lowercased().contains("summary")
            || query.lowercased().contains("tldr") || query.lowercased().contains("shorten")
        },
        promptBuilder: { query, selectedText in
          if let text = selectedText, !text.isEmpty {
            return """
              INSTRUCTION: \(query)

              TEXT TO SUMMARIZE:
              \(text)
              """
          } else {
            return "SUMMARIZE: \(query)"
          }
        }
      ),

      // Default fallback template
      PromptTemplate(
        name: "General",
        systemPrompt: """
          You are a direct assistant that provides only answers with no explanations.
          Do not begin with acknowledgments or end with pleasantries.
          Respond with ONLY the exact output requested.
          """,
        matcher: { _, _ in
          // This is a catch-all that always matches
          return true
        },
        promptBuilder: { query, selectedText in
          if let text = selectedText, !text.isEmpty {
            return """
              INSTRUCTION: \(query)

              CONTENT:
              \(text)
              """
          } else {
            return query
          }
        }
      ),
    ]
  }

  // MARK: - Public Methods

  /// Generate a prompt based on the query and optional selected text
  /// - Parameters:
  ///   - query: The user's query or instruction
  ///   - selectedText: Optional text that the user has selected
  /// - Returns: A tuple containing the system prompt and the content prompt
  func generatePrompt(for query: String, selectedText: String? = nil) -> (
    systemPrompt: String, promptContent: String
  ) {
    // Find the first matching template
    let matchedTemplate =
      templates.first { template in
        template.matcher(query, selectedText)
      } ?? templates.last!  // Fallback to the last template (which is our catch-all)

    // Generate the prompt using the template
    let promptContent = matchedTemplate.promptBuilder(query, selectedText)
    let systemPrompt = matchedTemplate.systemPrompt

    // Log what template was selected for debugging
    print("Using prompt template: \(matchedTemplate.name)")

    return (systemPrompt, promptContent)
  }

  /// Add a response format directive to ensure AI responds correctly
  /// - Parameter promptContent: The original prompt content
  /// - Returns: Prompt content with the response format directive
  func addResponseFormat(to promptContent: String, type: String = "general") -> String {
    // Remove any existing response format directives
    let cleaned = promptContent.replacingOccurrences(
      of: "<response_format>.*?</response_format>",
      with: "",
      options: [.regularExpression]
    )

    // Response format directive based on type
    let formatDirective: String

    switch type.lowercased() {
    case "rewrite", "revision", "improve":
      formatDirective =
        "<response_format>Provide only the rewritten text without any explanations, introductions, conclusions, or repetitions.</response_format>"
    case "code", "function", "api":
      formatDirective =
        "<response_format>Provide only the code solution without any explanations, introductions, conclusions, or discussion.</response_format>"
    case "translate", "translation":
      formatDirective =
        "<response_format>Provide only the translated text without any explanations, introductions, or additional text.</response_format>"
    case "summary", "summarize":
      formatDirective =
        "<response_format>Provide only the summary without any explanations, introductions, or additional text.</response_format>"
    case "write", "compose", "create":
      formatDirective =
        "<response_format>Provide only the requested text without any explanations, introductions, or additional commentary.</response_format>"
    default:
      formatDirective =
        "<response_format>Provide only the direct answer without any explanations, introductions, conclusions, or repetitions.</response_format>"
    }

    return formatDirective + "\n\n" + cleaned
  }

  // Create a specialized prompt for file analysis
  func createFileAnalysisPrompt(fileDetails: [String: Any], userRequest: String?) -> String {
    // Extract key file information
    let fileName = fileDetails["name"] as? String ?? "unknown file"
    let filePath = fileDetails["path"] as? String ?? ""
    let fileType = fileDetails["type"] as? String ?? "unknown type"
    let fileSize = fileDetails["size"] as? UInt64 ?? 0

    // Format file size nicely
    let formattedSize: String
    if fileSize < 1024 {
      formattedSize = "\(fileSize) bytes"
    } else if fileSize < 1024 * 1024 {
      formattedSize = String(format: "%.2f KB", Double(fileSize) / 1024)
    } else if fileSize < 1024 * 1024 * 1024 {
      formattedSize = String(format: "%.2f MB", Double(fileSize) / (1024 * 1024))
    } else {
      formattedSize = String(format: "%.2f GB", Double(fileSize) / (1024 * 1024 * 1024))
    }

    // Start building the prompt
    var prompt = """
      # File Analysis Task

      You are analyzing the following file:

      - **Name**: \(fileName)
      - **Path**: \(filePath)
      - **Type**: \(fileType)
      - **Size**: \(formattedSize)

      """

    // Add dates if available
    if let creationDate = fileDetails["creationDate"] as? Date {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .medium
      prompt += "- **Created**: \(formatter.string(from: creationDate))\n"
    }

    if let modificationDate = fileDetails["modificationDate"] as? Date {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .medium
      prompt += "- **Modified**: \(formatter.string(from: modificationDate))\n"
    }

    // Add dimensions for images
    if let width = fileDetails["width"] as? Int,
      let height = fileDetails["height"] as? Int
    {
      prompt += "- **Dimensions**: \(width) × \(height) pixels\n"
    }

    // Add content type-specific information
    if fileType.contains("image") {
      prompt += "\n## Image Details\n"

      // Add image format details if available
      if let bitsPerPixel = fileDetails["bitsPerPixel"] as? Int {
        prompt += "- **Bits per pixel**: \(bitsPerPixel)\n"
      }

      if let colorSpace = fileDetails["colorSpace"] as? String {
        prompt += "- **Color space**: \(colorSpace)\n"
      }

      // Add base64 snippet if available
      if let base64 = fileDetails["base64"] as? String {
        let previewLength = min(50, base64.count)
        prompt += "- **Base64 preview**: \(base64.prefix(previewLength))...\n"
        prompt += "- **Full Base64 data is available** (length: \(base64.count) characters)\n"
      }
    } else if fileType.contains("PDF") {
      prompt += "\n## PDF Details\n"

      if let pageCount = fileDetails["pageCount"] as? Int {
        prompt += "- **Number of pages**: \(pageCount)\n"
      }

      // Add PDF metadata if available
      let pdfMetadataKeys = fileDetails.keys.filter { $0.hasPrefix("pdf_") }
      if !pdfMetadataKeys.isEmpty {
        prompt += "- **Metadata**:\n"
        for key in pdfMetadataKeys {
          if let value = fileDetails[key] {
            let cleanKey = key.replacingOccurrences(of: "pdf_", with: "")
            prompt += "  - \(cleanKey): \(value)\n"
          }
        }
      }
    } else if fileType.contains("text") {
      prompt += "\n## Text File Details\n"

      if let lineCount = fileDetails["lineCount"] as? Int {
        prompt += "- **Number of lines**: \(lineCount)\n"
      }

      if let textPreview = fileDetails["textPreview"] as? String {
        prompt += "\n### Content Preview:\n"
        prompt += "```\n\(textPreview)\n```\n"
      }
    }

    // Add user's specific request if provided
    if let request = userRequest, !request.isEmpty {
      prompt += "\n## Your Task\n\n"
      prompt += "The user has requested: \"\(request)\"\n\n"
    } else {
      // Default instructions if no specific request
      prompt += "\n## Your Task\n\n"
      prompt += """
        Please analyze this file and provide the following:

        1. A summary of what this file appears to be
        2. Key information extracted from the metadata
        3. Suggestions for how this file might be used
        4. Any potential issues or concerns with the file

        If it's an image or document, describe what it likely contains based on the metadata.
        If you see a base64 string, DO NOT try to decode it in your response.
        """
    }

    return prompt
  }
}
