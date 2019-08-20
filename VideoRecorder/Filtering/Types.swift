//
//  Types.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 19/07/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

import simd

struct Vertex {
   var position: float3
   var textureCoordinates: float2
}

struct Filters {
   var brightness: Float = 0.0
   var contrast: Float = 0.0
   var saturation: Float = 0.0
}
