import Foundation
import React

@objc(CalendarModule)
class CalendarModule: RCTEventEmitter {
    
    private let webSocketService = WebSocketService()
    private var hasListeners = false
    
    override init() {
        super.init()
        setupNotificationObservers()
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    override func supportedEvents() -> [String]! {
        return ["WebSocketEvent", "WebSocketMessage", "WebSocketError"]
    }
    
    override func startObserving() {
        hasListeners = true
    }
    
    override func stopObserving() {
        hasListeners = false
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(webSocketEventReceived(_:)),
            name: NSNotification.Name("WebSocketEvent"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(webSocketMessageReceived(_:)),
            name: NSNotification.Name("WebSocketMessage"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(webSocketErrorReceived(_:)),
            name: NSNotification.Name("WebSocketError"),
            object: nil
        )
    }
    
    @objc private func webSocketEventReceived(_ notification: Notification) {
        if hasListeners, let userInfo = notification.userInfo {
            sendEvent(withName: "WebSocketEvent", body: userInfo)
        }
    }
    
    @objc private func webSocketMessageReceived(_ notification: Notification) {
        if hasListeners, let userInfo = notification.userInfo {
            sendEvent(withName: "WebSocketMessage", body: userInfo)
        }
    }
    
    @objc private func webSocketErrorReceived(_ notification: Notification) {
        if hasListeners, let userInfo = notification.userInfo {
            sendEvent(withName: "WebSocketError", body: userInfo)
        }
    }
    
    @objc func createCalendarEvent(_ url: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        print("CalendarModule: createCalendarEvent called with URL: \(url)")
        
        DispatchQueue.main.async { [weak self] in
            self?.webSocketService.startWebSocket(url: url)
            resolver(["success": true, "message": "WebSocket service started"])
        }
    }
    
    @objc func stopWebSocket(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        print("CalendarModule: stopWebSocket called")
        
        DispatchQueue.main.async { [weak self] in
            self?.webSocketService.stopWebSocket()
            resolver(["success": true, "message": "WebSocket service stopped"])
        }
    }
    
    @objc func sendMessage(_ message: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        print("CalendarModule: sendMessage called with message: \(message)")
        
        DispatchQueue.main.async { [weak self] in
            self?.webSocketService.sendMessage(message)
            resolver(["success": true, "message": "Message sent"])
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

