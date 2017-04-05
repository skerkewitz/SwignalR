//
//  HubProxyInterface.swift
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

public protocol SRHubProxyInterface: class {

    /** The state of the underlying connection. */
    var connectionState: ConnectionState { get }

    /**
     * Creates a new `SRSubscription` object
     *
     * @param eventName the name of the event to subscribe to
     * @param object The receiver to perform selector on
     * @param selector A selector identifying the message to send.
     * @return An instance of an `SRSubscription` object
     */
    func on(_ eventName: String, handler block: @escaping ([Any]?) -> ())

    /**
     * Invokes a SignalR Server Hub method with the specified method name and arguments
     *
     * @param method the `NSString` object representing the name of the server method to invoke
     * @param args the arguments to pass as part of the invocation
     * @param block the block to be called once the server method is invoked, this may be nil
     */
    func invoke(_ method: String, withArgs args: [Any]?, completionHandler block:((Any?, NSError?) -> ())?)


    /**
     * Add a event to the ignore list.
     *
     * If the server send as an invoke event and the hub has no subscriber for the event the hub will log an error
     * message. In some cases this can be the intended behavior and the error log message is misleading and annoying.
     * In those cases you can add the event to the ignore list to get rid of the log message.
     *
     * \note If you are subscribed to an event and at the same event to the ignore list the invoke will still be done.rethrows
     * The ignore only works for events with out any subscriber.
     *
     * The eventName match be an exact, case sensitive match.
     */
    func ignoreRemoveInvoke(for eventName: String)

    /** Remove an event from the ignore list. The return value indicates if the event was on the ignore list in the first place. */
    func unignoreRemoveInvoke(for eventName: String) -> Bool
}
