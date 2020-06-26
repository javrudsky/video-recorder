//
//  Shader.metal
//  Video Recorder
//
//  Created by Javier L. Avrudsky on 24/05/2019.
//  Copyright © 2019 Javi. All rights reserved.
//

#include <metal_math>
#include <metal_stdlib>
#include "Filters.h"

using namespace metal;

constant int ATTR_VERTEX_POSITION_INDEX = 0;
constant int ATTR_TEXTURE_COORD_INDEX = 1;

struct VertexIn {
   float4 position [[ attribute(ATTR_VERTEX_POSITION_INDEX) ]];
   float2 textureCoordinates [[ attribute(ATTR_TEXTURE_COORD_INDEX) ]];
};

struct RasterizerIn {
   float4 position [[ position ]];
   float2 textureCoordinates;
};

struct Filters {
   float brightness;
   float contrast;
   float saturation;
};

vertex RasterizerIn vertex_shader(const VertexIn vertexIn [[ stage_in ]]) {
   RasterizerIn rasterizerIn;
   rasterizerIn.position = mirrorOverY(rotateVertex(vertexIn.position));
   rasterizerIn.textureCoordinates = vertexIn.textureCoordinates;
   
   return rasterizerIn;
}

fragment half4 texture_shader(const RasterizerIn rasterizerIn [[ stage_in ]],
                              sampler sampler2d [[ sampler(0) ]],
                              texture2d<float> texture [[ texture(0) ]]) {
   
   float4 color = texture.sample(sampler2d, rasterizerIn.textureCoordinates);
   return half4(color.r, color.g, color.b, 1.0);
}

kernel void kernel_shader(texture2d<float, access::read> sourceTexture [[texture(0)]],
                          constant Filters &filters [[ buffer(1) ]],
                          texture2d<float, access::write> filteredTexture [[texture(1)]],
                          uint2 position [[ thread_position_in_grid ]]) {
   
   if (position.x >= filteredTexture.get_width() || position.y >= filteredTexture.get_height()) {
      return;
   }
   
   float4 color = sourceTexture.read(position);
   color =  apply_brightness(color, filters.brightness);
   color = apply_contrast(color, filters.contrast);
   color = apply_saturation(color, filters.saturation);
   filteredTexture.write(color, position);
}

