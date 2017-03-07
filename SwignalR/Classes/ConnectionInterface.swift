//
//  ConnectionInterface.h
//  SignalR
//
//  Created by Alex Billingsley on 2/16/13.
//  Copyright (c) 2011 DyKnow LLC. (http://dyknow.com/)
//  Created by Stefan Kerkewitz on 27/02/2017.
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

//@protocol SRClientTransportInterface;
//@class SRVersion;

public protocol SRConnectionInterface: class {

    /* Block types. */
    typealias StartedBlock = () -> ()
    typealias ReceivedBlock = (Any) -> ()
    typealias ErrorBlock = (Error) -> ()
    typealias ClosedBlock = () -> ()
    typealias ReconnectingBlock = () -> ()
    typealias ReconnectedBlock = () -> ()
    typealias StateChangedBlock = (ConnectionState) -> ()
    typealias ConnectionSlowBlock = () -> ()

    /* Block handler. */
    var started: StartedBlock? { get set }
    var received: ReceivedBlock? { get set }
    var error: ErrorBlock? { get set }
    var closed: ClosedBlock? { get set }
    var reconnecting: ReconnectingBlock? { get set }
    var reconnected: ReconnectedBlock? { get set }
    var stateChanged: StateChangedBlock? { get set }
    var connectionSlow: ConnectionSlowBlock? { get set }


    /** An arbitrary query string provided by the user. Will be appended to all requests. */
    var queryString: [String: String] { get }
    var state: ConnectionState { get }

    var clientProtocol: SRVersion { get }

    var transportConnectTimeout: TimeInterval { get set }
    var keepAliveData: SRKeepAliveData? { get set }
    var messageId: String! { get set }
    var groupsToken: String! { get set }
    var items: NSMutableDictionary { get set }
    var connectionId: String! { get set }
    var connectionToken: String! { get set }
    var url: String { get set }

    var transport: SRClientTransportInterface! { get set }
    var credentials: URLCredential { get set }
    var headers: [String: String] { get set }

    func onSending() -> String? //TODO: this just encapsulates connectionData. can we pull this into a getUrl like js client does?


    // Connection Management
//    @warn_unused_result
    func changeState(_ oldState: ConnectionState, toState: ConnectionState) -> Bool

    func start()
    func stop()

    func disconnect()


    // Sending Data
    func send(_ object: Any, completionHandler block: ((Any?, NSError?) -> ())?)

    // Receiving Data
    func didReceiveData(_ data: Any)

    func didReceive(error: Error)

    func willReconnect()

    func didReconnect()

    func connectionDidSlow()

    // Preparing Requests
    func updateLastKeepAlive()

    func prepare(request: inout URLRequest)
}