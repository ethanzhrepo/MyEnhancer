import Foundation

protocol ModelProvider {
    func fetchAvailableModels() async throws -> [String]
}

class ModelManager: ObservableObject {
    @Published var modelsByProvider: [String: [String]] = [:]
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    
    private let fallbackModels: [String: [String]] = [
        "OpenAI": ["gpt-4o", "gpt-4o-mini", "o1", "o1-mini", "o3-mini", "gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"],
        "X": ["grok-2-vision-1212", "grok-2-1212", "grok-beta"],
        "DeepSeek": ["deepseek-chat", "deepseek-coder"],
        "Gemini": ["gemini-1.5-pro", "gemini-1.5-flash", "gemini-1.0-pro"],
        "Ollama": ["llama3.2", "llama3.1", "codellama", "mistral", "qwen2.5"]
    ]
    
    init() {
        modelsByProvider = fallbackModels
    }
    
    func refreshModels(for provider: String) async {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        do {
            let models = try await fetchModelsForProvider(provider)
            await MainActor.run {
                modelsByProvider[provider] = models
                isLoading = false
            }
        } catch {
            await MainActor.run {
                lastError = "Failed to fetch \(provider) models: \(error.localizedDescription)"
                isLoading = false
            }
            print("Error fetching models for \(provider): \(error)")
        }
    }
    
    func refreshAllModels() async {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        let providers = ["OpenAI", "DeepSeek", "Gemini", "Ollama"]
        
        await withTaskGroup(of: Void.self) { group in
            for provider in providers {
                group.addTask {
                    do {
                        let models = try await self.fetchModelsForProvider(provider)
                        await MainActor.run {
                            self.modelsByProvider[provider] = models
                        }
                    } catch {
                        print("Error fetching models for \(provider): \(error)")
                    }
                }
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func fetchModelsForProvider(_ provider: String) async throws -> [String] {
        switch provider {
        case "OpenAI":
            let apiKey = UserDefaults.standard.string(forKey: "openaiKey") ?? ""
            guard !apiKey.isEmpty else { 
                throw ModelError.noApiKey(provider: provider)
            }
            let openAI = OpenAI(apiKey: apiKey)
            return try await openAI.fetchAvailableModels()
            
        case "DeepSeek":
            let apiKey = UserDefaults.standard.string(forKey: "deepseekKey") ?? ""
            guard !apiKey.isEmpty else { 
                throw ModelError.noApiKey(provider: provider)
            }
            let deepseek = DeepSeek(apiKey: apiKey)
            return try await deepseek.fetchAvailableModels()
            
        case "Gemini":
            let apiKey = UserDefaults.standard.string(forKey: "geminiKey") ?? ""
            guard !apiKey.isEmpty else { 
                throw ModelError.noApiKey(provider: provider)
            }
            let gemini = Gemini(apiKey: apiKey)
            return try await gemini.fetchAvailableModels()
            
        case "Ollama":
            let host = UserDefaults.standard.string(forKey: "ollamaHost") ?? "localhost"
            let port = UserDefaults.standard.string(forKey: "ollamaPort") ?? "11434"
            let ollama = Ollama(host: host, port: port)
            return try await ollama.fetchAvailableModels()
            
        case "X":
            return fallbackModels["X"] ?? []
            
        default:
            return fallbackModels[provider] ?? []
        }
    }
    
    func getModels(for provider: String) -> [String] {
        return modelsByProvider[provider] ?? fallbackModels[provider] ?? []
    }
}

enum ModelError: LocalizedError {
    case noApiKey(provider: String)
    case networkError(String)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .noApiKey(let provider):
            return "No API key configured for \(provider)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

extension OpenAI: ModelProvider {}

extension DeepSeek: ModelProvider {}
extension Gemini: ModelProvider {}
extension Ollama: ModelProvider {}