//
//  Log.swift
//  VideoRecorder
//
//  Created by Javier L. Avrudsky on 23/10/2019.
//  Copyright © 2019 Black Tobacco. All rights reserved.
//

import Foundation

class Log {

   #if DEBUG
       static var isEnabled: Bool = true
   #else
       static var isEnabled: Bool = false
   #endif

   private enum LogType: String {
      case warning
      case error
      case info
      case debug
   }

   // MARK: - Private
   private static func log(logType: LogType, message: String, component: Any? = nil) {
      let logTypeTag = logType.rawValue.uppercased()
      var componentTag = ""
      if let component = component {
         componentTag = "[\(String(describing: type(of: component)))]"
      }
      if isEnabled || logType == .error {
         print("\(logTypeTag) \(componentTag): \(message)")
      }
   }

   // MARK: - API
   static func d(_ message: String, _ component: Any? = nil) {
      log(logType: .debug, message: message, component: component)
   }

   static func w(_ message: String, _ component: Any? = nil) {
      log(logType: .warning, message: message, component: component)
   }

   static func i(_ message: String, _ component: Any? = nil) {
      log(logType: .info, message: message, component: component)
   }

   static func e(_ message: String, _ component: Any? = nil) {
      log(logType: .error, message: message, component: component)
   }
}
