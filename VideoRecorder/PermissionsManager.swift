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

   func checkAndAskCameraPermissions() -> Bool {
      var result: AVAuthorizationStatus = .authorized
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
         break

      case .notDetermined:

         AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            if !granted {
               result = .denied
            }
         })

      default:
         result = .denied
      }
      return result == .authorized
   }

   func checkAndAskPhotoLibraryAccess() -> Bool {
      var result: PHAuthorizationStatus = .authorized
      switch PHPhotoLibrary.authorizationStatus() {
      case .authorized:
         break

      case .notDetermined:
         PHPhotoLibrary.requestAuthorization { access in
            result = access
         }

      default:
         result = .denied
      }
      return result == .authorized
   }
}
