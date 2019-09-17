//
//  VideoCamera.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 15/08/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

typealias VideoOutputHandler = (CVPixelBuffer) -> Void

class VideoCamera: NSObject {

   private let kVideoWidth = 1080
   private let kDesiredFrameRate: Double = 60.0

   var videoOutputHandler: VideoOutputHandler?

   private enum SessionSetupResult {
      case success
      case notAuthorized
      case configurationFailed
   }

   private let session = AVCaptureSession()
   private var isSessionRunning = false
   private var connection: AVCaptureConnection?


   // Communicate with the session and other session objects on this queue.
   private let sessionQueue = DispatchQueue(label: "javi.vc.sessionQueue")
   private let dataOutputQueue = DispatchQueue(label: "javi.vc.videoDataQueue",
                                               qos: .userInitiated,
                                               attributes: [],
                                               autoreleaseFrequency: .workItem)
   private let videoDataOutput = AVCaptureVideoDataOutput()
   private var setupResult: SessionSetupResult = .success

   @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!

   private let fpsCalculator = FpsCalculator()

   var currentFps: Int {
      return fpsCalculator.fps
   }

   override init() {

   }

   func askCameraPermissions() {
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
         break

      case .notDetermined:
         sessionQueue.suspend()
         AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            if !granted {
               self.setupResult = .notAuthorized
            }
            self.sessionQueue.resume()
         })

      default:
         setupResult = .notAuthorized
      }

      sessionQueue.async {
         self.configureSession()
      }
   }

   private func configureSession() {
      if setupResult != .success {
         return
      }

      session.beginConfiguration()

      guard let videoDevice = chooseVideoDevice() else {
         sessionSetupFail(reason: "Default video device is unavailable.")
         return
      }

      let captureDeviceInputResult = captureDevice(captureDevice: videoDevice)
      guard let videoDeviceInput = captureDeviceInputResult.captureDeviceInput else {
         sessionSetupFail(reason: "Couldn't create video device input: " +
            "\(captureDeviceInputResult.errorMessage ?? "Unknown error")")
         return
      }

      if !add(inputDevice: videoDeviceInput) {
         sessionSetupFail(reason: "Couldn't add video device input to the session.")
         return
      }

      if !add(videoDataOutput: videoDataOutput) {
         sessionSetupFail(reason: "Could not add video data output to the session")
         return
      }
      setup(videoDataOutput: videoDataOutput)
      setInitialVideoFormat(for: videoDevice)

      session.commitConfiguration()
      session.startRunning()
      initialConnectionSetup()
   }

   private func hasDesiredResolution(format: CMFormatDescription) -> Bool {
      let dimension = CMVideoFormatDescriptionGetDimensions(format)
      if orientation.isLandscape {
         return dimension.height == kVideoWidth
      }
      return dimension.width == kVideoWidth
   }

   private func isResolution(_ resolutionA: CMVideoDimensions, betterThan resolutionB: CMVideoDimensions) -> Bool {
      return resolutionA.height >= resolutionB.height && resolutionA.width >= resolutionB.width
   }

   private func setInitialVideoFormat(for device: AVCaptureDevice) {

      var bestFormat: AVCaptureDevice.Format?
      var bestResolution: CMVideoDimensions?
      var bestFrameRateRange: AVFrameRateRange?

      for format in device.formats where hasDesiredResolution(format: format.formatDescription) {
         if let range = format.videoSupportedFrameRateRanges.first (where: { $0.maxFrameRate >= kDesiredFrameRate }) {
            let resolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if bestResolution ==  nil || isResolution(resolution, betterThan: bestResolution!) {
               bestResolution = resolution
               bestFrameRateRange = range
               bestFormat = format
            }
         }

      }

      if let bestFormat = bestFormat,
         let bestFrameRateRange = bestFrameRateRange {
         do {
            try device.lockForConfiguration()
            device.activeFormat = bestFormat
            let duration = bestFrameRateRange.minFrameDuration
            device.activeVideoMinFrameDuration = duration
            device.activeVideoMaxFrameDuration = duration
            device.unlockForConfiguration()
            print("Format applied successfully: \(bestFormat.description)")
         } catch {
            print("Unable to apply best format")
         }
      }
   }

   var orientation: UIDeviceOrientation = .landscapeLeft {
      didSet {
         if let connection = self.connection {
            guard let newVideoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue),
               orientation.isPortrait || orientation.isLandscape else {
                  return
            }
            sessionQueue.async {
               connection.videoOrientation = newVideoOrientation
            }

         }
      }
   }
}

