//
//  Connection.swift
//  SignalR
//
//  Created by Alex Billingsley on 10/17/11.
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

public class SRConnection: SRConnectionInterface {

    public var started: SRConnectionInterface.StartedBlock?
    public var received: SRConnectionInterface.ReceivedBlock?
    public var error: SRConnectionInterface.ErrorBlock?
    public var closed: SRConnectionInterface.ClosedBlock?
    public var reconnecting: SRConnectionInterface.ReconnectingBlock?
    public var reconnected: SRConnectionInterface.ReconnectedBlock?
    public var stateChanged: SRConnectionInterface.StateChangedBlock?
    public var connectionSlow: SRConnectionInterface.ConnectionSlowBlock?

    var assemblyVersion: SRVersion? = nil
    var defaultAbortTimeout: TimeInterval = 30
    var disconnectTimeout: TimeInterval = 0
    var disconnectTimeoutOperation: BlockOperation?

    var connectionData: String = ""
    var monitor: SRHeartbeatMonitor? = nil

    public let clientProtocol = SRVersion(major:1, minor:3)
    public var transportConnectTimeout: TimeInterval = 0
    public var keepAliveData: SRKeepAliveData?
    public var messageId: String!
    public var groupsToken: String!
    public var connectionId: String!
    public var connectionToken: String!
    public var url: String
    public var queryString: [String: String]
    public var state: ConnectionState
    public var transport: SRClientTransportInterface!
    public var headers = [String: String]()

    /* --- Initializing an SRConnection Object --- */

    public init(urlString url: String, queryString: [String: String] = [String: String]()) {

        self.url = url.hasSuffix("/") ? url : url + "/"
        self.queryString = queryString;
    //self.disconnectTimeoutOperation = DisposableAction.Empty;
    //self.connectingMessageBuffer = new ConnectingMessageBuffer(this, OnMessageReceived);
        self.state = .disconnected;
    }

    /* --- Connection Management --- */

    public func start() {
        /* Pick the best transport supported by the client. */
        self.start(SRAutoTransport())
    }

    func start(_ transport: SRClientTransportInterface) {
        if !self.changeState(.disconnected, toState:.connecting) {
            return
        }

        self.monitor = SRHeartbeatMonitor(connection: self)
        self.transport = transport

        self.negotiate(transport)
    }

    func negotiate(_ transport: SRClientTransportInterface) {
        SRLogDebug("will negotiate");

        /* FIX ME: This will crash if we using a non hub connection. */
        self.connectionData = self.onSending()!

        self.transport.negotiate(self, connectionData: self.connectionData) { (negotiationResponse, error) in

            if let error = error {
                SRLogError("negotiation failed \(error)");
                self.didReceive(error: error)
                self.didClose()
                return
            }

            guard let negotiationResponse = negotiationResponse else {
                fatalError("No negotiation response.")
            }

            SRLogDebug("negotiation was successful \(negotiationResponse)")
            self.verifyProtocolVersion(negotiationResponse.protocolVersion)

            self.connectionId = negotiationResponse.connectionId
            self.connectionToken = negotiationResponse.connectionToken
            self.disconnectTimeout = negotiationResponse.disconnectTimeout
            self.transportConnectTimeout = self.transportConnectTimeout + negotiationResponse.transportConnectTimeout

            // If we have a keep alive
            if negotiationResponse.keepAliveTimeout > 0 {
                self.keepAliveData = SRKeepAliveData(timeout: negotiationResponse.keepAliveTimeout)
            }

            self.startTransport()
        }
    }

    func startTransport() {
        SRLogDebug("will start transport")
        self.transport.start(self, connectionData:self.connectionData) { (response, error) in
            if error == nil {
                SRLogInfo("Start transport was successful, using \(self.transport.name)")
                _ = self.changeState(.connecting, toState:.connected)

                if self.keepAliveData != nil && self.transport.supportsKeepAlive {
                    SRLogDebug("connection starting keepalive monitor")
                    self.monitor?.start()
                }

                self.started?()

            } else {
                SRLogError("start transport failed \(error!)")
                self.didReceive(error: error!)
                self.didClose()
            }
        }
    }

