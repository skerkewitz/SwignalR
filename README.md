# SwignalR

A [SignalR](https://www.asp.net/signalr) client implementation in Swift (port of https://github.com/skerkewitz/SignalR-ObjC).

# Work in progress

The development branch works, but only "WebSocket" and "Long Polling" transport are implemented at the moment. Also probably kinda buggy.

# Dependencies 
- [Alamofire](https://github.com/Alamofire/Alamofire) 4.3 for HTTP stuff.
- [Starscream](https://github.com/daltoniam/Starscream) 2.0.3 for WebSockets.
- [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack) 3.0.0 for logging.

# Cocoapod
Not yet, sorry.

# Alternatives
- [SwiftR](https://github.com/adamhartford/SwiftR) SignalR client in JavaScript, running in a WebView, wrapped in Swift.
- [SignalR-ObjC](https://github.com/DyKnow/SignalR-ObjC) SignalR client in Objective-C.

