//
//  Types.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 19/07/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

import simd

struct Vertex {
   var position: SIMD3<Float>
   var textureCoordinates: SIMD2<Float>
}

struct Filters {
   var brightness: Float = 0.0
   var contrast: Float = 0.0
   var saturation: Float = 0.0
}
