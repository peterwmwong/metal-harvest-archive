import SwiftUI
import Metal

enum Mode {
    case harvest_archive_binary
    case use_archive_binary
}

let MODE = Mode.harvest_archive_binary

struct Renderer {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let renderPipeline: MTLRenderPipelineState
    
    public init(device: MTLDevice) throws {
       self.device = device
       self.commandQueue = device.makeCommandQueue()!
        
        let lib = device.makeDefaultLibrary()!
        lib.label = "Library"

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = lib.makeFunction(name: "vert_main")
        desc.fragmentFunction = lib.makeFunction(name: "frag_main")
        desc.colorAttachments[0]?.pixelFormat = .bgra8Unorm

        let archdesc = MTLBinaryArchiveDescriptor()
        
        switch MODE {
        case .harvest_archive_binary:
            let archive = try device.makeBinaryArchive(descriptor: archdesc)
            try archive.addRenderPipelineFunctions(descriptor: desc)
            try archive.serialize(to: NSURL.fileURL(withPath: "/Users/pwong/Downloads/x-game.metallib"))
            renderPipeline = try device.makeRenderPipelineState(descriptor: desc)
        
        case .use_archive_binary:
            archdesc.url = NSURL.fileURL(withPath: "/Users/pwong/projects/x-gpubin/archive-with-air.metallib")
            let archive = try device.makeBinaryArchive(descriptor: archdesc)
            desc.binaryArchives = [archive];
            renderPipeline = try! device.makeRenderPipelineState(descriptor: desc, options: [.failOnBinaryArchiveMiss]).0
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
