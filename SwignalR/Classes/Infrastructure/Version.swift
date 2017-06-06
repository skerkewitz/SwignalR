//
//  Version.swift
//  SignalR
//
//  Created by Alex Billingsley on 1/10/12.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
//  Created by Stefan Kerkewitz on 27/02/2017.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
//  to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of
//  the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
//  THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

import Foundation

/**
 * `SRVersion` represents the signalr protocol version number.
 */

public struct SRVersion: CustomStringConvertible, Equatable {

    /** The value of the major component of the version number for the current `SRVersion` object. */
    public let major: UInt

    /** The value of the minor component of the version number for the current `SRVersion` object. */
    public let minor: UInt

    /** The value of the revision component of the version number for the current `SRVersion` object. */
    public let revision: UInt

    /** The value of the build component of the version number for the current `SRVersion` object. */
    public let build: UInt

    public var description : String {
        return "\(self.major).\(self.minor).\(self.build).\(self.revision)"
    }

    /**
     * Initializes a new instance of the `SRVersion` class using the specified major, minor, build and revision values.
     *
     * @param major an `NSInteger` representing the major component of a version
     * @param minor an `NSInteger` representing the minior component of a version
     * @param build an `NSInteger` representing the build component of a version
     * @param revision an `NSInteger` representing the revision component of a version
     */
    public init(major: UInt, minor: UInt, build: UInt = 0, revision: UInt = 0) {
        self.major = major
        self.minor = minor
        self.build = build
        self.revision = revision
    }

    /**
     * Tries to convert the string representation of a version number to an equivalent `SRVersion` object, and returns a value that indicates whether the conversion succeeded.
     *
     * @param input an `NSString` representing an `SRVersion` to convert
     * @param version the parsed `SRVersion` object
     *
     * @return a bool representing the sucess of the parse
     */
    static func parse(from input: String) -> SRVersion? {

        guard !input.isEmpty else {
            return nil
        }

        let components = input.components(separatedBy: ".")
        guard components.count >= 2 && components.count <= 4 else {
            return nil
        }

        var major: UInt = 0
        var minor : UInt = 0
        var build : UInt = 0
        var revision : UInt = 0

        for (index, component) in components.enumerated() {
            switch (index) {
            case 0:
                major = UInt(component) ?? 0
            case 1:
                minor = UInt(component) ?? 0
            case 2:
                build = UInt(component) ?? 0
            case 3:
                revision = UInt(component) ?? 0
            default:
                break
            }
        }

        return SRVersion(major: major, minor: minor, build: build, revision: revision)
    }

    public static func ==(lhs: SRVersion, rhs: SRVersion) -> Bool {

//        if lhs === rhs {
//            return true
//        }

        return lhs.major == rhs.major
                && lhs.minor == rhs.minor
                && lhs.build == rhs.build
                && lhs.revision == rhs.revision
    }
}