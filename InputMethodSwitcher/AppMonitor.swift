import SwiftUI
import Combine
import Carbon

class AppMonitor: ObservableObject {
    @Published var activeAppIdentifier: String = ""
    @Published var activeAppName: String = ""
    private var cancellable: AnyCancellable?
    private var timer: Timer?
    @Published var appInputMethods: [String: String] = [:] // 应用程序名称到输入法的映射
    var inputMethodManager = InputMethodManager()

    init() {
        loadSettings()
        _ = inputMethodManager.getAvailableInputMethods()
        setupAppFrontSwitchedHandler()
    }

    // 设置应用切换的监听
    func setupAppFrontSwitchedHandler() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let activeApp = NSWorkspace.shared.frontmostApplication {
                let identifier = activeApp.bundleIdentifier ?? "Unknown"
                let appName = activeApp.localizedName ?? "Unknown"
                
                // 检查是否是不同的应用
                if self.activeAppIdentifier != identifier {
                    self.activeAppIdentifier = identifier
                    self.activeAppName = appName
                    self.appFrontSwitched()
                }
            }
        }
    }

    // 前台应用切换时的回调
    func appFrontSwitched() {
        print("当前激活的应用程序是：\(self.activeAppName) (\(self.activeAppIdentifier)")
        applyInputMethod(for: self.activeAppIdentifier)
    }

    func loadSettings() {
        // 从 UserDefaults 加载用户配置的输入法设置
        print("[DEBUG] 正在加载用户输入法设置...")
        if let savedSettings = UserDefaults.standard.dictionary(forKey: "AppInputMethods") as? [String: String] {
            appInputMethods = savedSettings
        }
    }

    func saveSettings() {
        // 将用户配置的输入法设置保存到 UserDefaults
        print("[DEBUG] 正在保存用户输入法设置...")
        UserDefaults.standard.set(appInputMethods, forKey: "AppInputMethods")
    }

    func applyInputMethod(for appIdentifier: String) {
        if let inputMethodID = appInputMethods[appIdentifier] {
            if (inputMethodID != "default") {
                print("[DEBUG] 切换到输入法ID：\(inputMethodID)")
                inputMethodManager.switchInputMethod(to: inputMethodID)
            } else {
                print("[DEBUG] 输入法 default")
            }
        } else {
            print("[DEBUG] 未找到对应的输入法设置")
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
