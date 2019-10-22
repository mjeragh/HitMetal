//
//  Renderer.swift
//  HitTestMetal
//
//  Created by Mohammad Jeragh on 4/1/19.
//  Copyright © 2019 Mohammad Jeragh. All rights reserved.
//

// Our platform independent renderer class

/**
 * Copyright (c) 2018 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import MetalKit

class Renderer: NSObject {
    
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var colorPixelFormat: MTLPixelFormat!
    static var library: MTLLibrary?
    var depthStencilState: MTLDepthStencilState!
    
    var uniforms = Uniforms()
    var fragmentUniforms = FragmentUniforms()
    var scene = Scene()
    
    // Camera holds view and projection matrices
    lazy var camera: Camera = {
        let camera = Camera()
        camera.position = [0, 2, -15]
        camera.rotation = [0, 0, 0]
        return camera
    }()
    
    // Array of Models allows for rendering multiple models
    var models: [Model] = []
    var primitives: [Primitive] = []
    var characters: [Character] = []
    
    lazy var sunlight: Light = {
        var light = buildDefaultLight()
        light.position = [1, 2, -2]
        return light
    }()
    
    lazy var ambientLight: Light = {
        var light = buildDefaultLight()
        light.color = [0.5, 1, 0]
        light.intensity = 0.1
        light.type = Ambientlight
        return light
    }()
    
//    lazy var redLight: Light = {
//        var light = buildDefaultLight()
//        light.position = [-0, 0.5, -0.5]
//        light.color = [1, 0, 0]
//        light.attenuation = SIMD3<Float>(1, 3, 4)
//        light.type = Pointlight
//        return light
//    }()
//
//    lazy var spotlight: Light = {
//        var light = buildDefaultLight()
//        light.position = [0.4, 0.8, 1]
//        light.color = [1, 0, 1]
//        light.attenuation = SIMD3<Float>(1, 0.5, 0)
//        light.type = Spotlight
//        light.coneAngle = radians(fromDegrees: 40)
//        light.coneDirection = [-2, 0, -1.5]
//        light.coneAttenuation = 12
//        return light
//    }()
    
    var lights: [Light] = []
    
    // Debug drawing of lights
    lazy var lightPipelineState: MTLRenderPipelineState = {
        return buildLightPipelineState()
    }()
    
    init(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("GPU not available")
        }
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.device = device
        Renderer.device = device
        Renderer.commandQueue = device.makeCommandQueue()!
        Renderer.colorPixelFormat = metalView.colorPixelFormat
        Renderer.library = device.makeDefaultLibrary()
        
        super.init()
        metalView.clearColor = MTLClearColor(red: 0, green: 0,
                                             blue: 0.2, alpha: 1)
        metalView.delegate = self
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
        
        // add model to the scene
        let train = Model(name: "train")
        train.name = "train"
        train.position = [0, 0, 0]
        train.rotation = [0, radians(fromDegrees: 45), 0]
        models.append(train)
        
        let jesse = Model(name: "jesse")
        jesse.position = [-1,-1,0]
        jesse.scale = [0.01,0.01,0.01]
        jesse.rotation = [radians(fromDegrees: 90), radians(fromDegrees: 180), 0]
        models.append(jesse)
        
        let fir = Model(name: "treefir")
        fir.name = "tree"
        fir.position = [1.4, 0, 0]
        models.append(fir)
        
        buildDepthStencilState()
        
        lights.append(sunlight)
        lights.append(ambientLight)
//        lights.append(redLight)
//        lights.append(spotlight)
        fragmentUniforms.lightCount = UInt32(lights.count)
        
        //adding to sceene root node
        for model in models {
            scene.rootNode.addChildNode(model)
        }
        
        //creat a sphere
        let sphere = Primitive(shape: .sphere, size: 1.0)
        sphere.position = [0,0,0]
        //sphere.pivotPosition = [1,2,0]
        sphere.material.baseColor = [1.0, 0, 0]
        sphere.material.metallic = 0.0
        sphere.material.roughness = 0
        sphere.material.shininess = 0.4
        sphere.material.specularColor = [0,0,0]
        sphere.material.secondColor = [1.0,1.0,0.0]
        sphere.material.ambientOcclusion = [0,0,0]
        sphere.name = "sun"
        primitives.append(sphere)
        
        let box = Primitive(shape: .cube, size: 1.0)
        box.position = [-1.5,0.5,0]
        box.rotation = [0, radians(fromDegrees: 45), 0]
        box.material.baseColor = [0, 0.5, 0]
        box.material.secondColor = [1.0,1.0,0.0]
        box.material.metallic = 1.0
        box.material.roughness = 0.0
        box.material.shininess = 0.1
        box.material.specularColor = [0,1.0,0.0]
        box.material.ambientOcclusion = [1.0,1.0,1.0]
        box.name = "cube"
        
        
        
        primitives.append(box)
        if let tp = touchPlane.debugPlane {
            
            primitives.append(tp)
            
        }
        
        for primitive in primitives {
            scene.rootNode.addChildNode(primitive)
        }
        
        
        // add model to the scene
       //race_track
        //toy_drummer
        //simpleMaterial
        let file = "toy_drummer"
        let char = Character(name: file)
        char.name = file
        char.position = [0, 1, -2]
        char.rotation = [0, radians(fromDegrees: 180), 0]
        char.scale = [0.2,0.2,0.2]
        characters.append(char)
        
        
        let tulip = Character(name: "flower_tulip")
        tulip.name = "tulip"
        tulip.position = [0, 1, 0]
        tulip.rotation = [0, radians(fromDegrees: 45), 0]
        tulip.scale = [0.1,0.1,0.1]
        characters.append(tulip)
        
        //adding to sceene root node
        for character in characters {
            scene.rootNode.addChildNode(character)
        }
        
      
    }
    
   
    
    
    
    func buildDefaultLight() -> Light {
        var light = Light()
        light.position = [0, 0, 0]
        light.color = [1, 1, 1]
        light.specularColor = [0.6, 0.6, 0.6]
        light.intensity = 1
        light.attenuation = SIMD3<Float>(1, 0, 0)
        light.type = Sunlight
        return light
    }
    
    func buildDepthStencilState() {
        // 1
        let descriptor = MTLDepthStencilDescriptor()
        // 2
        descriptor.depthCompareFunction = .less
        // 3
        descriptor.isDepthWriteEnabled = true
        depthStencilState =
            Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }
    
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        camera.aspect = Float(view.bounds.width)/Float(view.bounds.height)
    }
    
    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let renderEncoder =
            commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
        }
        renderEncoder.setDepthStencilState(depthStencilState)
        
        fragmentUniforms.cameraPosition = camera.position
        uniforms.projectionMatrix = camera.projectionMatrix
        uniforms.viewMatrix = camera.viewMatrix
        
        renderEncoder.setFragmentBytes(&lights,
                                       length: MemoryLayout<Light>.stride * lights.count,
                                       index: 2)
        renderEncoder.setFragmentBytes(&fragmentUniforms,
                                       length: MemoryLayout<FragmentUniforms>.stride,
                                       index: 3)
        
        // render all the models in the array
        for model in models {
            // model matrix now comes from the Model's superclass: Node
            renderEncoder.pushDebugGroup(model.name)
            uniforms.modelMatrix = model.modelMatrix
            uniforms.normalMatrix = float3x3(normalFrom4x4: model.modelMatrix)

            renderEncoder.setVertexBytes(&uniforms,
                                         length: MemoryLayout<Uniforms>.stride, index: 1)


            for mesh in model.meshes {
                for vertexBuffer in mesh.mtkMesh.vertexBuffers {

                    renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, index: 0)

                    for submesh in mesh.submeshes {
                        var material = submesh.material
                        renderEncoder.setFragmentBytes(&material,
                                                        length: MemoryLayout<Material>.stride,
                                                        index: 11)
                        renderEncoder.setFragmentTexture(submesh.textures.baseColor, index: 0)
                        renderEncoder.setRenderPipelineState(submesh.pipelineState)
                        let mtkSubmeh = submesh.mtkSubmesh
                        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                            indexCount: mtkSubmeh.indexCount,
                                                            indexType: mtkSubmeh.indexType,
                                                            indexBuffer: mtkSubmeh.indexBuffer.buffer,
                                                            indexBufferOffset: mtkSubmeh.indexBuffer.offset)
                    }

            }//vertexbuffer


        }//meshes
            renderEncoder.popDebugGroup()
        }//model
        
        
         //render all the Characters in the array
        for character in characters {
            // model matrix now comes from the Model's superclass: Node
            
            
            for meshState in character.nodes{
                renderEncoder.setRenderPipelineState(meshState.1 as MTLRenderPipelineState)
                renderEncoder.setVertexBuffer(meshState.0.vertexBuffers[0].buffer, offset: 0, index: 0)
                
                uniforms.modelMatrix = character.modelMatrix * meshState.localTransform
                uniforms.normalMatrix = float3x3(normalFrom4x4: character.modelMatrix)
                
                renderEncoder.setVertexBytes(&uniforms,
                                             length: MemoryLayout<Uniforms>.stride, index: 1)
                
                for submesh in meshState.0.submeshes {
                    renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                        indexCount: submesh.indexCount,
                                                        indexType: submesh.indexType,
                                                        indexBuffer: submesh.indexBuffer.buffer,
                                                        indexBufferOffset: submesh.indexBuffer.offset)
                }
            }

        }
        
        for primitive in primitives {
            
           uniforms.modelMatrix = primitive.modelMatrix
            uniforms.normalMatrix = float3x3(normalFrom4x4: primitive.modelMatrix)
            
            renderEncoder.setVertexBuffer(primitive.vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBytes(&uniforms,
                                         length: MemoryLayout<Uniforms>.stride, index: 1)
            
            renderEncoder.setRenderPipelineState(primitive.pipelineState)
            for submesh in primitive.mesh.submeshes{
                renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
            }
//            if debugRenderBoundingSphere {
//                primitive.boundingSphere.debugBoundingSphere!.render(renderEncoder: renderEncoder, uniforms: uniforms)
//            }
        }
        
        
       // debugLights(renderEncoder: renderEncoder, lightType: Spotlight)
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}


