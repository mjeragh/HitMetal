
import Foundation
import MetalKit

class Scene {
    let rootNode = Node()

    var plane : Node? {
      //  get {
            for n in rootNode.children {
                if (n.name == "plane") {
                    return n
                }
        }
            return nil
  //  }
}
    
    func hitTest(_ ray: Ray) -> HitResult? {
        return rootNode.hitTest(ray)
    }
    func unproject(_ ray: Ray) -> HitResult? {
        return plane!.unproject(ray)
    }
}
