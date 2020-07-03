//
//  VideoRecorder.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 27/09/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import Photos

enum OperationResult {
   case initializeSuccess
   case initializeFail
   case writeFileSuccess
   case writeFileFail
}

enum RecorderStatus {
   case prepared
   case recording
   case resuming
   case idle
   case pausing
   case paused
   case failed
   case stoping
   case stopped
}

struct RecorderInfo {
   let operationResult: OperationResult
   let recorderStatus: RecorderStatus
   let message: String?

   init(operationResult: OperationResult, recorderStatus: RecorderStatus, message: String? = nil) {
      self.operationResult = operationResult
      self.recorderStatus = recorderStatus
      self.message = message
   }
}

class VideoRecorder {
   private let kFileType = "mov"
   private let writingQueue = DispatchQueue(label: "com.javi.videorecording.recording")
   private let statusQueue = DispatchQueue(label: "com.javi.videorecording.status")
   private var assetWriter: AVAssetWriter?
   private let fileManager = FileManager.default
   private var currentFileUrl: URL?
   private var videoSourceWriterInput: AVAssetWriterInput?
   private var videoFormatDescription: CMFormatDescription
   private var assetWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
   private let orientationDetector = OrientationDetector()
   private var shouldRotateOnWrite = false
   private var lastPauseTime = CMTimeMake(value: 0, timescale: 1)
   private var totalPauseTimeOffset = CMTimeMake(value: 0, timescale: 1)

   private var recordingStatus: RecorderStatus = .idle
   var status: RecorderStatus {
      var currentStatus: RecorderStatus!
      statusQueue.sync {
         currentStatus = self.recordingStatus
      }
      return currentStatus
   }

   var statusHandler: ((RecorderInfo) -> Void)?

   init(videoFormatDescription: CMFormatDescription) {
      self.videoFormatDescription = videoFormatDescription
      orientationDetector.orientationChangedHandler = { [weak self] newOrientation in
         if let self = self {
            self.shouldRotateOnWrite = newOrientation == .portrait
         }
      }
      orientationDetector.start()
   }

   // MARK: - API -
   func record() {
      if !isPhotoLibraryGranted() {
         return
      }
      DispatchQueue.global().async {
         self.startWriting()
         if !self.canStartWritingSession() {
            Log.e("Could not start writing session, invalid status", self)
            self.transitionToStatus(.idle)
         } else {
            self.transitionToStatus(.prepared)
         }
         let operationResult: OperationResult = (self.status == .prepared ? .initializeSuccess : .initializeFail)
         self.statusHandler?(RecorderInfo(operationResult: operationResult, recorderStatus: self.status))
      }
   }

   func resume() {
      transitionToStatus(.resuming)
   }

   func pause() {
      transitionToStatus(.pausing)
   }

   func stop() {
      transitionToStatus(.stoping)
   }

   // MARK: - Writing -
   func newTemporalFileUrl() -> URL? {
      do {
         let folder = try fileManager.url(for: .cachesDirectory,
                                          in: .allDomainsMask,
                                          appropriateFor: nil,
                                          create: false)
         return folder.appendingPathComponent(randomName())
      } catch {
         Log.e("Error creating temporal video file", self)
      }
      return nil
   }

   func randomName() -> String {
      return "\(UUID().uuidString).\(kFileType)"
   }

   func startWriting() {
      if !canStartRecording() {
         transitionToStatus(.idle, errorMessage: "Could not start writing, invalid status: \(self.status)")
         return
      }

      if let url = newTemporalFileUrl() {
         currentFileUrl = url
         do {
            assetWriter = try AVAssetWriter(url: url, fileType: .mov)

            if !setupVideoSourceInput() {
               transitionToStatus(.failed, errorMessage: "Failed to setup video input writer")
            }

            if let writer = assetWriter {
               if writer.startWriting() {
                  transitionToStatus(.prepared)
               } else {
                  transitionToStatus(.failed,
                                     errorMessage:
                     "Failed to start writing with asset writer: " +
                        (writer.error?.localizedDescription ?? "Unknown error") +
                     "for url: \(url.path))")
               }
            } else {
               transitionToStatus(.failed,
                                  errorMessage: "Asset writer was not created")
            }
         } catch {
            transitionToStatus(.failed,
                               errorMessage: "Error while creating asset writer: \(error.localizedDescription)")
         }
      }
   }

