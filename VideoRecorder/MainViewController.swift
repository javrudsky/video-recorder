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
    
    
    
    var metalView: MTKView {
        return view as! MTKView
    }
    
    var filteringPipeling: TextureFilteringPipeline?
    var renderer: ViewRenderer?
    
    var brightnessFilter: TextureFilter!
    var saturationFilter: TextureFilter!
    var contrastFilter: TextureFilter!
    
    var texture: Texture!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let device = MTLCreateSystemDefaultDevice() {
            filteringPipeling = TextureFilteringPipeline(device: device)
            texture = Texture(fromResource: "jeep", withExtension: "jpg", on: device)
            renderer = ViewRenderer(device: device)
            renderer?.texture = texture
            metalView.device = device
            metalView.clearColor = Colors.yellow
            metalView.delegate = renderer
        }
        brightnessFilter = BrightnessFilter()
        saturationFilter = SaturationFilter()
        contrastFilter = ContrastFilter()
        
        setupUI()
        updateFilteringPipeline()
    }
    
    func setupUI() {
        brightnessSlider.minimumValue = TextureFilterValues.min
        brightnessSlider.maximumValue = TextureFilterValues.max
        brightnessSlider.value = TextureFilterValues.default
        setBrightnessTitle(value: brightnessSlider.value)
        brightnessLabel.backgroundColor = UIColor.white
        
        contrastSlider.minimumValue = TextureFilterValues.min
        contrastSlider.maximumValue = TextureFilterValues.max
        contrastSlider.value = TextureFilterValues.default
        setContrastTitle(value: contrastSlider.value)
        contrastLabel.backgroundColor = UIColor.white
        
        saturationSlider.minimumValue = TextureFilterValues.min
        saturationSlider.maximumValue = TextureFilterValues.max
        saturationSlider.value = TextureFilterValues.default
        setSaturationTitle(value: saturationSlider.value)
        saturationLabel.backgroundColor = UIColor.white
    }
    
    @IBAction func brightnessChanged(_ sender: Any) {
        let slider = sender as! UISlider
        let value = slider.value
        setBrightnessTitle(value: value)
        brightnessFilter.value = value
        updateFilteringPipeline()
    }
    
    @IBAction func constrastChanged(_ sender: Any) {
        let slider = sender as! UISlider
        let value = slider.value
        setContrastTitle(value: value)
        contrastFilter.value = value
        updateFilteringPipeline()
    }
    
    @IBAction func saturationChanged(_ sender: Any) {
        let slider = sender as! UISlider
        let value = slider.value
        setSaturationTitle(value: value)
        saturationFilter.value = value
        updateFilteringPipeline()
    }
    
    func updateFilteringPipeline() {
        filteringPipeling?.set(filter: brightnessFilter)
        filteringPipeling?.set(filter: contrastFilter)
        filteringPipeling?.set(filter: saturationFilter)
        filteringPipeling?.applyFilter(texture: texture) { filteredTexture in
            if let renderer = self.renderer {
                renderer.texture = filteredTexture
            }
        }
    }
    
    func setBrightnessTitle(value: Float) {
        brightnessLabel.text = "Brightness (\(decimalFormat(value)))"
        brightnessFilter.value = value
    }
    
    func setContrastTitle(value: Float) {
        contrastLabel.text = "Contrast (\(decimalFormat(value)))"
        contrastFilter.value = value
    }
    
    func setSaturationTitle(value: Float) {
        saturationLabel.text = "Saturation (\(decimalFormat(value)))"
        saturationFilter.value = value
    }
    
    func decimalFormat(_ value: Float) -> String {
        return String(format: "%.01f", value)
    }
}
