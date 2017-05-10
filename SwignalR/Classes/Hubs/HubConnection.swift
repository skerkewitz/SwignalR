//
//  HubConnection.swift
//  SignalR
//
//  Created by Alex Billingsley on 10/31/11.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
//  Created by Stefan Kerkewitz on 01/03/2017.
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
 * An `SRHubConnection` object provides an abstraction over `SRConnection` and provides support for publishing and subscribing to custom events
 */
public class SRHubConnection: SRConnection, SRHubConnectionInterface {

    private struct CallbackData {
        let id: Int
        let url: String
        let block: SRHubConnectionHubResultBlock
        let timestamp = Int(Date().timeIntervalSince1970)
    }


    private var hubs = [String: SRHubProxy]()

    private var callbacks = [String : CallbackData]()

    private var callbackId: Int = 1

    /* --- Initialization --- */

    public init(urlString url: String, useDefault: Bool = true) {
        super.init(urlString: SRHubConnection.getUrl(URL: url, useDefault: useDefault))
    }

    public init(urlString url: String, queryString: [String: String], useDefault: Bool = true) {
        super.init(urlString: SRHubConnection.getUrl(URL: url, useDefault: useDefault), queryString: queryString)
    }

    /**
     * Creates a client side proxy to the hub on the server side.
     *
     * <code>
     *  SRHubProxy *myHub = [connection createProxy:@"MySite.MyHub"];
     * </code>
     * @warning *Important:* The name of this hub needs to be the full type name of the hub.
     *
     * @param hubName hubName the name of the hub
     * @return SRHubProxy object
     */
    public func createHubProxy(_ hubName: String) -> SRHubProxyInterface {
        if self.state != .disconnected {
            fatalError(NSLocalizedString("Proxies cannot be added after the connection has been started.", comment: "NSInternalInconsistencyException"))
        }

        SRLogDebug("will create proxy \(hubName)")

        let name = hubName.lowercased()
        if let hubProxy = self.hubs[name] {
            return hubProxy
        }

        let hubProxy = SRHubProxy(connection: self, hubName: name)
        self.hubs[name] = hubProxy;
        return hubProxy;
    }

    public func registerCallback(url: String, callback: @escaping SRHubConnectionHubResultBlock) -> String {
        let newId = "\(callbackId)"
        self.callbacks[newId] = CallbackData(id: callbackId, url: url, block: callback)
        self.callbackId += 1

        /* Check for old hanging calls. */
        if self.callbackId % 10 == 0 {
            let now = Int(Date().timeIntervalSince1970)
            let threshold = 30

            self.callbacks.values.forEach { value in
                if value.timestamp + threshold < now {
                    SRLogWarn("Hanging call for \(value.id) \(value.url), elapsed time \(value.timestamp - now) seconds)")
                }
            }
        }
        
        return newId
    }

    class func getUrl(URL: String, useDefault: Bool) -> String {
        var _url = URL
        if URL.hasSuffix("/") == false {
            _url = URL + "/"
        }

        if (useDefault) {
            return _url + "signalr"
        }

        return _url;
    }

    /* --- Sending data --- */

    public override func onSending() -> String? {

        var dataArray = [[String: Any]]()
        for key in self.hubs.keys {
            let registration = SRHubRegistrationData(name: key)
            dataArray.append(registration.proxyForJson())
        }

        let data = try? JSONSerialization.data(withJSONObject: dataArray)
        return String(data: data!, encoding: .utf8)!
    }

    /* --- Received Data --- */
    public override func didReceiveData(_ data: Any) {
        if let data = data as? [String: Any] {
            if data["I"] != nil {
                let result = SRHubResult(dictionary: data)
                self.invokeCallback(with: result)
            } else {
                let invocation = SRHubInvocation(dictionary: data)
                if let hubProxy = self.hubs[invocation.hub.lowercased()] {
                    if let state = invocation.state, state.count > 0 {
                        for key in state.keys {
                            hubProxy.state[key] = state[key]
                        }
                    }
                    hubProxy.invokeEvent(invocation.method, withArgs:invocation.args)
                }

                super.didReceiveData(data)
            }
        }
    }

    public override func willReconnect() {
        self.clearInvocationCallbacks(errorMessage: "Connection started reconnecting before invocation result was received.")
        super.willReconnect()
    }

    private func invokeCallback(with result: SRHubResult) {
        /* Remove the callback and invoke the callback block. */
        if let idKey = result.id, let callback = self.callbacks.removeValue(forKey: idKey) {
            callback.block(result)
        }
    }

    private func clearInvocationCallbacks(errorMessage error: String) {
        let hubErrorResult = SRHubResult(error: error)
        for callback in self.callbacks.values {
            callback.block(hubErrorResult);
        }

        self.callbacks.removeAll()
    }

    public override func didClose() {
        self.clearInvocationCallbacks(errorMessage: "Connection was disconnected before invocation result was received.")
        super.didClose()
    }
}
