import Foundation

class Ollama {
    private let apiKey: String
    private let host: String
    private let port: String
    private let session: URLSession
    
    init(apiKey: String = "", host: String = "localhost", port: String = "11434") {
        self.apiKey = apiKey
        self.host = host
        self.port = port
        self.session = NetworkConfig.configuredSession()
    }
    
    private var baseURL: String {
        return "http://\(host):\(port)"
    }
    
    func complete(model: String, prompt: String) async throws -> String {
        print("=== Ollama API Debug ===")
        print("Model: \(model)")
        print("Input text: \(prompt)")
        print("API URL: \(baseURL)/api/chat")
        print("Host: \(host):\(port)")
        print("=======================")
        
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "stream": false
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
        
        let apiResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
        
        return apiResponse.message.content
    }
    
    func fetchAvailableModels() async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, _) = try await session.data(for: request)
        let modelsResponse = try JSONDecoder().decode(OllamaModelsResponse.self, from: data)
        
        return modelsResponse.models.map { $0.name }.sorted()
    }
}

struct OllamaResponse: Codable {
    let message: Message
    let done: Bool
    let total_duration: Int?
    let load_duration: Int?
    let prompt_eval_count: Int?
    let prompt_eval_duration: Int?
    let eval_count: Int?
    let eval_duration: Int?
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct OllamaModelsResponse: Codable {
    let models: [Model]
    
    struct Model: Codable {
        let name: String
        let model: String?
        let modified_at: String?
        let size: Int?
        let digest: String?
        let details: Details?
        
        struct Details: Codable {
            let parent_model: String?
            let format: String?
            let family: String?
            let families: [String]?
            let parameter_size: String?
            let quantization_level: String?
        }
    }
}