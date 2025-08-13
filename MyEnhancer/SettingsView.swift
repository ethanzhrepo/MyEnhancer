import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedProvider") private var selectedProvider: String = "OpenAI"
    @AppStorage("selectedModel") private var selectedModel: String = "gpt-4-turbo"
    @AppStorage("openaiKey") private var openaiKey: String = ""
    @AppStorage("grokKey") private var grokKey: String = ""
    @AppStorage("deepseekKey") private var deepseekKey: String = ""
    @AppStorage("geminiKey") private var geminiKey: String = ""
    @AppStorage("ollamaHost") private var ollamaHost: String = "localhost"
    @AppStorage("ollamaPort") private var ollamaPort: String = "11434"
    @AppStorage("showOnTop") private var showOnTop: Bool = false
    @AppStorage("useProxy") private var useProxy: Bool = false
    @AppStorage("proxyHost") private var proxyHost: String = ""
    @AppStorage("proxyPort") private var proxyPort: String = ""
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var modelManager = ModelManager()
    
    // 临时存储编辑中的值
    @State private var tempProvider: String
    @State private var tempModel: String
    @State private var tempOpenAIKey: String
    @State private var tempGrokKey: String
    @State private var tempDeepSeekKey: String
    @State private var tempGeminiKey: String
    @State private var tempOllamaHost: String
    @State private var tempOllamaPort: String
    @State private var tempShowOnTop: Bool
    @State private var tempUseProxy: Bool
    @State private var tempProxyHost: String
    @State private var tempProxyPort: String
    
    let providers = ["OpenAI", "X", "DeepSeek", "Gemini", "Ollama"]
    
    init() {
        _tempProvider = State(initialValue: UserDefaults.standard.string(forKey: "selectedProvider") ?? "OpenAI")
        _tempModel = State(initialValue: UserDefaults.standard.string(forKey: "selectedModel") ?? "gpt-4-turbo")
        _tempOpenAIKey = State(initialValue: UserDefaults.standard.string(forKey: "openaiKey") ?? "")
        _tempGrokKey = State(initialValue: UserDefaults.standard.string(forKey: "grokKey") ?? "")
        _tempDeepSeekKey = State(initialValue: UserDefaults.standard.string(forKey: "deepseekKey") ?? "")
        _tempGeminiKey = State(initialValue: UserDefaults.standard.string(forKey: "geminiKey") ?? "")
        _tempOllamaHost = State(initialValue: UserDefaults.standard.string(forKey: "ollamaHost") ?? "localhost")
        _tempOllamaPort = State(initialValue: UserDefaults.standard.string(forKey: "ollamaPort") ?? "11434")
        _tempShowOnTop = State(initialValue: UserDefaults.standard.bool(forKey: "showOnTop"))
        _tempUseProxy = State(initialValue: UserDefaults.standard.bool(forKey: "useProxy"))
        _tempProxyHost = State(initialValue: UserDefaults.standard.string(forKey: "proxyHost") ?? "")
        _tempProxyPort = State(initialValue: UserDefaults.standard.string(forKey: "proxyPort") ?? "")
    }
    
    // 获取当前选中提供商的 API Key
    private var currentApiKey: Binding<String> {
        Binding(
            get: { 
                switch tempProvider {
                case "OpenAI": return tempOpenAIKey
                case "X": return tempGrokKey
                case "DeepSeek": return tempDeepSeekKey
                case "Gemini": return tempGeminiKey
                default: return ""
                }
            },
            set: { newValue in
                switch tempProvider {
                case "OpenAI": tempOpenAIKey = newValue
                case "X": tempGrokKey = newValue
                case "DeepSeek": tempDeepSeekKey = newValue
                case "Gemini": tempGeminiKey = newValue
                default: break
                }
            }
        )
    }
    
    var body: some View {
        Form {
            // 代理设置
            Section {
                Toggle("Use SOCKS5 Proxy", isOn: $tempUseProxy)
                
                if tempUseProxy {
                    TextField("Host", text: $tempProxyHost)
                        .textFieldStyle(.roundedBorder)
                    TextField("Port", text: $tempProxyPort)
                        .textFieldStyle(.roundedBorder)
                }
            } header: {
                Text("Proxy Settings")
            }
            
            // AI 提供商设置
            Section {
                Picker("Provider", selection: $tempProvider) {
                    ForEach(providers, id: \.self) { provider in
                        Text(provider).tag(provider)
                    }
                }
                .onChange(of: tempProvider) {
                    // 当供应商改变时，设置默认模型
                    let models = modelManager.getModels(for: tempProvider)
                    if !models.isEmpty {
                        tempModel = models[0]
                    }
                }
                
                HStack {
                    Picker("Model", selection: $tempModel) {
                        let models = modelManager.getModels(for: tempProvider)
                        ForEach(models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .onChange(of: modelManager.modelsByProvider) {
                        // 当模型列表更新时，确保选中的模型是有效的
                        let models = modelManager.getModels(for: tempProvider)
                        if !models.contains(tempModel) && !models.isEmpty {
                            tempModel = models[0]
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await modelManager.refreshModels(for: tempProvider)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(modelManager.isLoading)
                    .buttonStyle(.borderless)
                }
                
                if modelManager.isLoading {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            .scaleEffect(0.5)
                        Text("Loading models...")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                
                if let error = modelManager.lastError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            } header: {
                
            }
            
            Section {
                if tempProvider == "Ollama" {
                    TextField("Host", text: $tempOllamaHost)
                        .textFieldStyle(.roundedBorder)
                    TextField("Port", text: $tempOllamaPort)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("API Key", text: currentApiKey)
                        .textFieldStyle(.roundedBorder)
                        .focusable(false)
                }
            } header: {
                Text(tempProvider == "Ollama" ? "Ollama Configuration" : "API Configuration")
            }
            
            Section {
                Toggle("Show on top", isOn: $tempShowOnTop)
            } header: {
                
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    // 保存设置
                    selectedProvider = tempProvider
                    selectedModel = tempModel
                    openaiKey = tempOpenAIKey
                    grokKey = tempGrokKey
                    deepseekKey = tempDeepSeekKey
                    geminiKey = tempGeminiKey
                    ollamaHost = tempOllamaHost
                    ollamaPort = tempOllamaPort
                    showOnTop = tempShowOnTop
                    useProxy = tempUseProxy
                    proxyHost = tempProxyHost
                    proxyPort = tempProxyPort
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 400, height: 300)
        .onAppear {
            // 确保初始模型选择是有效的
            let models = modelManager.getModels(for: tempProvider)
            if !models.contains(tempModel) && !models.isEmpty {
                tempModel = models[0]
            }
        }
    }
}

#Preview {
    SettingsView()
} 
