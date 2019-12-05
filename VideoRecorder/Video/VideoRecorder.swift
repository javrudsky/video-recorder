//
//  VideoRecorder.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 27/09/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

import Foundation
import AVFoundation

enum RecorderStatus {
   case initialized
   case recording
   case resuming
   case idle
   case pausing
   case paused
   case failed
}

struct RecorderInfo {
   let status: RecorderStatus
   let message: String?

   init(status: RecorderStatus, message: String? = nil) {
      self.status = status
      self.message = message
   }
}

class VideoRecorder {
   private let kFileType = "mov"
   private let writingQueue = DispatchQueue(label: "com.javi.videorecording.recording", attributes: .concurrent)
   private let statusQueue = DispatchQueue(label: "com.javi.videorecording.status")
   private var assetWriter: AVAssetWriter?
   private let fileManager = FileManager.default
   private var currentFileUrl: URL?
   private var videoSourceWriterInput: AVAssetWriterInput?
   private var videoFormatDescription: CMFormatDescription

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
   }

   // MARK: - API -
   func record() {
      DispatchQueue.global().async {
         self.startWriting()
         if !self.canStartWritingSession() {
            Log.e("Could not start writing session, invalid status", self)
            self.transitionToStatus(.idle)
         } else {
            self.transitionToStatus(.recording)
         }
         self.statusHandler?(RecorderInfo(status: self.status))
      }
   }

   func resume() {
      transitionToStatus(.recording)
   }

   func pause() {
      transitionToStatus(.pausing)
   }

   func stop() {
      stopRecording()
   }

   // MARK: - Writing -
   func newTemporalFileUrl() -> URL? {
      do {
         let folder = try fileManager.url(for: .libraryDirectory,
                                          in: .localDomainMask,
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
         transitionToStatus(.initialized, errorMessage: "Could not start writing, invalid status: \(self.status)")
         return
      }

      if let url = newTemporalFileUrl() {
         currentFileUrl = url
         do {
            assetWriter = try AVAssetWriter(url: url, fileType: .mov)


            if !setupVideoSourceInput() {
               transitionToStatus(.failed, errorMessage: "Failed to setup video input writer")
            }

            if let writer = assetWriter, writer.startWriting() {
               transitionToStatus(.initialized)
            } else {
               transitionToStatus(.failed, errorMessage: "Failed to create asset writer")
            }
         } catch {
            transitionToStatus(.failed, errorMessage: "Error while creating asset writer: \(error.localizedDescription)")
         }
      }
   }

   func setupVideoSourceInput() -> Bool {
      videoSourceWriterInput = AVAssetWriterInput(mediaType: .video,
                                                  outputSettings: nil,
                                                  sourceFormatHint: videoFormatDescription)

      if let videoSourceWriterInput = videoSourceWriterInput,
         let assetWriter = assetWriter,
         assetWriter.canAdd(videoSourceWriterInput) {
         videoSourceWriterInput.expectsMediaDataInRealTime = true
         assetWriter.add(videoSourceWriterInput)
         return true
      }
      return false
   }

   func writeFrame(sample: CMSampleBuffer) {
      guard let assetWriter = self.assetWriter, canAppendFrames() else {
         return
      }

      if(status == .initialized || status == .resuming) {
         if #available(iOS 13.0, *) {
            assetWriter.startSession(atSourceTime: sample.decodeTimeStamp)
         } else {
            assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample))
         }
         transitionToStatus(.recording)
      }

      if let videoSourceWriterInput = self.videoSourceWriterInput,
         videoSourceWriterInput.isReadyForMoreMediaData {
         videoSourceWriterInput.append(sample)
      }

      if(status == .pausing) {
         if #available(iOS 13.0, *) {
            assetWriter.endSession (atSourceTime: sample.decodeTimeStamp)
         } else {
            assetWriter.endSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample))
         }
         transitionToStatus(.paused)
         return
      }

   }

   func stopRecording() {
      assetWriter?.finishWriting { [weak self] in
         if let self = self {
            if self.assetWriter?.status == .failed {
               self.transitionToStatus(.failed)
               let message = "Failing when finishing writing"
               self.statusHandler?(RecorderInfo(status: self.status, message: message))
               Log.e(message, self)
            } else {

            }
            self.transitionToStatus(.idle)
         }
      }
   }

   // MARK: - Status Handling -
   func canStartRecording() -> Bool {
      return [.idle, .failed].contains(status)
   }

   func canAppendFrames() -> Bool {
      return [.initialized, .recording, .pausing].contains(status)
   }

   func canStartWritingSession() -> Bool {
      return status == .initialized
   }

   func transitionToStatus(_ status: RecorderStatus, errorMessage: String? = nil) {
      statusQueue.sync {
         recordingStatus = .initialized
      }
      if let message = errorMessage {
         Log.e(message)
      }
   }
}
