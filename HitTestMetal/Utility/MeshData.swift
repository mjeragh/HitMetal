/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains datastructures for the game engine
*/

import Foundation
import ModelIO

//// Per-submesh material uniforms
//struct Material {
//    var baseColor: (SIMD3<Float>?, Int?) = (SIMD3<Float>(1, 1, 1), nil)
//    var metallic: (Float?, Int?) = (0, nil)
//    var roughness: (Float?, Int?) = (0, nil)
//    var normalMap: Int?
//    var ambientOcclusionMap: Int?
//}

/// Per-mesh index and instance data
struct MeshData {
    var vbCount = 0
    var vbStartIdx = 0
    var ibStartIdx = 0
    var idxCounts = [Int]()
    var idxTypes = [MDLIndexBitDepth]()
    var materials = [Material]()
}

/// Describes how a mesh is bound to a skeleton
struct SkinData: JointPathRemappable {
    var jointPaths = [String]()

    var parentIndices = [Int?]()
    var skinToSkeletonMap = [Int]()
    var geometryInverseBindTransforms = [float4x4]()
    var bindTransforms = [float4x4]()
    var animationIndex: Int?
}

/// Stores skeleton data as well as its time-sampled animation
struct AnimatedSkeleton: JointPathRemappable {
    var jointPaths = [String]()

    var animationToSkeletonMap = [Int]()

    var keyTimes = [Double]()
    var translations = [vector_float3]()
    var rotations = [simd_quatf]()

    var jointCount: Int {
        return jointPaths.count
    }

    var timeSampleCount: Int {
        return keyTimes.count
    }
}

/// Describes a camera in a renderable scene
//struct CameraData {
//    var transformIndex: Int?
//    var nearPlane: Float = 0.1
//    var farPlane: Float = 1000
//    var fieldOfView: Float = 90
//}
