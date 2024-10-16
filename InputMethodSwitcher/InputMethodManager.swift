import SwiftUI
import Combine
import Carbon
import Cocoa
import CoreImage.CIFilterBuiltins

class InputMethodManager {
    private var cachedInputMethods: [InputMethod]?
    private var cachedInputMethodsDict: [String: InputMethod]?
    
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
        if let namePtr = TISGetInputSourceProperty(inputSource, kTISPropertyLocalizedName) {
            let name = Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
            return name
        } else {
            return id
        }
    }
    
    func getInputSourceIcon(inputSource: TISInputSource) -> NSImage? {
        // 尝试获取输入法的图标引用 这个方式获取出来的 ABC 图标很迷
//        if let iconRefPtr = TISGetInputSourceProperty(inputSource, kTISPropertyIconRef) {
//            let iconRef = OpaquePointer(iconRefPtr)
//            // 使用 IconRef 创建 NSImage
//            let icon = NSImage(iconRef: iconRef)
//            return icon
//        }

        // 如果图标引用不可用，尝试获取图标的 URL
        if let iconURLPtr = TISGetInputSourceProperty(inputSource, kTISPropertyIconImageURL) {
            let url = Unmanaged<CFURL>.fromOpaque(iconURLPtr).takeUnretainedValue() as URL
            if let icon = NSImage(contentsOf: url) {
                return icon
            }
        }
        
        return nil
    }
    
    // 应用反色效果
    func applyInversion(to nsImage: NSImage?) -> NSImage? {
        guard let nsImage = nsImage else { return nil }

        // 创建一个新的 NSImage，用于存储处理后的图像表示
        let invertedImage = NSImage(size: nsImage.size)

        for imageRep in nsImage.representations {
            if let bitmapRep = imageRep as? NSBitmapImageRep,
               let cgImage = bitmapRep.cgImage {

                // 创建 CIImage 并应用反色滤镜
                let ciImage = CIImage(cgImage: cgImage)
                let filter = CIFilter.colorInvert()
                filter.inputImage = ciImage

                let context = CIContext(options: nil)
                if let outputImage = filter.outputImage,
                   let outputCGImage = context.createCGImage(outputImage, from: ciImage.extent) {

                    // 创建新的 NSBitmapImageRep，并保留原始尺寸和分辨率
                    let outputImageRep = NSBitmapImageRep(cgImage: outputCGImage)

                    // 设置尺寸以保留分辨率（重要）
                    outputImageRep.size = bitmapRep.size

                    // 将新的图像表示添加到 invertedImage
                    invertedImage.addRepresentation(outputImageRep)
                } else {
                    // 如果处理失败，保留原始的图像表示
                    invertedImage.addRepresentation(imageRep)
                }
            } else {
                // 非位图类型 TODO 还需要更加细节的处理
                guard let tiffData = nsImage.tiffRepresentation,
                      let ciImage = CIImage(data: tiffData) else {
                    return nsImage
                }

                let context = CIContext(options: nil)
                let filter = CIFilter.colorInvert()  // 反色滤镜

                filter.inputImage = ciImage

                if let outputImage = filter.outputImage,
                   let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                    return NSImage(cgImage: cgImage, size: nsImage.size)
                }
                return nsImage
            }
        }

        return invertedImage
    }

    // 获取所有可用输入法，返回列表
    func getAvailableInputMethods() -> [InputMethod] {
        if let cachedMethods = cachedInputMethods {
            // 返回缓存的输入法列表å
            return cachedMethods
        }
        
        var inputMethods: [InputMethod] = [InputMethod(id: "default", name: "-", icon: nil)]
        var inputMethodsMap: [String: InputMethod] = [:] // 用于缓存的 Map
        inputMethodsMap["default"] = InputMethod(id: "default", name: "-", icon: nil)
        
        if let cfArray = TISCreateInputSourceList(nil, false)?.takeRetainedValue() {
            for cf in cfArray as NSArray {
                let inputSource = cf as! TISInputSource
                
                // 检查输入法是否为键盘类型
                if let categoryPtr = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceCategory) {
                    let category = Unmanaged<CFString>.fromOpaque(categoryPtr).takeUnretainedValue() as String
                    
                    if category == kTISCategoryKeyboardInputSource as String {
                        // 检查输入法是否被启用
                        if let isEnabledPtr = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsSelectCapable),
                           let isEnabled = Unmanaged<CFBoolean>.fromOpaque(isEnabledPtr).takeUnretainedValue() as? Bool, isEnabled {
                            
                            if let inputSourceIDPtr = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
                                let inputSourceID = Unmanaged<CFString>.fromOpaque(inputSourceIDPtr).takeUnretainedValue() as String
                                let name = getInputSourceLocalizedName(id: inputSourceID, inputSource: inputSource)
                                print("[DEBUG-输入法] \(name) [\(inputSourceID)]")
                                let icon = getInputSourceIcon(inputSource: inputSource)
                                let iconInversion = applyInversion(to: icon)
                                
                                let inputMethod = InputMethod(id: inputSourceID, name: name, icon: icon, iconInversion: iconInversion)
                                
                                // 将输入法加入 Map 和 List
                                inputMethods.append(inputMethod)
                                inputMethodsMap[inputSourceID] = inputMethod
                            }
                        }
                    }
                }
            }
        }
        
        self.cachedInputMethods = inputMethods
        self.cachedInputMethodsDict = inputMethodsMap
        return inputMethods
    }

    // 切换到指定的输入法
    func switchInputMethod(to sourceID: String) {
        print("[DEBUG] 正在切换输入法...")
        if let inputSource = self.getInputSource(for: sourceID) {
            print("[DEBUG] 找到匹配的输入法ID：\(sourceID)，正在切换...")
            TISSelectInputSource(inputSource)
        } else {
            print("[DEBUG] 未找到任何输入法源")
        }
    }
    
    // 根据输入法ID获取缓存中的输入法
    func getCachedInputMethod(for key: String) -> InputMethod? {
        return cachedInputMethodsDict?[key]
    }
}

struct InputMethod: Identifiable {
    var id: String
    var name: String
    var icon: NSImage?
    var iconInversion: NSImage?
}
