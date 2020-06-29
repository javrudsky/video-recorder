//
//  AVAssetWriter+Extension.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 29/06/2020.
//  Copyright © 2020 Black Tobacco. All rights reserved.
//

import Foundation
import AVFoundation

extension AVAssetWriter.Status: CustomStringConvertible {
   public var description: String {
      switch self {
      case .writing:
         return "writing"
      case .completed:
         return "completed"
      case .failed:
         return "failed"
      case .cancelled:
         return "canceled"
      default:
         return "unknown"
      }
   }
}
