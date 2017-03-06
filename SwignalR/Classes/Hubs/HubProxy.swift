//
//  HubProxy.swift
//  SignalR
//
//  Created by Alex Billingsley on 10/31/11.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
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
 * An `SRHubProxy` object provides support for SignalR Hubs
 */
class SRHubProxy: SRHubProxyInterface {

    private let connection: SRHubConnectionInterface
    private let hubName: String

    private var subscriptions = [String : SRSubscription]()

    /**
     * The client proxy provides a state object in which you can store data that you want to be transmitted to the
     * server with each method call. On the server you can access this data in the Clients. Caller property in Hub
     * methods that are called by clients.
     *
     * The property is not populated for the connection lifetime event handler methods OnConnected, OnDisconnected,
     * and OnReconnected.
     *
     * You can update values in the server and they are passed back to the client.
     */
    var state = [String : Any]()


    /**
     * Initializes a new `SRHubProxy` object with the specified `SRConnection` and hubname
     *
     * @warning *Important* the hubname needs to be the full type name of the hub.
     *
     * @param connection the connection to initialize the hub on
     * @param hubname an `NSString` representing the hubname
     * @return an `SRHubProxy` object
     */
    init(connection: SRHubConnectionInterface, hubName: String) {
        self.connection = connection
        self.hubName = hubName
    }

    /* --- Subscription Management --- */

    public func on(_ eventName: String, handler block: @escaping ([Any]?) -> ()) {

        if let subscription = self.subscriptions[eventName] {
            SRLogWarn("HubProxy already has a subscription for \(eventName), overwriting with new block")
        }

        let subscription = SRSubscription(block: block)
        self.subscriptions[eventName] = subscription
    }

    /* --- Publish --- */

    public func invoke(_ method: String, withArgs args: [Any]?, completionHandler block:((Any?, NSError?) -> ())? = nil) {

        let callbackId = self.connection.registerCallback() { (result: SRHubResult) in
            if let strError = result.error {
                let userInfo: [AnyHashable: Any] = [
                    NSLocalizedFailureReasonErrorKey : NSExceptionName.internalInconsistencyException,
                    NSLocalizedDescriptionKey : "\(strError)"
                ]
                let localizedString = NSLocalizedString("com.SignalR.SignalR-ObjC." + String(describing: self), comment: "")
                let error = NSError(domain: localizedString, code:0, userInfo: userInfo)
                self.connection.didReceive(error: error)
                block?(nil, error);
            } else {
                if let state = result.state {
                    for key in state.keys {
                        self.state[key] = state[key]
                    }
                }

                /* Forward the result which my be nil. */
                block?(result.result, nil);
            }
        }
        
        let hubInvocation = SRHubInvocation(name: self.hubName, method: method, args: args, callbackId: callbackId, state: self.state)
        self.connection.send(hubInvocation, completionHandler: block)
    }

    /**
     * Invokes the `SRSubscription` object that corresponds to eventName
     *
     * @param eventName the `NSString` object representing the name of the subscription event
     * @param args the arguments to pass as part of the invocation
     */
    internal func invokeEvent(_ eventName: String, withArgs args: [Any]?) {
        if let eventObj = self.subscriptions[eventName] {
            eventObj.handler(args);
        } else {
            SRLogError("Do not now a subscription for eventName: \(eventName)")
        }
    }
}
