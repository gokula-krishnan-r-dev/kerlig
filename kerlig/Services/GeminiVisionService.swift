import AppKit
import Foundation
import PDFKit
import UniformTypeIdentifiers

class GeminiVisionService {
  // API URL for Gemini Vision API (Updated to use Gemini 1.5 Flash)
  private let baseURL =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"

  // API key - should be stored securely in a real app
  private var apiKey: String {
    return "AIzaSyDEOpIpJOPOnbTUP61BI9s_kyFPBHnUgow"
  }

  // MARK: - Main Processing Methods
  
  // Process any file type with intelligent routing
  func processFile(
    fileURL: URL, prompt: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    do {
      let resourceValues = try fileURL.resourceValues(forKeys: [.contentTypeKey])
      guard let contentType = resourceValues.contentType else {
        completion(.failure(GeminiError.invalidFileType("Cannot determine file type")))
        return
      }
      
      // Route to appropriate processing method based on file type with fallback to extension
      if contentType.conforms(to: .image) {
        processImageFile(fileURL: fileURL, prompt: prompt, completion: completion)
      } else if contentType.conforms(to: .pdf) {
        processPDFFile(fileURL: fileURL, prompt: prompt, completion: completion)
      } else if isDocumentType(contentType) || isDocumentByExtension(fileURL.pathExtension) {
        processDocumentFile(fileURL: fileURL, prompt: prompt, completion: completion)
      } else if isSpreadsheetType(contentType) || isSpreadsheetByExtension(fileURL.pathExtension) {
        processSpreadsheetFile(fileURL: fileURL, prompt: prompt, completion: completion)
      } else if contentType.conforms(to: .text) || isTextByExtension(fileURL.pathExtension) {
        processTextFile(fileURL: fileURL, prompt: prompt, completion: completion)
      } else {
        processGenericFile(fileURL: fileURL, prompt: prompt, completion: completion)
      }
      
    } catch {
      completion(.failure(error))
    }
  }

  // Process an image file with Gemini Vision
  func processImageFile(
    fileURL: URL, prompt: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    do {
      // Check if the file is an image
      let fileType = try fileURL.resourceValues(forKeys: [.contentTypeKey]).contentType
      guard fileType?.conforms(to: .image) == true else {
        completion(.failure(GeminiError.invalidFileType("File is not an image")))
        return
      }

      // Load the image data
      guard let image = NSImage(contentsOf: fileURL),
        let imageData = image.tiffRepresentation,
        let bitmapImage = NSBitmapImageRep(data: imageData),
        let jpegData = bitmapImage.representation(using: .jpeg, properties: [:])
      else {
        completion(.failure(GeminiError.imageProcessingError("Failed to process image")))
        return
      }

      // Convert image to base64
      let base64String = jpegData.base64EncodedString()

      // Send to Gemini Vision API
      sendToGeminiVision(base64Image: base64String, prompt: prompt, completion: completion)
    } catch {
      completion(.failure(error))
    }
  }
  
  // Process PDF files with comprehensive analysis
  func processPDFFile(
    fileURL: URL, prompt: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    guard let pdfDocument = PDFDocument(url: fileURL) else {
      completion(.failure(GeminiError.invalidFileType("Cannot open PDF file")))
      return
    }
    
    let pageCount = pdfDocument.pageCount
    var analysis = "PDF Analysis:\n"
    analysis += "File: \(fileURL.lastPathComponent)\n"
    analysis += "Pages: \(pageCount)\n\n"
    
    // Extract text content from all pages
    var fullText = ""
    for pageIndex in 0..<min(pageCount, 10) { // Limit to first 10 pages
      if let page = pdfDocument.page(at: pageIndex),
         let pageText = page.string {
        fullText += "Page \(pageIndex + 1):\n\(pageText)\n\n"
      }
    }
    
    if !fullText.isEmpty {
      // Process text content with Gemini
      let textPrompt = "\(prompt)\n\nPDF Content:\n\(fullText)"
      sendTextToGemini(text: textPrompt, completion: completion)
    } else {
      // If no text, try to convert first page to image
      if let firstPage = pdfDocument.page(at: 0) {
        convertPDFPageToImage(page: firstPage, prompt: prompt, completion: completion)
      } else {
        completion(.failure(GeminiError.invalidFileType("Cannot extract content from PDF")))
      }
    }
  }
  
