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


      print("combinedPrompt: \(combinedPrompt)")

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


      print("analysis: \(analysis)")

      let extractedContent = convertSpreadsheetToText(fileURL: fileURL)
      
      print("extractedContent: \(extractedContent)")

      let combinedPrompt = """
      \(prompt)
      
      \(extractedContent)

      Please analyze this spreadsheet and provide insights based on the user's request above and the extracted content.
      
      """


      print("combinedPrompt: \(combinedPrompt)")

      sendTextToGemini(text: combinedPrompt, completion: completion)




      
      // completion(.success(analysis))
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
  
  // Try the new robust DOCX extraction method
  if let extractedText = extractDocxContentRobust(fileURL: fileURL) {
    content += "Successfully extracted text content:\n\n"
    content += extractedText
    return content
  }
  
  // Fallback to NSAttributedString method
  if let extractedText = extractTextWithNSAttributedString(fileURL: fileURL) {
    content += "Extracted using NSAttributedString:\n\n"
    content += extractedText
    return content
  }
  
  // Final fallback: Analyze structure
  content += analyzeDocumentStructure(fileURL: fileURL)
  content += "\n\nNote: Unable to extract text content. The DOCX file may be corrupted, password-protected, or use unsupported formatting."
  
  return content
}

// MARK: - Advanced Text Extraction Methods

private func extractDocxContentRobust(fileURL: URL) -> String? {
  print("🔄 Starting robust DOCX extraction for: \(fileURL.lastPathComponent)")
  
  do {
    // Verify file exists and is readable
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      print("❌ File does not exist: \(fileURL.path)")
      return nil
    }
    
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("docx_extraction_\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    print("📁 Created temporary directory: \(tempDir.path)")
    
    defer {
      do {
        try FileManager.default.removeItem(at: tempDir)
        print("🗑️ Cleaned up temporary directory")
      } catch {
        print("⚠️ Failed to cleanup temp directory: \(error)")
      }
    }
    
    // Extract DOCX (ZIP) file
    print("📦 Attempting to extract DOCX ZIP structure...")
    if extractDocxZip(sourceURL: fileURL, destinationURL: tempDir) {
      print("✅ Successfully extracted DOCX ZIP")
      
      // Look for document.xml
      let documentXMLPath = tempDir.appendingPathComponent("word/document.xml")
      
      if FileManager.default.fileExists(atPath: documentXMLPath.path) {
        print("📄 Found document.xml, parsing content...")
        let xmlContent = try String(contentsOf: documentXMLPath, encoding: .utf8)
        
        if let parsedText = parseWordDocumentXML(xmlContent) {
          print("✅ Successfully extracted \(parsedText.count) characters from DOCX")
          return parsedText
        } else {
          print("⚠️ XML parsing returned no text")
        }
      } else {
        print("❌ document.xml not found in expected location")
        // List contents to debug
        do {
          let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
          print("📂 Available files in extracted DOCX:")
          for item in contents {
            print("  - \(item.lastPathComponent)")
          }
        } catch {
          print("❌ Failed to list extracted contents: \(error)")
        }
      }
    } else {
      print("❌ Failed to extract DOCX ZIP structure")
    }
    
    // Fallback: Try direct binary extraction
    print("🔄 Attempting fallback binary extraction...")
    if let binaryText = extractTextFromDocxBinary(fileURL: fileURL) {
      print("✅ Binary extraction successful, found \(binaryText.count) characters")
      return binaryText
    } else {
      print("❌ Binary extraction failed")
    }
    
    return nil
    
  } catch {
    print("❌ Error in robust DOCX extraction: \(error.localizedDescription)")
    return nil
  }
}

private func extractDocxZip(sourceURL: URL, destinationURL: URL) -> Bool {
  let task = Process()
  task.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
  task.arguments = ["-q", "-o", sourceURL.path, "-d", destinationURL.path]
  
  do {
    try task.run()
    task.waitUntilExit()
    return task.terminationStatus == 0
  } catch {
    return false
  }
}

