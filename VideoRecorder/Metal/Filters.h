//
//  Filters.h
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 20/07/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

#ifndef Filters_h
#define Filters_h

float4 apply_brightness(float4 color, float brightness);
float4 apply_contrast(float4 color, float contrast);
float4 apply_saturation(float4 color, float saturation);
float4 rotateVertex(float4 position);
float4 mirrorOverY(float4 position);

#endif /* Filters_h */
