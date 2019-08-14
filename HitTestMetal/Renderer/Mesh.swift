/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import MetalKit

struct Mesh {
  
  let mtkMesh: MTKMesh
  let submeshes: [Submesh]
  
  init(mdlMesh: MDLMesh, mtkMesh: MTKMesh) {
    self.mtkMesh = mtkMesh
    submeshes = zip(mdlMesh.submeshes!, mtkMesh.submeshes).map {
      Submesh(mdlSubmesh: $0.0 as! MDLSubmesh, mtkSubmesh: $0.1)
    }
  }
}

struct Submesh {
  
  struct Textures {
    let baseColor: MTLTexture?
    
    init(material: MDLMaterial?) {
      guard let baseColor = material?.property(with: .baseColor),
        baseColor.type == .texture,
        let mdlTexture = baseColor.textureSamplerValue?.texture else {
          self.baseColor = nil
          return
      }
      
      let textureLoader = MTKTextureLoader(device: Renderer.device)
      let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
        .origin: MTKTextureLoader.Origin.bottomLeft
      ]
      self.baseColor = try? textureLoader.newTexture(texture: mdlTexture,
                                                     options: textureLoaderOptions)
    }
  }
  
  let mtkSubmesh: MTKSubmesh
  let material: Material
  let textures: Textures
  let pipelineState: MTLRenderPipelineState
  //let instancedPipelineState: MTLRenderPipelineState
  
  init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh) {
    self.mtkSubmesh = mtkSubmesh
    material = Material(material: mdlSubmesh.material)
    textures = Textures(material: mdlSubmesh.material)
    pipelineState = Submesh.createPipelineState(vertexFunctionName: "vertex_main",
                                                textures: textures)
   // instancedPipelineState = Submesh.createPipelineState(vertexFunctionName: "vertex_instances", textures: textures)
  }
  
  static func createPipelineState(vertexFunctionName: String,
                                  textures: Textures) -> MTLRenderPipelineState {


    //create function constant
    let functionConstants = makeFunctionConstants(textures: textures)
    let library = Renderer.library
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineDescriptor.vertexFunction = library?.makeFunction(name: vertexFunctionName)
    pipelineDescriptor.fragmentFunction = try! library?.makeFunction(name: "fragment_main", constantValues: functionConstants)
    pipelineDescriptor.vertexDescriptor = MTLVertexDescriptor.defaultVertexDescriptor()
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    
    return try! Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
  }
    
    static func makeFunctionConstants(textures: Textures) -> MTLFunctionConstantValues {
        let functionConstants = MTLFunctionConstantValues()
        var property = textures.baseColor != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 0)
//        property = textures.normal != nil
//        functionConstants.setConstantValue(&property, type: .bool, index: 1)
//        property = textures.roughness != nil
//        functionConstants.setConstantValue(&property, type: .bool, index: 2)
//        property = false
//        functionConstants.setConstantValue(&property, type: .bool, index: 3)
//        functionConstants.setConstantValue(&property, type: .bool, index: 4)
        return functionConstants
    }
    
    
}

private extension Material {
  init(material: MDLMaterial?) {
    self.init()
    if let baseColor = material?.property(with: .baseColor),
      baseColor.type == .float3 {
      self.baseColor = baseColor.float3Value
    }
    if let specular = material?.property(with: .specular),
      specular.type == .float3 {
      self.specularColor = specular.float3Value
    }
    if let shininess = material?.property(with: .specularExponent),
      shininess.type == .float {
      self.shininess = shininess.floatValue
    }
  }
}
