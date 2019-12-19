//
//  CMSampleBuffer+Extension.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 19/12/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

import Foundation
import CoreMedia

extension CMSampleBuffer {
   func timestamp() -> CMTime {
      /// TODO: Find the issue for decodeTImeStamp and
      /// -[AVAssetWriter startSessionAtSourceTime:] invalid parameter not satisfying: CMTIME_IS_NUMERIC(startTime)
//      if #available(iOS 13.2, *) {
//         return self.decodeTimeStamp
//      } else {
//         return CMSampleBufferGetPresentationTimeStamp(self)
//      }
      return CMSampleBufferGetPresentationTimeStamp(self)
   }
}