private func parseWordDocumentXML(_ xmlContent: String) -> String? {
  print("🔍 Parsing Word document XML (\(xmlContent.count) characters)")
  var extractedText = ""
  var textElements: [String] = []
  
  // Parse Word document XML using comprehensive regex patterns
  let patterns = [
    // Main text content in <w:t> tags with various attributes
    "<w:t(?:\\s[^>]*)?>([^<]*)</w:t>",
    // Text with space preservation
    "<w:t\\s+xml:space=\"preserve\"[^>]*>([^<]*)</w:t>",
    // Simple text pattern for fallback
    "<w:t>([^<]*)</w:t>",
    // Alternative text patterns
    "<text[^>]*>([^<]*)</text>"
  ]
  
  var totalMatches = 0
  
  for (index, pattern) in patterns.enumerated() {
    do {
      let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
      let matches = regex.matches(in: xmlContent, options: [], range: NSRange(location: 0, length: xmlContent.count))
      
      print("📊 Pattern \(index + 1): Found \(matches.count) matches")
      totalMatches += matches.count
      
      for match in matches {
        if match.numberOfRanges > 1 {
          let range = match.range(at: 1)
          if let swiftRange = Range(range, in: xmlContent) {
            let text = String(xmlContent[swiftRange])
            let decodedText = decodeXMLEntities(text).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !decodedText.isEmpty && decodedText.count > 0 {
              textElements.append(decodedText)
            }
          }
        }
      }
    } catch {
      print("⚠️ Regex error for pattern \(index + 1): \(error)")
      continue
    }
  }
  
  print("📝 Found \(textElements.count) text elements from \(totalMatches) total matches")
  
  // Remove duplicates while preserving order
  var uniqueElements: [String] = []
  var seen = Set<String>()
  
  for element in textElements {
    if !seen.contains(element) && element.count > 0 {
      uniqueElements.append(element)
      seen.insert(element)
    }
  }
  
  print("✨ Unique text elements: \(uniqueElements.count)")
  
  // Join elements with appropriate spacing
  extractedText = uniqueElements.joined(separator: " ")
  
  // Add paragraph structure based on XML
  extractedText = addParagraphStructure(xmlContent: xmlContent, text: extractedText)
  
  // Final cleanup and validation
  let cleanedText = extractedText
    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    .trimmingCharacters(in: .whitespacesAndNewlines)
  
  print("📄 Final extracted text length: \(cleanedText.count) characters")
  
  if cleanedText.count > 5 {
    print("✅ Successfully parsed DOCX content")
    return cleanedText
  } else {
    print("❌ Insufficient text content extracted")
    return nil
  }
}

private func addParagraphStructure(xmlContent: String, text: String) -> String {
  print("📋 Adding paragraph structure to text")
  
  // Count paragraph breaks in XML
  let paragraphElements = xmlContent.components(separatedBy: "</w:p>")
  let paragraphCount = paragraphElements.count - 1
  
  print("📊 Found \(paragraphCount) paragraphs in XML structure")
  
  if paragraphCount <= 1 {
    return text
  }
  
  // Try to intelligently add paragraph breaks
  let words = text.components(separatedBy: " ")
  let wordsPerParagraph = max(10, words.count / paragraphCount)
  
  var result = ""
  var currentParagraph = ""
  var wordCount = 0
  
  for word in words {
    currentParagraph += word + " "
    wordCount += 1
    
    // Check if we should end this paragraph
    if wordCount >= wordsPerParagraph {
      // Look for a natural break point (sentence end)
      if word.hasSuffix(".") || word.hasSuffix("!") || word.hasSuffix("?") {
        result += currentParagraph.trimmingCharacters(in: .whitespaces) + "\n\n"
        currentParagraph = ""
        wordCount = 0
      }
    }
  }
  
  // Add any remaining text
  if !currentParagraph.isEmpty {
    result += currentParagraph.trimmingCharacters(in: .whitespaces)
  }
  
  let finalResult = result.trimmingCharacters(in: .whitespacesAndNewlines)
  print("📝 Added paragraph structure: \(finalResult.components(separatedBy: "\n\n").count) paragraphs")
  
  return finalResult
}

