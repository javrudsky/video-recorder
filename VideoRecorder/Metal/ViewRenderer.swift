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
   static let textureCoordinates = 1
}

class ViewRenderer: NSObject {

   var texture: Texture?

   private let kVertexShaderFunction = "vertex_shader"
   private let kFragmentShaderFunction = "texture_shader"

   private let vertices: [Vertex] = [
      Vertex(position: float3(-1.0, 1.0, 0.0), textureCoordinates: float2(0.0, 1.0)),
      Vertex(position: float3(-1.0, -1.0, 0.0), textureCoordinates: float2(0.0, 0.0)),
      Vertex(position: float3(1.0, -1.0, 0.0), textureCoordinates: float2(1.0, 0.0)),
      Vertex(position: float3(1.0, 1.0, 0.0), textureCoordinates: float2(1.0, 1.0))
   ]

   private let indexes: [UInt16] = [
      0, 1, 2,
      2, 3, 0
   ]

   private var device: MTLDevice
   private var commandQueue: MTLCommandQueue?
   private var sampleState: MTLSamplerState?
   private var pipelineState: MTLRenderPipelineState?
   private var vertexBuffer: MTLBuffer?
   private var indexBuffer: MTLBuffer?

   init(device: MTLDevice) {
      self.device = device
      self.commandQueue = device.makeCommandQueue()
      super.init()
      buildModel()
      buildPipelineState()
      buildSampleState()
   }

   private func buildModel() {
      // TODO: Find out why should add +1 to vertices.count to make the shader get the last vertex
      vertexBuffer = device.makeBuffer(bytes: vertices,
                                       length: (vertices.count + 1) * MemoryLayout<Vertex>.size,
                                       options: [])
      indexBuffer = device.makeBuffer(bytes: indexes,
                                      length: indexes.count * MemoryLayout<UInt16>.size,
                                      options: [])
   }

   private func buildPipelineState() {
      let library = device.makeDefaultLibrary()
      let vertexFunction = library?.makeFunction(name: kVertexShaderFunction)
      let fragmentFunction = library?.makeFunction(name: kFragmentShaderFunction)

      let vertexDescriptor = MTLVertexDescriptor()
      vertexDescriptor.attributes[AttributeIndex.vertexPosition].format = .float3
      vertexDescriptor.attributes[AttributeIndex.vertexPosition].offset = 0
      vertexDescriptor.attributes[AttributeIndex.vertexPosition].bufferIndex = 0

      vertexDescriptor.attributes[AttributeIndex.textureCoordinates].format = .float2
      vertexDescriptor.attributes[AttributeIndex.textureCoordinates].offset = MemoryLayout<float3>.stride
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
         let indexBuffer = self.indexBuffer,
         let texture = self.texture?.texture,
         let commandQueue = self.commandQueue,
         let commandBuffer = commandQueue.makeCommandBuffer(),
         let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
      }

      commandEncoder.setFragmentSamplerState(sampleState, index: 0)
      commandEncoder.setRenderPipelineState(pipelineState)
      commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
      commandEncoder.setFragmentTexture(texture, index: 0)
      commandEncoder.drawIndexedPrimitives(type: .triangle,
                                           indexCount: indexes.count,
                                           indexType: .uint16,
                                           indexBuffer: indexBuffer,
                                           indexBufferOffset: 0)
      commandEncoder.endEncoding()
      commandBuffer.present(drawable)
      commandBuffer.commit()
   }
}
