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

@objc public class SRVersion: NSObject {


    /** The value of the build component of the version number for the current `SRVersion` object. */
    public var build: Int = 0

    /** The value of the major component of the version number for the current `SRVersion` object. */
    public var major: Int = 0

    /** The value of the majorRevision component of the version number for the current `SRVersion` object. */
    public var majorRevision: Int = 0

    /** The value of the minor component of the version number for the current `SRVersion` object. */
    public var minor: Int = 0

    /** The value of the minorRevision component of the version number for the current `SRVersion` object. */
    public var minorRevision: Int = 0

    /** The value of the revision component of the version number for the current `SRVersion` object. */
    public var revision: Int = 0

    public override var description : String {
        return "\(self.major),\(self.minor),\(self.build),\(self.revision)"
    }

    /**
     * Initializes a new instance of the `SRVersion` class using the specified major and minor values.
     *
     * @param major an `NSInteger` representing the major component of a version
     * @param minor an `NSInteger` representing the minior component of a version
     */
    public init(major: Int, minor: Int) {
        super.init()
        self.major = major;
        self.minor = minor;

        if self.major < 0 || self.minor < 0 {
            fatalError(NSLocalizedString("Component cannot be less than 0", comment: "NSInvalidArgumentException"))
        }
    }

    /**
     * Initializes a new instance of the `SRVersion` class using the specified major, minor, and build values.
     *
     * @param major an `NSInteger` representing the major component of a version
     * @param minor an `NSInteger` representing the minior component of a version
     * @param build an `NSInteger` representing the build component of a version
     */
    convenience public init(major: Int, minor: Int, build: Int) {
        self.init(major: major, minor: minor)

        self.build = build;

        if self.build < 0 {
            fatalError(NSLocalizedString("Component cannot be less than 0", comment: "NSInvalidArgumentException"))
        }
    }

    /**
     * Initializes a new instance of the `SRVersion` class using the specified major, minor, build and revision values.
     *
     * @param major an `NSInteger` representing the major component of a version
     * @param minor an `NSInteger` representing the minior component of a version
     * @param build an `NSInteger` representing the build component of a version
     * @param revision an `NSInteger` representing the revision component of a version
     */
    convenience public init(major: Int, minor: Int, build: Int, revision: Int) {
        self.init(major: major, minor: minor, build: build)

        self.revision = revision
        if self.revision < 0 {
            fatalError(NSLocalizedString("Component cannot be less than 0", comment: "NSInvalidArgumentException"))
        }
    }

    /**
     * Tries to convert the string representation of a version number to an equivalent `SRVersion` object, and returns a value that indicates whether the conversion succeeded.
     *
     * @param input an `NSString` representing an `SRVersion` to convert
     * @param version the parsed `SRVersion` object
     *
     * @return a bool representing the sucess of the parse
     */
    class func tryParse(input: String!, forVersion: inout SRVersion) -> Bool {
        var success = true
//
//        if input == nil || input.isEmpty {
//            return false
//        }
//
//        NSArray *components = [input componentsSeparatedByString:@"."];
//        if ([components count]
//
//< 2 || [components count] > 4) {
//
//return NO;
//}
//
//SRVersion *temp = [[SRVersion alloc] init];
//for (int i = 0; i < [components count]; i++) {
//    switch (i) {
//    case 0:
//        temp.major = [components[0] integerValue];
//        break;
//    case 1:
//        temp.minor = [components[1] integerValue];
//        break;
//    case 2:
//        temp.build = [components[2] integerValue];
//        break;
//    case 3:
//        temp.revision = [components[3] integerValue];
//        break;
//    default:
//        break;
//    }
//}
//*version = temp;

        return success;
    }

    func isEqual(object: Any) -> Bool {

        if let other = object as? SRVersion {

            if self == other {
                return true
            }

            return self.major == other.major
                    && self.minor == other.minor
                    && self.build == other.build
                    && self.revision == other.revision
        }

        return false
    }


}