private func decodeXMLEntities(_ text: String) -> String {
  return text
    .replacingOccurrences(of: "&lt;", with: "<")
    .replacingOccurrences(of: "&gt;", with: ">")
    .replacingOccurrences(of: "&amp;", with: "&")
    .replacingOccurrences(of: "&quot;", with: "\"")
    .replacingOccurrences(of: "&apos;", with: "'")
    .replacingOccurrences(of: "&nbsp;", with: " ")
}

private func extractTextFromDocxBinary(fileURL: URL) -> String? {
  guard let data = try? Data(contentsOf: fileURL) else { return nil }
  
  // Convert to string and extract readable content
  let dataString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? ""
  
  // Look for readable text patterns in the binary data
  var extractedWords: [String] = []
  let words = dataString.components(separatedBy: .whitespacesAndNewlines)
  
  for word in words {
    let cleanWord = word.trimmingCharacters(in: .punctuationCharacters.union(.symbols))
    if isReadableWord(cleanWord) {
      extractedWords.append(cleanWord)
    }
  }
  
  // Join words and validate
  let result = extractedWords.joined(separator: " ")
  return result.count > 50 ? result : nil
}

private func isReadableWord(_ word: String) -> Bool {
  guard word.count >= 2 && word.count <= 50 else { return false }
  
  let letterCount = word.filter { $0.isLetter }.count
  let digitCount = word.filter { $0.isNumber }.count
  
  // Must be mostly letters
  return letterCount >= word.count / 2 && digitCount < word.count / 2
}

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

// Legacy extraction methods removed - replaced with robust extraction above

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


// MARK: - Spreadsheet Content Extraction

