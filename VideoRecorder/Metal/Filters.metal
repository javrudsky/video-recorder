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

constant float DEFAULT_BRIGHTNESS = 0.0;
constant float DEFAULT_CONTRAST = 1.0;
constant float DEFAULT_SATURATION = 1.0;

constant float RED_BF = 0.299;
constant float GREEN_BF = 0.587;
constant float BLUE_BF = 0.114;

float saturated_color_channel(float color_chanel, float brightness_value, float saturation) {
   return brightness_value + ((color_chanel) - brightness_value) * saturation;
}

float4 apply_brightness(float4 color, float brightness) {
   if(brightness == DEFAULT_BRIGHTNESS) {
      return color;
   }
   return color + brightness;
}

float4 apply_contrast(float4 color, float contrast) {
   if(contrast == DEFAULT_CONTRAST) {
      return color;
   }
   float3 rgbColor = ((color.rgb - 0.5f) * contrast) + 0.5f;
   return float4(rgbColor, 1.0);
}

float4 apply_saturation(float4 color, float saturation) {
   if(saturation == DEFAULT_SATURATION) {
      return color;
   }
   float brightness_value = sqrt(pow(color.r, 2) * RED_BF + pow(color.g, 2) * GREEN_BF + pow(color.b, 2) * BLUE_BF);
   return float4(saturated_color_channel(color.r, brightness_value, saturation),
                 saturated_color_channel(color.g, brightness_value, saturation),
                 saturated_color_channel(color.b, brightness_value, saturation),
                 1.0);
}
