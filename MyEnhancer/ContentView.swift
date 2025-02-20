//
//  ContentView.swift
//  MyEnhancer
//
//  Created by Ethan on 2025-02-05.
//

import SwiftUI

// 定义可能的错误类型
enum AIError: LocalizedError {
    case noApiKey
    case noModelSelected
    case noInputText
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "Please configure API Key in settings"
        case .noModelSelected:
            return "Please select a model in settings"
        case .noInputText:
            return "Please enter some text"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var selectedLanguage: String = "English"
    @State private var selectedPersonality: String = "1920s Gangster"
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @AppStorage("showOnTop") private var showOnTop: Bool = false
    
    let languages = ["English", "简体中文", "日本語", "한국어", "العربية", "Deutsch"]
    let personalities = [
        "1920s Gangster", "Caveman", "Cockney", "Emoji Madness", 
        "Indian Guru", "Influencer", "News Anchor", "Old-Timey Prospector",
        "Pirate", "Rapper", "Roast Comic", "Scientist", "Scotsman",
        "Shakespearean", "Southern Belle", "Stand-up Comedian",
        "Valley Girl", "Wrestler"
    ]
    
    // 每次使用时实时读取配置
    private func getCurrentSettings() -> (provider: String, model: String, apiKey: String)? {
        let defaults = UserDefaults.standard
        guard let provider = defaults.string(forKey: "selectedProvider"),
              let model = defaults.string(forKey: "selectedModel") else {
            return nil
        }
        
        let apiKey = provider == "OpenAI" 
            ? defaults.string(forKey: "openaiKey") ?? ""
            : defaults.string(forKey: "grokKey") ?? ""
            
        return (provider, model, apiKey)
    }
    
    // 检查基本配置
    private func validateSettings() throws {
        guard let settings = getCurrentSettings() else {
            throw AIError.noModelSelected
        }
        guard !settings.apiKey.isEmpty else {
            throw AIError.noApiKey
        }
        guard !inputText.isEmpty else {
            throw AIError.noInputText
        }
    }
    
    // 处理AI请求
    private func processAIRequest(withPrompt prompt: String) async {
        do {
            try validateSettings()
            guard let settings = getCurrentSettings() else {
                throw AIError.noModelSelected
            }
            
            isProcessing = true
            errorMessage = nil
            
            let result: String
            if settings.provider == "OpenAI" {
                let openAI = OpenAI(apiKey: settings.apiKey)
                result = try await openAI.complete(model: settings.model, prompt: prompt)
            } else {
                let grok = Grok(apiKey: settings.apiKey)
                result = try await grok.complete(model: settings.model, prompt: prompt)
            }
            
            await MainActor.run {
                outputText = result
            }
            
        } catch let error as AIError {
            print("Error occurred: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        } catch {
            print("Error occurred: \(error)")
            await MainActor.run {
                errorMessage = "Unexpected error: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 输入文本框
            ZStack(alignment: .topLeading) {
                TextEditor(text: $inputText)
                    .frame(height: 80)
                    .font(.system(size: 14))
                    .padding(8)
                
                if inputText.isEmpty {
                    Text("Enter text here...")
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 13)
                        .allowsHitTesting(false)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.2))
            )
            
            // 按钮行
            HStack {
                // 左侧按钮组
                HStack(spacing: 10) {
                    Button("Proofread") {
                        Task {
                            await processAIRequest(withPrompt: Prompts.PROOFREAD + inputText)
                        }
                    }
                    .disabled(isProcessing)
                    
                    Button("Shorten") {
                        Task {
                            await processAIRequest(withPrompt: Prompts.SHORTEN + inputText)
                        }
                    }
                    .disabled(isProcessing)
                    
                    Divider()
                        .frame(height: 20)
                    
                    Picker("", selection: $selectedPersonality) {
                        ForEach(personalities, id: \.self) { personality in
                            Text(personality).tag(personality)
                        }
                    }
                    .frame(width: 100)
                    .disabled(isProcessing)
                    
                    Button("As Personality") {
                        Task {
                            // TODO: 实现性格转换功能
                        }
                    }
                    .disabled(isProcessing)
                }
                
                Divider()
                    .frame(height: 20)
                
                // 右侧语言选择和翻译
                HStack(spacing: 10) {
                    Picker("", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(language)
                        }
                    }
                    .frame(width: 80)
                    .disabled(isProcessing)
                    
                    Button("Translate") {
                        Task {
                            let translationPrompt = Prompts.TRANSLATE
                                .replacingOccurrences(of: "{TARGET_LANGUAGE}", with: selectedLanguage)
                            await processAIRequest(withPrompt: translationPrompt + inputText)
                        }
                    }
                    .disabled(isProcessing)
                }
            }
            .padding(.vertical, 10)
            
            // 错误消息显示
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.vertical, 4)
            }
            
            // 输出文本框
            TextEditor(text: $outputText)
                .frame(height: 80)
                .font(.system(size: 14))
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.2))
                )
                .overlay(
                    Group {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                )
            
            // Stay on top 复选框
            HStack {
                Toggle("Stay on top", isOn: $showOnTop)
                    .toggleStyle(.checkbox)
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding()
        .background(WindowAccessor(showOnTop: showOnTop))
    }
}

// 添加一个用于访问窗口的辅助视图
struct WindowAccessor: NSViewRepresentable {
    let showOnTop: Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.level = showOnTop ? .floating : .normal
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            window.level = showOnTop ? .floating : .normal
        }
    }
}

#Preview {
    ContentView()
}
