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
    var popupController: PopupWindowController?

    init() {
        loadSettings()
        _ = inputMethodManager.getAvailableInputMethods()
        setupPopupController()
        setupAppFrontSwitchHandler()
    }
    
    func setupPopupController() {
        self.popupController = PopupWindowController()
    }
    
    func setupAppFrontSwitchHandler() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(appDidActivate), name: NSWorkspace.didActivateApplicationNotification, object: nil)
                
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidActivate),
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
    }
    
    @objc func appDidActivate(notification: NSNotification) {
        if let userInfo = notification.userInfo,
           let app = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           let bundleIdentifier = app.bundleIdentifier,
           let appName = app.localizedName
        {
            self.activeAppIdentifier = bundleIdentifier
            self.activeAppName = appName
            print("[DEBUG] 应用切换：\(appName) \(bundleIdentifier)")
            applyInputMethod(for: bundleIdentifier)
        }
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
                // 展示 Popup 提示
                if let method = inputMethodManager.getCachedInputMethod(for: inputMethodID),
                    UserDefaults.standard.bool(forKey: "switchNotice") {
                    self.popupController?.showAndAnimate(icon: method.iconInversion?.toSwiftUIImage() ?? Image(systemName: "keyboard"), text: method.name)
                }
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
