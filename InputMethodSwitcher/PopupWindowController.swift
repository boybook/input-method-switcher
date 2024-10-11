import SwiftUI
import AppKit

// 自定义 NSWindow 来设置无边框窗口
class PopupWindowController: NSWindowController {
    var timer: DispatchWorkItem? // 用于管理5秒的计时器
    var isAnimating = false // 标记当前是否有动画进行
    var contentView: InputMethodView?
    var viewModel: InputMethodViewModel?

    convenience init() {
        let viewModel = InputMethodViewModel()
        let contentView = InputMethodView(viewModel: viewModel)
        
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless], // 设置为无边框
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        window.isOpaque = false // 设置窗口透明
        window.backgroundColor = .clear // 背景透明
        window.hasShadow = false // 添加阴影
        window.level = .floating // 窗口显示在最前面
        // 使窗口鼠标可穿透
        window.ignoresMouseEvents = true
        
        window.contentView = NSHostingView(rootView: contentView)
        
        self.init(window: window)
        self.contentView = contentView
        self.viewModel = viewModel
    }
    
    func showAndAnimate(icon: Image?, text: String) {
        // 如果有计时器或正在动画，等待动画结束后更新内容
        if isAnimating {
            hideAndAnimate(fast: true) { [weak self] in
                self?.updateContentAndShow(icon: icon, text: text)
            }
        } else {
            updateContentAndShow(icon: icon, text: text)
        }
    }
    
    private func updateContentAndShow(icon: Image?, text: String) {
        // 使用 viewModel 更新 SwiftUI 视图内容
        viewModel?.updateContent(icon: icon, text: text)
        startShowAnimation()
    }
    
    private func startShowAnimation() {
        guard let window = self.window else { return }
        
        // 移动窗口到鼠标位置右下角
        let mouseLocation = NSEvent.mouseLocation
        let position = NSPoint(x: mouseLocation.x + 16, y: mouseLocation.y - 24)
        
        window.setFrameOrigin(position)
        window.makeKeyAndOrderFront(nil)
        
        // 动画效果（缩放 + 透明度渐变）
        window.alphaValue = 0.0
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            window.animator().alphaValue = 1.0
        } completionHandler: {
            self.isAnimating = true
            // 设置自动消失的计时器
            self.startDismissTimer()
        }
    }
    
    private func startDismissTimer() {
        // 如果已有计时器，先取消
        timer?.cancel()
        
        // 创建新的计时器
        timer = DispatchWorkItem { [weak self] in
            self?.hideAndAnimate()
        }
        
        // 延时执行隐藏动画
        if let timer = timer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: timer)
        }
    }
    
    func hideAndAnimate(fast: Bool = false, completion: (() -> Void)? = nil) {
        guard let window = self.window else { return }

        // 动画淡出，快速模式时加速淡出
        NSAnimationContext.runAnimationGroup { context in
            context.duration = fast ? 0.1 : 0.2 // 快速消失
            window.animator().alphaValue = 0.0
        } completionHandler: {
            window.orderOut(nil)
            self.isAnimating = false
            completion?() // 动画结束后执行 completion
        }
    }
}

class InputMethodViewModel: ObservableObject {
    @Published var icon: Image? = Image(systemName: "keyboard")
    @Published var text: String = "ABC"
    
    func updateContent(icon: Image?, text: String) {
        self.icon = icon
        self.text = text
    }
}

// SwiftUI 视图：输入法切换 UI
struct InputMethodView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @ObservedObject var viewModel: InputMethodViewModel

    var body: some View {
        HStack {
            if let icon = viewModel.icon {
                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
            }
            Text(viewModel.text)
                .foregroundColor(.white)
                .font(.system(size: 12))
                .fixedSize() // 确保 Text 根据内容自适应宽度
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.accentColor)
                .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                opacity = isHovered ? 0.2 : 1.0 // 鼠标悬停时调整透明度为 50%，否则恢复为 100%
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    InputMethodView(viewModel: InputMethodViewModel())
}
