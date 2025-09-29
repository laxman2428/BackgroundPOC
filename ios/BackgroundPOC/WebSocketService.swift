import Foundation
import UIKit
import UserNotifications
import BackgroundTasks
import Network

@objc(WebSocketService)
class WebSocketService: NSObject {
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var reconnectTimer: Timer?
    private var isConnected = false
    private var webSocketURL: String = ""
    
    // Background task identifier
    private let backgroundTaskIdentifier = "com.backgroundpoc.websocket"
    
    override init() {
        super.init()
        setupURLSession()
        requestNotificationPermission()
    }
    
    private func setupURLSession() {
        let config = URLSessionConfiguration.background(withIdentifier: backgroundTaskIdentifier)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    @objc func startWebSocket(url: String) {
        print("WebSocketService: Starting WebSocket with URL: \(url)")
        self.webSocketURL = url
        
        guard let session = urlSession else {
            print("WebSocketService: URLSession not initialized")
            return
        }
        
        guard let webSocketURL = URL(string: url) else {
            print("WebSocketService: Invalid URL: \(url)")
            return
        }
        
        let request = URLRequest(url: webSocketURL)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // Send initial notification
        sendNotification(title: "WebSocket Service", body: "Connecting...")
        
        // Start listening for messages
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("WebSocketService: Received message: \(text)")
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("WebSocketService: Received data message: \(text)")
                        self?.handleMessage(text)
                    }
                @unknown default:
                    print("WebSocketService: Unknown message type")
                }
                
                // Continue listening
                self?.receiveMessage()
                
            case .failure(let error):
                print("WebSocketService: Receive error: \(error)")
                self?.handleConnectionError(error)
            }
        }
    }
    
    private func handleMessage(_ message: String) {
        // Send event to React Native
        DispatchQueue.main.async {
            let userInfo: [String: Any] = [
                "message": message,
                "type": "message"
            ]
            NotificationCenter.default.post(name: NSNotification.Name("WebSocketMessage"), object: nil, userInfo: userInfo)
        }
    }
    
    private func handleConnectionError(_ error: Error) {
        print("WebSocketService: Connection error: \(error)")
        isConnected = false
        
        // Send error event to React Native
        DispatchQueue.main.async {
            let userInfo: [String: Any] = [
                "error": error.localizedDescription,
                "type": "error"
            ]
            NotificationCenter.default.post(name: NSNotification.Name("WebSocketError"), object: nil, userInfo: userInfo)
        }
        
        // Attempt reconnection after delay
        scheduleReconnect()
    }
    
    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            print("WebSocketService: Attempting reconnection...")
            self?.startWebSocket(url: self?.webSocketURL ?? "")
        }
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
    
    @objc func stopWebSocket() {
        print("WebSocketService: Stopping WebSocket")
        reconnectTimer?.invalidate()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        sendNotification(title: "WebSocket Service", body: "Disconnected")
    }
    
    @objc func sendMessage(_ message: String) {
        guard isConnected else {
            print("WebSocketService: Not connected, cannot send message")
            return
        }
        
        let webSocketMessage = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(webSocketMessage) { error in
            if let error = error {
                print("WebSocketService: Send error: \(error)")
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension WebSocketService: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocketService: WebSocket connected")
        isConnected = true
        
        DispatchQueue.main.async {
            let userInfo: [String: Any] = [
                "status": "connected",
                "type": "connection"
            ]
            NotificationCenter.default.post(name: NSNotification.Name("WebSocketEvent"), object: nil, userInfo: userInfo)
        }
        
        sendNotification(title: "WebSocket Service", body: "Connected")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocketService: WebSocket disconnected with code: \(closeCode)")
        isConnected = false
        
        DispatchQueue.main.async {
            let userInfo: [String: Any] = [
                "status": "disconnected",
                "type": "connection",
                "closeCode": closeCode.rawValue
            ]
            NotificationCenter.default.post(name: NSNotification.Name("WebSocketEvent"), object: nil, userInfo: userInfo)
        }
        
        sendNotification(title: "WebSocket Service", body: "Disconnected")
        
        // Attempt reconnection if not intentionally closed
        if closeCode != .goingAway && closeCode != .normalClosure {
            scheduleReconnect()
        }
    }
}

