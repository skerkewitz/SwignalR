//
//  HeartbeatMonitor.swift
//  SignalR
//
//  Created by Alex Billingsley on 5/9/13.
//  Copyright (c) 2013 DyKnow LLC. (http://dyknow.com/)
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

@objc public class SRHeartbeatMonitor : NSObject {

    public var beenWarned: Bool = false
    public var timedOut: Bool = false

    public var connection: SRConnectionInterface
    public var timer: Timer? = nil

    init(connection: SRConnectionInterface) {
        self.connection = connection
        super.init()
    }

    public func start() {
        self.connection.updateLastKeepAlive()
        self.beenWarned = false
        self.timedOut = false
        self.timer = Timer.scheduledTimer(timeInterval: self.connection.keepAliveData!.checkInterval.doubleValue,
                target:self, selector:#selector(heartbeat), userInfo:nil, repeats:true)
    }


    public func stop() {
        self.timer!.invalidate()
        self.timer = nil
    }


    func heartbeat(_ timer: Timer) {
        let timeElapsed = Date().timeIntervalSince(self.connection.keepAliveData!.lastKeepAlive!)
        self.beat(timeElapsed)
    }

    func beat(_ timeElapsed: TimeInterval) {
        if (self.connection.state == .connected) {
            if timeElapsed >= self.connection.keepAliveData!.timeout.doubleValue {
                if !self.timedOut {
                    // Connection has been lost
                    SRLogWarn("Connection Timed-out : Transport Lost Connection")
                    self.timedOut = true;
                    self.connection.transport.lostConnection(self.connection)
                }
            } else if timeElapsed >= self.connection.keepAliveData!.timeoutWarning.doubleValue {
                if (!self.beenWarned) {
                    // Inform user and set HasBeenWarned to true
                    SRLogWarn("Connection Timeout Warning : Notifying user")
                    self.beenWarned = true
                    self.connection.connectionDidSlow()
                }
            } else {
               self.beenWarned = false;
                self.timedOut = false;
            }
        }
    }
}

