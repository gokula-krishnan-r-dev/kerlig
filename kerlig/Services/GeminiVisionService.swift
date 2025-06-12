import AppKit
import Foundation
import PDFKit
import UniformTypeIdentifiers

class GeminiVisionService {
  // API URL for Gemini Vision API (Using Pro Vision model)
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

      print("analysis: \(analysis)")

      // Convert document to text and combine with user prompt
      let extractedContent = convertDocToText(fileURL: fileURL)
      
      // Create comprehensive prompt for Gemini
      let combinedPrompt = """
      \(prompt)
      
      \(extractedContent)
      
      Please analyze this document and provide insights based on the user's request above and the extracted content.
      """

      // Process with Gemini text API
      sendTextToGemini(text: combinedPrompt, completion: completion)
      
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
    // Use the high-level Gemini Pro model for advanced text processing
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
        "temperature": 0.7,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 4096,
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
            print("text: \(text)")
          completion(.success(text))
        } else {
          let responseString = String(data: data, encoding: .utf8) ?? "Could not decode response"
          print("responseString: \(responseString)")
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
          print("text: \(text)")
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


// MARK: - Document Conversion

private func convertDocToText(fileURL: URL) -> String {
  let fileExtension = fileURL.pathExtension.lowercased()
  let fileName = fileURL.lastPathComponent
  
  // Create a comprehensive analysis prompt for the document
  var analysisText = """
  Document Analysis Request:
  
  File: \(fileName)
  Type: \(getDocumentTypeDescription(fileExtension: fileExtension))
  Path: \(fileURL.path)
  
  """
  
  // Add file metadata
  do {
    let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
    if let fileSize = attributes[.size] as? Int64 {
        analysisText += "Size: \(formatFileSize(bytes: fileSize))\n"
    }
    if let modificationDate = attributes[.modificationDate] as? Date {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .short
      analysisText += "Modified: \(formatter.string(from: modificationDate))\n"
    }
  } catch {
    analysisText += "Could not read file metadata: \(error.localizedDescription)\n"
  }
  
  analysisText += "\n"
  
  // Try different extraction methods based on file type
  switch fileExtension {
  case "docx":
    analysisText += extractDocxContent(fileURL: fileURL)
  case "doc":
    analysisText += extractDocContent(fileURL: fileURL)
  case "rtf":
    analysisText += extractRTFContent(fileURL: fileURL)
  case "pages":
    analysisText += extractPagesContent(fileURL: fileURL)
  case "odt":
    analysisText += extractODTContent(fileURL: fileURL)
  case "txt":
    analysisText += extractPlainTextContent(fileURL: fileURL)
  default:
    analysisText += extractGenericDocumentContent(fileURL: fileURL)
  }
  
  return analysisText
}

// MARK: - Document Content Extraction Methods

private func extractDocxContent(fileURL: URL) -> String {
  var content = "DOCX Document Content Extraction:\n\n"
  
  // Method 1: Try NSAttributedString with proper DOCX options
  if let extractedText = extractTextWithNSAttributedString(fileURL: fileURL) {
    content += "Extracted Text Content:\n"
    content += extractedText
    content += "\n\nDocument successfully parsed using NSAttributedString."
    return content
  }
  
  // Method 2: Extract from DOCX ZIP structure
  if let extractedText = extractTextFromDocxZip(fileURL: fileURL) {
    content += "Extracted Text Content (ZIP method):\n"
    content += extractedText
    content += "\n\nDocument successfully parsed by extracting from DOCX internal structure."
    return content
  }
  
  // Method 3: Try reading as plain text (sometimes works)
  if let extractedText = extractAsPlainText(fileURL: fileURL) {
    content += "Extracted Text Content (Plain text method):\n"
    content += extractedText
    content += "\n\nDocument parsed using plain text extraction."
    return content
  }
  
  // Final fallback: Analyze structure
  content += analyzeDocumentStructure(fileURL: fileURL)
  content += "\n\nNote: Multiple extraction methods attempted. This DOCX file may have complex formatting or protection that prevents text extraction."
  
  return content
}

// MARK: - Advanced Text Extraction Methods

private func extractTextWithNSAttributedString(fileURL: URL) -> String? {
  // Try multiple document type options
  let documentTypes: [NSAttributedString.DocumentType] = [
    .docFormat,
    .rtf,
    .html,
    .plain
  ]
  
  for docType in documentTypes {
    do {
      let attributedString = try NSAttributedString(
        url: fileURL,
        options: [
          .documentType: docType,
          .characterEncoding: String.Encoding.utf8.rawValue
        ],
        documentAttributes: nil
      )
      
      let text = attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
      if !text.isEmpty && text.count > 10 { // Ensure we got meaningful content
        return text
      }
    } catch {
      continue // Try next method
    }
  }
  
  return nil
}

private func extractTextFromDocxZip(fileURL: URL) -> String? {
  // DOCX files are ZIP archives containing XML files
  // The main document content is in word/document.xml
  
  do {
    // Create temporary directory for extraction
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    
    defer {
      // Clean up temporary directory
      try? FileManager.default.removeItem(at: tempDir)
    }
    
    // Try to unzip the DOCX file
    if let extractedText = unzipAndExtractDocxText(docxURL: fileURL, tempDir: tempDir) {
      return extractedText
    }
    
  } catch {
    print("Error extracting DOCX ZIP: \(error)")
  }
  
  return nil
}

private func unzipAndExtractDocxText(docxURL: URL, tempDir: URL) -> String? {
  do {
    // Method 1: Try using unzip command
    if let extractedText = extractUsingUnzipCommand(docxURL: docxURL, tempDir: tempDir) {
      return extractedText
    }
    
    // Method 2: Read the DOCX file as data and parse directly
    let docxData = try Data(contentsOf: docxURL)
    return extractTextFromDocxData(data: docxData)
    
  } catch {
    print("Error reading DOCX data: \(error)")
    return nil
  }
}

private func extractUsingUnzipCommand(docxURL: URL, tempDir: URL) -> String? {
  // Use the system's unzip command to extract the DOCX file
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
  process.arguments = ["-q", "-o", docxURL.path, "-d", tempDir.path]
  
  do {
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus == 0 {
      // Successfully extracted, now look for document.xml
      let documentXMLPath = tempDir.appendingPathComponent("word/document.xml")
      
      if FileManager.default.fileExists(atPath: documentXMLPath.path) {
        let xmlContent = try String(contentsOf: documentXMLPath, encoding: .utf8)
        return extractTextFromDocumentXML(xmlContent: xmlContent)
      }
    }
  } catch {
    print("Error using unzip command: \(error)")
  }
  
  return nil
}

private func extractTextFromDocumentXML(xmlContent: String) -> String? {
  var extractedText = ""
  
  // Parse Word document XML to extract text content
  // Look for <w:t> tags which contain the actual text
  do {
    let regex = try NSRegularExpression(pattern: "<w:t[^>]*>([^<]*)</w:t>", options: [])
    let matches = regex.matches(in: xmlContent, options: [], range: NSRange(location: 0, length: xmlContent.count))
    
    for match in matches {
      if match.numberOfRanges > 1 {
        let range = match.range(at: 1)
        if let swiftRange = Range(range, in: xmlContent) {
          let text = String(xmlContent[swiftRange])
          // Decode XML entities
          let decodedText = text
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
          
          extractedText += decodedText
        }
      }
    }
    
    // Also look for paragraph breaks
    let paragraphRegex = try NSRegularExpression(pattern: "</w:p>", options: [])
    let paragraphMatches = paragraphRegex.matches(in: xmlContent, options: [], range: NSRange(location: 0, length: xmlContent.count))
    
    // Add line breaks for paragraphs
    var result = extractedText
    for _ in paragraphMatches {
      result = result.replacingOccurrences(of: "</w:p>", with: "\n")
    }
    
    let cleanedText = result
      .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    
    return cleanedText.isEmpty ? nil : cleanedText
    
  } catch {
    print("Error parsing document XML: \(error)")
    return nil
  }
}

private func extractTextFromDocxData(data: Data) -> String? {
  // Convert data to string and look for text content
  // DOCX files contain XML, so we can try to extract text from XML-like structures
  
  if let dataString = String(data: data, encoding: .utf8) {
    return extractTextFromXMLString(xmlString: dataString)
  }
  
  // Try with different encodings
  if let dataString = String(data: data, encoding: .ascii) {
    return extractTextFromXMLString(xmlString: dataString)
  }
  
  // Try to find readable text in the binary data
  return extractReadableTextFromBinary(data: data)
}

private func extractTextFromXMLString(xmlString: String) -> String? {
  var extractedText = ""
  
  // Look for text between XML tags (simplified XML parsing)
  let patterns = [
    "<w:t[^>]*>([^<]*)</w:t>", // Word text elements (most important)
    "<w:instrText[^>]*>([^<]*)</w:instrText>", // Word instruction text
    "<text[^>]*>([^<]*)</text>", // Generic text elements
    ">([A-Za-z0-9\\s.,!?;:\"'()\\-_@#$%&*+=\\[\\]{}|\\\\/:;<>?~`]+)<" // Any readable text between angle brackets
  ]
  
  for pattern in patterns {
    do {
      let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
      let matches = regex.matches(in: xmlString, options: [], range: NSRange(location: 0, length: xmlString.count))
      
      for match in matches {
        if match.numberOfRanges > 1 {
          let range = match.range(at: 1)
          if let swiftRange = Range(range, in: xmlString) {
            let matchedText = String(xmlString[swiftRange])
            // Clean and validate the text
            let cleanedMatch = matchedText
              .replacingOccurrences(of: "&lt;", with: "<")
              .replacingOccurrences(of: "&gt;", with: ">")
              .replacingOccurrences(of: "&amp;", with: "&")
              .replacingOccurrences(of: "&quot;", with: "\"")
              .replacingOccurrences(of: "&apos;", with: "'")
              .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if cleanedMatch.count > 1 && !cleanedMatch.contains("<") && !cleanedMatch.contains(">") {
              extractedText += cleanedMatch + " "
            }
          }
        }
      }
    } catch {
      continue
    }
  }
  
  // Clean up the extracted text
  let cleanedText = extractedText
    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    .trimmingCharacters(in: .whitespacesAndNewlines)
  
  return cleanedText.count > 10 ? cleanedText : nil
}

private func extractReadableTextFromBinary(data: Data) -> String? {
  // Look for readable text in the binary data
  var extractedText = ""
  var currentWord = ""
  var wordCount = 0
  
  for byte in data {
    if (byte >= 32 && byte <= 126) || byte == 9 || byte == 10 || byte == 13 { // Printable ASCII + tab, newline, carriage return
        let char = Character(UnicodeScalar(byte))
      
      if char.isWhitespace {
        if currentWord.count > 2 && isValidWord(currentWord) {
          extractedText += currentWord + " "
          wordCount += 1
        }
        currentWord = ""
      } else {
        currentWord += String(char)
      }
    } else {
      // Non-printable character, end current word
      if currentWord.count > 2 && isValidWord(currentWord) {
        extractedText += currentWord + " "
        wordCount += 1
      }
      currentWord = ""
    }
  }
  
  // Add the last word if it's valid
  if currentWord.count > 2 && isValidWord(currentWord) {
    extractedText += currentWord
    wordCount += 1
  }
  
  // Only return if we found a reasonable amount of text
  let cleanedText = extractedText
    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    .trimmingCharacters(in: .whitespacesAndNewlines)
  
  return (wordCount > 5 && cleanedText.count > 50) ? cleanedText : nil
}

private func isValidWord(_ word: String) -> Bool {
  // Check if the word looks like actual text (not random characters)
  let vowelCount = word.lowercased().filter { "aeiou".contains($0) }.count
  let consonantCount = word.filter { $0.isLetter && !"aeiouAEIOU".contains($0) }.count
  let digitCount = word.filter { $0.isNumber }.count
  
  // Valid words should have some vowels, or be common short words, or contain some letters
  return word.count >= 3 && (
    vowelCount > 0 || // Has vowels
    ["the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "its", "may", "new", "now", "old", "see", "two", "way", "who", "boy", "did", "man", "men", "run", "she", "too", "use"].contains(word.lowercased()) || // Common short words
    (word.filter { $0.isLetter }.count > word.count / 2) // Mostly letters
  ) && digitCount < word.count / 2 // Not mostly digits
}

private func extractAsPlainText(fileURL: URL) -> String? {
  // Sometimes DOCX files can be partially read as plain text
  do {
    let content = try String(contentsOf: fileURL, encoding: .utf8)
    
    // Filter out XML tags and keep only readable text
    let cleanedContent = content.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
      .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    
    return cleanedContent.count > 50 ? cleanedContent : nil
    
  } catch {
    // Try with different encodings
    if let content = try? String(contentsOf: fileURL, encoding: .ascii) {
      let cleanedContent = content.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      
      return cleanedContent.count > 50 ? cleanedContent : nil
    }
  }
  
  return nil
}

private func extractDocContent(fileURL: URL) -> String {
  var content = "DOC Document Content Extraction:\n\n"
  
  // Try to extract text using NSAttributedString
  if let attributedString = try? NSAttributedString(url: fileURL, options: [:], documentAttributes: nil) {
    content += "Extracted Text Content:\n"
    content += attributedString.string
    content += "\n\nDocument successfully parsed as DOC format."
  } else {
    content += analyzeDocumentStructure(fileURL: fileURL)
    content += "\n\nNote: Direct text extraction failed. This DOC file may require Microsoft Word or compatible software for full content access."
  }
  
  return content
}

private func extractRTFContent(fileURL: URL) -> String {
  var content = "RTF Document Content Extraction:\n\n"
  
  do {
    let attributedString = try NSAttributedString(url: fileURL, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
    content += "Extracted Text Content:\n"
    content += attributedString.string
    content += "\n\nRTF document successfully parsed."
  } catch {
    content += "RTF parsing error: \(error.localizedDescription)\n"
    content += analyzeDocumentStructure(fileURL: fileURL)
  }
  
  return content
}

private func extractPagesContent(fileURL: URL) -> String {
  var content = "Apple Pages Document Analysis:\n\n"
  
  // Pages files are actually packages (directories)
  if fileURL.hasDirectoryPath {
    content += "Pages document detected as package format.\n"
    content += "Contents:\n"
    
    do {
      let contents = try FileManager.default.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil)
      for item in contents {
        content += "- \(item.lastPathComponent)\n"
      }
      
      // Look for preview or index files
      let previewURL = fileURL.appendingPathComponent("preview.jpg")
      let indexURL = fileURL.appendingPathComponent("index.xml")
      
      if FileManager.default.fileExists(atPath: previewURL.path) {
        content += "\nPreview image found - document contains visual content.\n"
      }
      
      if FileManager.default.fileExists(atPath: indexURL.path) {
        content += "\nDocument structure file found.\n"
        if let xmlContent = try? String(contentsOf: indexURL) {
          content += "Document metadata available for analysis.\n"
        }
      }
      
    } catch {
      content += "Error reading Pages document structure: \(error.localizedDescription)\n"
    }
  }
  
  content += "\nNote: Pages documents require Apple Pages or compatible software for full text extraction."
  return content
}

private func extractODTContent(fileURL: URL) -> String {
  var content = "OpenDocument Text (ODT) Analysis:\n\n"
  
  // ODT files are ZIP archives containing XML
  content += "ODT files are compressed archives containing structured XML content.\n"
  content += analyzeDocumentStructure(fileURL: fileURL)
  content += "\n\nNote: ODT files require LibreOffice, OpenOffice, or compatible software for full text extraction."
  
  return content
}

private func extractPlainTextContent(fileURL: URL) -> String {
  var content = "Plain Text File Content:\n\n"
  
  do {
    let textContent = try String(contentsOf: fileURL, encoding: .utf8)
    content += textContent
  } catch {
    // Try different encodings
    if let textContent = try? String(contentsOf: fileURL, encoding: .ascii) {
      content += textContent
    } else if let textContent = try? String(contentsOf: fileURL, encoding: .utf16) {
      content += textContent
    } else {
      content += "Error reading text file: \(error.localizedDescription)"
    }
  }
  
  return content
}

private func extractGenericDocumentContent(fileURL: URL) -> String {
  var content = "Generic Document Analysis:\n\n"
  content += analyzeDocumentStructure(fileURL: fileURL)
  content += "\n\nNote: This document type requires specialized software for full content extraction."
  return content
}

private func analyzeDocumentStructure(fileURL: URL) -> String {
  var analysis = "Document Structure Analysis:\n"
  
  do {
    let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
    
    if let fileSize = attributes[.size] as? Int64 {
        analysis += "File Size: \(formatFileSize(bytes: fileSize))\n"
      
      // Read first few bytes to determine file signature
      if let fileHandle = FileHandle(forReadingAtPath: fileURL.path) {
        let headerData = fileHandle.readData(ofLength: 16)
        fileHandle.closeFile()
        
        let headerHex = headerData.map { String(format: "%02x", $0) }.joined(separator: " ")
        analysis += "File Header: \(headerHex)\n"
        
        // Identify common document signatures
        if headerData.starts(with: Data([0x50, 0x4B])) {
          analysis += "Format: ZIP-based document (DOCX, ODT, etc.)\n"
        } else if headerData.starts(with: Data([0xD0, 0xCF, 0x11, 0xE0])) {
          analysis += "Format: Microsoft Compound Document (DOC, XLS, PPT)\n"
        } else if headerData.starts(with: Data([0x7B, 0x5C, 0x72, 0x74])) {
          analysis += "Format: Rich Text Format (RTF)\n"
        } else {
          analysis += "Format: Unknown or proprietary format\n"
        }
      }
    }
    
    // Check if it's a package/bundle
    if fileURL.hasDirectoryPath {
      analysis += "Type: Document Package/Bundle\n"
      let contents = try FileManager.default.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil)
      analysis += "Contains \(contents.count) items\n"
    }
    
  } catch {
    analysis += "Error analyzing document: \(error.localizedDescription)\n"
  }
  
  return analysis
}


//formatFileSize

private func formatFileSize(bytes: Int64) -> String {
  let formatter = ByteCountFormatter()
  formatter.allowedUnits = [.useKB, .useMB, .useGB]
  formatter.countStyle = .file
  return formatter.string(fromByteCount: bytes)
}


//getDocumentTypeDescription
private func getDocumentTypeDescription(fileExtension: String) -> String {
  switch fileExtension.lowercased() {
  case "doc", "docx": return "Microsoft Word Document"
  case "ppt", "pptx": return "Microsoft PowerPoint Presentation"
  case "xls", "xlsx": return "Microsoft Excel Spreadsheet"
  case "odt": return "OpenDocument Text"
  case "odp": return "OpenDocument Presentation"
  case "pages": return "Apple Pages Document"
  case "key": return "Apple Keynote Presentation"
  case "rtf": return "Rich Text Format Document"
  default: return "Document"
  }
}
