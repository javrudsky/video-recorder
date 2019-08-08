//
//  Texture.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 31/07/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

import MetalKit

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
            print("error: Texture loaded \(error.localizedDescription)")
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
}
