//
//  SRLog.swift
//  Pods
//
//  Created by Stefan Kerkewitz on 06/03/2017.
//
//

import Foundation
import CocoaLumberjack

public var logLevel: DDLogLevel = .info
public var logContext: Int = 0


/** Log a given message as error. */
func SRLogError(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, asynchronous async: Bool = true) {
    if logLevel.rawValue >= DDLogLevel.error.rawValue {
        DDLogError(message, context: logContext, file: file, function: function, line: line, asynchronous: async)
    }
}

/** Log a given message as warning. */
func SRLogWarn(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, asynchronous async: Bool = true) {
    if logLevel.rawValue >= DDLogLevel.warning.rawValue {
        DDLogWarn(message, context: logContext, file: file, function: function, line: line, asynchronous: async)
    }
}

/** Log the given message as info. */
func SRLogInfo(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, asynchronous async: Bool = true) {
    if logLevel.rawValue >= DDLogLevel.info.rawValue {
        DDLogInfo(message, context: logContext, file: file, function: function, line: line, asynchronous: async)
    }
}

/** Log a given message as debug. */
func SRLogDebug(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, asynchronous async: Bool = true) {
    if logLevel.rawValue >= DDLogLevel.debug.rawValue {
        DDLogDebug(message, context: logContext, file: file, function: function, line: line, asynchronous: async)
    }
}

/** Log a given network message as info. */
func SRLogTrace(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, asynchronous async: Bool = true) {
    if logLevel.rawValue >= DDLogLevel.verbose.rawValue {
        DDLogVerbose(message, context: logContext, file: file, function: function, line: line, asynchronous: async)
    }
}
