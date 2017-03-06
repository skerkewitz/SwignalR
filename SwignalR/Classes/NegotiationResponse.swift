//
//  NegotiationResponse.swift
//  SignalR
//
//  Created by Alex Billingsley on 11/1/11.
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
 *  An `SRNegotiationResponse` object provides access to the negotiation response object received from the server
 */
public struct SRNegotiationResponse: SRDeserializable {

    public static let kConnectionId = "ConnectionId"
    public static let kConnectionToken = "ConnectionToken"
    public static let kUrl = "Url"
    public static let kProtocolVersion = "ProtocolVersion"
    public static let kDisconnectTimeout = "DisconnectTimeout"
    public static let kTryWebSockets = "TryWebSockets"
    public static let kKeepAliveTimeout = "KeepAliveTimeout"
    public static let kTransportConnectTimeout = "TransportConnectTimeout"

    /** An `NSString` object representing the connectionId belonging to the current client */
    public let connectionId: String

    public let connectionToken: String

    /** An `NSString` object representing the app relative server url the client should use for all
     * subsequent requests. */
    public let url: String

    /** An `NSString` object representing the protocol version the server is using. */
    public let protocolVersion: String

    public let disconnectTimeout: TimeInterval

    public let tryWebSockets: Bool

    public let keepAliveTimeout: TimeInterval

    public let transportConnectTimeout: TimeInterval

    public init(dictionary dict: [String: Any]) {
        self.connectionId = dict[SRNegotiationResponse.kConnectionId] as! String
        self.connectionToken = dict[SRNegotiationResponse.kConnectionToken] as! String
        self.url = dict[SRNegotiationResponse.kUrl] as! String
        self.protocolVersion = dict[SRNegotiationResponse.kProtocolVersion] as! String
        self.disconnectTimeout = dict[SRNegotiationResponse.kDisconnectTimeout] as! TimeInterval
        self.tryWebSockets = dict[SRNegotiationResponse.kTryWebSockets] as! Bool
        self.keepAliveTimeout = dict[SRNegotiationResponse.kKeepAliveTimeout] as! TimeInterval
        self.transportConnectTimeout = dict[SRNegotiationResponse.kTransportConnectTimeout] as! TimeInterval
    }
}

