import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var appMonitor: AppMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建状态栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)
        }

        // 创建菜单
        let menu = NSMenu()
        let preferencesItem = NSMenuItem(title: "偏好设置", action: #selector(openPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu

        // 请求辅助功能权限
        requestAccessibilityPermissions()
    }

    @objc func openPreferences() {
        if let appMonitor = appMonitor {
            SettingsWindowManager.shared.show(appMonitor: appMonitor)
        } else {
            print("appMonitor 未设置")
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func requestAccessibilityPermissions() {
        let options: [String: AnyObject] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true as AnyObject]
        let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if isTrusted {
            print("辅助功能权限已授予")
        } else {
            print("辅助功能权限未授予，请检查系统设置")
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 在应用关闭时，移除状态栏图标
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
}
