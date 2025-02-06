import Foundation

struct NetworkConfig {
    static func configuredSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        
        // 检查是否启用代理
        if UserDefaults.standard.bool(forKey: "useProxy"),
           let host = UserDefaults.standard.string(forKey: "proxyHost"),
           let portString = UserDefaults.standard.string(forKey: "proxyPort"),
           let port = Int(portString),
           !host.isEmpty {
            
            // 配置 SOCKS5 代理
            configuration.connectionProxyDictionary = [
                kCFProxyTypeKey: kCFProxyTypeSOCKS,
                kCFProxyHostNameKey: host,
                kCFProxyPortNumberKey: port
            ]
        }
        
        return URLSession(configuration: configuration)
    }
} 