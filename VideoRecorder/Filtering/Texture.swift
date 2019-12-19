//
//  Texture.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 31/07/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

import MetalKit
import CoreMedia

enum TextureAccess {
   case readOnly
   case readAndwrite
}

struct TextureDescriptor {
   var width: Int
   var height: Int
   var access: TextureAccess = .readOnly
}

struct Texture {
   private var device: MTLDevice
   var texture: MTLTexture?
   var pixelBuffer: CVPixelBuffer? {
      return pixelBufferFromTexture()
   }

   init(fromResource fileName: String, withExtension fileType: String, on device: MTLDevice) {
      self.device = device
      self.texture = loadTexture(fileName: fileName, fileType: fileType)
   }

   init(texture: MTLTexture) {
      self.device = texture.device
   }

   init(from descriptor: TextureDescriptor, on device: MTLDevice) {
      self.device = device
      self.texture = textureFrom(descriptor: descriptor)
   }

   init(from sampleBuffer: CMSampleBuffer, on device: MTLDevice) {
      self.device = device
      self.texture = textureFrom(sampleBuffer: sampleBuffer)
   }
}

extension Texture {
   private func loadTexture(fileName: String, fileType: String) -> MTLTexture? {
      var texture: MTLTexture?
      let textureLoader = MTKTextureLoader(device: device)
      let textureLoaderOptions: [MTKTextureLoader.Option: Any]
      if ProcessInfo().isOperatingSystemAtLeast(
         OperatingSystemVersion(majorVersion: 10,
                                minorVersion: 0,
                                patchVersion: 0)) {
         textureLoaderOptions = [MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.bottomLeft]
      } else {
         textureLoaderOptions = [:]
      }

      if let textureUrl = Bundle.main.url(forResource: fileName, withExtension: fileType) {
         do {
            texture = try textureLoader.newTexture(URL: textureUrl, options: textureLoaderOptions)
         } catch {
            Log.e("Could not load texture: \(error.localizedDescription)", self)
         }
      }
      return texture
   }

   private func textureFrom(descriptor: TextureDescriptor) -> MTLTexture? {
      let mtlDescriptor = MTLTextureDescriptor()
      mtlDescriptor.pixelFormat = .bgra8Unorm
      mtlDescriptor.width = descriptor.width
      mtlDescriptor.height = descriptor.height
      if descriptor.access == .readAndwrite {
         mtlDescriptor.usage = [.shaderRead, .shaderWrite]
      }

      return device.makeTexture(descriptor: mtlDescriptor)
   }

   private func textureFrom(sampleBuffer: CMSampleBuffer) -> MTLTexture? {
      guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
         return nil
      }

      let width = CVPixelBufferGetWidth(pixelBuffer)
      let height = CVPixelBufferGetHeight(pixelBuffer)

      var textureCache: CVMetalTextureCache?
      if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, self.device, nil, &textureCache) != kCVReturnSuccess {
         return nil
      }
      var cvTextureOut: CVMetalTexture?
      CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                textureCache!,
                                                pixelBuffer,
                                                nil,
                                                .bgra8Unorm,
                                                width,
                                                height,
                                                0,
                                                &cvTextureOut)
      guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
         return nil
      }
      CVMetalTextureCacheFlush(textureCache!, 0)
      return texture
   }

   private func pixelBufferFromTexture() -> CVPixelBuffer? {
      if let metalTexture = self.texture {
         var pixelBuffer: CVPixelBuffer? = nil
         let bufferCreationResult = CVPixelBufferCreate(nil, metalTexture.width,
                                                        metalTexture.height,
                                                        kCVPixelFormatType_32BGRA, nil,
                                                        &pixelBuffer)

         if  bufferCreationResult == kCVReturnSuccess,
            let pixelBuffer = pixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, .init(rawValue: 0))
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let region = MTLRegionMake2D(0, 0, Int(width), height)

            guard let bufferAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
               Log.e("Couldn't get pixel buffer address", self)
               return nil
            }
            metalTexture.getBytes(bufferAddress, bytesPerRow: Int(bytesPerRow), from: region, mipmapLevel: 0)
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .init(rawValue: 0))
            return pixelBuffer
         } else {
            Log.e("Couldn't create pixel buffer from texture. Result code: \(bufferCreationResult)")
         }
      }
      return nil
   }

}
