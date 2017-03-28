//
//  HubResult.swift
//  SwignalR
//
//  Created by Alex Billingsley on 11/2/11.
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

/** An `SRHubResult` object represents a SignalR Server Hub Response. */
public struct SRHubResult: SRDeserializable {

    static let kId = "I"
    static let kResult = "R"
    static let kHubException = "H"
    static let kError = "E"
    static let kErrorData = "D"
    static let kState = "S"

    /** Callback ID of this HubResult. */
    let id: String?

    /** A generic result object received from the server. */
    let result: Any?
    let hubException: Bool

    /** An string representing an error received from the server. */
    let error: String?

    /** Extra error data */
    let errorData: Any?

    /** The associated state map. */
    let state: [String:Any]?

    init(error: String) {
        self.error = error

        self.id = nil
        self.result = nil
        self.errorData = nil
        self.state = nil
        self.hubException = false
    }

    init(dictionary dict: [String:Any]) {
        self.id = dict[SRHubResult.kId] as? String
        self.result = dict[SRHubResult.kResult]
        self.hubException = dict[SRHubResult.kHubException] as? Bool ?? false
        self.error = dict[SRHubResult.kError] as? String
        self.errorData = dict[SRHubResult.kErrorData]
        self.state = dict[SRHubResult.kState] as? [String : Any]
    }
}

