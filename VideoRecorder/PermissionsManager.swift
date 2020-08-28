//
//  PermissionsManager.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 11/12/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

import Foundation
import Photos

class PermissionsManager {

   var permissionsGrantedHandler: (() -> Void)?

   var cameraResult = false
   var photoLibraryResult = false

   func checkAndAskPermissions() -> Bool {
      let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
      if cameraStatus == .notDetermined {
         AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            self.cameraResult = granted
            self.triggerPermissionHandler()
         })
      } else {
         cameraResult = (cameraStatus == .authorized)
      }

      let photoLibraryStatus = PHPhotoLibrary.authorizationStatus()
      if photoLibraryStatus == .notDetermined {
         PHPhotoLibrary.requestAuthorization { access in
            self.photoLibraryResult = (access == .authorized)
            self.triggerPermissionHandler()
         }
      } else {
         photoLibraryResult = (photoLibraryStatus == .authorized)
      }
      return cameraResult && photoLibraryResult
   }

   private func triggerPermissionHandler() {
      if cameraResult, photoLibraryResult, let handler = permissionsGrantedHandler {
         DispatchQueue.main.async {
            handler()
         }
      }
   }
}
