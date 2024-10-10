import SwiftUI
import LaunchAtLogin

struct GlobalSettingsView: View {
    @EnvironmentObject var appMonitor: AppMonitor
    @State private var launchAtLogin = false
    @State private var switchNotice = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack {
                    SettingRow(appName: "开机自动启动", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) {
                            LaunchAtLogin.isEnabled = launchAtLogin
                            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
                        }
                    Divider().opacity(0.5)
                    SettingRow(appName: "切换时在光标处显示", isOn: $switchNotice)
                        .onChange(of: switchNotice) {
                            UserDefaults.standard.set(switchNotice, forKey: "switchNotice")
                        }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)  // 使用系统的次级颜色作为边框
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color(NSColor.windowBackgroundColor).opacity(0.2)))  // 使用系统窗口背景色
                )
                Spacer().frame(height: 16)
                // Footer 部分
                VStack {
                    Text("© 2024 boybook. All rights reserved.")
                        .font(.footnote)
                        .foregroundColor(.secondary.opacity(0.65))
                        .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
            switchNotice = UserDefaults.standard.bool(forKey: "switchNotice")
        }
    }
}

// 自定义行视图，表示每个设置项
struct SettingRow: View {
    var appName: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(appName)
                .font(.system(size: 13))

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))  // 使用系统主色调
                .labelsHidden()
                .scaleEffect(0.65)  // 调整开关为小号样式
        }
        .padding(.vertical, 0)  // 设置上下的垂直内边距
    }
}

#Preview {
    GlobalSettingsView()
}