    public func changeState(_ oldState: ConnectionState, toState newState:ConnectionState) -> Bool {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        // If we're in the expected old state then change state and return true
        if (self.state == oldState) {
            self.state = newState;

            SRLogDebug("connection state did change from \(oldState) to \(newState)")
            self.stateChanged?(self.state);
            return true
        }

        // Invalid transition
        return false
    }

    func verifyProtocolVersion(_ versionString: String) {

        guard let version = SRVersion.parse(from: versionString) else {
            fatalError("Could not parse version")
        }

        if version != self.clientProtocol {
            // SKerkewitz: how does versioning in signalR work?
            SRLogError("Remote SignalR version is \(versionString)")
            //SRLogError("Invalid version \(version), expected \(self.clientProtocol)")
        }
    }

    func stopAndCallServer() {
        self.stop(timeout: self.defaultAbortTimeout)
    }

    func stopButDoNotCallServer() {
        //immediately give up telling the server
        self.stop(timeout: -1)
    }

    public func stop() {
        self.stopAndCallServer()
    }

    /** timeout <= 0 does not call server (immediate timeout). */
    public func stop(timeout: TimeInterval)  {
        // Do nothing if the connection is offline
        if (self.state != .disconnected) {

            SRLogDebug("connection will stop monitoring keepalive")
            self.monitor!.stop()
            self.monitor = nil

            SRLogDebug("connection will abort transport")
            self.transport.abort(self, timeout:timeout, connectionData:self.connectionData)
            self.disconnect()

            self.transport = nil
        }
    }

    public func disconnect() {
        if self.state != .disconnected {
            self.state = .disconnected

            self.monitor?.stop()
            self.monitor = nil

            // Clear the state for this connection
            self.connectionId = nil
            self.connectionToken = nil
            self.groupsToken = nil
            self.messageId = nil

            self.didClose()
        }
    }

    func didClose() {
        SRLogDebug("connection did close")
        self.closed?()
    }

    /* --- Sending Data --- */
    public func onSending() -> String? {
        return nil;
    }

    public func send(_ object: Any, completionHandler block:((Any?, NSError?) -> ())?) {
        if self.state == .disconnected {
            let userInfo: [AnyHashable : Any] = [
                    NSLocalizedFailureReasonErrorKey : NSExceptionName.internalInconsistencyException,
                    NSLocalizedDescriptionKey : NSLocalizedString("Start must be called before data can be sent", comment:"NSInternalInconsistencyException")
            ]
            let localizedString = NSLocalizedString("com.SignalR.SignalR-ObjC." + String(describing: self), comment: "")
            let error = NSError(domain: localizedString, code:0, userInfo:userInfo)
            self.didReceive(error :error)
            block?(nil, error);
            return;
        }

        if self.state == .connecting {
            let userInfo: [AnyHashable : Any] = [
                    NSLocalizedFailureReasonErrorKey : NSExceptionName.internalInconsistencyException,
                    NSLocalizedDescriptionKey : NSLocalizedString("The connection has not been established", comment:"NSInternalInconsistencyException")
            ]

            let localizedString = NSLocalizedString("com.SignalR.SignalR-ObjC." + String(describing: self), comment: "")
            let error = NSError(domain: localizedString, code:0, userInfo:userInfo)
            self.didReceive(error: error)
            block?(nil, error);
            return;
        }

        let message: String
        if let str = object as? String {
            message = str;
        } else {

            let data: Data?
            if let serializable = object as? SRSerializable {
                data = try? JSONSerialization.data(withJSONObject: serializable.proxyForJson())
            } else {
                data = try? JSONSerialization.data(withJSONObject: object)
            }

            message = String(data: data!, encoding: .utf8)!
        }

        SRLogDebug("connection transport will send \(message)")
        self.transport.send(self, data: message, connectionData: self.connectionData, completionHandler: block)
    }


