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
            MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 24, bufferIndex: 0)
        ]
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: 32)
        return vertexDescriptor
    }()
    
   
    typealias characterData = (mesh: MTKMesh,pipelineState: MTLRenderPipelineState, nodeName: String, localTransform: matrix_float4x4)
    var nodes = [characterData]()
    var boundingMesh : MDLMesh? = nil
    var flag = true
    
    init(name: String) {
        let assetURL : URL
        if let URL = Bundle.main.url(forResource: name, withExtension: "usdz") {
            assetURL = URL
        }
        else {
            assetURL =  Bundle.main.url(forResource: name, withExtension: "usda")!
            
        }
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let asset = MDLAsset(url: assetURL, vertexDescriptor: Character.defaultVertexDescriptor,
                             bufferAllocator: allocator,preserveTopology: false,
                            error: nil)
        
        
        asset.loadTextures()
        super.init()
       // storeAllMeshesInSceneGraph(with: asset)
        self.boundingBox = asset.boundingBox//boundingMesh!.boundingBox
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
    
    /// Record all mesh data required to render a particular mesh
    func storeAllMeshesInSceneGraph(with asset: MDLAsset) {
        walkSceneGraph(in: asset) { object, currentIdx, _ in
            if let mesh = object as? MDLMesh {
//                if flag {
//                    boundingMesh = mesh
//                    flag = !flag
//                }
               let pipelineState = Character.buildPipelineState(vertexDescriptor: mesh.vertexDescriptor)
                let mtkMesh = try! MTKMesh(mesh: mesh, device: Renderer.device)
                
                if let transform = object.transform {
                    nodes.append((mtkMesh,pipelineState,object.path,transform.matrix))
                } else {
                    nodes.append((mtkMesh,pipelineState,object.path,matrix_identity_float4x4))
                    
                }
                
                
                
            }
        }
    }
}
