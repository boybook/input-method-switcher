import SwiftUI
import Combine
import Carbon

class InputMethodManager {
    private var cachedInputMethods: [InputMethod]? // 缓存的输入法列表
    
    // 根据输入法ID获取输入法源
    func getInputSource(for identifier: String) -> TISInputSource? {
        if let cfArray = TISCreateInputSourceList(nil, false)?.takeRetainedValue() {
            for cf in cfArray as NSArray {
                let inputSource = cf as! TISInputSource

                if let inputSourceIDPtr = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
                    let inputSourceID = Unmanaged<CFString>.fromOpaque(inputSourceIDPtr).takeUnretainedValue() as String
                    if inputSourceID == identifier {
                        return inputSource
                    }
                }
            }
        }
        return nil
    }
    
    // 获取输入法的本地化名称
    func getInputSourceLocalizedName(id: String, inputSource: TISInputSource) -> String {
        switch id {
        case "com.tencent.inputmethod.wetype.pinyin":
            return "微信拼音"
        case "com.sogou.inputmethod.sogou.pinyin":
            return "搜狗拼音"
        case "com.apple.inputmethod.SCIM.ITABC":
            return "中文"
        case "com.apple.keylayout.ABC":
            return "ABC"
        default:
            if let namePtr = TISGetInputSourceProperty(inputSource, kTISPropertyLocalizedName) {
                let name = Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
                return name
            } else {
                return id
            }
        }
    }
    
    func getInputSourceIcon(inputSource: TISInputSource) -> NSImage? {
        // 获取图标引用
        if let iconRefPtr = TISGetInputSourceProperty(inputSource, kTISPropertyIconRef) {
            let iconRef = OpaquePointer(iconRefPtr)
            
            // 使用 IconRef 创建 NSImage
            return NSImage(iconRef: iconRef)
        }

        // 如果图标引用不可用，尝试获取图标的 URL
        if let iconURLPtr = TISGetInputSourceProperty(inputSource, kTISPropertyIconImageURL) {
            let url = Unmanaged<CFURL>.fromOpaque(iconURLPtr).takeUnretainedValue() as URL
            return NSImage(contentsOf: url)  // 从URL加载图像
        }
        
        return nil
    }

    // 获取所有可用输入法
    func getAvailableInputMethods() -> [InputMethod] {
        if let cachedMethods = cachedInputMethods {
            return cachedMethods
        }

        var inputMethods: [InputMethod] = [InputMethod(id: "default", name: "-", icon: nil)]
        
        if let cfArray = TISCreateInputSourceList(nil, false)?.takeRetainedValue() {
            for cf in cfArray as NSArray {
                let inputSource = cf as! TISInputSource
                
                // 检查输入法是否启用
                if let isEnabledPtr = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsEnableCapable),
                   let isEnabled = Unmanaged<CFBoolean>.fromOpaque(isEnabledPtr).takeUnretainedValue() as? Bool, isEnabled {
                    
                    if let inputSourceIDPtr = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
                        let inputSourceID = Unmanaged<CFString>.fromOpaque(inputSourceIDPtr).takeUnretainedValue() as String
                        let name = getInputSourceLocalizedName(id: inputSourceID, inputSource: inputSource)
                        let icon = getInputSourceIcon(inputSource: inputSource)
                        
                        inputMethods.append(InputMethod(id: inputSourceID, name: name, icon: icon))
                    }
                }
            }
        }
        
        cachedInputMethods = inputMethods
        return inputMethods
    }

    // 切换到指定的输入法
    func switchInputMethod(to sourceID: String) {
        print("[DEBUG] 正在切换输入法...")
        if let inputSource = getInputSource(for: sourceID) {
            print("[DEBUG] 找到匹配的输入法ID：\(sourceID)，正在切换...")
            TISSelectInputSource(inputSource)
        } else {
            print("[DEBUG] 未找到任何输入法源")
        }
    }
}

struct InputMethod: Identifiable {
    var id: String
    var name: String
    var icon: NSImage?  // 添加图标属性
}
