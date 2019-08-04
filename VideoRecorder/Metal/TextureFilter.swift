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
    var value: Float { set get }
    var filterValue: Float { get }
}

extension TextureFilter {
    func clamp(_ value: Float) -> Float {
        return max(min(value, TextureFilterValues.max), TextureFilterValues.min)
    }
}

class BaseFilter: TextureFilter {
    fileprivate var clampledValue: Float = 0.0
    fileprivate var computedValue: Float = 0.0
    var filterValue: Float {
        return computedValue
    }
    var value: Float = 0.0
}

class BrightnessFilter: BaseFilter {
    override var value: Float {
        set {
            clampledValue = clamp(newValue)
            computedValue = clampledValue / TextureFilterValues.max
            //print("value: \(value): clamped: \(clampledValue) computed: \(computedValue)")
        }
        get {
            return clampledValue
        }
    }
    
    
}

class ContrastFilter: BaseFilter {
    override var value: Float {
        set {
            clampledValue = clamp(newValue)
            computedValue = (clampledValue + TextureFilterValues.max) / TextureFilterValues.max
        }
        get {
            return clampledValue
        }
    }
}

class SaturationFilter: BaseFilter {
    override var value: Float {
        set {
            clampledValue = clamp(newValue)
            computedValue = (clampledValue + TextureFilterValues.max) / TextureFilterValues.max
        }
        get {
            return clampledValue
        }
    }
}

