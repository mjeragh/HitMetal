/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains utility functions
*/

import Foundation
import ModelIO

extension MDLAsset {
    /// Pretty-print MDLAsset's scene graph
    func printAsset() {
        func printSubgraph(object: MDLObject, indent: Int = 0) {
            print(String(repeating: " ", count: indent), object.name, object)

            for childIndex in 0..<object.children.count {
                printSubgraph(object: object.children[childIndex], indent: indent + 2)
            }
        }

        for childIndex in 0..<self.count {
            printSubgraph(object: self[childIndex]!)
        }
    }
}

/// Protocol for remapping joint paths (e.g. between a skeleton's complete joint list
/// and the the subset bound to a particular mesh)
protocol JointPathRemappable {
    var jointPaths: [String] { get }
}

// returns a sparse mapping from src jointPath to dst, no mapping is represented by nil
func mapSparseJoints(from srcJointPaths: [String], to dstJointPaths: [String]) -> [Int?] {
    return srcJointPaths.compactMap { srcJointPath in
        if let index = dstJointPaths.firstIndex(of: srcJointPath) {
            return index
        }

        return nil
    }
}

/// Compute an index map from all elements of A.jointPaths to the corresponding paths in B.jointPaths
func mapJoints<A: JointPathRemappable>(from src: A, to dstJointPaths: [String]) -> [Int] {
    return src.jointPaths.compactMap { srcJointPath in
        if let index = dstJointPaths.firstIndex(of: srcJointPath) {
            return index
        }
        print("Warning! animated joint \(srcJointPath) does not exist in skeleton")
        return nil
    }
}

/// Initializer for double4x4 -> float4x4
//extension float4x4 {
//    public init(_ matrix: double4x4) {
//        self.columns.0 = simd_float(matrix.columns.0)
//        self.columns.1 = simd_float(matrix.columns.1)
//        self.columns.2 = simd_float(matrix.columns.2)
//        self.columns.3 = simd_float(matrix.columns.3)
//    }
//}

/// Using the parentIndices, concatenate local transforms
func computeSkeletonTransforms(parentIndices: [Int?], localTransforms: [float4x4]) -> [float4x4] {
    var skeletonTransforms = [float4x4](repeating: matrix_identity_float4x4, count: localTransforms.count)

    // using the skeletonParentIndices compute the worldBindTransforms
    for (curIndex, parentIndexOptional) in parentIndices.enumerated() {
        let localTransform = localTransforms[curIndex]
        if let parentIndex = parentIndexOptional {
            let parentTransform = skeletonTransforms[parentIndex]
            skeletonTransforms[curIndex] = simd_mul(localTransform, parentTransform)
        } else {
            skeletonTransforms[curIndex] = localTransform
        }
    }

    return skeletonTransforms
}

/// Helper function for converting from jointPaths to parentIndices
func jointPathsToParentIndices(jointPaths: [String]) -> [Int?] {
    // store the joint bind transforms which give us the bind pose
    var parentLookUp = [String: Int?]()

    // enumerate the jointPaths mapping them to parent indices
    return jointPaths.enumerated().map { (curIdx: Int, jointPath: String) -> Int? in
        // trim trailing forward slashes
        let trimmedJointPath = jointPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let splitPath = trimmedJointPath.components(separatedBy: "/")

        // get parent path
        let subSplitPath = splitPath.prefix(splitPath.count - 1)

        // set the idx for the current index for future parent lookups
        parentLookUp[splitPath.last!] = curIdx

        // return the parentLookUp index, nil if non existant in dictionary
        return subSplitPath.count > 0 ? parentLookUp[subSplitPath.last!] as? Int : nil
    }
}

/// Traverse an MDLAsset's scene graph and run a closure on each element,
/// passing on each element's flattened node index as well as its parent's index
func walkSceneGraph(in asset: MDLAsset, perNodeBody: (MDLObject, Int, Int?) -> Void) {
    func walkGraph(in object: MDLObject, currentIndex: inout Int, parentIndex: Int?, perNodeBody: (MDLObject, Int, Int?) -> Void) {
        perNodeBody(object, currentIndex, parentIndex)

        let ourIndex = currentIndex
        currentIndex += 1
        for childIndex in 0..<object.children.count {
            walkGraph(
                in: object.children[childIndex],
                currentIndex: &currentIndex,
                parentIndex: ourIndex,
                perNodeBody: perNodeBody
            )
        }
    }

    var currentIndex = 0
    for childIndex in 0..<asset.count {
        walkGraph(in: asset[childIndex]!, currentIndex: &currentIndex, parentIndex: nil, perNodeBody: perNodeBody)
    }
}

