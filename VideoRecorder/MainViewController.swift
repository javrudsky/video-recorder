//
//  MainViewController.swift
//  Video Recorder
//
//  Created by Javier L. Avrudsky on 24/05/2019.
//  Copyright © 2019 Javi. All rights reserved.
//

import UIKit
import MetalKit

struct FilterName {
   static let brightness = "Brightness"
   static let contrast = "Contrast"
   static let saturation = "Contrast"
}

class MainViewController: UIViewController {

   @IBOutlet weak var brightnessLabel: UILabel!
   @IBOutlet weak var brightnessSlider: UISlider!

   @IBOutlet weak var contrastLabel: UILabel!
   @IBOutlet weak var contrastSlider: UISlider!

   @IBOutlet weak var saturationLabel: UILabel!
   @IBOutlet weak var saturationSlider: UISlider!

   var metalView: MTKView {
      if let metalView = view as? MTKView {
         return metalView
      }
      fatalError("Metal view not available")
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

   @IBAction func filterValueChanged(_ sender: UISlider) {
      var label: UILabel?
      var filter: TextureFilter?

      let value = sender.value
      switch sender {
      case brightnessSlider:
         filter = brightnessFilter
         label = brightnessLabel
      case contrastSlider:
         filter = contrastFilter
         label = contrastLabel
      case saturationSlider:
         filter = saturationFilter
         label = saturationLabel
      default:
         print("Not available filter")
      }

      filter?.value = value

      if let filter = filter, let label = label {
         setFilterLabelTitle(label: label, value: value)
         updateFilteringPipeline(updatedFilter: filter)
      }
   }

   // MARK: Filtering
   private func updateFilteringPipeline() {
      updateFilteringPipeline(updatedFilter: brightnessFilter)
      updateFilteringPipeline(updatedFilter: contrastFilter)
      updateFilteringPipeline(updatedFilter: saturationFilter)
   }

   private func updateFilteringPipeline(updatedFilter filter: TextureFilter) {
      if let filteringPipeling = self.filteringPipeling {
         filteringPipeling.set(filter: filter)
         filteringPipeling.applyFilter(texture: texture) { filteredTexture in
            if let renderer = self.renderer {
               renderer.texture = filteredTexture
            }
         }
      }
   }

   // MARK: UI
   private func setupUI() {
      setupFilterSlider(slider: brightnessSlider)
      setFilterLabelTitle(label: brightnessLabel, value: brightnessFilter.value)
      brightnessLabel.backgroundColor = UIColor.white

      setupFilterSlider(slider: contrastSlider)
      setFilterLabelTitle(label: contrastLabel, value: contrastSlider.value)
      contrastLabel.backgroundColor = UIColor.white

      setupFilterSlider(slider: saturationSlider)
      setFilterLabelTitle(label: saturationLabel, value: saturationSlider.value)
      saturationLabel.backgroundColor = UIColor.white
   }

   private func setupFilterSlider(slider: UISlider) {
      slider.minimumValue = TextureFilterValues.min
      slider.maximumValue = TextureFilterValues.max
      slider.value = TextureFilterValues.default
   }

   private func setFilterLabelTitle(label: UILabel, value: Float) {
      let filterName = titleForFilterLabel(label: label)
      label.text = "\(filterName) (\(decimalFormat(value)))"
   }

   private func decimalFormat(_ value: Float) -> String {
      return String(format: "%.01f", value)
   }

   private func titleForFilterLabel(label: UILabel) -> String {
      var title = ""
      switch label {
      case brightnessLabel:
         title = FilterName.brightness
      case contrastLabel:
         title = FilterName.contrast
      case saturationLabel:
         title = FilterName.saturation
      default:
         print("Should not reach here")
      }
      return title
   }
}
