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

    @IBOutlet weak var brightnessLabel: UILabel!
    @IBOutlet weak var brightnessSlider: UISlider!
    
    @IBOutlet weak var contrastLabel: UILabel!
    @IBOutlet weak var contrastSlider: UISlider!
    
    @IBOutlet weak var saturationLabel: UILabel!
    @IBOutlet weak var saturationSlider: UISlider!
    
    let kMinFilterValue: Float = -127.5
    let kMaxFilterValue: Float = 127.5
    let kInitialFilterValue: Float = 0.0
    
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
        setupUI()
    }
    
    func setupUI() {
        brightnessSlider.minimumValue = kMinFilterValue
        brightnessSlider.maximumValue = kMaxFilterValue
        brightnessSlider.value = kInitialFilterValue
        setBrightnessTitle(value: brightnessSlider.value)
        brightnessLabel.backgroundColor = UIColor.white
        
        contrastSlider.minimumValue = kMinFilterValue
        contrastSlider.maximumValue = kMaxFilterValue
        contrastSlider.value = kInitialFilterValue
        setContrastTitle(value: contrastSlider.value)
        contrastLabel.backgroundColor = UIColor.white
        
        saturationSlider.minimumValue = kMinFilterValue
        saturationSlider.maximumValue = kMaxFilterValue
        saturationSlider.value = kInitialFilterValue
        setSaturationTitle(value: saturationSlider.value)
        saturationLabel.backgroundColor = UIColor.white
        
        renderer.brightness = kInitialFilterValue
        renderer.contrast = kInitialFilterValue
        renderer.saturation = kInitialFilterValue
    }
    
    @IBAction func brightnessChanged(_ sender: Any) {
        let slider = sender as! UISlider
        let value = slider.value
        renderer.brightness = value
        setBrightnessTitle(value: value)
    }
    
    @IBAction func constrastChanged(_ sender: Any) {
        let slider = sender as! UISlider
        let value = slider.value
        renderer.contrast = value
        setContrastTitle(value: value)
    }
    
    @IBAction func saturationChanged(_ sender: Any) {
        let slider = sender as! UISlider
        let value = slider.value
        renderer.saturation  = value
        setSaturationTitle(value: value)
    }
    
    func setBrightnessTitle(value: Float) {
        brightnessLabel.text = "Brightness (\(decimalFormat(value)))"
    }
    
    func setContrastTitle(value: Float) {
        contrastLabel.text = "Contrast (\(decimalFormat(value)))"
    }
    
    func setSaturationTitle(value: Float) {
        saturationLabel.text = "Saturation (\(decimalFormat(value)))"
    }
    
    func decimalFormat(_ value: Float) -> String {
        return String(format: "%.01f", value)
    }
}