/// Traverse thescene graph rooted at object and run a closure on each element,
/// passing on each element's flattened node index as well as its parent's index
func walkSceneGraph(rootAt object: MDLObject, perNodeBody: (MDLObject, Int, Int?) -> Void) {
    var currentIndex = 0

    func walkGraph(object: MDLObject, currentIndex: inout Int, parentIndex: Int?, perNodeBody: (MDLObject, Int, Int?) -> Void) {
        perNodeBody(object, currentIndex, parentIndex)

        let ourIndex = currentIndex
        currentIndex += 1
        for childIndex in 0..<object.children.count {
            walkGraph(
                object: object.children[childIndex],
                currentIndex: &currentIndex,
                parentIndex: ourIndex,
                perNodeBody: perNodeBody
            )
        }
    }

    walkGraph(object: object, currentIndex: &currentIndex, parentIndex: nil, perNodeBody: perNodeBody)
}

/// Traverse an MDLAsset's masters list and run a closure on each element
func walkMasters(in asset: MDLAsset, perNodeBody: (MDLObject) -> Void) {
    func walkGraph(in object: MDLObject, perNodeBody: (MDLObject) -> Void) {
        perNodeBody(object)

        for childIndex in 0..<object.children.count {
            walkGraph(in: object.children[childIndex], perNodeBody: perNodeBody)
        }
    }

    for childIndex in 0..<asset.masters.count {
        walkGraph(in: asset.masters[childIndex], perNodeBody: perNodeBody)
    }
}

/// Find the index of the (first) MDLMesh in MDLAsset.masters that an MDLObject.instance points to
func findMasterIndex(_ masterMeshes: [MDLMesh], _ instance: MDLObject) -> Int? {
    /// find first MDLMesh in MDLObject hierarchy
    func findFirstMesh(_ object: MDLObject) -> MDLMesh? {
        if let object = object as? MDLMesh {
            return object
        }
        for childIndex in 0..<object.children.count {
            return findFirstMesh(object.children[childIndex])
        }
        return nil
    }

    if let mesh = findFirstMesh(instance) {
        return masterMeshes.firstIndex(of: mesh)
    }

    return nil
}

/// Sort all mesh instances by mesh index, and return a permutation which groups together
/// all instances of all particular mesh
func sortedMeshIndexPermutation(_ instanceMeshIndices: [Int]) -> ([Int], [Int]) {
    let permutation = (0..<instanceMeshIndices.count).sorted { instanceMeshIndices[$0] < instanceMeshIndices[$1] }

    var instanceCounts = [Int](repeating: 0, count: instanceMeshIndices.max()! + 1)
    for instanceMeshIndex in instanceMeshIndices {
        instanceCounts[instanceMeshIndex] += 1
    }

    return (permutation, instanceCounts)
}

/// Returns the index of a texture path
func findTextureIndex(_ path: String?, _ texturePaths: inout [String]) -> Int? {
    guard path != nil else { return nil }
    if let idx = texturePaths.firstIndex(of: path!) {
        return idx
    } else {
        texturePaths.append(path!)
        return texturePaths.count - 1
    }
}

/// Append the asset url to all texture paths
func fixupPaths(_ asset: MDLAsset, _ texturePaths: inout [String]) {
    guard let assetURL = asset.url else { return }

    let assetRelativeURL = assetURL.deletingLastPathComponent()
    texturePaths = texturePaths.map { assetRelativeURL.appendingPathComponent($0).absoluteString }
}

/// Find the shortest subpath containing a rootIdentifier (used to find a e.g. skeleton's root path)
func findShortestPath(in path: String, containing rootIdentifier: String) -> String? {
    var result = ""
    let pathArray = path.components(separatedBy: "/")
    for name in pathArray {
        result += name
        if name.range(of: rootIdentifier) != nil {
            return result
        }
        result += "/"
    }
    return nil
}

/// Get a float3 property from an MDLMaterialProperty
func getMaterialFloat3Value(_ materialProperty: MDLMaterialProperty) -> SIMD3<Float> {
    return materialProperty.float3Value
}

/// Get a float property from an MDLMaterialProperty
func getMaterialFloatValue(_ materialProperty: MDLMaterialProperty) -> Float {
    return materialProperty.floatValue
}

/// Uniformly sample a time interval
func sampleTimeInterval(start startTime: TimeInterval, end endTime: TimeInterval,
                        frameInterval: TimeInterval) -> [TimeInterval] {
    let count = Int( (endTime - startTime) / frameInterval )
    return (0..<count).map { startTime + TimeInterval($0) * frameInterval }
}