private func convertSpreadsheetToText(fileURL: URL) -> String {
  let fileExtension = fileURL.pathExtension.lowercased()
  let fileName = fileURL.lastPathComponent
  
  print("🔄 Starting spreadsheet extraction for: \(fileName) (.\(fileExtension))")
  
  // Create comprehensive analysis prompt for the spreadsheet
  var analysisText = """
  Spreadsheet Analysis Request:
  
  File: \(fileName)
  Type: \(getSpreadsheetTypeDescription(fileExtension))
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
  
  // Route to appropriate extraction method based on file type
  switch fileExtension {
  case "xlsx":
    analysisText += extractXlsxContent(fileURL: fileURL)
  case "xls":
    analysisText += extractXlsContent(fileURL: fileURL)
  case "csv":
    analysisText += extractCsvContent(fileURL: fileURL)
  case "numbers":
    analysisText += extractNumbersContent(fileURL: fileURL)
  case "ods":
    analysisText += extractOdsContent(fileURL: fileURL)
  default:
    analysisText += extractGenericSpreadsheetContent(fileURL: fileURL)
  }
  
  return analysisText
}

// MARK: - Excel XLSX Extraction

private func extractXlsxContent(fileURL: URL) -> String {
  var content = "XLSX Spreadsheet Content Extraction:\n\n"
  
  // Try the robust XLSX extraction method
  if let extractedContent = extractXlsxContentRobust(fileURL: fileURL) {
    content += "Successfully extracted spreadsheet content:\n\n"
    content += extractedContent
    return content
  }
  
  // Fallback to NSAttributedString method
  if let extractedText = extractSpreadsheetWithNSAttributedString(fileURL: fileURL) {
    content += "Extracted using NSAttributedString:\n\n"
    content += extractedText
    return content
  }
  
  // Final fallback: Analyze structure
  content += analyzeSpreadsheetStructure(fileURL: fileURL)
  content += "\n\nNote: Unable to extract spreadsheet content. The XLSX file may be corrupted, password-protected, or use unsupported formatting."
  
  return content
}

private func extractXlsxContentRobust(fileURL: URL) -> String? {
  print("🔄 Starting robust XLSX extraction for: \(fileURL.lastPathComponent)")
  
  do {
    // Verify file exists and is readable
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      print("❌ File does not exist: \(fileURL.path)")
      return nil
    }
    
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("xlsx_extraction_\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    print("📁 Created temporary directory: \(tempDir.path)")
    
    defer {
      do {
        try FileManager.default.removeItem(at: tempDir)
        print("🗑️ Cleaned up temporary directory")
      } catch {
        print("⚠️ Failed to cleanup temp directory: \(error)")
      }
    }
    
    // Extract XLSX (ZIP) file
    print("📦 Attempting to extract XLSX ZIP structure...")
    if extractSpreadsheetZip(sourceURL: fileURL, destinationURL: tempDir) {
      print("✅ Successfully extracted XLSX ZIP")
      
      // Parse worksheet data
      if let parsedContent = parseXlsxWorksheets(tempDir: tempDir) {
        print("✅ Successfully extracted \(parsedContent.count) characters from XLSX")
        return parsedContent
      } else {
        print("⚠️ Worksheet parsing returned no content")
      }
    } else {
      print("❌ Failed to extract XLSX ZIP structure")
    }
    
    return nil
    
  } catch {
    print("❌ Error in robust XLSX extraction: \(error.localizedDescription)")
    return nil
  }
}

private func extractSpreadsheetZip(sourceURL: URL, destinationURL: URL) -> Bool {
  let task = Process()
  task.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
  task.arguments = ["-q", "-o", sourceURL.path, "-d", destinationURL.path]
  
  do {
    try task.run()
    task.waitUntilExit()
    return task.terminationStatus == 0
  } catch {
    print("❌ Unzip failed: \(error)")
    return false
  }
}

private func parseXlsxWorksheets(tempDir: URL) -> String? {
  print("📊 Parsing XLSX worksheets")
  var extractedContent = ""
  
  // Look for worksheet files
  let xlWorksheetDir = tempDir.appendingPathComponent("xl/worksheets")
  
  guard FileManager.default.fileExists(atPath: xlWorksheetDir.path) else {
    print("❌ xl/worksheets directory not found")
    return nil
  }
  
  do {
    let worksheetFiles = try FileManager.default.contentsOfDirectory(at: xlWorksheetDir, includingPropertiesForKeys: nil)
      .filter { $0.pathExtension == "xml" }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
    
    print("📋 Found \(worksheetFiles.count) worksheet(s)")
    
    for (index, worksheetFile) in worksheetFiles.enumerated() {
      print("📄 Processing worksheet \(index + 1): \(worksheetFile.lastPathComponent)")
      
      let xmlContent = try String(contentsOf: worksheetFile, encoding: .utf8)
      
      if let worksheetData = parseWorksheetXML(xmlContent, worksheetName: "Sheet\(index + 1)") {
        extractedContent += worksheetData + "\n\n"
      }
    }
    
    // Also try to get shared strings if available
    let sharedStringsPath = tempDir.appendingPathComponent("xl/sharedStrings.xml")
    if FileManager.default.fileExists(atPath: sharedStringsPath.path) {
      print("📝 Processing shared strings")
      let sharedStringsXML = try String(contentsOf: sharedStringsPath, encoding: .utf8)
      if let sharedStrings = parseSharedStrings(sharedStringsXML) {
        extractedContent = replaceSharedStringReferences(in: extractedContent, with: sharedStrings)
      }
    }
    
    return extractedContent.isEmpty ? nil : extractedContent
    
  } catch {
    print("❌ Error parsing worksheets: \(error)")
    return nil
  }
}

private func parseWorksheetXML(_ xmlContent: String, worksheetName: String) -> String? {
  print("🔍 Parsing worksheet XML (\(xmlContent.count) characters)")
  var worksheetContent = "=== \(worksheetName) ===\n"
  var cells: [(row: Int, col: Int, value: String)] = []
  
  // Extract cell data using regex
  let cellPattern = "<c[^>]*r=\"([A-Z]+)(\\d+)\"[^>]*>.*?<v>([^<]*)</v>.*?</c>"
  
  do {
    let regex = try NSRegularExpression(pattern: cellPattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
    let matches = regex.matches(in: xmlContent, options: [], range: NSRange(location: 0, length: xmlContent.count))
    
    print("📊 Found \(matches.count) cells with values")
    
    for match in matches {
      if match.numberOfRanges >= 4 {
        let colRange = match.range(at: 1)
        let rowRange = match.range(at: 2)
        let valueRange = match.range(at: 3)
        
        if let colSwiftRange = Range(colRange, in: xmlContent),
           let rowSwiftRange = Range(rowRange, in: xmlContent),
           let valueSwiftRange = Range(valueRange, in: xmlContent) {
          
          let colRef = String(xmlContent[colSwiftRange])
          let rowRef = String(xmlContent[rowSwiftRange])
          let value = String(xmlContent[valueSwiftRange])
          
          if let rowNum = Int(rowRef) {
            let colNum = columnLetterToNumber(colRef)
            cells.append((row: rowNum, col: colNum, value: value))
          }
        }
      }
    }
    
    // Also look for inline strings
    let inlineStringPattern = "<c[^>]*r=\"([A-Z]+)(\\d+)\"[^>]*>.*?<is>.*?<t>([^<]*)</t>.*?</is>.*?</c>"
    let inlineRegex = try NSRegularExpression(pattern: inlineStringPattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
    let inlineMatches = inlineRegex.matches(in: xmlContent, options: [], range: NSRange(location: 0, length: xmlContent.count))
    
    print("📝 Found \(inlineMatches.count) inline string cells")
    
    for match in inlineMatches {
      if match.numberOfRanges >= 4 {
        let colRange = match.range(at: 1)
        let rowRange = match.range(at: 2)
        let valueRange = match.range(at: 3)
        
        if let colSwiftRange = Range(colRange, in: xmlContent),
           let rowSwiftRange = Range(rowRange, in: xmlContent),
           let valueSwiftRange = Range(valueRange, in: xmlContent) {
          
          let colRef = String(xmlContent[colSwiftRange])
          let rowRef = String(xmlContent[rowSwiftRange])
          let value = String(xmlContent[valueSwiftRange])
          
          if let rowNum = Int(rowRef) {
            let colNum = columnLetterToNumber(colRef)
            cells.append((row: rowNum, col: colNum, value: value))
          }
        }
      }
    }
    
    // Sort cells by row and column
    cells.sort { ($0.row, $0.col) < ($1.row, $1.col) }
    
    // Convert to readable format
    if !cells.isEmpty {
      var currentRow = -1
      var rowContent = ""
      
      for cell in cells {
        if cell.row != currentRow {
          if !rowContent.isEmpty {
            worksheetContent += "Row \(currentRow): \(rowContent.trimmingCharacters(in: .whitespaces))\n"
          }
          currentRow = cell.row
          rowContent = ""
        }
        
        let decodedValue = decodeXMLEntities(cell.value)
        rowContent += "\(numberToColumnLetter(cell.col)): \(decodedValue) | "
      }
      
      // Add the last row
      if !rowContent.isEmpty {
        worksheetContent += "Row \(currentRow): \(rowContent.trimmingCharacters(in: .whitespaces))\n"
      }
    }
    
    print("✅ Parsed worksheet with \(cells.count) cells")
    return worksheetContent.isEmpty ? nil : worksheetContent
    
  } catch {
    print("❌ Error parsing worksheet XML: \(error)")
    return nil
  }
}

private func parseSharedStrings(_ xmlContent: String) -> [String]? {
  print("🔤 Parsing shared strings")
  var sharedStrings: [String] = []
  
  // Extract shared string values
  let stringPattern = "<si[^>]*>.*?<t[^>]*>([^<]*)</t>.*?</si>"
  
  do {
    let regex = try NSRegularExpression(pattern: stringPattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
    let matches = regex.matches(in: xmlContent, options: [], range: NSRange(location: 0, length: xmlContent.count))
    
    for match in matches {
      if match.numberOfRanges >= 2 {
        let valueRange = match.range(at: 1)
        if let valueSwiftRange = Range(valueRange, in: xmlContent) {
          let value = String(xmlContent[valueSwiftRange])
          sharedStrings.append(decodeXMLEntities(value))
        }
      }
    }
    
    print("📚 Found \(sharedStrings.count) shared strings")
    return sharedStrings.isEmpty ? nil : sharedStrings
    
  } catch {
    print("❌ Error parsing shared strings: \(error)")
    return nil
  }
}

private func replaceSharedStringReferences(in content: String, with sharedStrings: [String]) -> String {
  // This is a simplified implementation - in a real XLSX file,
  // we'd need to track which cells reference shared strings
  return content
}

private func columnLetterToNumber(_ letter: String) -> Int {
  var result = 0
  for char in letter.uppercased() {
    result = result * 26 + Int(char.asciiValue! - 64)
  }
  return result
}

private func numberToColumnLetter(_ number: Int) -> String {
  var num = number
  var result = ""
  
  while num > 0 {
    num -= 1
    result = String(Character(UnicodeScalar(65 + num % 26)!)) + result
    num /= 26
  }
  
  return result.isEmpty ? "A" : result
}

// MARK: - Other Spreadsheet Format Extraction

private func extractXlsContent(fileURL: URL) -> String {
  var content = "XLS (Legacy Excel) Content Extraction:\n\n"
  
  // Try NSAttributedString first
  if let extractedText = extractSpreadsheetWithNSAttributedString(fileURL: fileURL) {
    content += "Extracted using NSAttributedString:\n\n"
    content += extractedText
    return content
  }
  
  // Try binary extraction
  if let binaryContent = extractSpreadsheetFromBinary(fileURL: fileURL) {
    content += "Extracted from binary data:\n\n"
    content += binaryContent
    return content
  }
  
  content += analyzeSpreadsheetStructure(fileURL: fileURL)
  content += "\n\nNote: XLS files require specialized parsers. Consider converting to XLSX or CSV format for better analysis."
  
  return content
}

private func extractCsvContent(fileURL: URL) -> String {
  var content = "CSV Content Extraction:\n\n"
  
  do {
    let csvContent = try String(contentsOf: fileURL, encoding: .utf8)
    let lines = csvContent.components(separatedBy: .newlines).prefix(100) // Limit to first 100 rows
    
    content += "CSV Data (first 100 rows):\n"
    for (index, line) in lines.enumerated() {
      if !line.trimmingCharacters(in: .whitespaces).isEmpty {
        content += "Row \(index + 1): \(line)\n"
      }
    }
    
    let totalLines = csvContent.components(separatedBy: .newlines).count
    if totalLines > 100 {
      content += "\n... and \(totalLines - 100) more rows\n"
    }
    
    print("✅ Successfully extracted CSV with \(totalLines) rows")
    
  } catch {
    content += "Error reading CSV file: \(error.localizedDescription)\n"
    
    // Try different encodings
    if let csvContent = try? String(contentsOf: fileURL, encoding: .windowsCP1252) {
      content += "\nExtracted using Windows-1252 encoding:\n"
      content += String(csvContent.prefix(1000)) + "...\n"
    }
  }
  
  return content
}

private func extractNumbersContent(fileURL: URL) -> String {
  var content = "Apple Numbers Content Analysis:\n\n"
  
  if fileURL.hasDirectoryPath {
    content += "Numbers document detected as package format.\n"
    
    do {
      let contents = try FileManager.default.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil)
      content += "Package contents:\n"
      for item in contents {
        content += "- \(item.lastPathComponent)\n"
      }
      
      // Look for preview or data files
      let previewURL = fileURL.appendingPathComponent("preview.jpg")
      if FileManager.default.fileExists(atPath: previewURL.path) {
        content += "\nPreview image found - spreadsheet contains visual elements.\n"
      }
      
    } catch {
      content += "Error reading Numbers package: \(error.localizedDescription)\n"
    }
  }
  
  content += "\nNote: Numbers files require Apple Numbers or compatible software for full data extraction."
  return content
}

private func extractOdsContent(fileURL: URL) -> String {
  var content = "OpenDocument Spreadsheet (ODS) Analysis:\n\n"
  content += "ODS files are compressed archives containing structured XML content.\n"
  content += analyzeSpreadsheetStructure(fileURL: fileURL)
  content += "\n\nNote: ODS files require LibreOffice, OpenOffice, or compatible software for full data extraction."
  return content
}

private func extractGenericSpreadsheetContent(fileURL: URL) -> String {
  var content = "Generic Spreadsheet Analysis:\n\n"
  content += analyzeSpreadsheetStructure(fileURL: fileURL)
  content += "\n\nNote: This spreadsheet format requires specialized software for content extraction."
  return content
}

// MARK: - Helper Methods

private func extractSpreadsheetWithNSAttributedString(fileURL: URL) -> String? {
  do {
    let attributedString = try NSAttributedString(url: fileURL, options: [:], documentAttributes: nil)
    let text = attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
    return text.count > 10 ? text : nil
  } catch {
    print("NSAttributedString extraction failed: \(error)")
    return nil
  }
}

private func extractSpreadsheetFromBinary(fileURL: URL) -> String? {
  guard let data = try? Data(contentsOf: fileURL) else { return nil }
  
  // Look for readable text in binary data
  let dataString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? ""
  
  var extractedLines: [String] = []
  let lines = dataString.components(separatedBy: .newlines)
  
  for line in lines.prefix(50) { // Limit to first 50 lines
    let cleanLine = line.trimmingCharacters(in: .controlCharacters.union(.whitespaces))
    if cleanLine.count > 3 && isReadableSpreadsheetLine(cleanLine) {
      extractedLines.append(cleanLine)
    }
  }
  
  return extractedLines.isEmpty ? nil : extractedLines.joined(separator: "\n")
}

private func isReadableSpreadsheetLine(_ line: String) -> Bool {
  let letterCount = line.filter { $0.isLetter }.count
  let digitCount = line.filter { $0.isNumber }.count
  let totalCount = line.count
  
  // Should contain some letters or numbers, and not be mostly symbols
  return (letterCount + digitCount) > totalCount / 3 && totalCount < 500
}

private func analyzeSpreadsheetStructure(fileURL: URL) -> String {
  var analysis = "Spreadsheet Structure Analysis:\n"
  
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
        
        // Identify common spreadsheet signatures
        if headerData.starts(with: Data([0x50, 0x4B])) {
          analysis += "Format: ZIP-based spreadsheet (XLSX, ODS, etc.)\n"
        } else if headerData.starts(with: Data([0xD0, 0xCF, 0x11, 0xE0])) {
          analysis += "Format: Microsoft Compound Document (XLS)\n"
        } else if headerData.prefix(3) == Data([0xEF, 0xBB, 0xBF]) {
          analysis += "Format: UTF-8 with BOM (likely CSV)\n"
        } else {
          analysis += "Format: Unknown or plain text format\n"
        }
      }
    }
    
  } catch {
    analysis += "Error analyzing spreadsheet: \(error.localizedDescription)\n"
  }
  
  return analysis
}


//getSpreadsheetTypeDescription
private func getSpreadsheetTypeDescription(_ fileExtension: String) -> String {
  switch fileExtension.lowercased() {
    case "xlsx", "xlsm", "xlsb", "xls":
      return "Excel"
    case "csv":
      return "CSV"
    case "ods":
      return "OpenDocument Spreadsheet"
    case "numbers":
      return "Apple Numbers"
    default:
      return "Spreadsheet"
  }
}
