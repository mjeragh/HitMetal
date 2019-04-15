//
//  File.swift
//  HitTestMetal
//
//  Created by Mohammad Jeragh on 4/10/19.
//  Copyright © 2019 Mohammad Jeragh. All rights reserved.
//

import Foundation
import simd
import os.log
import MetalKit

struct Plane {
    let n: float4
    var a : Float {
      return n.x
    }
    var  b: Float {
        return n.y
    }
    var c: Float {
    return n.z
    }
    var d: Float {
    return n.w
    }
    //the (a, b, c, d) in a*x + b*y + c*z + d = 0.
    
    var debugPlane: Primitive?
    
    init(a: Float, b: Float, c: Float, d: Float, debug: Bool = false )
    {
        self.n = float4(a, b, c, d)
        if debug {
            self.debugPlane = Primitive(shape: .plane, size: 10)
            debugPlane?.rotation = [c * radians(fromDegrees: -90), a * radians(fromDegrees: -90), b * radians(fromDegrees: -90)]
            debugPlane?.position = [a, b ,c] * d
            debugPlane?.material.baseColor = [0, 0.0, 0]
            debugPlane?.material.metallic = 0.0
            debugPlane?.material.roughness = 0.1
            debugPlane?.material.shininess = 1.0
            debugPlane?.material.specularColor = [0,0.0,0.0]
            debugPlane?.material.ambientOcclusion = [1.0,1.0,1.0]
            debugPlane?.name = "debugPlane"
        }
    }
    
    func intersectionPlane(_ ray: Ray) -> Float {
        let n = normalize(float3(self.n.xyz))
        let pZero = float3(0 + d,0 + d,0 + d)
        let denom = -simd_dot(n, ray.direction)
        os_log("p0: %f, %f, %f, denom: %f", pZero.x,pZero.y,pZero.z,denom)
        if (denom > Float(1e-6)){
            let p0l0 = ray.origin - pZero
            let t = simd_dot(p0l0, n) / denom
            return t
        }
        
        
        return Float(0.0)
    }
    
    
    
}
