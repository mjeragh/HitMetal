//
//  Shaders.metal
//  HitTestMetal
//
//  Created by Mohammad Jeragh on 4/1/19.
//  Copyright © 2019 Mohammad Jeragh. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

struct VertexIn {
    float4 position [[ attribute(0) ]];
    float3 normal [[ attribute(1) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float3 worldPosition;
    float3 worldNormal;
};

vertex VertexOut vertex_main(const VertexIn vertexIn [[ stage_in ]],
                             constant Uniforms &uniforms [[ buffer(1) ]])
{
    VertexOut out;
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix
    * uniforms.modelMatrix * vertexIn.position;
    out.worldPosition = (uniforms.modelMatrix * vertexIn.position).xyz;
    out.worldNormal = uniforms.normalMatrix * vertexIn.normal;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              // 1
                              constant Light *lights [[buffer(2)]],
                              constant FragmentUniforms &fragmentUniforms [[ buffer(3)]]) {
    float3 baseColor = float3(1, 1, 1);
    float3 diffuseColor = 0;
    float3 ambientColor = 0;
    float3 specularColor = 0;
    float materialShininess = 32;
    float3 materialSpecularColor = float3(1, 1, 1);
    // 2
    float3 normalDirection = normalize(in.worldNormal);
    for (uint i = 0; i < fragmentUniforms.lightCount; i++) {
        Light light = lights[i];
        if (light.type == Sunlight) {
            float3 lightDirection = normalize(light.position);
            // 3
            float diffuseIntensity =
            saturate(dot(lightDirection, normalDirection));
            // 4
            diffuseColor += light.color * baseColor * diffuseIntensity;
            if (diffuseIntensity > 0) {
                // 1 (R)
                float3 reflection =
                reflect(lightDirection, normalDirection);
                // 2 (V)
                float3 cameraPosition =
                normalize(in.worldPosition - fragmentUniforms.cameraPosition);
                // 3
                float specularIntensity =
                pow(saturate(dot(reflection, cameraPosition)), materialShininess);
                specularColor +=
                light.specularColor * materialSpecularColor * specularIntensity;
            }
        } else if (light.type == Ambientlight) {
            ambientColor += light.color * light.intensity;
        } else if (light.type == Pointlight) {
            // 1
            float d = distance(light.position, in.worldPosition);
            // 2
            float3 lightDirection = normalize(light.position - in.worldPosition);
            // 3
            float attenuation = 1.0 / (light.attenuation.x +
                                       light.attenuation.y * d + light.attenuation.z * d * d);
            
            float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
            float3 color = light.color * baseColor * diffuseIntensity;
            // 4
            color *= attenuation;
            diffuseColor += color;
        } else if (light.type == Spotlight) {
            // 1
            float d = distance(light.position, in.worldPosition);
            float3 lightDirection = normalize(light.position - in.worldPosition);
            // 2
            float3 coneDirection = normalize(-light.coneDirection);
            float spotResult = (dot(lightDirection, coneDirection));
            // 3
            if (spotResult > cos(light.coneAngle)) {
                float attenuation = 1.0 / (light.attenuation.x +
                                           light.attenuation.y * d + light.attenuation.z * d * d);
                // 4
                attenuation *= pow(spotResult, light.coneAttenuation);
                float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
                float3 color = light.color * baseColor * diffuseIntensity;
                color *= attenuation;
                diffuseColor += color;
            }
        }
    }
    // 5
    float3 color = diffuseColor + ambientColor + specularColor;
    return float4(color, 1);
}
