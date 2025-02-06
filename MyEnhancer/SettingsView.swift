import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedProvider") private var selectedProvider: String = "OpenAI"
    @AppStorage("selectedModel") private var selectedModel: String = "gpt-4-turbo"
    @AppStorage("openaiKey") private var openaiKey: String = ""
    @AppStorage("grokKey") private var grokKey: String = ""
    @AppStorage("showOnTop") private var showOnTop: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    // 临时存储编辑中的值
    @State private var tempProvider: String
    @State private var tempModel: String
    @State private var tempOpenAIKey: String
    @State private var tempGrokKey: String
    @State private var tempShowOnTop: Bool
    
    let providers = ["OpenAI", "X"]
    
    let modelsByProvider = [
        "OpenAI": ["gpt-4o", "gpt-4o-mini", "o1", "o1-mini", "o3-mini", "gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"],
        "X": ["grok-2-vision-1212", "grok-2-1212", "grok-beta"]
    ]
    
    init() {
        _tempProvider = State(initialValue: UserDefaults.standard.string(forKey: "selectedProvider") ?? "OpenAI")
        _tempModel = State(initialValue: UserDefaults.standard.string(forKey: "selectedModel") ?? "gpt-4-turbo")
        _tempOpenAIKey = State(initialValue: UserDefaults.standard.string(forKey: "openaiKey") ?? "")
        _tempGrokKey = State(initialValue: UserDefaults.standard.string(forKey: "grokKey") ?? "")
        _tempShowOnTop = State(initialValue: UserDefaults.standard.bool(forKey: "showOnTop"))
    }
    
    // 获取当前选中提供商的 API Key
    private var currentApiKey: Binding<String> {
        Binding(
            get: { tempProvider == "OpenAI" ? tempOpenAIKey : tempGrokKey },
            set: { newValue in
                if tempProvider == "OpenAI" {
                    tempOpenAIKey = newValue
                } else {
                    tempGrokKey = newValue
                }
            }
        )
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Provider", selection: $tempProvider) {
                    ForEach(providers, id: \.self) { provider in
                        Text(provider).tag(provider)
                    }
                }
                .onChange(of: tempProvider) { _ in
                    // 当供应商改变时，设置默认模型
                    if let models = modelsByProvider[tempProvider] {
                        tempModel = models[0]
                    }
                }
                
                Picker("Model", selection: $tempModel) {
                    if let models = modelsByProvider[tempProvider] {
                        ForEach(models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                }
            } header: {
                
            }
            
            Section {
                SecureField("API Key", text: currentApiKey)
                    .textFieldStyle(.roundedBorder)
            } header: {
                
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
                    showOnTop = tempShowOnTop
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}

#Preview {
    SettingsView()
} 
