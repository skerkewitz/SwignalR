//
//  WebSocketTransport.swift
//  SignalR
//
//  Created by Alex Billingsley on 4/8/13.
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
import Starscream
import Alamofire

typealias SRWebSocketStartBlock = (Any?, NSError?) -> ()

fileprivate struct SRWebSocketConnectionInfo {

    let connection: SRConnectionInterface
    let data: String

    public init(connection: SRConnectionInterface, data: String) {
        self.connection = connection
        self.data = data
    }
}

final public class SRWebSocketTransport : SRHttpBasedTransport {

    /** TimeInterval in seconds to wait before reconnecting. */
    private let reconnectDelay: TimeInterval = 2.0

    // inherited from base

    internal var webSocket: WebSocket? = nil
    fileprivate var connectionInfo: SRWebSocketConnectionInfo? = nil

    /** This is used to store the initial connect block so we can call it in case of an time out. */
    internal var startBlock: SRWebSocketStartBlock? = nil
    internal var connectTimeoutOperation: BlockOperation? = nil

    public init() {
        super.init(name: "webSockets", supportsKeepAlive: true)
    }

    
    public override func negotiate(_ connection: SRConnectionInterface, connectionData: String, completionHandler block: @escaping ((SRNegotiationResponse?, NSError?) -> ())) {
        SRLogDebug("WebSocket will negotiate");
        super.negotiate(connection, connectionData: connectionData, completionHandler: block)
    }


    public override func start(_ connection: SRConnectionInterface, connectionData: String, completionHandler block: ((Any?, NSError?) -> ())?) {
        SRLogDebug("WebSocket will connect with connectionData \(connectionData)")
        self.connectionInfo = SRWebSocketConnectionInfo(connection: connection, data: connectionData)
        self.performConnect(block: block)
    }

    public override func send(_ connection: SRConnectionInterface, data: String, connectionData: String, completionHandler block: ((Any?, NSError?) -> ())?) {
        SRLogDebug("Will send data on WebSocket \(data)")

        if let socket = webSocket, socket.isConnected {
            socket.write(string: data)
        } else {
            let userInfo = [
                    NSLocalizedDescriptionKey: NSLocalizedString("WebSocket is not connected", comment: ""),
                    NSLocalizedFailureReasonErrorKey: NSLocalizedString("Data could not be send as WebSocket is currently not connected.", comment: ""),
                    NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Retry or switch transports.", comment: "")
            ]

            let notConnected = NSError(domain: NSLocalizedString("com.SignalR.SignalR-ObjC." + String(describing: self), comment: ""), code: NSURLErrorNetworkConnectionLost, userInfo: userInfo)
            block?(nil, notConnected)
        }
    }


    public override func abort(_ connection: SRConnectionInterface, timeout: TimeInterval, connectionData: String) {
        SRLogWarn("Abort, will close WebSocket")
        self.stopWebsocket()
        super.abort(connection, timeout: timeout, connectionData: connectionData)
    }

    public override func lostConnection(_ connection: SRConnectionInterface) {
        SRLogWarn("Lost connection, closing WebSocket")
        self.stopWebsocket()

        if self.tryCompleteAbort() {
            return
        }

        self.reconnect(connection)
    }

    func stopWebsocket() {
        self.webSocket!.delegate = nil
        self.webSocket!.disconnect()
        self.webSocket = nil
    }


    /* --- Websockets Transport --- */

