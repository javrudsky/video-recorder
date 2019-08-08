//
//  VideoRecorderTests.swift
//  Video Recorder Tests
//
//  Created by Javier L. Avrudsky on 11/07/2019.
//  Copyright © 2019 Javi. All rights reserved.
//

import XCTest
@testable import VideoRecorder

class TextureFilterTests: XCTestCase {

   var brightnessFilter: TextureFilter!
   var contrastFilter: TextureFilter!
   var saturationFilter: TextureFilter!

   override func setUp() {
   }

   override func tearDown() {
   }

   func testInitValue() {
      brightnessFilter = BrightnessFilter()
      contrastFilter = ContrastFilter()
      saturationFilter = SaturationFilter()

      XCTAssertEqual(0.0, brightnessFilter.value)
      XCTAssertEqual(0.0, brightnessFilter.normalizedValue)

      XCTAssertEqual(0.0, contrastFilter.value)
      XCTAssertEqual(1.0, contrastFilter.normalizedValue)

      XCTAssertEqual(0.0, saturationFilter.value)
      XCTAssertEqual(1.0, saturationFilter.normalizedValue)
   }

   func testMaxClampedValue() {
      brightnessFilter = BrightnessFilter()
      contrastFilter = ContrastFilter()
      saturationFilter = SaturationFilter()

      brightnessFilter.value = 200.0
      contrastFilter.value = 200.0
      saturationFilter.value = 200.0

      XCTAssertEqual(127.5, brightnessFilter.value)
      XCTAssertEqual(1.0, brightnessFilter.normalizedValue)

      XCTAssertEqual(127.5, contrastFilter.value)
      XCTAssertEqual(2.0, contrastFilter.normalizedValue)

      XCTAssertEqual(127.5, saturationFilter.value)
      XCTAssertEqual(2.0, saturationFilter.normalizedValue)
   }

   func testMinClampedValue() {
      brightnessFilter = BrightnessFilter()
      contrastFilter = ContrastFilter()
      saturationFilter = SaturationFilter()

      brightnessFilter.value = -200.0
      contrastFilter.value = -200.0
      saturationFilter.value = -200.0

      XCTAssertEqual(-127.5, brightnessFilter.value)
      XCTAssertEqual(-1.0, brightnessFilter.normalizedValue)

      XCTAssertEqual(-127.5, contrastFilter.value)
      XCTAssertEqual(0.0, contrastFilter.normalizedValue)

      XCTAssertEqual(-127.5, saturationFilter.value)
      XCTAssertEqual(0.0, saturationFilter.normalizedValue)
   }

}
