//
//  LongPollingTransport.swift
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
//  Created by Stefan Kerkewitz on 03/03/2017.
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
import Alamofire

/**
 * Long polling does not create a persistent connection, but instead polls the server with a request that stays open
 * until the server responds, at which point the connection closes, and a new connection is requested immediately.
 * This may introduce some latency while the connection resets.
 */
final class SRLongPollingTransport: SRHttpBasedTransport {

    /**
     * The time to wait after a connection drops to try reconnecting.
     *
     * By default, this is 5 seconds
     */
    let reconnectDelay: TimeInterval = 5.0

    /**
     * The time to wait after an error happens to continue polling.
     *
     * By default, this is 2 seconds
     */
    let errorDelay: TimeInterval = 2.0

    var pollingOperationQueue: OperationQueue

    init() {
        self.pollingOperationQueue = OperationQueue()
        self.pollingOperationQueue.maxConcurrentOperationCount = 1
        super.init(name: "longPolling", supportsKeepAlive: false)
    }

    override func negotiate(_ connection: SRConnectionInterface, connectionData: String, completionHandler block: @escaping (SRNegotiationResponse?, NSError?) -> ()) {
        SRLogDebug("longPolling will negotiate")
        super.negotiate(connection, connectionData: connectionData, completionHandler: block)
    }

    override func start(_ connection: SRConnectionInterface, connectionData: String, completionHandler block: ((Any?, NSError?) -> ())?) {
        SRLogDebug("longPolling will connect with connectionData \(connectionData)")
        self.poll(connection, connectionData: connectionData, completionHandler: block)
    }

    override func send(_ connection: SRConnectionInterface, data: String, connectionData: String, completionHandler block: ((Any?, NSError?) -> ())?) {
        SRLogDebug("longPolling will send data \(data)")
        super.send(connection, data: data, connectionData: connectionData, completionHandler: block)
    }

    override func abort(_ connection: SRConnectionInterface, timeout: TimeInterval, connectionData: String) {
        SRLogDebug("longPolling will abort");
        super.abort(connection, timeout: timeout, connectionData: connectionData)
    }

    override func lostConnection(_ connection: SRConnectionInterface) {
        SRLogDebug("longPolling  lost connection");
    }


    func poll(_ connection: SRConnectionInterface, connectionData: String, completionHandler block:((Any?, NSError?) -> ())?) {

        let url: String
        if (connection.messageId == nil) {
            url = connection.url + "connect"
        } else if self.isConnectionReconnecting(connection) {
            url = connection.url + "reconnect"
        } else {
            url = connection.url + "poll"
        }

        var canReconnect = true
        self.delayConnectionReconnect(connection, canReconnect:&canReconnect)

        var parameters: [String: String] = [
                "transport": self.name,
                "connectionToken": connection.connectionToken ?? "",
                "messageId": connection.messageId ?? "",
                "groupsToken": connection.groupsToken ?? "",
                "connectionData": connectionData
        ]

        /* Forward query strings. */
        for key in connection.queryString.keys {
            parameters[key] = connection.queryString[key]!
        }

        let dataRequest = Alamofire.request(url, method: .get, parameters: parameters)
        SRLogDebug("longPolling will connect at url: \(dataRequest.request!.url!.absoluteString)")
        dataRequest.responseString { response in

            SRLogDebug("longPolling did receive: \(response.value!)")

            var shouldReconnect = false
            var disconnectedReceived = false

            if let error = response.error as NSError? {
                SRLogError("longPolling did fail with error \(error)")
                canReconnect = false

                // Transition into reconnecting state
                _ = SRConnection.ensureReconnecting(connection)

                if !self.tryCompleteAbort() && !SRExceptionHelper.isRequestAborted(error) {
                    connection.didReceive(error: error)
                    SRLogDebug("will poll again in \(self.errorDelay) seconds")
                    canReconnect = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + self.errorDelay) { [weak self] in
                        self?.poll(connection, connectionData: connectionData, completionHandler: nil)
                    }
                } else {
                    self.completeAbort()
                    block?(nil, error);
                }

                /* Stop here. */
                return
            }

            connection.process(response: response.value!, shouldReconnect:&shouldReconnect, disconnected:&disconnectedReceived)
            block?(nil, nil);

            if self.isConnectionReconnecting(connection) {
                // If the timeout for the reconnect hasn't fired as yet just fire the
                // event here before any incoming messages are processed
                SRLogWarn("reconnecting");
                canReconnect = self.connectionReconnect(connection)
            }

            if (shouldReconnect) {
                // Transition into reconnecting state
                SRLogDebug("longPolling did receive shouldReconnect command from server")
                SRConnection.ensureReconnecting(connection)
            }

            if (disconnectedReceived) {
                SRLogDebug("longPolling did receive disconnect command from server")
                connection.disconnect()
            }

            if !self.tryCompleteAbort() {
                //Abort has not been called so continue polling...
                canReconnect = true
                self.poll(connection, connectionData:connectionData, completionHandler:nil)
            } else {
                SRLogWarn("longPolling has shutdown due to abort")
            }
        }
    }

    func delayConnectionReconnect(_ connection: SRConnectionInterface, canReconnect: inout Bool) {
        if self.isConnectionReconnecting(connection) {
            SRLogWarn("will reconnect in \(self.reconnectDelay)")
            DispatchQueue.main.asyncAfter(deadline: .now() + self.reconnectDelay) { [weak self] in
                SRLogWarn("reconnecting")
                self?.connectionReconnect(connection)
                //canReconnect = self?.connectionReconnect(connection) ?? false
            }
        }
    }
    
    @discardableResult
    func connectionReconnect(_ connection: SRConnectionInterface) -> Bool {
        // Mark the connection as connected
        if connection.changeState(.reconnecting, toState:.connected) {
            connection.didReconnect()
        }

        return false
    }

    func isConnectionReconnecting(_ connection: SRConnectionInterface) -> Bool {
        return connection.state == .reconnecting;
    }
}


class SRExceptionHelper {
    class func isRequestAborted(_ error: NSError) -> Bool {
        return error.code == NSURLErrorCancelled
    }
}



