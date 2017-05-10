//
//  AutoTransport.swift
//  SignalR
//
//  Created by Alex Billingsley on 1/15/12.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
//  Created by Stefan Kerkewitz on 06/03/2017.
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
 * `SRAutoTransport` object provides support for choosing the best transport for the client
 *
 * ## Fallback order
 * 1. Websockets SRWebSocketTransport
 * 2. Server-Sent Events SRServerSentEventsTransport (not implemented yet)
 * 3. Long Polling SRLongPollingTransport
 */
final public class SRAutoTransport: SRHttpBasedTransport {

    /** List of all known transport implementations in fallback order. */
    public var transports: [SRClientTransportInterface]

    /** The current used transport implementation. */
    public var transport: SRClientTransportInterface? = nil

    public convenience init() {
        let transports = [SRWebSocketTransport(), SRLongPollingTransport()]
        self.init(withTransports: transports)
    }

    public init(withTransports transports: [SRClientTransportInterface]) {
        self.transports = transports
        super.init(name: "auto", supportsKeepAlive: false)
    }

    public override var name: String {
        get { return self.transport?.name ?? super.name }
    }

    public override var supportsKeepAlive: Bool {
        get { return self.transport?.supportsKeepAlive ?? super.supportsKeepAlive }
    }

    public override func negotiate(_ connection: SRConnectionInterface, connectionData: String, completionHandler block: @escaping (SRNegotiationResponse?, NSError?) -> ()) {
        SRLogDebug("autoTransport will negotiate");
        super.negotiate(connection, connectionData: connectionData) { (negotiationResponse, error) in
            if let error = error {
                SRLogWarn("Negotiate failed, trying next transport. Reason was \(error)")
                if let tryWebSockets = negotiationResponse?.tryWebSockets, tryWebSockets == false {
                    SRLogWarn("server does not support websockets");
                    if let index = self.transports.index(where: { $0.name == "webSockets" }) {
                        self.transports.remove(at: index)
                    }
                }
            }

            block(negotiationResponse, error);
        }
    }

    public override func start(_ connection: SRConnectionInterface, connectionData: String, completionHandler block: ((Any?, NSError?) -> ())?) {
        SRLogDebug("autoTransport will connect with connectionData \(connectionData)")
        self.start(connection, connectionData:connectionData, transportIndex:0, completionHandler:block)
    }

    func start(_ connection: SRConnectionInterface, connectionData: String, transportIndex index: Int, completionHandler block: ((Any?, NSError?) -> ())?) {
        let transport = self.transports[index]
        SRLogDebug("autoTransport will attempt to start \(transport.name)")
        transport.start(connection, connectionData: connectionData) { (response, error) in

            if let error = error {
                SRLogWarn("Error on start, will switch to next transport. Error was: \(error)")

                // If that transport fails to initialize then fallback
                let nextIndex = index + 1
                if nextIndex < self.transports.count {
                    // Try the next transport
                    self.start(connection, connectionData:connectionData, transportIndex:nextIndex, completionHandler:block)
                } else {
                    // If there's nothing else to try then just fail
                    let userInfo: [AnyHashable:Any] = [
                        NSLocalizedFailureReasonErrorKey : NSExceptionName.internalInconsistencyException,
                        NSLocalizedDescriptionKey : NSLocalizedString("No transport could be initialized successfully. Try specifying a different transport or none at all for auto initialization.", comment: "")
                    ]
                    let error = NSError(domain: NSLocalizedString("com.SignalR.SignalR-ObjC." + String(describing: self), comment: ""), code:0, userInfo:userInfo)
                    SRLogError("autoTransport failed to initialize a transport");
                    block?(nil, error);
                }

                return
            }

            /* Set the active transport. */
            self.transport = transport
            SRLogInfo("Did set active SignalR transport to \(self.transport!.name)")
            block?(nil, nil)
        }
    }

    public override func send(_ connection: SRConnectionInterface, data: String, connectionData: String, completionHandler block: ((Any?, NSError?) -> ())?) {
        if let transport = self.transport {
            transport.send(connection, data: data, connectionData: connectionData, completionHandler: block)
        } else {
            SRLogError("Can not send data, no transport selected. Skipping...")
        }
    }

    public override func abort(_ connection: SRConnectionInterface, timeout: TimeInterval, connectionData: String) {
        SRLogDebug("autoTransport will abort")
        super.abort(connection, timeout: timeout, connectionData: connectionData)
    }

    public override func lostConnection(_ connection: SRConnectionInterface) {
        SRLogWarn("autoTransport lost connection")
        super.lostConnection(connection)
    }
}
