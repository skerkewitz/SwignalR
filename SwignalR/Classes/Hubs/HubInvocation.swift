//
//  HubInvocation.swift
//  SignalR
//
//  Created by Alex Billingsley on 11/7/11.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
//  Created by Stefan Kerkewitz on 28/02/2017.
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
 * An `SRHubInvocation` object defines the interface for invoking methods on the SignalR Client using a Hubs
 * implementation
 */
internal struct SRHubInvocation: SRDeserializable, SRSerializable {

    static let kCallbackId = "I"
    static let kHub = "H"
    static let kMethod = "M"
    static let kArgs = "A"
    static let kState = "S"

    let callbackId: String?

    /** The `NSString` object corresponding to the hub to preform an invocation on */
    let hub: String

    /** The `NSString` object corresponding to the method to invoke on the hub */
    let method: String

    /** The `NSMutableArray` object corresponding to the arguments to be passed as part of the invocation */
    let args: [Any]?

    /** The `NSMutableDictionary` object corresponding to the client state */
    let state: [String:Any]?

    init(name: String, method: String, args: [Any]?, callbackId: String, state: [String: Any]) {
        self.hub = name
        self.method = method
        self.args = args
        self.callbackId = callbackId
        self.state = state
    }

    init(dictionary dict: [String: Any]) {
        self.callbackId = dict[SRHubInvocation.kCallbackId] as? String
        self.hub = dict[SRHubInvocation.kHub] as! String
        self.method = dict[SRHubInvocation.kMethod] as! String
        self.args = dict[SRHubInvocation.kArgs] as? [Any]
        self.state = dict[SRHubInvocation.kState] as? [String:Any]
    }

    func proxyForJson() -> [String: Any] {
        var dict = [String: Any]()
        dict[SRHubInvocation.kCallbackId] = self.callbackId
        dict[SRHubInvocation.kHub] = self.hub
        dict[SRHubInvocation.kMethod] = self.method
        dict[SRHubInvocation.kArgs] = self.args
        dict[SRHubInvocation.kState] = self.state
        return dict
    }
}

