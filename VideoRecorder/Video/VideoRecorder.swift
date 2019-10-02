//
//  VideoRecorder.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 27/09/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

import Foundation

enum RecorderStatus {
   case recording
   case stopped
   case paused
}

class VideoRecorder {
   private var recordingStatus: RecorderStatus = .stopped
   var status: RecorderStatus {
      return recordingStatus
   }

   func record() {
      recordingStatus = .recording
   }

   func resume() {
      recordingStatus = .recording
   }

   func pause() {
      recordingStatus = .paused
   }

   func stop() {
      recordingStatus = .stopped
   }
}
