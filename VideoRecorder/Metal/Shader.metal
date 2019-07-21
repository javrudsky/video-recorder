//
//  Shader.metal
//  Video Recorder
//
//  Created by Javier L. Avrudsky on 24/05/2019.
//  Copyright © 2019 Javi. All rights reserved.
//

#include <metal_stdlib>
#include "Filters.h"

using namespace metal;

constant int ATTR_VERTEX_POSITION_INDEX = 0;
constant int ATTR_VERTEX_COLOR_INDEX = 1;
constant int ATTR_TEXTURE_COORD_INDEX = 2;

struct VertexIn {
    float4 position [[ attribute(ATTR_VERTEX_POSITION_INDEX) ]];
    float4 color [[ attribute(ATTR_VERTEX_COLOR_INDEX) ]];
    float2 textureCoordinates [[ attribute(ATTR_TEXTURE_COORD_INDEX) ]];
};

struct RasterizerIn {
    float4 position [[ position ]];
    float4 color;
    float brightness;
    float contrast;
    float2 textureCoordinates;
};

struct Filters {
    float brightness;
    float contrast;
};

vertex RasterizerIn vertex_shader(const VertexIn vertexIn [[ stage_in ]],
                               constant Filters &filters [[ buffer(1) ]]) {
    RasterizerIn rasterizerIn;
    rasterizerIn.position = vertexIn.position;
    rasterizerIn.color = vertexIn.color;
    rasterizerIn.textureCoordinates = vertexIn.textureCoordinates;
    rasterizerIn.brightness = filters.brightness;
    rasterizerIn.contrast = filters.contrast;
    
    return rasterizerIn;
}

fragment half4 fragment_shader(const RasterizerIn rasterizerIn [[ stage_in ]]) {
    return half4(rasterizerIn.color + rasterizerIn.brightness / 127.0);
}

fragment half4 texture_shader(const RasterizerIn rasterizerIn [[ stage_in ]],
                              sampler sampler2d [[ sampler(0) ]],
                              texture2d<float> texture [[ texture(0) ]]) {

    float4 color = texture.sample(sampler2d, rasterizerIn.textureCoordinates);
    color =  apply_brightness(color, rasterizerIn.brightness);
    color = apply_contrast(color, rasterizerIn.contrast);
    return half4(color.r, color.g, color.b, 1.0);
}
