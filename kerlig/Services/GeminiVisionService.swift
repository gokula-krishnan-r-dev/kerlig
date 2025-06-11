import AppKit
import Foundation

class GeminiVisionService {
  // API URL for Gemini Vision API
  private let baseURL =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent"

  // API key - should be stored securely in a real app
  private var apiKey: String {
    return "AIzaSyDEOpIpJOPOnbTUP61BI9s_kyFPBHnUgow"
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
      // We have a file path but no base64 data or not an image, try to load it
      let fileURL = URL(fileURLWithPath: path)
      processImageFile(fileURL: fileURL, prompt: prompt, completion: completion)
    } else {
      // No usable data
      completion(.failure(GeminiError.invalidFileType("File cannot be processed as an image")))
    }
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

  // Error cases
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
}
