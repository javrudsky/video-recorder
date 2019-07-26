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
    static let textureCoordinates = 2
}

class ViewRenderer: NSObject  {
    
    var device: MTLDevice
    var commandQueue: MTLCommandQueue!
    var filters: Filters
    var texture: MTLTexture?
    var sampleState: MTLSamplerState?
    let kMaxFilterValue: Float = 127.5
    
    var brightness: Float = 0.0 {
        didSet {
            filters.brightness = brightness / kMaxFilterValue
        }
    }
    
    var contrast: Float = 0.0 {
        didSet {
            filters.contrast = (contrast + kMaxFilterValue) / kMaxFilterValue
        }
    }
    
    var saturation: Float = 0.0 {
        didSet {
            filters.saturation = (saturation + kMaxFilterValue) / kMaxFilterValue
        }
    }
    
    var vertices: [Vertex] = [
        Vertex(position: float3(-1.0, 1.0, 0.0), color: float4(1.0, 0.0, 0.0, 1.0), texture: float2(0.0, 1.0)),
        Vertex(position: float3(-1.0, -1.0, 0.0), color: float4(1.0, 0.0, 0.0, 1.0), texture: float2(0.0, 0.0)),
        Vertex(position: float3(1.0, -1.0, 0.0), color: float4(1.0, 0.0, 0.0, 1.0), texture: float2(1.0, 0.0)),
        Vertex(position: float3(1.0, 1.0, 0.0), color: float4(0.0, 1.0, 1.0, 1.0), texture: float2(1.0, 1.0)),
    ]
    
    var indexes: [UInt16] = [
        0, 1, 2,
        2, 3, 0
    ]
    
    
    var pipelineState: MTLRenderPipelineState?
    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    
    override init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!
        self.filters = Filters()
        super.init()
        buildModel()
        buildPipelineState()
        buildSampleState()
    }
    
    private func buildModel() {
        // TODO: Find out why should add +1 to vertices.count to make the shader get the last vertex
        vertexBuffer = device.makeBuffer(bytes: vertices, length: (vertices.count + 1) * MemoryLayout<Vertex>.size, options: [])
        indexBuffer = device.makeBuffer(bytes: indexes, length: indexes.count * MemoryLayout<UInt16>.size, options: [])
        
    }
    
    private func buildPipelineState() {
        let library = device.makeDefaultLibrary()
        var fragmentFunctionName = "fragment_shader"
        texture = loadTexture(imageName: "jeep", imageExtension: "jpg")
        if let _ = texture {
            fragmentFunctionName = "texture_shader"
        }
        let vertexFunction = library?.makeFunction(name: "vertex_shader")
        let fragmentFunction = library?.makeFunction(name: fragmentFunctionName)
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[AttributeIndex.vertexPosition].format = .float3
        vertexDescriptor.attributes[AttributeIndex.vertexPosition].offset = 0
        vertexDescriptor.attributes[AttributeIndex.vertexPosition].bufferIndex = 0
        
        vertexDescriptor.attributes[AttributeIndex.vertexColor].format = .float4
        vertexDescriptor.attributes[AttributeIndex.vertexColor].offset = MemoryLayout<float3>.stride
        vertexDescriptor.attributes[AttributeIndex.vertexColor].bufferIndex = 0
        
        vertexDescriptor.attributes[AttributeIndex.textureCoordinates].format = .float2
        vertexDescriptor.attributes[AttributeIndex.textureCoordinates].offset = MemoryLayout<float3>.stride + MemoryLayout<float4>.stride
        vertexDescriptor.attributes[AttributeIndex.textureCoordinates].bufferIndex = 0
        
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
    
    private func loadTexture(imageName: String, imageExtension: String) -> MTLTexture? {
        var texture: MTLTexture? = nil;
        let textureLoader = MTKTextureLoader(device: device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any]
        if ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 0, patchVersion: 0)) {
            textureLoaderOptions = [MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.bottomLeft]
        } else {
            textureLoaderOptions = [:]
        }
        
        if let textureUrl = Bundle.main.url(forResource: imageName, withExtension: imageExtension) {
            do {
                texture = try textureLoader.newTexture(URL: textureUrl, options: textureLoaderOptions)
            } catch {
                print("error: Texture loaded \(error.localizedDescription)")
            }
        }
        return texture;
    }
    
    private func buildSampleState() {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        sampleState = device.makeSamplerState(descriptor: descriptor)
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
        commandEncoder?.setFragmentSamplerState(sampleState, index: 0)
        commandEncoder?.setRenderPipelineState(pipelineState)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.setVertexBytes(&filters, length: MemoryLayout<Filters>.stride, index: 1)
        commandEncoder?.setFragmentTexture(texture, index: 0)
        commandEncoder?.drawIndexedPrimitives(type: .triangle, indexCount: indexes.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
