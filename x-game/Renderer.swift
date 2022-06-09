import SwiftUI
import Metal

let SOURCE = """
    #include <metal_stdlib>
    
    using namespace metal;
    
    struct VertexOut {
        float4 position [[position]];
        float point_size [[point_size]];
    };
    
    vertex VertexOut
    main_vertex(constant ulong & frame_num [[buffer(0)]]) {
        return {
            .position = float4(0,0,0,1),
            .point_size = float(frame_num)
        };
    }
    
    fragment half4
    main_fragment(const float2 pos [[point_coord]]) {
        float const sd = round(1.0 - length(pos - 0.5));
        return half4(0, 1, 0, 1) * sd;
    }
    """

struct Renderer {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let renderPipeline: MTLRenderPipelineState
    
    public init(device: MTLDevice) throws {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        do{
            let lib = try device.makeLibrary(source: SOURCE, options: nil)
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction = lib.makeFunction(name: "main_vertex")
            desc.fragmentFunction = lib.makeFunction(name: "main_fragment")
            desc.colorAttachments[0]?.pixelFormat = .bgra8Unorm
            self.renderPipeline = try device.makeRenderPipelineState(descriptor: desc)
        }
        catch {
            print(error)
            throw error
        }
    }
    
    public func encodeRender(target: MTLTexture, desc: MTLRenderPassDescriptor,frameNum: inout UInt64) -> MTLCommandBuffer {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let enc = commandBuffer.makeRenderCommandEncoder(descriptor: desc)!
        enc.setRenderPipelineState(renderPipeline)
        enc.setVertexBytes(&frameNum, length: MemoryLayout<UInt64>.size, index: 0)
        enc.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1)
        enc.endEncoding()
        return commandBuffer
    }
}
