import Foundation

class WhisperAIService {
    private let baseURL = "https://api.cloudflare.com/client/v4/accounts"
    private let apiKey: String
    private let accountId: String
    
    private let session = URLSession.shared
    
    init() {
        // In a real app, you'd store these securely in Keychain or environment variables
        self.apiKey = "KwN_b2d75ffXwWeiDCHXhp6n4xVEqDOSURxyKxVN"
        self.accountId = "4927f1a99d25e859fc8b52d162887976"
        
        // For development, you might want to set default values
        if apiKey.isEmpty {
            NSLog("⚠️ CLOUDFLARE_API_KEY not found in environment variables")
        }
        if accountId.isEmpty {
            NSLog("⚠️ CLOUDFLARE_ACCOUNT_ID not found in environment variables")
        }
    }
    
    // MARK: - Public Methods
    
    func transcribeAudio(audioData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty && !accountId.isEmpty else {
            completion(.failure(WhisperError.missingCredentials))
            return
        }
        
        NSLog("🔄 Starting audio transcription with Cloudflare Whisper")
        
        // Create the request
        let url = URL(string: "\(baseURL)/\(accountId)/ai/run/@cf/openai/whisper")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = createMultipartBody(audioData: audioData, boundary: boundary)
        request.httpBody = httpBody
        
        // Make the request
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                NSLog("❌ Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(WhisperError.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(WhisperError.noData))
                return
            }
            
            // Handle response
            self.handleResponse(data: data, statusCode: httpResponse.statusCode, completion: completion)
        }.resume()
    }
    
    // MARK: - Private Methods
    
    private func createMultipartBody(audioData: Data, boundary: String) -> Data {
        var body = Data()
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add parameters
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"task\"\r\n\r\n".data(using: .utf8)!)
        body.append("transcribe".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    private func handleResponse(data: Data, statusCode: Int, completion: @escaping (Result<String, Error>) -> Void) {
        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            NSLog("📝 Whisper API Response: \(responseString)")
        }
        
        guard statusCode == 200 else {
            let error = WhisperError.apiError(statusCode: statusCode, message: "Request failed with status \(statusCode)")
            completion(.failure(error))
            return
        }
        
        do {
            let response = try JSONDecoder().decode(WhisperResponse.self, from: data)
            
            if response.success {
                if let transcription = response.result?.text {
                    NSLog("✅ Transcription successful: \(transcription)")
                    completion(.success(transcription))
                } else {
                    completion(.failure(WhisperError.noTranscription))
                }
            } else {
                let errorMessage = response.errors?.first?.message ?? "Unknown error"
                completion(.failure(WhisperError.apiError(statusCode: statusCode, message: errorMessage)))
            }
        } catch {
            NSLog("❌ JSON parsing error: \(error)")
            completion(.failure(WhisperError.jsonParsingError(error)))
        }
    }
}

// MARK: - Response Models
struct WhisperResponse: Codable {
    let success: Bool
    let result: WhisperResult?
    let errors: [WhisperErrorResponse]?
    
    struct WhisperResult: Codable {
        let text: String
        let language: String?
        let segments: [Segment]?
        
        struct Segment: Codable {
            let id: Int
            let seek: Double
            let start: Double
            let end: Double
            let text: String
            let tokens: [Int]
            let temperature: Double
            let avg_logprob: Double
            let compression_ratio: Double
            let no_speech_prob: Double
        }
    }
}

struct WhisperErrorResponse: Codable {
    let code: Int
    let message: String
}

// MARK: - Error Types
extension WhisperAIService {
    enum WhisperError: LocalizedError {
        case missingCredentials
        case invalidResponse
        case noData
        case noTranscription
        case apiError(statusCode: Int, message: String)
        case jsonParsingError(Error)
        
        var errorDescription: String? {
            switch self {
            case .missingCredentials:
                return "Missing Cloudflare API credentials. Please set CLOUDFLARE_API_KEY and CLOUDFLARE_ACCOUNT_ID."
            case .invalidResponse:
                return "Invalid response from Whisper API"
            case .noData:
                return "No data received from Whisper API"
            case .noTranscription:
                return "No transcription text found in response"
            case .apiError(let statusCode, let message):
                return "API Error (\(statusCode)): \(message)"
            case .jsonParsingError(let error):
                return "JSON parsing error: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Configuration Extension
extension WhisperAIService {
    static func configureCredentials(apiKey: String, accountId: String) {
        // Store credentials securely in Keychain (implementation would depend on your security requirements)
        let keychain = Keychain()
        keychain.set(apiKey, forKey: "CloudflareAPIKey")
        keychain.set(accountId, forKey: "CloudflareAccountID")
    }
    
    private func getStoredCredentials() -> (apiKey: String?, accountId: String?) {
        let keychain = Keychain()
        let apiKey = keychain.get("CloudflareAPIKey")
        let accountId = keychain.get("CloudflareAccountID")
        return (apiKey, accountId)
    }
}

// MARK: - Simple Keychain Helper
private class Keychain {
    func set(_ value: String, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    func get(_ key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }
} 