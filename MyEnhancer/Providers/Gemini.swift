import Foundation

class Gemini {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let session: URLSession
    
    init(apiKey: String) {
        self.apiKey = apiKey
        self.session = NetworkConfig.configuredSession()
    }
    
    func complete(model: String, prompt: String) async throws -> String {
        print("=== Gemini API Debug ===")
        print("Model: \(model)")
        print("Input text: \(prompt)")
        print("API URL: \(baseURL)/\(model):generateContent")
        print("API Key: \(apiKey.prefix(8))...")
        print("========================")
        
        guard let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2048
            ]
        ]
        
        print("Request Headers:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("\(key): \(value)")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, httpResponse) = try await session.data(for: request)
        
        if let httpResponse = httpResponse as? HTTPURLResponse {
            print("Response status code: \(httpResponse.statusCode)")
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response JSON: \(jsonString)")
        }
        
        let apiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        return apiResponse.candidates.first?.content.parts.first?.text ?? ""
    }
    
    func fetchAvailableModels() async throws -> [String] {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, _) = try await session.data(for: request)
        let modelsResponse = try JSONDecoder().decode(GeminiModelsResponse.self, from: data)
        
        return modelsResponse.models
            .filter { $0.name.contains("gemini") }
            .map { $0.name.replacingOccurrences(of: "models/", with: "") }
            .sorted()
    }
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
        let finishReason: String?
        let index: Int?
        let safetyRatings: [SafetyRating]?
    }
    
    struct Content: Codable {
        let parts: [Part]
        let role: String?
    }
    
    struct Part: Codable {
        let text: String?
    }
    
    struct SafetyRating: Codable {
        let category: String
        let probability: String
    }
}

struct GeminiModelsResponse: Codable {
    let models: [Model]
    
    struct Model: Codable {
        let name: String
        let version: String?
        let displayName: String?
        let description: String?
        let inputTokenLimit: Int?
        let outputTokenLimit: Int?
        let supportedGenerationMethods: [String]?
        let temperature: Double?
        let topP: Double?
        let topK: Int?
    }
}