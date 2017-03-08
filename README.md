# SwignalR

A [SignalR](https://www.asp.net/signalr) client implementation in Swift (port of [SignalR-ObjC](https://github.com/DyKnow/SignalR-ObjC)).

For a good overview of SignalR have a lock here: [SignalR on the wire - an informal description of the signalr SignalR](https://blog.3d-logic.com/2015/03/29/signalr-on-the-wire-an-informal-description-of-the-signalr-protocol/)
# Work in progress
This project is work in progress. I don't recomment to use it in production yet. Only "WebSocket" and "Long Polling" and "Auto" transport are implemented at the moment. Probably kinda buggy.

# Dependencies 
- [Alamofire](https://github.com/Alamofire/Alamofire) 4.3 for HTTP stuff.
- [Starscream](https://github.com/daltoniam/Starscream) 2.0.3 for WebSockets.
- [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack) 3.0.0 for logging.

# Cocoapod
Not yet, sorry.

# Alternatives
- [SwiftR](https://github.com/adamhartford/SwiftR) SignalR client in JavaScript, running in a WebView, wrapped in Swift.
- [SignalR-ObjC](https://github.com/DyKnow/SignalR-ObjC) SignalR client in Objective-C.



