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

public final class SRStatistics {

    private static var statsInvoke = [String: Int]()
    private static var statsCounter = 0

    /* Set to true to enable statistics. */
    public static var useStatistic = false

    class func trackInvoke(onHub: String, forMethod: String) {
        let key = onHub + "." + forMethod
        let count = SRStatistics.statsInvoke[key] ?? 0
        SRStatistics.statsInvoke[key] = count + 1
        SRStatistics.statsCounter += 1
    }

    class func printStats() {

        /* Don't flood the console. */
        guard SRStatistics.statsCounter % 50 == 0 else {
            return
        }

        let keys = SRStatistics.statsInvoke.sorted(by: { $0.value > $1.value })
        var stats = "=== SignalR Hub invoke stats ===\n"
        for k in keys {
            stats = stats + "\(k)\n"
        }

        stats = stats + "---"
        SRLogInfo(stats)
    }
}

/**
 * An `SRHubProxy` object provides support for SignalR Hubs
 */
class SRHubProxy: SRHubProxyInterface {

    private let connection: SRHubConnectionInterface
    private let hubName: String

    private var subscriptions = [String : SRSubscription]()

    /**
     * If we receive a a invoke event from the remote but do not have a subscription we log a warning. Use this array to
     * to silence this warning for event you would like to ignore.
     */
    private var ignoreRemoteInvokesSet =  Set<String>()

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

    var connectionState: ConnectionState { get { return self.connection.state } }

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

    public func ignoreRemoveInvoke(for eventName: String) {
        self.ignoreRemoteInvokesSet.insert(eventName)
    }

    public func unignoreRemoveInvoke(for eventName: String) -> Bool {
        return self.ignoreRemoteInvokesSet.remove(eventName) != nil

    }

    /* --- Subscription Management --- */
    public func on(_ eventName: String, handler block: @escaping ([Any]?) -> ()) {

        if self.subscriptions[eventName] != nil {
            SRLogWarn("HubProxy already has a subscription for \(eventName), overwriting with new block")
        }

        let subscription = SRSubscription(block: block)
        self.subscriptions[eventName] = subscription
    }

    /* --- Publish --- */

    public func invoke(_ method: String, withArgs args: [Any]?, completionHandler block:((Any?, NSError?) -> ())? = nil) {
        let callbackId = self.connection.registerCallback(url: method) { (result: SRHubResult) in
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


        /* Track the call in the statistics. */
        if SRStatistics.useStatistic {
            SRStatistics.trackInvoke(onHub: hubName, forMethod: method)
            SRStatistics.printStats()
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
        } else if self.ignoreRemoteInvokesSet.contains(eventName) {
            SRLogDebug("Do not now a subscription for eventName: \(eventName) with args \(String(describing: args)) but it is mark as ignore.")
        } else {
            /* Only log fully when running on debug. */
            SRLogWarn("Do not now a subscription for eventName: \(eventName)")
        }
    }
}