  // Process document files (DOC, DOCX, etc.)
  func processDocumentFile(
    fileURL: URL, prompt: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    let fileName = fileURL.lastPathComponent
    let fileExtension = fileURL.pathExtension.lowercased()
    
    do {
      let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
      let fileSize = attributes[.size] as? Int64 ?? 0
      let modificationDate = attributes[.modificationDate] as? Date
      
      var analysis = "Document Analysis:\n"
      analysis += "File: \(fileName)\n"
      analysis += "Type: \(getDocumentTypeDescription(fileExtension))\n"
      analysis += "Size: \(formatFileSize(fileSize))\n"
      
      if let date = modificationDate {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        analysis += "Modified: \(formatter.string(from: date))\n"
      }
      
      analysis += "\nDocument Type: \(fileExtension.uppercased())\n"
      analysis += "Recommended Actions:\n"
      analysis += "• Open with appropriate application for full content analysis\n"
      analysis += "• Export as PDF or text format for AI analysis\n"
      analysis += "• Use document-specific tools for advanced processing\n\n"
      
      if !prompt.isEmpty {
        analysis += "User Request: \(prompt)\n"
        analysis += "Response: I can see this is a \(getDocumentTypeDescription(fileExtension)) file. To provide detailed analysis of the content, please export it as a PDF or text file, or share specific questions about the document structure or content."
      }
      
      completion(.success(analysis))
    } catch {
      completion(.failure(error))
    }
  }
  
  // Process spreadsheet files (Excel, Numbers, etc.)
  func processSpreadsheetFile(
    fileURL: URL, prompt: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    let fileName = fileURL.lastPathComponent
    let fileExtension = fileURL.pathExtension.lowercased()
    
    do {
      let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
      let fileSize = attributes[.size] as? Int64 ?? 0
      
      var analysis = "Spreadsheet Analysis:\n"
      analysis += "File: \(fileName)\n"
      analysis += "Type: \(getSpreadsheetTypeDescription(fileExtension))\n"
      analysis += "Size: \(formatFileSize(fileSize))\n\n"
      
      analysis += "Spreadsheet Features:\n"
      analysis += "• Likely contains tabular data, formulas, and charts\n"
      analysis += "• May have multiple sheets/tabs\n"
      analysis += "• Could include financial data, analytics, or structured information\n\n"
      
      analysis += "Recommended Actions:\n"
      analysis += "• Export as CSV for data analysis\n"
      analysis += "• Convert to PDF for visual analysis\n"
      analysis += "• Use spreadsheet applications for detailed examination\n\n"
      
      if !prompt.isEmpty {
        analysis += "User Request: \(prompt)\n"
        analysis += "Response: I can see this is a \(getSpreadsheetTypeDescription(fileExtension)) file. For detailed analysis of the data, formulas, or charts, please export it as CSV for data analysis or PDF for visual examination."
      }
      
      completion(.success(analysis))
    } catch {
      completion(.failure(error))
    }
  }
  
  // Process text files
  func processTextFile(
    fileURL: URL, prompt: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    do {
      let content = try String(contentsOf: fileURL, encoding: .utf8)
      let fileName = fileURL.lastPathComponent
      
      // Limit content for processing
      let maxLength = 5000 // Reasonable limit for text processing
      let processedContent = content.count > maxLength ? String(content.prefix(maxLength)) + "...\n[Content truncated]" : content
      
      let textPrompt = """
      File: \(fileName)
      Content Type: Text File
      
      \(prompt)
      
      File Content:
      \(processedContent)
      """
      
      sendTextToGemini(text: textPrompt, completion: completion)
    } catch {
      completion(.failure(error))
    }
  }
  
