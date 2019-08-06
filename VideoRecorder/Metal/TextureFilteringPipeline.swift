//
//  FilteringPipeline.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 27/07/2019.
//  Copyright © 2019 Javi. All rights reserved.
//

import Foundation
import MetalKit

typealias FilteredTextureHandler = ((Texture?)->Void)

class TextureFilteringPipeline {
   private let kKernelShaderFunction = "kernel_shader"
   private var filters: [String:TextureFilter]
   private var device: MTLDevice
   private var commandQueue: MTLCommandQueue?
   private var sampleState: MTLSamplerState?
   private var pipelineState: MTLComputePipelineState?
   
   private var kernelFilters: Filters
   private var filtersDefaults: Filters
   
   private let kBrightnessFilterKey = String(describing: BrightnessFilter.self)
   private let kContrastFilterKey = String(describing: ContrastFilter.self)
   private let kSaturationFilterKey = String(describing: SaturationFilter.self)
   
   init(device: MTLDevice) {
      filters = [String:TextureFilter]()
      kernelFilters = Filters()
      filtersDefaults = Filters()
      self.device = device
      self.commandQueue = device.makeCommandQueue()
      buildPipelineState()
      buildSampleState()
      setDefaultFiltersValues()
   }
   
   func set(filter: TextureFilter) {
      filters[key(for: type(of:filter))] = filter
   }
   
   func clear(filter: TextureFilter.Type) {
      filters.removeValue(forKey: key(for: filter))
   }
   
   func clearAllFilters() {
      filters.removeAll();
   }
   
   func applyFilter(texture: Texture, completion: @escaping FilteredTextureHandler) {
      
      guard let pipelineState = pipelineState,
         let sourceTexture = texture.texture,
         let commandQueue = self.commandQueue,
         let commandBuffer = commandQueue.makeCommandBuffer(),
         let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            completion(nil)
            return
      }
      
      let textureDescriptor = TextureDescriptor(width: sourceTexture.width, height: sourceTexture.height, access: .readAndwrite)
      let targetTexture = Texture(from: textureDescriptor, on: device)
      guard let filteredTexture = targetTexture.texture else {
         completion(nil)
         return
      }
      
      kernelFilters.brightness = filters[kBrightnessFilterKey]?.normalizedValue ?? filtersDefaults.brightness
      kernelFilters.contrast = filters[kContrastFilterKey]?.normalizedValue ?? filtersDefaults.contrast
      kernelFilters.saturation = filters[kSaturationFilterKey]?.normalizedValue ?? filtersDefaults.saturation
      
      DispatchQueue.global().async {
         
         let threadExecutionWidth = pipelineState.threadExecutionWidth
         let threadgroupHeight = pipelineState.maxTotalThreadsPerThreadgroup / threadExecutionWidth
         let threadsPerThreadgroup = MTLSizeMake(threadExecutionWidth, threadgroupHeight, 1)
         let threadgroupsPerGrid = MTLSize(width: (sourceTexture.width + threadExecutionWidth - 1) / threadExecutionWidth,
                                           height: (sourceTexture.height + threadgroupHeight - 1) / threadgroupHeight,
                                           depth: 1)
         
         commandEncoder.setSamplerState(self.sampleState, index: 0)
         commandEncoder.setComputePipelineState(pipelineState)
         commandEncoder.setBytes(&self.kernelFilters, length: MemoryLayout<Filters>.stride, index: 1)
         commandEncoder.setTexture(sourceTexture, index: 0)
         commandEncoder.setTexture(filteredTexture, index: 1)
         /// TODO: Check hardware available to add line bellow
         //commandEncoder.dispatchThreads(threadgroups, threadsPerThreadgroup: threadgroupCounts)
         commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
         commandEncoder.endEncoding()
         commandBuffer.commit()
         DispatchQueue.main.async {
            commandBuffer.waitUntilCompleted()
            completion(targetTexture)
         }
      }
   }
}

extension TextureFilteringPipeline {
   
   private func key(for filterType: TextureFilter.Type) -> String {
      return String(describing: filterType)
   }
   
   private func buildPipelineState() {
      let library = device.makeDefaultLibrary()
      let kernelFunction = library?.makeFunction(name: kKernelShaderFunction)
      
      do {
         pipelineState = try device.makeComputePipelineState(function: kernelFunction!)
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
   
   private func setDefaultFiltersValues() {
      filtersDefaults.brightness = BrightnessFilter().normalizedValue
      filtersDefaults.contrast = ContrastFilter().normalizedValue
      filtersDefaults.saturation = SaturationFilter().normalizedValue
   }
}
