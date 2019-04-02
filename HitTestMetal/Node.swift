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

class Node {
    let identifier = UUID()
  var name: String = "untitled"
  var position: float3 = [0, 0, 0]
  var rotation: float3 = [0, 0, 0]
  var scale: float3 = [1, 1, 1]
    var test: float4 = [1,1,1,1]
    weak var parent: Node?
    var material = Material()
    
    var boundingBox = MDLAxisAlignedBoundingBox()
    var size: float3 {
        return boundingBox.maxBounds - boundingBox.minBounds
    }
  
  var modelMatrix: float4x4 {
    let translateMatrix = float4x4(translation: position)
    let rotateMatrix = float4x4(rotation: rotation)
    let scaleMatrix = float4x4(scaling: scale)
    return translateMatrix * rotateMatrix * scaleMatrix
  }
  
    var worldTransform: float4x4 {
        if let parent = parent {
            return parent.worldTransform * modelMatrix
        } else {
            return modelMatrix
        }
    }
    
   
    
    var children: [Node] = []
    
    func addChildNode(_ node: Node) {
        if node.parent != nil {
            node.removeFromParent()
        }
        children.append(node)
    }
    
    private func removeChildNode(_ node: Node) {
        children = children.filter { $0 != node } //  In Swift 4.2, this could be written with removeAll(where:)
    }
    
    func removeFromParent() {
        parent?.removeChildNode(self)
    }
    
}

extension Node: Equatable, CustomDebugStringConvertible {
    
    
    
    func hitTest(_ ray: Ray) -> HitResult? {
        let modelToWorld = worldTransform
        let localRay = modelToWorld.inverse * ray
        
        var nearest: HitResult?
        if let modelPoint = boundingBox.intersect(localRay, position: position) {
            let worldPoint = modelToWorld * modelPoint
            let worldParameter = ray.interpolate(worldPoint)
            nearest = HitResult(node: self, ray: ray, parameter: worldParameter)
        }
        
        var nearestChildHit: HitResult?
        for child in children {
            if let childHit = child.hitTest(ray) {
                if let nearestActualChildHit = nearestChildHit {
                    if childHit < nearestActualChildHit {
                        nearestChildHit = childHit
                    }
                } else {
                    nearestChildHit = childHit
                }
            }
        }
        
        if let nearestActualChildHit = nearestChildHit {
            if let nearestActual = nearest {
                if nearestActualChildHit < nearestActual {
                    return nearestActualChildHit
                }
            } else {
                return nearestActualChildHit
            }
        }
        
        return nearest
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    var debugDescription: String { return "<Node>: \(name )" }
}

extension MDLAxisAlignedBoundingBox {
    
    func intersect(_ ray: Ray, position: float3) -> float4? {
        
        var tmin = minBounds + position
        var tmax = maxBounds + position
        
        let inverseDirection = 1 / ray.direction
        
        var sign : [Int] = [(inverseDirection.x < 0) ? 1 : 0,(inverseDirection.y < 0) ? 1 : 0,(inverseDirection.z < 0) ? 1 : 0]
        
        
        var bounds : [float3] = [tmin,tmax]
        
        
        var t0 = Float(tmax.z)
        
        if ((tmin.x > tmax.y) || (tmin.y > tmax.x)){
            return nil
        }
        
        
        
        if (tmin.y > tmin.x){
            tmin.x = tmin.y;
        }
        
        
        if (tmax.y < tmax.x){
            tmax.x = tmax.y;
        }
        
        tmin.z = (bounds[sign[2]].z - ray.origin.z) * inverseDirection.z
        tmax.z = (bounds[1-sign[2]].z - ray.origin.z) * inverseDirection.z
        
        
        
        if ((tmin.x > tmax.z) || (tmin.z > tmax.x)){
            return nil
        }
        
        if (tmin.z > tmin.x){
            tmin.x = tmin.z
            t0 = tmin.x
        }
        
        if (tmax.z < tmax.x){
            tmax.x = tmax.z
            t0 = tmax.z
        }
        
        print("t0 \(t0)")
        return float4(ray.origin + ray.direction * t0, 1)
    }
}