  // Process generic files
  func processGenericFile(
    fileURL: URL, prompt: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    let fileName = fileURL.lastPathComponent
    let fileExtension = fileURL.pathExtension.lowercased()
    
    do {
      let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
      let fileSize = attributes[.size] as? Int64 ?? 0
      let modificationDate = attributes[.modificationDate] as? Date
      
      var analysis = "File Analysis:\n"
      analysis += "File: \(fileName)\n"
      analysis += "Extension: .\(fileExtension)\n"
      analysis += "Size: \(formatFileSize(fileSize))\n"
      
      if let date = modificationDate {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        analysis += "Modified: \(formatter.string(from: date))\n"
      }
      
      analysis += "\nFile Type: \(describeFileType(fileExtension))\n"
      analysis += "Status: File detected but specialized processing not available\n\n"
      
      if !prompt.isEmpty {
        analysis += "User Request: \(prompt)\n"
        analysis += "Response: I can see information about this \(fileExtension.uppercased()) file, but I don't have specialized processing capabilities for this file type. If you have specific questions about the file or need it analyzed, consider converting it to a supported format (PDF, image, or text) or using appropriate specialized tools."
      }
      
      completion(.success(analysis))
    } catch {
      completion(.failure(error))
    }
  }

  // Process a FileDetails object with Gemini Vision
  func processFileDetails(
    fileDetails: FileDetailsCapture.FileDetails, prompt: String,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    // Check if we have base64 data and it's an image
    if let base64 = fileDetails.base64, fileDetails.type.lowercased().contains("image") {
      // Send directly to Gemini Vision API
      sendToGeminiVision(base64Image: base64, prompt: prompt, completion: completion)
    } else if let path = fileDetails.path.isEmpty ? nil : fileDetails.path {
      // We have a file path, process the file
      let fileURL = URL(fileURLWithPath: path)
      processFile(fileURL: fileURL, prompt: prompt, completion: completion)
    } else {
      // No usable data
      completion(.failure(GeminiError.invalidFileType("File cannot be processed")))
    }
  }

  // MARK: - Helper Methods
  
  // Convert PDF page to image for vision processing
  private func convertPDFPageToImage(
    page: PDFPage, prompt: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    let pageRect = page.bounds(for: .mediaBox)
    let image = NSImage(size: pageRect.size)
    
    image.lockFocus()
    if let context = NSGraphicsContext.current?.cgContext {
      context.saveGState()
      context.translateBy(x: 0, y: pageRect.size.height)
      context.scaleBy(x: 1.0, y: -1.0)
      page.draw(with: .mediaBox, to: context)
      context.restoreGState()
    }
    image.unlockFocus()
    
    // Convert to JPEG and then to base64
    guard let imageData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: imageData),
          let jpegData = bitmapImage.representation(using: .jpeg, properties: [:]) else {
      completion(.failure(GeminiError.imageProcessingError("Failed to convert PDF page to image")))
      return
    }
    
