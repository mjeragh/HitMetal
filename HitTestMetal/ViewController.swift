//
//  GameViewController.swift
//  HitTestMetal
//
//  Created by Mohammad Jeragh on 4/1/19.
//  Copyright © 2019 Mohammad Jeragh. All rights reserved.
//

import MetalKit


let touchPlane = Plane(a: -0.8,b: 0.5,c: 0,d: 3, debug: true)

class ViewController: UIViewController {
    
    var renderer: Renderer?
    var selectedNode: Node?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let metalView = view as? MTKView else {
            fatalError("metal view not set up in storyboard")
        }
        selectedNode = nil
        renderer = Renderer(metalView: metalView)
        //addGestureRecognizer(to: metalView)
    }
}

class LocalViewController: UIViewController {}
