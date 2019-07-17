//
//  Shader.metal
//  Video Recorder
//
//  Created by Javier L. Avrudsky on 24/05/2019.
//  Copyright © 2019 Javi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

constant int ATTR_VERTEX_POSITION_INDEX = 0;
constant int ATTR_VERTEX_COLOR_INDEX = 1;

struct VertexIn {
    float4 position [[attribute(ATTR_VERTEX_POSITION_INDEX)]];
    float4 color [[attribute(ATTR_VERTEX_COLOR_INDEX)]];
};

struct VertexOut {
    float4 position [[ position ]];
    float4 color;
};

vertex VertexOut vertex_shader(const VertexIn vertexIn [[ stage_in ]]) {
    VertexOut vertexOut;
    vertexOut.position = vertexIn.position;
    vertexOut.color = vertexIn.color;
    return vertexOut;
}

fragment half4 fragment_shader(const VertexOut vertexIn [[ stage_in ]]) {
    return half4(vertexIn.color);
}
