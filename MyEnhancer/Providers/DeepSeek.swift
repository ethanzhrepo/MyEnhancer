import Foundation

class DeepSeek {
    private let apiKey: String
    private let baseURL = "https://api.deepseek.com/v1/chat/completions"
    private let modelsURL = "https://api.deepseek.com/v1/models"
    private let session: URLSession
    
    init(apiKey: String) {
        self.apiKey = apiKey
        self.session = NetworkConfig.configuredSession()
    }
    
    func complete(model: String, prompt: String) async throws -> String {
        print("=== DeepSeek API Debug ===")
        print("Model: \(model)")
        print("Input text: \(prompt)")
        print("API URL: \(baseURL)")
        print("API Key: \(apiKey.prefix(8))...")
        print("========================")
        
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
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
        
        let apiResponse = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
        
        return apiResponse.choices.first?.message.content ?? ""
    }
    
    func fetchAvailableModels() async throws -> [String] {
        guard let url = URL(string: modelsURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await session.data(for: request)
        let modelsResponse = try JSONDecoder().decode(DeepSeekModelsResponse.self, from: data)
        
        return modelsResponse.data.map { $0.id }.sorted()
    }
}

struct DeepSeekResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

struct DeepSeekModelsResponse: Codable {
    let data: [Model]
    
    struct Model: Codable {
        let id: String
        let object: String
        let created: Int?
        let owned_by: String?
    }
}