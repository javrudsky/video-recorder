//
//  Filter.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 27/07/2019.
//  Copyright © 2019 Javi. All rights reserved.
//

import Foundation

struct TextureFilterValues {
   static let min: Float = -127.5
   static let max: Float = 127.5
   static let `default`: Float = 0.0
}

protocol TextureFilter {
   var name: String { get }
   var value: Float { get set }
   var normalizedValue: Float { get }
}

extension TextureFilter {
   func clamp(_ value: Float) -> Float {
      return max(min(value, TextureFilterValues.max), TextureFilterValues.min)
   }
}

class BaseFilter: TextureFilter {
   fileprivate var clampledValue: Float = 0.0
   fileprivate var computedValue: Float = 0.0
   var name: String {
      return ""
   }

   var normalizedValue: Float {
      return computedValue
   }
   var value: Float = 0.0
}

class BrightnessFilter: BaseFilter {
   override var name: String {
      return "BrightnessFilter"
   }
   override var value: Float {
      set {
         clampledValue = clamp(newValue)
         computedValue = clampledValue / TextureFilterValues.max
      }
      get {
         return clampledValue
      }
   }

   override init() {
      super.init()
      self.value = 0.0
   }
}

class ContrastFilter: BaseFilter {
   override var name: String {
      return "ContrastFilter"
   }

   override var value: Float {
      set {
         clampledValue = clamp(newValue)
         computedValue = (clampledValue + TextureFilterValues.max) / TextureFilterValues.max
      }
      get {
         return clampledValue
      }
   }

   override init() {
      super.init()
      self.value = 0.0
   }
}

class SaturationFilter: BaseFilter {
   override var name: String {
      return "SaturationFilter"
   }

   override var value: Float {
      set {
         clampledValue = clamp(newValue)
         computedValue = (clampledValue + TextureFilterValues.max) / TextureFilterValues.max
      }
      get {
         return clampledValue
      }
   }

   override init() {
      super.init()
      self.value = 0.0
   }
}
