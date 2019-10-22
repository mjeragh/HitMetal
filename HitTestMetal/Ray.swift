
struct Ray {
    var origin: SIMD3<Float>
    var direction: SIMD3<Float>
    
    static func *(transform: float4x4, ray: Ray) -> Ray {
        let originT = (transform * SIMD4<Float>(ray.origin, 1)).xyz
        let directionT = (transform * SIMD4<Float>(ray.direction, 0)).xyz
        return Ray(origin: originT, direction: directionT)
    }
    
    /// Determine the point along this ray at the given parameter
    func extrapolate(_ parameter: Float) -> SIMD4<Float> {
        return SIMD4<Float>(origin + parameter * direction, 1)
    }
    
    /// Determine the parameter corresponding to the point,
    /// assuming it lies on this ray
    func interpolate(_ point: SIMD4<Float>) -> Float {
        return length(point.xyz - origin) / length(direction)
    }
}
