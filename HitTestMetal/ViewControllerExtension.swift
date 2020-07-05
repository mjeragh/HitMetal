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

import UIKit
import os.log
import os.signpost

extension ViewController {
  static var previousScale: CGFloat = 1
    
//  func addGestureRecognizer(to view: UIView) {
//    let pan = UIPanGestureRecognizer(target: self,
//                                     action: #selector(handlePan(gesture:)))
//    view.addGestureRecognizer(pan)
//
//    let pinch = UIPinchGestureRecognizer(target: self,
//                                         action: #selector(handlePinch(gesture:)))
//    view.addGestureRecognizer(pinch)
//  }
//
//  @objc func handlePan(gesture: UIPanGestureRecognizer) {
//    let translation = float2(Float(gesture.translation(in: gesture.view).x),
//                             Float(gesture.translation(in: gesture.view).y))
//    renderer?.rotateUsing(translation: translation)
//    gesture.setTranslation(.zero, in: gesture.view)
//  }
//
//  @objc func handlePinch(gesture: UIPinchGestureRecognizer) {
//    let sensitivity: Float = 0.8
//    renderer?.zoomUsing(delta: gesture.scale-ViewController.previousScale,
//                        sensitivity: sensitivity)
//    ViewController.previousScale = gesture.scale
//    if gesture.state == .ended {
//      ViewController.previousScale = 1
//    }
//  }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: view) {
            handleInteraction(at: location)
        }
        if let node = selectedNode {
            os_log("selectedNode %s",node.name)
        }
        else {
            os_log("No Seleted Node")
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard (selectedNode != nil)  else {
            return
        }
        if let location = touches.first?.location(in: view)  {
            let newPosition = unproject(at: location)
            selectedNode!.position = newPosition!
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        os_log("end Touches")
        guard (selectedNode != nil)  else {
            return
        }
        
        os_log("selectedNOde %s at location %f,%f,%f",selectedNode!.name,selectedNode!.position.x,selectedNode!.position.y,selectedNode!.position.z)
        selectedNode = nil
    }
    
    
    func unproject(at point: CGPoint) -> SIMD3<Float>? {
        guard let camera = renderer?.camera else { return nil}
        
        let viewport = view.bounds
        let width = Float(viewport.width)
        let height = Float(viewport.height)
        
        let projectionMatrix = camera.projectionMatrix
        let inverseProjectionMatrix = projectionMatrix.inverse
        
        // let viewMatrix = camera.worldTransform.inverse
        let inverseViewMatrix = camera.inverseViewMatrix//viewMatrix.inverse
        
        let clipX = (2 * Float(point.x)) / width - 1
        let clipY = 1 - (2 * Float(point.y)) / height
        let clipCoords = SIMD4<Float>(clipX, clipY, 0, 1) // Assume clip space is hemicube, -Z is into the screen
        
        var eyeRayDir = inverseProjectionMatrix * clipCoords
        eyeRayDir.z = 1
        eyeRayDir.w = 0
        
        var worldRayDir = (inverseViewMatrix * eyeRayDir).xyz
        worldRayDir = normalize(worldRayDir)
        
        

        
        let eyeRayOrigin = SIMD4<Float>(x: 0, y: 0, z: 0, w: 1)
        let worldRayOrigin = (inverseViewMatrix * eyeRayOrigin).xyz
        
        let ray = Ray(origin: worldRayOrigin, direction: worldRayDir)
       os_log("ray.direction %f, %f, %f",ray.direction.x, ray.direction.y, ray.direction.z)
     //   os_log("ray.origin %f, %f, %f",ray.origin.x, ray.origin.y, ray.origin.z)
        var position  = selectedNode!.position
        
        let parameter = touchPlane.intersectionPlane(ray)
        os_log("parameter: %f", parameter)
        if (parameter  > Float(0.0)) {
            
            position = ray.origin + ray.direction * parameter
            os_log("(unproject) intersectionPoint %f, %f, %f", ray.direction.x * parameter, ray.direction.y * parameter, ray.direction.z * parameter)
            position.y += 0
        }
        return position
    }
    
    func intersectionPlane(_ ray: Ray) -> Float {
        let n = normalize(SIMD3<Float>(0,1,0) )
        let pZero = SIMD3<Float>(0,0,0)
        let denom = -simd_dot(n, ray.direction)
        os_log("p0: %f, %f, %f, denom: %f", pZero.x,pZero.y,pZero.z,denom)
        if (denom > Float(1e-6)){
            let p0l0 = ray.origin - pZero
            let t = simd_dot(p0l0, n) / denom
            return t
        }
        
        
        return Float(0.0)
    }
    
    func handleInteraction(at point: CGPoint) {
        guard let camera = renderer?.camera else { return }
        
        let viewport = view.bounds// Assume viewport matches window; if not, apply additional inverse viewport xform
        let width = Float(viewport.width)
        let height = Float(viewport.height)
        // let aspectRatio = camera?.aspect//width / height
        
        let projectionMatrix = camera.projectionMatrix
        let inverseProjectionMatrix = projectionMatrix.inverse
        
       // let viewMatrix = camera.worldTransform.inverse
        let inverseViewMatrix = camera.inverseViewMatrix//viewMatrix.inverse
        
        let clipX = (2 * Float(point.x)) / width - 1
        let clipY = 1 - (2 * Float(point.y)) / height
        let clipCoords = SIMD4<Float>(clipX, clipY, 0, 1) // Assume clip space is hemicube, -Z is into the screen
        
        var eyeRayDir = inverseProjectionMatrix * clipCoords
        eyeRayDir.z = 1
        eyeRayDir.w = 0
        
        var worldRayDir = (inverseViewMatrix * eyeRayDir).xyz
        worldRayDir = normalize(worldRayDir)
        
        let eyeRayOrigin = SIMD4<Float>(x: 0, y: 0, z: 0, w: 1)
        let worldRayOrigin = (inverseViewMatrix * eyeRayOrigin).xyz
        
        let ray = Ray(origin: worldRayOrigin, direction: worldRayDir)
        os_log("(handleInteraction) ray.direction %f, %f, %f",ray.direction.x, ray.direction.y, ray.direction.z)
        if let hit = renderer?.scene.hitTest(ray) {
            print("Hit \(hit.node) at \(hit.intersectionPoint)")
            selectedNode = hit.node
        }
    }
    
}

