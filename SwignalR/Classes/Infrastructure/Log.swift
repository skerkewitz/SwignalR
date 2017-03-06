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


/** Log a given message as error. */
func SRLogError(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: Any? = nil, asynchronous async: Bool = true) {
    if logLevel.rawValue >= DDLogLevel.error.rawValue {
        DDLogError(message, file: file, function: function, line: line, tag: tag, asynchronous: async)
    }
}

/** Log a given message as warning. */
func SRLogWarn(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: Any? = nil, asynchronous async: Bool = true) {
    if logLevel.rawValue >= DDLogLevel.warning.rawValue {
        DDLogWarn(message, file: file, function: function, line: line, tag: tag, asynchronous: async)
    }
}

/** Log the given message as info. */
func SRLogInfo(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: Any? = nil, asynchronous async: Bool = true) {
    if logLevel.rawValue >= DDLogLevel.info.rawValue {
        DDLogInfo(message, file: file, function: function, line: line, tag: tag, asynchronous: async)
    }
}

/** Log a given message as debug. */
func SRLogDebug(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: Any? = nil, asynchronous async: Bool = true) {
    if logLevel.rawValue >= DDLogLevel.debug.rawValue {
        DDLogDebug(message, file: file, function: function, line: line, tag: tag, asynchronous: async)
    }
}

/** Log a given network message as info. */
func SRLogTrace(_ message: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: Any? = nil, asynchronous async: Bool = true) {
    if logLevel.rawValue >= DDLogLevel.verbose.rawValue {
        DDLogVerbose(message, file: file, function: function, line: line, tag: tag, asynchronous: async)
    }
}
