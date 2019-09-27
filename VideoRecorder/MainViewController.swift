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

   @IBOutlet weak var orientationIcon: UIImageView!
   @IBOutlet var icons: [UIImageView]!
   @IBOutlet weak var fpsLabel: UILabel!

   @IBOutlet var buttons: [UIButton]!

   @IBOutlet weak var playAndPauseButton: UIButton!
   @IBOutlet weak var stopButton: UIButton!
   @IBOutlet weak var showFiltersButton: UIButton!
   @IBOutlet weak var resetFiltersButton: UIButton!

    @IBOutlet weak var filtersMenuView: UIStackView!
    var areFiltersVisible = false
   @IBOutlet weak var filtersBotomConstraint: NSLayoutConstraint!
   var initialFilterMenuBotom: CGFloat = 0.0
   var filterMenuHeight: CGFloat = 0.0

   struct FilterIndex {
      static let brightess = 0
      static let contrast = 1
      static let saturatin = 2
   }

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
      camera.start()
      orientationDetector.orientationChangedHandler = { newOrientation in
         self.handle(orientation: newOrientation)
      }
      orientationDetector.start()
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
      fpsLabel.text = "0"
      for index in 0..<filters.count {
         setupFilterSlider(slider: filterSliders[index])
         setFilterLabelTitle(index: index, value: filterSliders[index].value)
      }
      initialFilterMenuBotom = filtersBotomConstraint.constant
      filterMenuHeight = filtersMenuView.frame.size.height
      showAndHideFilters()
   }

   private func setupFilterSlider(slider: UISlider) {
      slider.minimumValue = TextureFilterValues.min
      slider.maximumValue = TextureFilterValues.max
      slider.value = TextureFilterValues.default
   }

   private func setFilterLabelTitle(index: Int, value: Float) {
      filterLabels[index].text = "\(decimalFormat(value))"
   }

   private func decimalFormat(_ value: Float) -> String {
      return String(format: "%.01f", value)
   }

   private func handle(orientation: BasicOrientation) {
      var radians: Float = 0.0
      if orientation == .landscape {
         radians = .pi / 2.0
      }
      rotateImages(to: radians)
    }

   private func rotateImages(to angleInRadians: Float) {
      DispatchQueue.main.async {
         let transformation = CGAffineTransform(rotationAngle: CGFloat(angleInRadians))
         UIView.animate(withDuration: 0.5, animations: {

            for icon in self.icons {
               icon.transform = transformation
            }
            for label in self.filterLabels {
                label.transform = transformation
            }

            for button in self.buttons {
                button.transform = transformation
            }

            self.fpsLabel.transform = transformation
         })
      }
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

      self.displayFps()

   }

   private func displayFps() {
      DispatchQueue.main.async {
         self.fpsLabel.text = "\(self.camera.currentFps)"
      }
   }

    @IBAction func playAndPauseTap(_ sender: UIButton) {
    }

    @IBAction func stopTap(_ sender: UIButton) {
    }

    @IBAction func showFiltersTap(_ sender: UIButton) {
      showAndHideFiltersAnimated()
    }

   private func showAndHideFiltersAnimated() {
      DispatchQueue.main.async {
         UIView.animate(withDuration: 0.5, animations: {
            self.showAndHideFilters()
            self.view.layoutIfNeeded()
         })

      }
   }
   private func showAndHideFilters() {
      areFiltersVisible = !areFiltersVisible
      if areFiltersVisible {
         filtersBotomConstraint.constant = initialFilterMenuBotom
      } else {
         filtersBotomConstraint.constant = -initialFilterMenuBotom - filterMenuHeight
      }
   }
}
