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
    
    init(_ a: Float, b: Float, c: Float, d: Float )
    {
        self.n = float4(a, b, c, d)
    }
    
}
