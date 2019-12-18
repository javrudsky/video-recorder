//
//  ImageUtils.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 10/12/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

import Foundation
import CoreVideo
import CoreMedia

class ImageUtils {
   func buff(sampleBuffer: CMSampleBuffer) -> CVPixelBuffer? {
      return CMSampleBufferGetImageBuffer(sampleBuffer)
   }

   func updateSample(sampleBuffer: CMSampleBuffer, texture: MTLTexture) {
      //texture.getBytes(sampleBuffer.dataBuffer, bytesPerRow: 1, from: <#T##MTLRegion#>, mipmapLevel: <#T##Int#>)
   
      let  pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
      if let pixelBuffer = pixelBuffer {
         CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
         let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
         let width = CVPixelBufferGetWidth(pixelBuffer)
         let height = CVPixelBufferGetHeight(pixelBuffer)
         let region = MTLRegionMake2D(0, 0, Int(width), height)

         guard let tempBuffer = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
         texture.getBytes(tempBuffer, bytesPerRow: Int(bytesPerRow), from: region, mipmapLevel: 0)
         CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

      }
   }
}
