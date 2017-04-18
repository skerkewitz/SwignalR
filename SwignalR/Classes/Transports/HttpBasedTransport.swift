//
//  HttpBasedTransport.swift
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

import Foundation
import Alamofire

public class SRHttpBasedTransport: SRClientTransportInterface {

    var startedAbort: Bool = false

    public private(set) var name: String
    public private(set) var supportsKeepAlive: Bool

    public convenience init() {
        self.init(name: "", supportsKeepAlive: false)
    }

    public init(name: String, supportsKeepAlive: Bool) {
        self.name = name
        self.supportsKeepAlive = supportsKeepAlive
    }

    public func negotiate(_ connection: SRConnectionInterface, connectionData: String, completionHandler block: @escaping (SRNegotiationResponse?, NSError?) -> ()) {

        let parameters = connection.negotiateParameters(connectionData: connectionData, transportName: self.name)

        let url = connection.url + "negotiate"
        SRLogDebug("will negotiate at url: \(url)")
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON() { (response: DataResponse<Any>) in

            if let error = response.error {
                SRLogError("negotiate failed because of: \(error)")
                block(nil, error as NSError);
                return
            }

            SRLogDebug("negotiate was successful \(response)")
            block(SRNegotiationResponse(dictionary: response.result.value as! [String: Any]), nil)
        }
    }

    public func start(_ connection: SRConnectionInterface, connectionData: String, completionHandler block: ((Any?, NSError?) -> ())?) {
        // nothing
    }


    public func send(_ connection: SRConnectionInterface, data: String, connectionData: String, completionHandler block: ((Any?, NSError?) -> ())?) {

        let parameters = connection.negotiateParameters(connectionData: connectionData, transportName: self.name)

        let dataSendRequest = Alamofire.request(connection.url + "send", method: .get, parameters: parameters)
        let request = Alamofire.request(dataSendRequest.request!.url!.absoluteString, method: .post, parameters: ["data" : data])
//        connection.prepare(request: &request.request!)

        request.responseJSON(completionHandler: { response in

            if let error = response.error as NSError? {
                SRLogError("send failed \(error)")
                connection.didReceive(error: error)
                block?(nil, error);
                return
            }

            let value = response.value!
            SRLogDebug("send was successful \(value)")
            connection.didReceiveData(value)
            block?(value, nil);
        })
    }

    public func completeAbort() {
        // Make any future calls to Abort() no-op
        // Abort might still run, but any ongoing aborts will immediately complete
        self.startedAbort = true
    }


    public func tryCompleteAbort() -> Bool {
        return self.startedAbort
    }

    public func lostConnection(_ connection: SRConnectionInterface) {
        //TODO: Throw, Subclass should implement this.
    }

    //@parameter: timeout, the amount of time we
    public func abort(_ connection: SRConnectionInterface, timeout: TimeInterval, connectionData: String) {

        if (timeout <= 0) {
            SRLogWarn("stopping transport without informing server");
            return;
        }

        // FIX ME SKerkewitz
//
//        // Ensure that an abort request is only made once
//        if (!self.startedAbort) {
//            self.startedAbort = true;
//
//            let parameters = self.connectionParameters(connection, connectionData: connectionData)
//
//            let serializer = AFHTTPRequestSerializer()
//            let url = serializer.request(withMethod: "GET", urlString: connection.url + "abort", parameters: parameters, error: nil)
//            let request = serializer.request(withMethod: "POST", urlString: url.url!.absoluteString, parameters: nil, error: nil)
//            connection.prepareRequest(request) //TODO: prepareRequest
//            request.timeoutInterval = 2
//            let operation = AFHTTPRequestOperation(request: request as URLRequest)
//            operation.responseSerializer = AFJSONResponseSerializer()
//            //operation.shouldUseCredentialStorage = self.shouldUseCredentialStorage;
//            //operation.credential = self.credential;
//            //operation.securityPolicy = self.securityPolicy;
//            SRLogDebug("Will abort at url: \(request.url!.absoluteString)")
//            operation.setCompletionBlockWithSuccess({ (operation: AFHTTPRequestOperation, responseObject: Any) in
//                SRLogInfo("abort was successful \(responseObject)")
//            }, failure: { (operation: AFHTTPRequestOperation, error: Error) in
//                DDLogError("Abort failed \(error)");
//                self.completeAbort()
//            })
//            operation.start()
//        }
    }
}

extension SRConnectionInterface {

    func process(response: String, shouldReconnect: inout Bool, disconnected: inout Bool) {
        self.updateLastKeepAlive()
        shouldReconnect = false
        disconnected = false

        /* Ignore empty response. */
        guard !response.isEmpty else {
            return
        }

        let data: Data = response.data(using: .utf8)!
        if let result = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
            if result["I"] != nil {
                self.didReceiveData(result)
                return;
            }

            shouldReconnect = result["T"] as? Bool ?? false
            disconnected = result["D"] as? Bool ?? false

            if disconnected {
                return
            }

            if let groupsToken = result["G"] as? String {
                self.groupsToken = groupsToken
            }

            let messages = result["M"]
            if let messages = messages as? NSArray {
                self.messageId = result["C"] as! String;

                for message in messages {
                    self.didReceiveData(message)
                }

                // FIX ME SKerkewitz
                //                if result["S"] {
                //                    //TODO: Call Initialized Callback
                //                    //onInitialized();
                //                }
            }
        }
    }

    func negotiateParameters(connectionData: String, transportName name: String) -> [String: Any] {
        var parameters = Dictionary<String, Any>()

        parameters["transport"] = name
        parameters["connectionData"] = connectionData
        parameters["clientProtocol"] = self.clientProtocol

        if self.connectionToken != nil {
            parameters["connectionToken"] = self.connectionToken
        }

        /* Forward all key/values from the query string. */
        for (key, value) in self.queryString {
            parameters[key] = value
        }

        return parameters
    }
}
