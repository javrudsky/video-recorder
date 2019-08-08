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

   @IBOutlet var filterSliders: [UISlider]!
   @IBOutlet var filterLabels: [UILabel]!

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

   var metalView: MTKView {
      if let metalView = view as? MTKView {
         return metalView
      }
      fatalError("Metal view not available")
   }

   var filteringPipeling: TextureFilteringPipeline?
   var renderer: ViewRenderer?
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

      setupUI()
      updateFilteringPipeline()
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
      updateFilteringPipeline(updatedFilter: filter)
   }

   private func updateFilteringPipeline() {
      for filter in filters {
         updateFilteringPipeline(updatedFilter: filter)
      }
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
}
