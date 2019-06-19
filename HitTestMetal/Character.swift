//
//  Character.swift
//  HitTestMetal
//
//  Created by Mohammad Jeragh on 6/18/19.
//  Copyright © 2019 Mohammad Jeragh. All rights reserved.
//

import MetalKit

class Character: Node {
    
    static var defaultVertexDescriptor: MDLVertexDescriptor = {
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes = [
            MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0),
            MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: 12, bufferIndex: 0),
            MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 24, bufferIndex: 0),
            MDLVertexAttribute(name: MDLVertexAttributeJointIndices, format: .uShort4, offset: 32, bufferIndex: 0),
            MDLVertexAttribute(name: MDLVertexAttributeJointWeights, format: .float4, offset: 40, bufferIndex: 0)
        ]
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: 56)
        return vertexDescriptor
    }()
    
    let vertexBuffer: MTLBuffer
    let pipelineState: MTLRenderPipelineState
    let mesh: MTKMesh
    let submeshes: [Submesh]
    
    init(name: String) {
        let assetURL = Bundle.main.url(forResource: name, withExtension: "usda")!
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let asset = MDLAsset(url: assetURL, vertexDescriptor: Model.defaultVertexDescriptor,
                             bufferAllocator: allocator,preserveTopology: false,
                            error: nil)
        let mdlMesh = asset.object(at: 0).children[0] as! MDLMesh
        
        let mesh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
        self.mesh = mesh
        vertexBuffer = mesh.vertexBuffers[0].buffer
        
        submeshes = mdlMesh.submeshes?.enumerated().compactMap {index, submesh in
            (submesh as? MDLSubmesh).map {
                Submesh(submesh: mesh.submeshes[index],
                        mdlSubmesh: $0)
            }
            } ?? []
        
        pipelineState = Character.buildPipelineState(vertexDescriptor: mdlMesh.vertexDescriptor)
        super.init()
        self.boundingBox = mdlMesh.boundingBox
    }
    
    private static func buildPipelineState(vertexDescriptor: MDLVertexDescriptor) -> MTLRenderPipelineState {
        let library = Renderer.library
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        var pipelineState: MTLRenderPipelineState
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        return pipelineState
    }
}
