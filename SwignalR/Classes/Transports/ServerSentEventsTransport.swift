//
//  ServerSentEventsTransport.swift
//  SignalR
//
//  Created by Alex Billingsley on 1/7/12.
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
//
//import Foundation
//import CocoaLumberjack
//
//public typealias SRCompletionHandler = (Any?, NSError?) -> ()
//
//@objc public class SRServerSentEventsTransport: SRHttpBasedTransport {
//
//    /**
//     * Returns an `NSInteger` object with the time to wait after a connection drops to try reconnecting.
//     *
//     * By default, this is 2 seconds
//     */
//    public var reconnectDelay: NSNumber = NSNumber(value: 2)
//
//    public var stop: Bool
//    public var eventSource: SREventSourceStreamReader
//    public var serverSentEventsOperationQueue: OperationQueue
//    public var completionHandler: SRCompletionHandler?
//    public var connectTimeoutOperation: BlockOperation
//
//    public override init() {
//        self.serverSentEventsOperationQueue = OperationQueue()
//        self.serverSentEventsOperationQueue.maxConcurrentOperationCount = 1
//        super.init()
//    }
//
//    /* --- SRClientTransportInterface --- */
//
//    override public var name: String {
//        get {
//            return "serverSentEvents"
//        }
//    }
//    override public var supportsKeepAlive: Bool {
//        get {
//            return true
//        }
//    }
//
//    public override func negotiate(_ connection: SRConnectionInterface, connectionData: String, completionHandler block: @escaping ((SRNegotiationResponse, NSError?) -> ())) {
//        DDLogDebug("ServerSentEvents will negotiate");
//        super.negotiate(connection, connectionData: connectionData, completionHandler: block)
//    }
//
//
//    public override func start(_ connection: SRConnectionInterface, connectionData: String, completionHandler block: ((Any?, NSError?) -> ())!) {
//        DDLogDebug("ServerSentEvents will connect with connectionData \(connectionData)")
//        self.completionHandler = block;
//
//        self.connectTimeoutOperation = BlockOperation(block: { [weak self] in
//            guard let strongSelf = self else {
//                return
//            }
//
//            if self?.completionHandler != nil {
//                let userInfo: [AnyHashable : Any] = [
//                    NSLocalizedDescriptionKey: NSLocalizedString("Connection timed out.", comment: ""),
//                    NSLocalizedFailureReasonErrorKey: NSLocalizedString("Connection did not receive initialized message before the timeout.", comment: ""),
//                    NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Retry or switch transports.", comment: "")
//                ]
//
//                let timeout = NSError(domain: NSLocalizedString("com.SignalR.SignalR-ObjC." + String(describing: self), comment: ""), code:NSURLErrorTimedOut, userInfo:userInfo)
//                DDLogError("ServerSentEvents failed to receive initialized message before timeout")
//                strongSelf.completionHandler?(nil, timeout);
//                strongSelf.completionHandler = nil;
//            }
//        })
//        self.connectTimeoutOperation.perform(#selector(start), with:nil, afterDelay:connection.transportConnectTimeout.doubleValue)
//        self.open(connection, connectionData:connectionData, isReconnecting:false)
//    }
//
//    public override func send(_ connection: SRConnectionInterface, data: String, connectionData: String, completionHandler block: ((Any?, NSError?) -> ())!) {
//        DDLogDebug("ServerSentEvents will send data \(data)")
//        super.send(connection, data: data, connectionData: connectionData, completionHandler: block)
//    }
//
//
//    public override func abort(_ connection: SRConnectionInterface, timeout: NSNumber, connectionData: String) {
//        DDLogDebug("ServerSentEvents will abort")
//        self.stop = true
//        self.serverSentEventsOperationQueue.cancelAllOperations() // this will enqueue a failure on run loop
//        super.abort(connection, timeout: timeout, connectionData: connectionData) //we expect this to set stop to YES
//    }
//
//    public override func lostConnection(_ connection: SRConnectionInterface) {
//        DDLogWarn("ServerSentEvents lost connection, cancelling connection")
//        self.serverSentEventsOperationQueue.cancelAllOperations()
//    }
//
//    /* --- SSE Transport --- */
//
//    func open(_ connection: SRConnectionInterface, connectionData: String, isReconnecting: Bool) {
//        var parameters: [String: Any] = [:
//            // SKerkewitz: FIX ME
////            "transport" : self.name,
////            "connectionToken" : (connection.connectionToken) ? connection.connectionToken! : "",
////            "messageId" : (connection.messageId) ? connection.messageId : "",
////            "groupsToken" : (connection.groupsToken) ? connection.groupsToken : "",
////            "connectionData" : (connectionData) ? connectionData : ""
//        ]
//
//        // SKerkewitz: FIX ME
////        if connection.queryString {
////            parameters.append(connection.queryString())
////        }
//
//        let url = isReconnecting ? connection.url + "reconnect" : connection.url + "connect"
//        let serializer = SREventSourceRequestSerializer()
//        let request: NSMutableURLRequest = serializer.request(withMethod:"GET", urlString:url, parameters:parameters, error:nil)
//        connection.prepareRequest(request) //TODO: prepareRequest
//        request.timeoutInterval = 240
//        request.setValue("Keep-Alive", forHTTPHeaderField:"Connection")
//        //TODO: prepareRequest
//
//        DDLogDebug("ServerSentEvents will connect at url: \(request.url!.absoluteString)")
//        let operation = AFHTTPRequestOperation(request: request as URLRequest)
//        operation.setResponseSerializer(SREventSourceResponseSerializer.serializer)
//        //operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
//        //operation.credential = self.credential;
//        //operation.securityPolicy = self.securityPolicy;
//        self.eventSource = SREventSourceStreamReader(stream: operation.outputStream)
//        self.eventSource.opened = { [weak connection] in
//            let strongConnection = connection!
//            DDLogInfo("ServerSentEvents did open eventSource")
//
//            // This will noop if we're not in the reconnecting state
//            if strongConnection.changeState(.reconnecting, toState:.connected) {
//                // Raise the reconnect event if the connection comes back up
//                strongConnection.didReconnect()
//            }
//        }
//
//        self.eventSource.message = { [weak connection, weak self] (sseEvent: SRServerSentEvent) in
//            let strongConnection = connection
//
//            if sseEvent.event == "data" {
//                let data = NSString(data: sseEvent.data, encoding:NSUTF8StringEncoding)
//                DDLogInfo("ServerSentEvents did receive: \(data)")
//                if data.caseInsensitiveCompare("initialized") == .orderedSame {
//                    return;
//                }
//
//                var shouldReconnect = false
//                var disconnect = false
//                self?.processResponse(strongConnection, response:data, shouldReconnect:&shouldReconnect, disconnected:&disconnect)
//                if self?.completionHandler {
//                    NSObject.cancelPreviousPerformRequestsWithTarget(self?.connectTimeoutOperation, selector:#selector(start), object:nil)
//                    self?.connectTimeoutOperation = nil;
//                    self?.completionHandler(nil, nil);
//                    self?.completionHandler = nil;
//                }
//
//                if disconnect {
//                    DDLogDebug("ServerSentEvents did receive disconnect command from server")
//                    self.stop = true
//                    self?.disconnect()
//                }
//            }
//        }
//
//        // server ended without error
//        self.eventSource.closed = { [weak connection, weak self] (exception: NSError) in
//            //__strong __typeof(&*weakSelf)strongSelf = weakSelf;
//            let strongConnection = connection
//
//            DDLogWarn("ServerSentEvents eventSource did close with error \(exception)")
//            if exception != nil {
//                // Check if the request is aborted
//                let isRequestAborted = SRExceptionHelper.isRequestAborted(exception)
//
//                if !isRequestAborted {
//                    // Don't raise exceptions if the request was aborted (connection was stopped).
//                    strongConnection.didReceiveError(exception)
//                }
//            }
//
//            //release eventSource, no other scopes have access, would like to release before
//            //eventSource will be nil for this scope before reconnect can call open, even if
//            //it wasn't doing a timeout first
//            self.eventSource = nil
//
//            if self?.stop {
//                self?.completeAbort()
//            } else if self?.tryCompleteAbort() {
//                // nothing
//            } else {
//                self?.reconnect(strongConnection, data:connectionData)
//            }
//        }
//
//        self.eventSource.start()
//        operation.setCompletionBlockWithSuccess({ (operation: AFHTTPRequestOperation, responseObject: Any) in
//            DDLogWarn("ServerSentEvents did complete")
////            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
////            __strong __typeof(&*weakConnection)strongConnection = weakConnection;
//            if self.stop {
//                self.completeAbort()
//            } else if self.tryCompleteAbort() {
//            } else {
//                self.reconnect(connection, data:connectionData)
//            }
//        }, failure: { (operation: AFHTTPRequestOperation, error: NSError) in
//            DDLogError("ServerSentEvents did fail with error \(error)")
//
//            //a little tough to read, but failure is mutually exclusive to open, message, or closed above
//            //also, you may start in the received above and end up in the failure case
//            //http://cocoadocs.org/docsets/AFNetworking/2.5.4/Classes/AFHTTPRequestOperation.html
//            //we however do close the eventSource below, which will lead us to the above code
////            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
//            if self?.completionHandler { //this is equivalent to the !reconnecting onStartFailed from c#
//                DDLogDebug("ServerSentEvents did fail while connecting")
//                NSObject.cancelPreviousPerformRequestsWithTarget(self.connectTimeoutOperation, selector:#selector(start), object:nil)
//                self.connectTimeoutOperation = nil;
//                self?.completionHandler(nil, error);
//                self?.completionHandler = nil;
//            } else if (!isReconnecting){//failure should first attempt to reconect
//                DDLogWarn("Will reconnect from errors: \(error)")
//            } else {//failure while reconnecting should error
//                //special case differs from above
//                DDLogError("Error: \(error)")
//                operation.cancel() //clean up to avoid duplicates
//                self?.eventSource.close(error) //clean up -> this should end up in eventSource.closed above
//                return;//bail out early as we've taken care of the below
//            }
//
//            operation.cancel() //clean up to avoid duplicates
//            self?.eventSource.close(); //clean up -> this should end up in eventSource.closed above
//        })
//        self.serverSentEventsOperationQueue.addOperation(operation)
//    }
//
//    func reconnect(connection: SRConnectionInterface, data: String) {
////        __weak __typeof(&*self)weakSelf = self;
////        __weak __typeof(&*connection)weakConnection = connection;
//        DDLogDebug("Will reconnect in \(self.reconnectDelay)")
//        BlockOperation(block: {
////            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
////            __strong __typeof(&*weakConnection)strongConnection = weakConnection;
//
//            if connection.state != .disconnected && SRConnection.ensureReconnecting(connection) {
//                DDLogWarn("reconnecting")
//                self.serverSentEventsOperationQueue.cancelAllOperations()
//                //now that all the current connections are tearing down, we have the queue to ourselves
//                self.open(connection, connectionData: data, isReconnecting: true)
//            }
//        }).perform(#selector(start), with:nil, afterDelay:self.reconnectDelay.doubleValue)
//    }
//
//    func isConnectionReconnecting(connection: SRConnectionInterface) -> Bool {
//        return connection.state == .reconnecting
//    }
//}
//
//
