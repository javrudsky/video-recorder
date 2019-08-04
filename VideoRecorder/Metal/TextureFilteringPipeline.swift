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
    private var filters: [String:TextureFilter]
    private var device: MTLDevice
    private var commandQueue: MTLCommandQueue!
    private var sampleState: MTLSamplerState?
    private var pipelineState: MTLComputePipelineState?
    private var kernelFilters: Filters
    
    init(device: MTLDevice) {
        filters = [String:TextureFilter]()
        kernelFilters = Filters()
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        buildPipelineState()
        buildSampleState()
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
        
        kernelFilters.brightness = filters["BrightnessFilter"]?.filterValue ?? 0.0
        kernelFilters.saturation = filters["SaturationFilter"]?.filterValue ?? 0.0
        kernelFilters.contrast = filters["ContrastFilter"]?.filterValue ?? 0.0
        
        DispatchQueue.global().async {
            
        
        let w = pipelineState.threadExecutionWidth
        let h = pipelineState.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        let threadgroupsPerGrid = MTLSize(width: (sourceTexture.width + w - 1) / w,
                                          height: (sourceTexture.height + h - 1) / h,
                                          depth: 1)

        commandEncoder.setSamplerState(self.sampleState, index: 0)
        commandEncoder.setComputePipelineState(pipelineState)
        commandEncoder.setBytes(&self.kernelFilters, length: MemoryLayout<Filters>.stride, index: 1)
        commandEncoder.setTexture(sourceTexture, index: 0)
        commandEncoder.setTexture(filteredTexture, index: 1)
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
        let kernelFunction = library?.makeFunction(name: "kernel_shader")
        
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
}
