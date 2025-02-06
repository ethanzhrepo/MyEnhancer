//
//  MyEnhancerApp.swift
//  MyEnhancer
//
//  Created by Ethan on 2025-02-05.
//

import SwiftUI

// 添加一个类来处理菜单操作和应用程序委托
class AppDelegate: NSObject, NSApplicationDelegate {
    @objc static func showSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 在应用程序完成启动后添加菜单项
        NSApp.mainMenu?.items.forEach { item in
            if item.title == "View" {
                let settingsItem = NSMenuItem(
                    title: "Settings...",
                    action: #selector(AppDelegate.showSettings),
                    keyEquivalent: ","
                )
                item.submenu?.insertItem(settingsItem, at: 0)
            }
        }
    }
}
    
@main
struct MyEnhancerApp: App {
    // 保持对 AppDelegate 的强引用
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 460)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 460, height: 300)
        .windowResizability(.contentSize)  // 禁止调整窗口大小
        
        // 添加设置窗口
        Settings {
            SettingsView()
        }
    }
}
