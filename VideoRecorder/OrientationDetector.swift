//
//  OrientationDetector.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 20/08/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

import Foundation
import CoreMotion

enum BasicOrientation {
   case portrait
   case landscape
}
typealias OrientationChangeHandler = (BasicOrientation) -> Void

class OrientationDetector {

   var orientation: BasicOrientation {
      return currentOrientation
   }
   var orientationChangedHandler: OrientationChangeHandler?

   private let kOrientationLimit = 0.5
   private let kMotionUpdateInterval = 1.0 / 60.0
   private var currentOrientation: BasicOrientation!
   private let motion = CMMotionManager()
   private let motionQueue = OperationQueue()

   func start() {
      startDetection()
   }

   func stop() {
      stopDetection()
   }

   private func startDetection() {
      if motion.isDeviceMotionAvailable {
         self.motion.deviceMotionUpdateInterval = kMotionUpdateInterval
         self.motion.showsDeviceMovementDisplay = true
         self.motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical,
                                              to: self.motionQueue, withHandler: { (data, error) in
                                                if let data = data {
                                                   self.detectOrientation(pitch: data.attitude.pitch)
                                                }
         })
      }
   }

   private func stopDetection() {
      motion.stopDeviceMotionUpdates()
   }

   private func detectOrientation(pitch: Double) {
      let newOrientation: BasicOrientation = (abs(pitch) > kOrientationLimit ? .portrait : .landscape)
      if(newOrientation != currentOrientation) {
         if let handler = orientationChangedHandler {
            handler(newOrientation)
         }
         currentOrientation = newOrientation
      }
   }
}
