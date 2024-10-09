import SwiftUI

class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    var window: NSWindow?

    func show(appMonitor: AppMonitor) {
        if window == nil {
            let settingsView = SettingsView()
                .environmentObject(appMonitor)  // 将 appMonitor 注入环境

            // 创建一个 NSWindow 并使用 NSHostingView 包装 SwiftUI 视图
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),  // 默认较大尺寸
                styleMask: [.titled, .closable, .resizable, .fullSizeContentView],  // 支持全尺寸内容视图
                backing: .buffered,
                defer: false
            )
            
            // 创建并设置工具栏
            let toolbar = NSToolbar()
            window?.toolbar = toolbar  // 将工具栏设置到窗口

            window?.center()
            window?.setFrameAutosaveName("Settings")  // 保存窗口尺寸和位置
            window?.isReleasedWhenClosed = false
            window?.contentView = NSHostingView(rootView: settingsView)
            window?.minSize = NSSize(width: 600, height: 400)  // 设置窗口的最小尺寸
            window?.title = "输入法自动切换"

            // 窗口关闭时，释放 window 对象
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: nil) { [weak self] _ in
                self?.window = nil
            }
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)  // 激活应用程序并确保窗口在前台显示
    }
}