    func performConnect(reconnecting: Bool = false, block: ((Any?, NSError?) -> ())?) {

        guard let connectionInfo = self.connectionInfo else {
            fatalError("Do not have a valid connection info.")
        }

        /* Build parameter map. */
        let connection = connectionInfo.connection
        var parameters: [String: String] = [
                "transport": self.name,
                "connectionToken": connection.connectionToken ?? "",
                "messageId": connection.messageId ?? "",
                "groupsToken": connection.groupsToken ?? "",
                "connectionData": connectionInfo.data
        ]

        /* Forward query strings. */
        for key in connection.queryString.keys {
            parameters[key] = connection.queryString[key]!
        }

        /* Create url request. */
        let urlString: String = connection.url + (reconnecting ? "reconnect" : "connect")
        var request = Alamofire.request(urlString, method: .get, parameters: parameters).request!

        connection.prepare(request: &request) //TODO: prepareRequest

        SRLogDebug("WebSocket will connect to url: \(request.url!.absoluteString)")

        self.startBlock = block
        if self.startBlock != nil {
            self.connectTimeoutOperation = BlockOperation(block: { [weak self] in
                guard let strongSelf = self else {
                    return
                }

                if (strongSelf.startBlock != nil) {
                    let userInfo = [
                            NSLocalizedDescriptionKey: NSLocalizedString("Connection timed out.", comment: ""),
                            NSLocalizedFailureReasonErrorKey: NSLocalizedString("Connection did not receive initialized message before the timeout.", comment: ""),
                            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Retry or switch transports.", comment: "")
                    ]

                    let timeout = NSError(domain: NSLocalizedString("com.SignalR.SignalR-ObjC." + String(describing: strongSelf), comment: ""), code: NSURLErrorTimedOut, userInfo: userInfo)
                    SRLogError("WebSocket failed to receive initialized message before timeout")
                    strongSelf.stopWebsocket()

                    let callback = strongSelf.startBlock
                    strongSelf.startBlock = nil;
                    callback?(nil, timeout)
                }
            })
            self.connectTimeoutOperation!.perform(#selector(BlockOperation.start), with: nil, afterDelay: connection.transportConnectTimeout)
        }
        self.webSocket = WebSocket(url: request.url!)
        self.webSocket!.delegate = self
        self.webSocket!.connect()
    }


    func reconnect(_ connection: SRConnectionInterface) {
        SRLogDebug("WebSocket will reconnect in \(self.reconnectDelay)")

        DispatchQueue.main.asyncAfter(deadline: .now() + self.reconnectDelay) { [weak self] in
            if SRConnection.ensureReconnecting(connection) {
                SRLogWarn("WebSocket reconnecting...")
                self?.performConnect(reconnecting: true, block: nil)
            }
        }
    }
}

extension SRWebSocketTransport: WebSocketDelegate {

    public func websocketDidConnect(socket: WebSocket) {
        SRLogDebug("WebSocket did open")

        guard let connection = self.connectionInfo?.connection else {
            fatalError("WebSocket did connect but transport has no connectionInfo instance.")
        }

        /* This will noop if we're not in the reconnecting state. */
        if connection.changeState(.reconnecting, toState:.connected) {
            connection.didReconnect()
        }
    }

    public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        SRLogDebug("WebSocket did receive: \(text)")

        var timedOut = false
        var disconnected = false

        guard let connection = self.connectionInfo?.connection else {
            fatalError("WebSocket did receive message but transport has no connectionInfo instance.")
        }

        connection.process(response: text, shouldReconnect:&timedOut, disconnected:&disconnected)
        if self.startBlock != nil {
            NSObject.cancelPreviousPerformRequests(withTarget: self.connectTimeoutOperation, selector:#selector(BlockOperation.start), object:nil)
            self.connectTimeoutOperation = nil

            let callback = self.startBlock
            self.startBlock = nil
            callback?(nil, nil);
        }

        /* Server requested disconnect. */
        if disconnected {
            SRLogWarn("WebSocket did receive disconnect command from server, will close")
            connection.disconnect()
            self.stopWebsocket()
        }
    }

    public func websocketDidReceiveData(socket: WebSocket, data: Data) {
        fatalError("Data not supported")
    }


    public func webSocket(_ webSocket: WebSocket, didFailWithError error: NSError) {

        guard let connection = self.connectionInfo?.connection else {
            fatalError("WebSocket did receive error but transport has no connectionInfo instance.")
        }

        SRLogError("WebSocket did fail with error \(connection.connectionId) \(error)")

        if let callback = self.startBlock {
            SRLogError("WebSocket did fail while connecting");
            NSObject.cancelPreviousPerformRequests(withTarget: self.connectTimeoutOperation, selector:#selector(BlockOperation.start), object:nil)
            self.connectTimeoutOperation = nil

            self.startBlock = nil
            callback(nil, error);
        } else if connection.state == .reconnecting {
            SRLogWarn("transport already reconnecting, ignoring error...")
        } else if self.startedAbort == false {
            SRLogWarn("transport will reconnect from errors: \(error)")
            self.reconnect(connection)
        }
    }

    public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if let error = error {
            SRLogError("WebSocket did close with with error: \(error)")
            self.webSocket(socket, didFailWithError: error)
            return
        } else {
            SRLogWarn("WebSocket did close cleanly.")
        }

        if self.tryCompleteAbort() {
            return
        }

        guard let connection = self.connectionInfo?.connection else {
            fatalError("WebSocket did disconnect but transport has no connectionInfo instance.")
        }

        self.reconnect(connection)
    }
}

