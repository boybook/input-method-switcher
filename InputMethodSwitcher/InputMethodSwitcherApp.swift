import SwiftUI

@main
struct InputMethodSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var appMonitor = AppMonitor()
    
    init() {
        appDelegate.appMonitor = appMonitor
    }

    var body: some Scene {
        Settings {
            
        }
    }
}
