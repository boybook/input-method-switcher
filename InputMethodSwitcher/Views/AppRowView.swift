import SwiftUI

struct AppRowView: View {
    @ObservedObject var app: InstalledApp
    @EnvironmentObject var appMonitor: AppMonitor
    @Environment(\.colorScheme) var colorScheme  // 获取当前颜色模式

    var body: some View {
        HStack {
            // 左侧的图标和应用名称
            HStack {
                Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                    .resizable()
                    .frame(width: 24, height: 24)
                    .cornerRadius(4)

                Text(app.name)
                    .font(.system(size: 14))
            }

            Spacer()

            // 右侧的输入法选择框，固定宽度
            Picker("输入法", selection: $app.inputMethodID) {
                ForEach(appMonitor.inputMethodManager.getAvailableInputMethods()) { inputMethod in
                    HStack {
                        if inputMethod.id == "default" {
                            // nothing
                        } else if let icon = inputMethod.icon {
                            // 根据当前颜色模式选择显示原图标或反色图标
                            if colorScheme == .dark, let iconInverted = inputMethod.iconInversion {
                                Image(nsImage: iconInverted)  // 暗色模式下显示反色图标
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(nsImage: icon)  // 亮色模式下显示正常图标
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                            }
                        } else {
                            // 默认图标（keyboard），根据颜色模式调整颜色
                            Image(systemName: "keyboard")
                                .foregroundColor(colorScheme == .dark ? .white : .black)  // 暗色模式下变为白色，亮色模式下为黑色
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                        }
                        Text(inputMethod.name)
                    }
                    .tag(inputMethod.id)
                }
            }
            .labelsHidden()
            .frame(width: 150)
            .onChange(of: app.inputMethodID) {
                appMonitor.appInputMethods[app.bundleIdentifier] = app.inputMethodID
                appMonitor.saveSettings()
            }
        }
        .padding(.vertical, 4)
    }
}
