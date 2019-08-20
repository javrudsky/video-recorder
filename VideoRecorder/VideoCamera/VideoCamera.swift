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

typealias VideoOutputHandler = (CVPixelBuffer)->Void

class VideoCamera: NSObject {
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
   private let sessionQueue = DispatchQueue(label: "session queue")
   private let dataOutputQueue = DispatchQueue(label: "VideoDataQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
   private let videoDataOutput = AVCaptureVideoDataOutput()
   private var setupResult: SessionSetupResult = .success

   @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!



   func askCameraPermissions() {
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
         // The user has previously granted access to the camera.
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
         // The user has previously denied access.
         setupResult = .notAuthorized
      }

      sessionQueue.async {
         self.configureSession()
      }
   }

   func configureSession() {
      if setupResult != .success {
         return
      }

      session.beginConfiguration()

      /*
       Do not create an AVCaptureMovieFileOutput when setting up the session because
       Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
       */
      session.sessionPreset = .hd1920x1080

      // Add video input.
      do {
         var defaultVideoDevice: AVCaptureDevice?

         // Choose the back dual camera, if available, otherwise default to a wide angle camera.

         if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            defaultVideoDevice = dualCameraDevice
         } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            // If a rear dual camera is not available, default to the rear wide angle camera.
            defaultVideoDevice = backCameraDevice
         } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            // If the rear wide angle camera isn't available, default to the front wide angle camera.
            defaultVideoDevice = frontCameraDevice
         }
         guard let videoDevice = defaultVideoDevice else {
            print("Default video device is unavailable.")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
         }

         let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

         if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
            self.videoDeviceInput = videoDeviceInput

            DispatchQueue.main.async {
               /*
                Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
                You can manipulate UIView only on the main thread.
                Note: As an exception to the above rule, it's not necessary to serialize video orientation changes
                on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.

                Use the window scene's orientation as the initial video orientation. Subsequent orientation changes are
                handled by CameraViewController.viewWillTransition(to:with:).
                */
               //               var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
               //               if self.windowOrientation != .unknown {
               //                  if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: self.windowOrientation) {
               //                     initialVideoOrientation = videoOrientation
               //                  }
               //               }

               //               self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation


            }
         } else {
            print("Couldn't add video device input to the session.")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
         }

         // Add a video data output
         if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
         } else {
            print("Could not add video data output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
         }
      } catch {
         print("Couldn't create video device input: \(error)")
         setupResult = .configurationFailed
         session.commitConfiguration()
         return
      }

      session.commitConfiguration()
      session.startRunning()
      if self.videoDataOutput.connections.count > 0 {
         connection = self.videoDataOutput.connections[0]
         connection!.automaticallyAdjustsVideoMirroring = false

         connection!.videoOrientation = .portraitUpsideDown
         connection!.isVideoMirrored = true
      }
   }

   var orientation: UIDeviceOrientation = .landscapeLeft {
      didSet {
         if let connection = self.connection {
            guard let newVideoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue),
               orientation.isPortrait || orientation.isLandscape else {
                  return
            }
            connection.videoOrientation = newVideoOrientation
         }
      }
   }
}

extension VideoCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
   func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {

      if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
         let videoOutputHandler = self.videoOutputHandler {
         videoOutputHandler(pixelBuffer)
      }
   }
}
