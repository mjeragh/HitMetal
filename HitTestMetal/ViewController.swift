//
//  GameViewController.swift
//  HitTestMetal
//
//  Created by Mohammad Jeragh on 4/1/19.
//  Copyright © 2019 Mohammad Jeragh. All rights reserved.
//

import MetalKit
class ViewController: UIViewController {
    
    var renderer: Renderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let metalView = view as? MTKView else {
            fatalError("metal view not set up in storyboard")
        }
        
        renderer = Renderer(metalView: metalView)
        //addGestureRecognizer(to: metalView)
    }
}

class LocalViewController: UIViewController {}