    /* --- Received Data --- */

    public func didReceiveData(_ message: Any) {
        SRLogDebug("connection did receive data \(message)")
        self.received?(message)
    }

    public func didReceive(error: Error) {
        SRLogError("Connection did receive error \(error)")
        self.error?(error);
    }

    public func willReconnect() {
        SRLogDebug("connection will reconnect")
        // Only allow the client to attempt to reconnect for a self.disconnectTimout TimeSpan which is set by
        // the server during negotiation.
        // If the client tries to reconnect for longer the server will likely have deleted its ConnectionId
        // topic along with the contained disconnect message.

        self.disconnectTimeoutOperation = BlockOperation(block: {
            SRLogWarn("connection failed to reconnect");
            self.stopButDoNotCallServer()
        })

        SRLogDebug("connection will disconnect if reconnect is not performed in \(self.disconnectTimeout)")
        self.disconnectTimeoutOperation!.perform(#selector(Operation.start), with:nil, afterDelay:self.disconnectTimeout)

        self.reconnecting?()
    }

    public func didReconnect() {
        SRLogDebug("connection did reconnect")
        NSObject.cancelPreviousPerformRequests(withTarget: self.disconnectTimeoutOperation, selector:#selector(Operation.start), object:nil)
        self.disconnectTimeoutOperation = nil;

        self.reconnected?();
        self.updateLastKeepAlive()
    }

    public func connectionDidSlow() {
        SRLogDebug("connection did slow")
        self.connectionSlow?()
    }

    /* --- Preparing Requests --- */

    /**
     * Adds an HTTP header to the receiver’s HTTP header dictionary.
     *
     * @param value The value for the header field.
     * @param field the name of the header field.
     **/
    func addValue(_ value: String, forHTTPHeaderField field: String) {
        self.headers[field] = value
    }

    public func updateLastKeepAlive() {
        self.keepAliveData?.lastKeepAlive = Date()
    }

    public func prepare(request: inout URLRequest) {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
            request.addValue(self.createUserAgentString(NSLocalizedString("SignalR.Client.iOS", ""), forHTTPHeaderField:"User-Agent"))
#elseif TARGET_OS_MAC
            request.addValue(self.createUserAgentString(NSLocalizedString("SignalR.Client.OSX", ""), forHTTPHeaderField:"User-Agent"))
#endif

        //TODO: set credentials
        //[request setCredentials:self.credentials];
        request.allHTTPHeaderFields = self.headers

        //TODO: Potentially set proxy here
    }

    func createUserAgentString(_ client: String) -> String {
        if self.assemblyVersion == nil {
            self.assemblyVersion = SRVersion(major:2, minor:0, build:0, revision:0)
        }

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        return "\(client)/\(self.assemblyVersion), (\(UIDevice.currentDevice().localizedModel) \(UIDevice.currentDevice().systemVersion))"
#elseif TARGET_OS_MAC
        // SKerkewitz: FIX ME
//        var environmentVersion = ""
//        if([[NSProcessInfo processInfo] operatingSystem] == NSMACHOperatingSystem) {
//            environmentVersion = [environmentVersion stringByAppendingString:@"Mac OS X"];
//            NSString *version = [[NSProcessInfo processInfo] operatingSystemVersionString];
//            if ([version rangeOfString:@"Version"].location != NSNotFound) {
//                environmentVersion = [environmentVersion stringByAppendingFormat:@" %@",version];
//            }
//            return [NSString stringWithFormat:@"%@/%@ (%@)",client,self.assemblyVersion,environmentVersion];
//        }
//        return [NSString stringWithFormat:@"%@/%@",client,self.assemblyVersion];
        return ""
#endif

        return ""
    }
}

extension SRConnection {

    class func ensureReconnecting(_ connection: SRConnectionInterface) -> Bool {

        if connection.changeState(.connected, toState:.reconnecting) {
            connection.willReconnect()
        }

        return connection.state == .reconnecting
    }
}


