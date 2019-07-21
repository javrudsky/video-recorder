//
//  filters.metal
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 20/07/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;


float4 apply_brightness(float4 color, float brightness) {
    return color + brightness / 127.0;
}

float4 apply_contrast(float4 color, float contrast) {
    const float normalized_constrast = (contrast + 127.0) / 255.0;
    float3 rgbColor = ((color.rgb - 0.5f) * max(normalized_constrast, 0.0)) + 0.5f;
    return float4(rgbColor, 1.0);
}
