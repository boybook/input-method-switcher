import SwiftUI

struct AppRowView: View {
    @ObservedObject var app: InstalledApp
    @EnvironmentObject var appMonitor: AppMonitor

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
//                        if let icon = inputMethod.icon {
//                            Image(nsImage: icon)
//                                .resizable()
//                                .frame(width: 16, height: 16)  // 设置图标大小
//                        }
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
