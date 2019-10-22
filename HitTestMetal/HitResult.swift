
import simd

struct HitResult {
    var node: Node
    var ray: Ray
    var parameter: Float
    
    var intersectionPoint: SIMD4<Float> {
        return SIMD4<Float>(ray.origin + parameter * ray.direction, 1)
    }
    
    static func < (_ lhs: HitResult, _ rhs: HitResult) -> Bool {
        return lhs.parameter < rhs.parameter
    }
}
