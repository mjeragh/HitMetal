/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains Baker that processes geometry and transforms
*/

import Foundation
import ModelIO

/// - Tag: GeometryAndTransforms
class Baker {
    var nodeNames = [String]()
    var texturePaths = [String]()

    var localTransforms = [matrix_float4x4]()
    var parentIndices = [Int?]()
    var meshNodeIndices = [Int]()
    var meshSkinIndices = [Int?]()
    var instanceCount = [Int]()

    var vertexDescriptors = [MDLVertexDescriptor]()
    var vertexBuffers = [Data]()
    var indexBuffers = [Data]()

    var meshes = [MeshData]()
    var skins = [SkinData]()

    var sampleTimes = [Double]()
    var localTransformAnimations = [[matrix_float4x4]]()
    var localTransformAnimationIndices = [Int?]()

    var skeletonAnimations = [AnimatedSkeleton]()
    var cameraData = Camera()
    
    var debugCounter = 1
    var mdlMeshes = [MDLMesh]()
    
    init() {}

    init(asset: MDLAsset) {
        storeAllMeshesInSceneGraph(with: asset)
        flattenSceneGraphHierarchy(with: asset)
        findCamera(with: asset)
    }

    /// Record all buffers and materials for an MDLMesh
    func store(_ mesh: MDLMesh) {
        let vertexBufferCount = mesh.vertexBuffers.count
        let vbStartIdx = vertexBuffers.count
        let ibStartIdx = indexBuffers.count
        var idxCounts = [Int]()
        var idxTypes = [MDLIndexBitDepth]()

        vertexDescriptors.append(mesh.vertexDescriptor)

        vertexBuffers += (0..<vertexBufferCount).map { vertexBufferIndex in
            let vertexBuffer = mesh.vertexBuffers[vertexBufferIndex]
            return Data(bytes: vertexBuffer.map().bytes, count: Int(vertexBuffer.length))
        }

        for case let submesh as MDLSubmesh in mesh.submeshes! {
            let idxBuffer = submesh.indexBuffer
            indexBuffers.append(Data(bytes: idxBuffer.map().bytes, count: Int(idxBuffer.length)))

            idxCounts.append(Int(submesh.indexCount))
            idxTypes.append(submesh.indexType)
        }

        let meshData = MeshData(vbCount: vertexBufferCount, vbStartIdx: vbStartIdx,
                                ibStartIdx: ibStartIdx, idxCounts: idxCounts,
                                idxTypes: idxTypes, materials: [])
        meshes.append(meshData)
    }

    /// Record a node's parent index and store its local transform
    func flattenNode(_ nodeObject: MDLObject, nodeIndex: Int, parentNodeIndex: Int?) {
        nodeNames.append(nodeObject.path)
        if let transform = nodeObject.transform {
            localTransforms.append(transform.matrix)
        } else {
            localTransforms.append(matrix_identity_float4x4)
        }

        parentIndices.append(parentNodeIndex)
    }

    /// Store scene graph hierarchy's data in linear arrays
    func flattenSceneGraphHierarchy(with asset: MDLAsset) {
        walkSceneGraph(in: asset) { object, currentIdx, parentIdx in
            self.flattenNode(object, nodeIndex: currentIdx, parentNodeIndex: parentIdx)
        }
    }

    /// Store camera data
    func findCamera(with asset: MDLAsset) {
        guard let cameras = asset.childObjects(of: MDLCamera.self) as? [MDLCamera], cameras.count > 0 else {
            print("No cameras found, using default Camera")
            self.cameraData = Camera()
            return
        }

        // select the first camera, since we only support one and the last one is default usually
        let camera = cameras.first!
        let cameraXFormIdx = nodeNames.index(of: camera.path)

        self.cameraData = Camera()
        self.cameraData.near = camera.nearVisibilityDistance
        self.cameraData.far = camera.farVisibilityDistance
        self.cameraData.fovDegrees = camera.fieldOfView
        
    }

    /// Record all mesh data required to render a particular mesh
    func storeAllMeshesInSceneGraph(with asset: MDLAsset) {
        walkSceneGraph(in: asset) { object, currentIdx, _ in
            if let mesh = object as? MDLMesh {
                meshNodeIndices.append(currentIdx)
//                store(mesh)
                mdlMeshes.append(mesh)
//                print("debugCtr= \(debugCounter)\n")
//                debugCounter+=1
            }
        }
    }
}