   func setupVideoSourceInput() -> Bool {

      // TODO: Refactor this code
      var videoSettings = [String: Any]()

      if videoSettings.isEmpty {
         var bitsPerPixel: Float
         let dimensions = CMVideoFormatDescriptionGetDimensions(videoFormatDescription)
         let numPixels = Float(dimensions.width * dimensions.height)
         var bitsPerSecond: Int

         Log.d("No video settings provided, using default settings", self)

         // Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
         if numPixels < 640 * 480 {
            // This bitrate approximately matches the quality produced by AVCaptureSessionPresetMedium or Low.
            bitsPerPixel = 4.05
         } else {
            // This bitrate approximately matches the quality produced by AVCaptureSessionPresetHigh.
            bitsPerPixel = 10.1
         }

         bitsPerSecond = Int(numPixels * bitsPerPixel)

         let compressionProperties: NSDictionary = [AVVideoAverageBitRateKey: bitsPerSecond,
                                                    AVVideoExpectedSourceFrameRateKey: 30,
                                                    AVVideoMaxKeyFrameIntervalKey: 30]

         videoSettings = [AVVideoCodecKey: AVVideoCodecType.h264,
                          AVVideoWidthKey: dimensions.width,
                          AVVideoHeightKey: dimensions.height,
                          AVVideoCompressionPropertiesKey: compressionProperties]
      }

      videoSourceWriterInput = AVAssetWriterInput(mediaType: .video,
                                                  outputSettings: videoSettings,
                                                  sourceFormatHint: videoFormatDescription)

      if let videoSourceWriterInput = videoSourceWriterInput,
         let assetWriter = assetWriter,
         assetWriter.canAdd(videoSourceWriterInput) {

         if shouldRotateOnWrite {
            videoSourceWriterInput.transform = CGAffineTransform(rotationAngle: .pi/2)
         }

         assetWriterInputPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoSourceWriterInput,
            sourcePixelBufferAttributes: nil)
         videoSourceWriterInput.expectsMediaDataInRealTime = true
         assetWriter.add(videoSourceWriterInput)
         return true
      }
      return false
   }

   func appendFrame(sample: CVPixelBuffer, at sourceTime: CMTime) {

      guard let assetWriter = self.assetWriter else {
         return
      }

      writingQueue.async {[weak self] in
         guard let self = self else {
            return
         }

         var fixedSourceTime = CMTimeSubtract(sourceTime, self.totalPauseTimeOffset)

         if self.status == .prepared || self.status == .resuming {
            let lastPauseTimeOffset = CMTimeSubtract(sourceTime, self.lastPauseTime)
            self.totalPauseTimeOffset = CMTimeAdd(self.totalPauseTimeOffset, lastPauseTimeOffset)
            fixedSourceTime = CMTimeSubtract(sourceTime, self.totalPauseTimeOffset)
            assetWriter.startSession(atSourceTime: fixedSourceTime)
            Log.d("Recording session started: \(assetWriter.status)", self)
            self.transitionToStatus(.recording)
         }

         if self.status == .paused {
            return
         }

         if self.status == .pausing {
            self.transitionToStatus(.paused)
            self.lastPauseTime = sourceTime
            Log.d("Recording session paused: \(assetWriter.status)", self)
            return
         }

         if self.status == .stoping {
            self.transitionToStatus(.stopped)
            assetWriter.endSession (atSourceTime: fixedSourceTime)
            self.stopRecording()
            Log.d("Recording session stopped: \(assetWriter.status)", self)
            return
         }

         if let videoSourceWriterInput = self.videoSourceWriterInput,
            let assetWriterInputPixelBufferAdaptor = self.assetWriterInputPixelBufferAdaptor,
            videoSourceWriterInput.isReadyForMoreMediaData,
            self.canAppendFrames() {
//            Log.d("Adding samples: \(assetWriter.status)", self)
            //TODO: Fix leak produced in this line
            assetWriterInputPixelBufferAdaptor.append(sample,
                                                      withPresentationTime: fixedSourceTime)
         }
      }
   }

   func stopRecording() {
      assetWriter?.finishWriting { [weak self] in
         if let self = self {
            if self.assetWriter?.status == .failed {
               self.transitionToStatus(.failed)
               let message = "Failing when finishing writing"
               self.statusHandler?(RecorderInfo(operationResult: .writeFileFail,
                                                recorderStatus: self.status,
                                                message: message))
               Log.e(message, self)
            }

            if let url = self.currentFileUrl, self.status != .failed {
               PHPhotoLibrary.shared().performChanges({
                  PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
               }, completionHandler: { saved, error in
                  if saved {
                     self.statusHandler?(RecorderInfo(operationResult: .writeFileSuccess, recorderStatus: .idle))
                  } else {
                     self.statusHandler?(RecorderInfo(operationResult: .writeFileFail,
                                                      recorderStatus: .idle,
                                                      message: "Error saving to photo library"))
                     Log.e("Error saving to library \(error.debugDescription)", self)
                  }
               })
            }
            self.transitionToStatus(.idle)
         }
      }
   }

   // MARK: - Status Handling -
   private func canStartRecording() -> Bool {
      return [.idle, .failed].contains(status)
   }

   private func canAppendFrames() -> Bool {
      return status == .recording
   }

   private func canStartWritingSession() -> Bool {
      return status == .prepared
   }

   private func transitionToStatus(_ status: RecorderStatus, errorMessage: String? = nil) {
      statusQueue.sync {
         recordingStatus = status
      }
      if let message = errorMessage {
         Log.e(message)
      }
   }

   // FIXME: Fix issue when first time running app and asking for permissions
   // MARK: - Check Permissions
   private func isPhotoLibraryGranted() -> Bool {
      return PHPhotoLibrary.authorizationStatus() == .authorized
   }
}
