//
//  MainViewController.swift
//  Video Recorder
//
//  Created by Javier L. Avrudsky on 24/05/2019.
//  Copyright © 2019 Javi. All rights reserved.
//

import UIKit
import MetalKit
import AVFoundation


class MainViewController: UIViewController {

   @IBOutlet var filterSliders: [UISlider]!
   @IBOutlet var filterLabels: [UILabel]!
   @IBOutlet weak var metalView: MTKView!

   struct FilterIndex {
      static let brightess = 0
      static let contrast = 1
      static let saturatin = 2
   }

   let filterNames = [
      "Brightness",
      "Contrast",
      "Saturation"
   ]

   var filters: [TextureFilter] = [
      BrightnessFilter(),
      ContrastFilter(),
      SaturationFilter()
   ]

   var filteringPipeling: TextureFilteringPipeline?
   var renderer: ViewRenderer?
   var device: MTLDevice?

   let camera = VideoCamera()
   let orientationDetector = OrientationDetector()

   override func viewDidLoad() {
      super.viewDidLoad()

      if let device = MTLCreateSystemDefaultDevice() {
         self.device = device
         filteringPipeling = TextureFilteringPipeline(device: device)
         renderer = ViewRenderer(device: device)
         metalView.device = device
         metalView.clearColor = Colors.yellow
         metalView.delegate = renderer
      }

      setupUI()
      camera.videoOutputHandler = handleVideoOutput
      camera.askCameraPermissions()
      orientationDetector.orientationChangedHandler = { newOrientation in
         self.handle(orientation: newOrientation)
      }
   }

   @IBAction func filterValueChanged(_ sender: UISlider) {
      if let index = filterSliders.firstIndex(of: sender) {
         updateFilter(index: index, value: filterSliders[index].value)
      }
   }

   @IBAction func resetFiltersButtonTap(_ sender: UIButton) {
      resetFilters()
   }

   // MARK: Filtering
   private func resetFilters() {
      for index in 0..<filters.count {
         filterSliders[index].value = TextureFilterValues.default
         updateFilter(index: index, value: TextureFilterValues.default)
      }
   }

   private func updateFilter(index: Int, value: Float) {
      var filter: TextureFilter = filters[index]
      filter.value = value
      setFilterLabelTitle(index: index, value: value)
   }

   private func applyFilters(to texture: Texture) {
      if let filteringPipeling = self.filteringPipeling {
         for filter in self.filters {
            filteringPipeling.set(filter: filter)
         }
         filteringPipeling.applyFilter(texture: texture) { filteredTexture in
            if let renderer = self.renderer {
               renderer.texture = filteredTexture
            }
         }
      }
   }

   // MARK: UI
   private func setupUI() {
      for index in 0..<filters.count {
         setupFilterSlider(slider: filterSliders[index])
         setFilterLabelTitle(index: index, value: filterSliders[index].value)
      }
   }

   private func setupFilterSlider(slider: UISlider) {
      slider.minimumValue = TextureFilterValues.min
      slider.maximumValue = TextureFilterValues.max
      slider.value = TextureFilterValues.default
   }

   private func setFilterLabelTitle(index: Int, value: Float) {
      let filterName = filterNames[index]
      filterLabels[index].text = "\(filterName) (\(decimalFormat(value)))"
   }

   private func decimalFormat(_ value: Float) -> String {
      return String(format: "%.01f", value)
   }

   private func handle(orientation: BasicOrientation) {
   }

   // MARK: VideoCamera
   private func handleVideoOutput(frame: CVPixelBuffer) {
      guard let device = self.device else {
         return
      }

      let texture = Texture(from: frame, on: device)
      if texture.texture != nil {
         applyFilters(to: texture)
      }
   }


}
