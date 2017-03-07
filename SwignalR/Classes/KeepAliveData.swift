//
//  KeepAliveData.swift
//  SignalR
//
//  Created by Alex Billingsley on 5/8/13.
//  Copyright (c) 2013 DyKnow LLC. (http://dyknow.com/)
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

public struct SRKeepAliveData {

    public var lastKeepAlive: Date?
    public let timeout: TimeInterval
    public let timeoutWarning: TimeInterval
    public let checkInterval: TimeInterval

    public init (lastKeepAlive: Date?, timeout: TimeInterval, timeoutWarning: TimeInterval, checkInterval: TimeInterval) {
        self.timeout = timeout;
        self.lastKeepAlive = lastKeepAlive;
        self.timeoutWarning = timeoutWarning;
        self.checkInterval = checkInterval;
    }

    public init (timeout: TimeInterval) {
        let timeoutWarning = timeout * 2.0 / 3.0
        let checkInterval = (timeout - timeoutWarning) / 3.0
        self.init(lastKeepAlive: nil, timeout: timeout, timeoutWarning: timeoutWarning, checkInterval: checkInterval)
    }

}


