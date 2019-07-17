//
//  ViewRenderer.swift
//  Video Recorder
//
//  Created by Javier L. Avrudsky on 24/05/2019.
//  Copyright © 2019 Javi. All rights reserved.
//

import Foundation
import MetalKit

struct AttributeIndex {
    static let vertexPosition = 0
    static let vertexColor = 1
}

struct Vertex {
    var position: float3
    var color: float4
}

class ViewRenderer: NSObject  {
    
    var device: MTLDevice
    var commandQueue: MTLCommandQueue!
    
    var vertices: [Vertex] = [
        Vertex(position: float3(-1.0, 1.0, 0.0), color: float4(1.0, 0.0, 0.0, 1.0)),
        Vertex(position: float3(1.0, 1.0, 0.0), color: float4(0.0, 1.0, 0.0, 1.0)),
        Vertex(position: float3(-1.0, -1.0, 0.0), color: float4(0.0, 0.0, 1.0, 1.0)),
        Vertex(position: float3(1.0, -1.0, 0.0), color: float4(0.0, 0.0, 1.0, 1.0))
    ]
    
    var indexes: [UInt16] = [
        0, 1, 2,
        1, 2, 3
    ]
    
    
    var pipelineState: MTLRenderPipelineState?
    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    
    override init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        buildModel()
        buildPipelineState()
    }
    
    private func buildModel() {
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.size, options: [])
        indexBuffer = device.makeBuffer(bytes: indexes, length: indexes.count * MemoryLayout<UInt16>.size, options: [])
        
    }
    
    private func buildPipelineState() {
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_shader")
        let fragmentFunction = library?.makeFunction(name: "fragment_shader")
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[AttributeIndex.vertexPosition].format = .float3
        vertexDescriptor.attributes[AttributeIndex.vertexPosition].offset = 0
        vertexDescriptor.attributes[AttributeIndex.vertexPosition].bufferIndex = 0
        vertexDescriptor.attributes[AttributeIndex.vertexColor].format = .float4
        vertexDescriptor.attributes[AttributeIndex.vertexColor].offset = MemoryLayout<float3>.stride
        vertexDescriptor.attributes[AttributeIndex.vertexColor].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("error: \(error.localizedDescription)")
        }
        
    }
}

extension ViewRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
            let pipelineState = pipelineState,
            let descriptor = view.currentRenderPassDescriptor ,
            let indexBuffer = self.indexBuffer else {
            return
        }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
        commandEncoder?.setRenderPipelineState(pipelineState)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.drawIndexedPrimitives(type: .triangle, indexCount: indexes.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        //commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
