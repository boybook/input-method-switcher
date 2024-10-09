import Foundation

class InstalledApp: ObservableObject, Identifiable {
    var id: UUID = UUID()
    var bundleIdentifier: String
    var name: String
    var path: String
    @Published var inputMethodID: String  // 使用 @Published 修饰
    var lastAccessDate: Date?

    init(bundleIdentifier: String, name: String, path: String, inputMethodID: String, lastAccessDate: Date?) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.path = path
        self.inputMethodID = inputMethodID
        self.lastAccessDate = lastAccessDate
    }
}
