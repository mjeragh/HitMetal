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

let debugRenderBoundingSphere = true

class DebugBoundingSphere {
  let pipelineState: MTLRenderPipelineState
    static var radius : Float = 0.0
    
  let boundingSphereMeshBuffer: MTLBuffer
  let boundingSphereIndexBuffer: MTLBuffer
  let boundingSphereIndexCount: Int
  let vertices: [Float]

    
    
  init?() {
    let library = Renderer.device.makeDefaultLibrary()
    let vertexFunction = library?.makeFunction(name: "debug_vertex")
    let fragmentFunction = library?.makeFunction(name: "debug_fragment")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
    
    pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    do {
      pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch let error {
      fatalError(error.localizedDescription)
    }
    vertices = DebugBoundingSphere.createMeshFromBoundingSphere()
    
    self.boundingSphereMeshBuffer = Renderer.device.makeBuffer(bytes: vertices,
                          length: vertices.count * MemoryLayout<Float>.size, options: [])!
    self.boundingSphereIndexBuffer = Renderer.device.makeBuffer(bytes: indices,
                          length: indices.count * MemoryLayout<UInt16>.size, options: [])!
    self.boundingSphereIndexCount = indices.count
  }
  
  func render(renderEncoder: MTLRenderCommandEncoder, uniforms: Uniforms) {
    var uniforms = uniforms
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(boundingSphereMeshBuffer, offset: 0, index: 21)
    renderEncoder.setVertexBytes(&uniforms,
                                 length: MemoryLayout<Uniforms>.stride,
                                 index: 1)
    renderEncoder.drawIndexedPrimitives(type: .lineStrip, indexCount: boundingSphereIndexCount,
                                        indexType: .uint16, indexBuffer: boundingSphereIndexBuffer,
                                        indexBufferOffset: 0)
  }
  
  private static func createMeshFromBoundingSphere() -> [Float] {
    
    
    var vertices = [Float]()
    let size = Float(10.0)
    stride(from: 0.0, to: 2 * Float.pi, by: 2 * Float.pi / size).forEach { i in
        // Do something
        vertices.append(cosf(i) * radius * 1.15);    //X coordinate
        vertices.append(sinf(i) * radius * 1.15);    //Y coordinate
        vertices.append(0);
    }
    vertices.append(vertices[0])

    
    return vertices
  }
  
  let indices: [UInt16] = [
    // front
    0, 1, 2,
    3, 4, 5,
    6, 7, 8,
    9
    ]
}
