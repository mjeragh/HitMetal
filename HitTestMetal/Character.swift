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
    
    //var vertexBuffer: MTLBuffer!
    //let pipelineState: MTLRenderPipelineState
    //var mesh: MTKMesh
    typealias meshState = (mesh: MTKMesh,pipelineState: MTLRenderPipelineState)
    var meshes = [meshState]()
    
    init(name: String) {
        let assetURL : URL
        if let URL = Bundle.main.url(forResource: name, withExtension: "usdz") {
            assetURL = URL
        }
        else {
            assetURL =  Bundle.main.url(forResource: name, withExtension: "usda")!
            
        }
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let asset = MDLAsset(url: assetURL, vertexDescriptor: Model.defaultVertexDescriptor,
                             bufferAllocator: allocator,preserveTopology: false,
                            error: nil)
        
        
       let sceneData = Baker(asset: asset)
        
        
        //sceneData.nodeNames
//        sceneData.mdlMeshes.count
//        let mdlMesh = sceneData.mdlMeshes[8]
       
        for mdlMesh in sceneData.mdlMeshes {
            let mesh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
            
            //vertexBuffer = mesh.vertexBuffers[0].buffer
            
            let pipelineState = Character.buildPipelineState(vertexDescriptor: mdlMesh.vertexDescriptor)
            meshes.append((mesh,pipelineState))
        }
        
        
        super.init()
        self.boundingBox = sceneData.mdlMeshes[0].boundingBox
    }
    
    private static func buildPipelineState(vertexDescriptor: MDLVertexDescriptor) -> MTLRenderPipelineState {
        let library = Renderer.library
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_normals")
        
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
