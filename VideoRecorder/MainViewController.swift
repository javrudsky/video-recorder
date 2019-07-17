//
//  MainViewController.swift
//  Video Recorder
//
//  Created by Javier L. Avrudsky on 24/05/2019.
//  Copyright © 2019 Javi. All rights reserved.
//

import UIKit
import MetalKit



class MainViewController: UIViewController {

    
    var metalView: MTKView {
        return view as! MTKView
    }
    
    var renderer: ViewRenderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        renderer = ViewRenderer()
        metalView.device = renderer.device
        metalView.clearColor = Colors.yellow
        metalView.delegate = renderer
    }
}