extension VideoCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
   func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {

      if let videoOutputHandler = self.videoOutputHandler,
         let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
         videoOutputHandler(pixelBuffer)
      }
      fpsCalculator.updateFrameTime()
   }

   func captureOutput(_ output: AVCaptureOutput,
                      didDrop sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
      print("dropped frame!!!")
   }
}

// MARK: Choosing Video Camera
extension VideoCamera {
   private func chooseVideoDevice() -> AVCaptureDevice? {
      var videoDevice: AVCaptureDevice?
      if let dualCameraDevice = dualCamera() {
         videoDevice = dualCameraDevice
      } else if let backCameraDevice = backCamera() {
         videoDevice = backCameraDevice
      } else if let frontCameraDevice = frontCamera() {
         videoDevice = frontCameraDevice
      }
      return videoDevice
   }

   private func dualCamera() -> AVCaptureDevice? {
      return AVCaptureDevice.default(.builtInDualCamera,
                                     for: .video,
                                     position: .back)
   }

   private func backCamera() -> AVCaptureDevice? {
      return AVCaptureDevice.default(.builtInWideAngleCamera,
                                     for: .video,
                                     position: .back)
   }

   private func frontCamera() -> AVCaptureDevice? {
      return AVCaptureDevice.default(.builtInWideAngleCamera,
                                     for: .video,
                                     position: .front)
   }
}

// MARK: Initial session setup
extension VideoCamera {
   private func captureDevice(
      captureDevice: AVCaptureDevice) -> (captureDeviceInput: AVCaptureDeviceInput?, errorMessage: String?) {

      var captureDeviceInput: AVCaptureDeviceInput?
      var errorMessage: String?
      do {
         captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
      } catch {
         errorMessage = error.localizedDescription
      }
      return (captureDeviceInput: captureDeviceInput, errorMessage: errorMessage)
   }

   private func add(inputDevice: AVCaptureDeviceInput) -> Bool {
      if session.canAddInput(inputDevice) {
         session.addInput(inputDevice)
         self.videoDeviceInput = inputDevice
         return true
      }
      return false
   }

   private func add(videoDataOutput: AVCaptureVideoDataOutput) -> Bool {
      if session.canAddOutput(videoDataOutput) {
         session.addOutput(videoDataOutput)
         return true
      }
      return false
   }

   private func setup(videoDataOutput: AVCaptureVideoDataOutput) {
      videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
      videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
   }

   private func sessionSetupFail(reason: String? = nil) {
      if let message = reason {
         print(message)
      }
      setupResult = .configurationFailed
      session.commitConfiguration()
   }
}

// MARK: Initial connection setup
extension VideoCamera {
   private func initialConnectionSetup() {
      if self.videoDataOutput.connections.count > 0 {
         connection = self.videoDataOutput.connections[0]
         if let connection = connection {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.videoOrientation = .portraitUpsideDown
            connection.isVideoMirrored = true
         }
      }
   }
}

// MARK: Calc FPS
class FpsCalculator {
   private var lastFrameTime: TimeInterval = Date().timeIntervalSince1970
   private var lastFps: Int = 0
   private var frameCounter: TimeInterval = 0
   private let kFrameCountToAverage: TimeInterval = 10.0

   var fps: Int {
      return lastFps
   }

   func updateFrameTime() {
      frameCounter += 1
      if frameCounter == kFrameCountToAverage {
         let time = Date().timeIntervalSince1970
         let elapsedTime = time - lastFrameTime
         if elapsedTime > 0 {
            lastFps = Int(1 / (elapsedTime / kFrameCountToAverage))
         }
         lastFrameTime = time
         frameCounter = 0
      }
   }
}