    let base64String = jpegData.base64EncodedString()
    sendToGeminiVision(base64Image: base64String, prompt: prompt, completion: completion)
  }
  
  // Send text to Gemini (text-only model)
  private func sendTextToGemini(
    text: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    // Use the text-only Gemini model for text processing
    let textURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    guard !apiKey.isEmpty else {
      completion(.failure(GeminiError.missingAPIKey))
      return
    }
    
    guard let url = URL(string: "\(textURL)?key=\(apiKey)") else {
      completion(.failure(GeminiError.invalidURL))
      return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let payload: [String: Any] = [
      "contents": [
        [
          "parts": [
            ["text": text]
          ]
        ]
      ],
      "generationConfig": [
        "temperature": 0.4,
        "topK": 32,
        "topP": 1,
        "maxOutputTokens": 2048,
      ],
    ]
    
    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    } catch {
      completion(.failure(error))
      return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }
      
      guard let data = data else {
        completion(.failure(GeminiError.noData))
        return
      }
      
      do {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
          completion(.success(text))
        } else {
          let responseString = String(data: data, encoding: .utf8) ?? "Could not decode response"
          completion(.failure(GeminiError.parsingError(responseString)))
        }
      } catch {
        completion(.failure(error))
      }
    }
    
    task.resume()
  }
  
  // Check if content type is a document - Safe implementation without force unwrapping
  private func isDocumentType(_ type: UTType) -> Bool {
    // First try with known UTTypes that should always be available
    if type.conforms(to: .data) {
      // Check with fallback to identifier strings
      let documentIdentifiers = [
        "com.microsoft.word.doc",
        "org.openxmlformats.wordprocessingml.document", // docx
        "com.microsoft.powerpoint.ppt",
        "org.openxmlformats.presentationml.presentation", // pptx
        "org.oasis-open.opendocument.text", // odt
        "com.apple.keynote.key",
        "com.apple.pages.pages",
        "public.rtf"
      ]
      
      // Check if the type identifier matches any document type
      return documentIdentifiers.contains(type.identifier)
    }
    
    return false
  }
  
  // Check if content type is a spreadsheet - Safe implementation without force unwrapping  
  private func isSpreadsheetType(_ type: UTType) -> Bool {
    // First try with known UTTypes that should always be available
    if type.conforms(to: .data) {
      // Check with fallback to identifier strings
      let spreadsheetIdentifiers = [
        "com.microsoft.excel.xls",
        "org.openxmlformats.spreadsheetml.sheet", // xlsx
        "org.oasis-open.opendocument.spreadsheet", // ods
        "com.apple.numbers.numbers",
        "public.comma-separated-values-text" // csv
      ]
      
      // Check if the type identifier matches any spreadsheet type
      return spreadsheetIdentifiers.contains(type.identifier)
    }
    
    return false
  }
  
  // Get document type description
  private func getDocumentTypeDescription(_ fileExtension: String) -> String {
    switch fileExtension.lowercased() {
    case "doc", "docx": return "Microsoft Word Document"
    case "ppt", "pptx": return "Microsoft PowerPoint Presentation" 
    case "odt": return "OpenDocument Text"
    case "odp": return "OpenDocument Presentation"
    case "pages": return "Apple Pages Document"
    case "key": return "Apple Keynote Presentation"
    case "rtf": return "Rich Text Format Document"
    default: return "Document File"
    }
  }
  
  // Get spreadsheet type description
  private func getSpreadsheetTypeDescription(_ fileExtension: String) -> String {
    switch fileExtension.lowercased() {
    case "xls", "xlsx": return "Microsoft Excel Spreadsheet"
    case "ods": return "OpenDocument Spreadsheet"
    case "numbers": return "Apple Numbers Spreadsheet"
    case "csv": return "Comma-Separated Values File"
    default: return "Spreadsheet File"
    }
  }
  
  // Describe file type
  private func describeFileType(_ fileExtension: String) -> String {
    switch fileExtension.lowercased() {
    case "pdf": return "PDF Document"
    case "doc", "docx": return "Word Document"
    case "xls", "xlsx": return "Excel Spreadsheet"
    case "ppt", "pptx": return "PowerPoint Presentation"
    case "numbers": return "Numbers Spreadsheet"
    case "odt": return "OpenDocument Text"
    case "odp": return "OpenDocument Presentation"
    case "pages": return "Pages Document"
    case "key": return "Keynote Presentation"
    case "rtf": return "Rich Text Format Document"
    case "txt": return "Text File"
    case "md": return "Markdown Document"
    case "json": return "JSON Data File"
    case "xml": return "XML Document"
    case "csv": return "Spreadsheet Data"
    case "zip", "rar", "7z": return "Compressed Archive"
    case "mp3", "wav", "flac": return "Audio File"
    case "mp4", "avi", "mov": return "Video File"
    case "png", "jpg", "jpeg", "gif": return "Image File"
    default: return "File"
    }
  }
  
  // Format file size
  private func formatFileSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
  
  // MARK: - Extension-based fallback detection methods
  // Check if file extension indicates a document
  private func isDocumentByExtension(_ fileExtension: String) -> Bool {
    let documentExtensions = ["doc", "docx", "ppt", "pptx", "odt", "odp", "pages", "key", "rtf"]
    return documentExtensions.contains(fileExtension.lowercased())
  }
  
  // Check if file extension indicates a spreadsheet
  private func isSpreadsheetByExtension(_ fileExtension: String) -> Bool {
    let spreadsheetExtensions = ["xls", "xlsx", "ods", "numbers", "csv"]
    return spreadsheetExtensions.contains(fileExtension.lowercased())
  }
  
  // Check if file extension indicates a text file
  private func isTextByExtension(_ fileExtension: String) -> Bool {
    let textExtensions = ["txt", "md", "json", "xml", "log", "py", "js", "html", "css", "swift", "java", "cpp", "c", "h", "rb", "php", "go", "rs", "ts", "jsx", "tsx", "vue", "yaml", "yml", "toml", "ini", "cfg", "conf"]
    return textExtensions.contains(fileExtension.lowercased())
  }

  // Send base64 encoded image to Gemini Vision API
  private func sendToGeminiVision(
    base64Image: String, prompt: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    // Check if API key is available
    guard !apiKey.isEmpty else {
      completion(.failure(GeminiError.missingAPIKey))
      return
    }

    // Create the full URL with API key
    guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
      completion(.failure(GeminiError.invalidURL))
      return
    }

    // Create the request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    // Create the payload
    let payload: [String: Any] = [
      "contents": [
        [
          "parts": [
            ["text": prompt],
            [
              "inline_data": [
                "mime_type": "image/jpeg",
                "data": base64Image,
              ]
            ],
          ]
        ]
      ],
      "generationConfig": [
        "temperature": 0.4,
        "topK": 32,
        "topP": 1,
        "maxOutputTokens": 2048,
      ],
    ]

    // Convert payload to JSON
    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    } catch {
      completion(.failure(error))
      return
    }

    // Make the API call
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data else {
        completion(.failure(GeminiError.noData))
        return
      }

      do {
        // Parse the JSON response
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let candidates = json["candidates"] as? [[String: Any]],
          let firstCandidate = candidates.first,
          let content = firstCandidate["content"] as? [String: Any],
          let parts = content["parts"] as? [[String: Any]],
          let firstPart = parts.first,
          let text = firstPart["text"] as? String
        {
          completion(.success(text))
        } else {
          // If we can't parse the JSON structure, return the raw response
          let responseString = String(data: data, encoding: .utf8) ?? "Could not decode response"
          completion(.failure(GeminiError.parsingError(responseString)))
        }
      } catch {
        completion(.failure(error))
      }
    }

    task.resume()
  }
}

// MARK: - Error Handling
enum GeminiError: Error, LocalizedError {
  case invalidFileType(String)
  case imageProcessingError(String)
  case missingAPIKey
  case invalidURL
  case noData
  case parsingError(String)

  var errorDescription: String? {
    switch self {
    case .invalidFileType(let message): return "Invalid file type: \(message)"
    case .imageProcessingError(let message): return "Image processing error: \(message)"
    case .missingAPIKey: return "Missing API key"
    case .invalidURL: return "Invalid URL"
    case .noData: return "No data received"
    case .parsingError(let response): return "Failed to parse response: \(response)"
    }
  }
}
