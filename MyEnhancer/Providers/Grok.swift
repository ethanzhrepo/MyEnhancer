import Foundation

class Grok {
    private let apiKey: String
    private let baseURL = "https://api.x.ai/v1/chat/completions"  // 示例 URL
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func complete(model: String, prompt: String) async throws -> String {
        // 调试输出
        print("=== Grok API Debug ===")
        print("Model: \(model)")
        print("Input text: \(prompt)")
        print("API URL: \(baseURL)")
        print("API Key: \(apiKey.prefix(8))...") // 只显示 API Key 的前 8 位
        print("=====================")
        
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")  // 确保移除空白字符
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        // 打印完整的请求头信息
        print("Request Headers:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("\(key): \(value)")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        // 记录响应状态码和原始数据
        if let httpResponse = httpResponse as? HTTPURLResponse {
            print("Response status code: \(httpResponse.statusCode)")
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response JSON: \(jsonString)")
        }
        
        let apiResponse = try JSONDecoder().decode(GrokResponse.self, from: data)
        
        return apiResponse.choices.first?.message.content ?? ""
    }
}

// Response models
struct GrokResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
} 