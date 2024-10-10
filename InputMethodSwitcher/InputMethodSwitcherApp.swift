import SwiftUI

@main
struct InputMethodSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {}

    var body: some Scene {
        Settings {
            
        }
    }
}

// 扩展 NSImage 以便于转换为 SwiftUI 的 Image
extension NSImage {
    func toSwiftUIImage() -> Image? {
        // 尝试将 NSImage 转换为 CGImage
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let cgImage = bitmap.cgImage else {
            return nil
        }
        // 使用 CGImage 初始化 SwiftUI 的 Image
        return Image(decorative: cgImage, scale: 1.0, orientation: .up)
    }
}
