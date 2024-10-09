import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject var appMonitor: AppMonitor
    @State private var installedApps: [InstalledApp] = []
    @State private var filteredApps: [InstalledApp] = []  // 用于存储过滤后的应用列表
    @State private var isLoading = true
    @State private var isSearching = false  // 控制搜索框的显示状态
    @State private var searchText = ""  // 用于存储用户输入的搜索内容

    var body: some View {
        VStack {
            if isLoading {
                // 显示加载指示器
                ProgressView()
                    .padding()
            } else {
                List {
                    ForEach(filteredApps) { app in
                        AppRowView(app: app)
                            .environmentObject(appMonitor)
                    }
                }
            }
        }
        .onAppear {
            loadInstalledApps()
        }
        .toolbar {
            // 添加工具栏
            ToolbarItem(placement: .automatic) {
                ZStack {
                    // 搜索框
                    if isSearching {
                        TextField("搜索应用", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: isSearching ? 200 : 0)  // 动态改变宽度
                            .transition(.move(edge: .trailing))  // 搜索框从右侧移入
                            .onChange(of: searchText) {
                                filterApps()
                            }
                    }

                    // 搜索按钮
                    if !isSearching {
                        Button(action: {
                            withAnimation {
                                isSearching = true
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                        }
                        .transition(.opacity)  // 动态淡入淡出搜索按钮
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isSearching)  // 添加平滑动画
            }
        }
    }

    func loadInstalledApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            let appURLs = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask)
            if let appURL = appURLs.first {
                if let apps = try? FileManager.default.contentsOfDirectory(at: appURL, includingPropertiesForKeys: [.contentAccessDateKey], options: .skipsHiddenFiles) {
                    // 过滤并获取应用程序信息
                    var loadedApps = apps.filter { $0.pathExtension == "app" }.compactMap { url -> InstalledApp? in
                        let appPath = url.path
                        let appName = getLocalizedAppName(from: url)  // 获取本地化名称
                        let bundleIdentifier = getBundleIdentifier(from: url)  // 获取包名
                        let inputMethodID = appMonitor.appInputMethods[bundleIdentifier] ?? "default"
                        
                        // 获取上次访问时间
                        let resourceValues = try? url.resourceValues(forKeys: [.contentAccessDateKey])
                        let lastAccessDate = resourceValues?.contentAccessDate

                        return InstalledApp(bundleIdentifier: bundleIdentifier, name: appName, path: appPath, inputMethodID: inputMethodID, lastAccessDate: lastAccessDate)
                    }

                    // 按照上次访问时间排序，降序排列
                    loadedApps.sort { ($0.lastAccessDate ?? Date.distantPast) > ($1.lastAccessDate ?? Date.distantPast) }

                    DispatchQueue.main.async {
                        self.installedApps = loadedApps
                        self.filteredApps = loadedApps  // 初始化为加载的应用列表
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    func getLocalizedAppName(from url: URL, languageCode: String = "zh-Hans") -> String {
        // Get the bundle for the application
        guard let bundle = Bundle(url: url) else {
            return url.deletingPathExtension().lastPathComponent
        }
        
        // Force the bundle to use the desired language (Chinese in this case)
        if let path = bundle.path(forResource: languageCode, ofType: "lproj"),
           let localizedBundle = Bundle(path: path) {
            // Retrieve localized app name
            if let localizedName = localizedBundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String {
                return localizedName
            } else if let localizedName = localizedBundle.localizedInfoDictionary?["CFBundleName"] as? String {
                return localizedName
            }
        }
        
        // Fallback to the standard name if no localized name is found
        let resourceValues = try? url.resourceValues(forKeys: [.localizedNameKey])
        return resourceValues?.localizedName ?? url.deletingPathExtension().lastPathComponent
    }
    
    func getBundleIdentifier(from url: URL) -> String {
        // 读取应用程序包的 Info.plist 文件
        let bundle = Bundle(url: url)
        // 返回 CFBundleIdentifier
        return bundle?.infoDictionary?["CFBundleIdentifier"] as? String ?? url.path()
    }

    // 根据搜索文本过滤应用程序
    func filterApps() {
        if searchText.isEmpty {
            filteredApps = installedApps  // 如果搜索框为空，则显示所有应用
        } else {
            filteredApps = installedApps.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppMonitor())
}
