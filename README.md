# SwignalR

A [SignalR](https://www.asp.net/signalr) client implementation in Swift (port of [SignalR-ObjC](https://github.com/DyKnow/SignalR-ObjC)).

For a good overview of SignalR have a lock here: [SignalR on the wire - an informal description of the signalr SignalR](https://blog.3d-logic.com/2015/03/29/signalr-on-the-wire-an-informal-description-of-the-signalr-protocol/)

# Supported transports

This library only supports `WebSockets` and `LongPolling`. The main reasons is that WebSocket is the best transport for almost all cases and LonPolling can be used as fallback.

# Work in progress
This project is work in progress and has probably still a few bugs here and there.

# Dependencies 
- [Alamofire](https://github.com/Alamofire/Alamofire) 4.3 for HTTP stuff.
- [Starscream](https://github.com/daltoniam/Starscream) 2.0.3 for WebSockets.
- [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack) 3.0.0 for logging.

# Cocoapod
As long as SwignalR is not stable I will no create a public cocoapod. However, if you would like to tryout SwignalR you can just add

```
pod 'SwignalR', :git => 'https://github.com/skerkewitz/SwignalR'
```

into your podfile. This will add the lastest version from the master branch into your project - which maybe broken at some times. 

# Alternatives
- [SwiftR](https://github.com/adamhartford/SwiftR) SignalR client in JavaScript, running in a WebView, wrapped in Swift.
- [SignalR-ObjC](https://github.com/DyKnow/SignalR-ObjC) SignalR client in Objective-C.



