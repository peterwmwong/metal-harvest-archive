import SwiftUI
import MetalKit

final class PreviewMetalView: MTKView {
    private let renderer: Renderer
    private var frameNum: UInt64 = 0
    
    init(device: MTLDevice?) {
        self.renderer = try! Renderer(device: device!)
        super.init(frame: .zero, device: device)
        self.preferredFramesPerSecond = 30
        self.isPaused = false
        self.enableSetNeedsDisplay = false
        self.autoResizeDrawable = true
        self.framebufferOnly = false
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    override func draw(_ rect: CGRect) {
        self.frameNum += 1;
        if let drawable = currentDrawable {
            let commandBuffer = renderer.encodeRender(target: drawable.texture, desc: currentRenderPassDescriptor!, frameNum: &frameNum)
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if canImport(UIKit)
    private typealias ViewRepresentable = UIViewRepresentable
    typealias ViewType = UIView
#elseif canImport(AppKit)
    private typealias ViewRepresentable = NSViewRepresentable
    typealias ViewType = NSView
#endif

struct ContentView: ViewRepresentable {
    #if canImport(UIKit)
    func makeUIView(context: Context) -> PreviewMetalView {
        return PreviewMetalView(device: MTLCreateSystemDefaultDevice())
    }
    func updateUIView(_ view: PreviewMetalView, context: Context) {}
    
    #elseif canImport(AppKit)
    func makeNSView(context: Context) -> PreviewMetalView {
        return PreviewMetalView(device: MTLCreateSystemDefaultDevice())
    }
    func updateNSView(_ view: PreviewMetalView, context: Context) {}
    #endif
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
