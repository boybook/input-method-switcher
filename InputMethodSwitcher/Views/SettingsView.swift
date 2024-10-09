import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab? = .home
    @EnvironmentObject var appMonitor: AppMonitor

    var body: some View {
        NavigationSplitView {
            // 左侧的边栏
            List(selection: $selectedTab) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.iconName)
                    }
                }
            }
            .listStyle(SidebarListStyle())
        } detail: {
            VStack {
                // 右侧的详细内容视图
                if let selectedTab = selectedTab {
                    switch selectedTab {
                    case .home:
                        WelcomeView()
                            .id(selectedTab)
                    case .app:
                        AppSettingsView()
                            .environmentObject(appMonitor)
                            .id(selectedTab)
                    case .settings:
                        GlobalSettingsView()
                            .id(selectedTab)
                    }
                } else {
                    Text("请选择一个设置选项")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: selectedTab) {
                // 更新窗口的标题
                if let newTab = selectedTab {
                    updateWindowTitle(to: newTab.titleName)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            // 设置初始窗口标题
            updateWindowTitle(to: selectedTab?.titleName ?? "InputMethodSwitcher")
        }
    }

    // 更新窗口标题的函数
    private func updateWindowTitle(to title: String) {
        if let window = NSApp.keyWindow {
            window.title = title
        }
    }
}

// 定义标签的枚举类型
enum SettingsTab: String, CaseIterable {
    case home = "欢迎"
    case app = "切换规则"
    case settings = "设置"
    
    var titleName: String {
        switch self {
        case .home:
            return "输入法自动切换"
        default:
            return self.rawValue
        }
    }

    var iconName: String {
        switch self {
        case .home:
            return "house"
        case .app:
            return "arrow.2.squarepath"
        case .settings:
            return "gearshape"
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack {
            Text("欢迎使用输入法自动切换！")
                .font(.largeTitle)
            Text("我可以根据应用自动切换输入法")
                .padding(8)
            Spacer().frame(height: 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppMonitor())
}
