//
//  ChatWebSocketClient.swift
//  RTCI
//
//  Created by Abhishek Saralaya on 06/12/25.
//


import Foundation

/// Wraps URLSessionWebSocketTask and exposes a simple send/receive API for the chat.
final class ChatWebSocketClient {
    enum Status {
        case connecting
        case open
        case closed
        case error(Error?)
    }
    
    private let url: URL
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    
    private(set) var status: Status = .connecting {
        didSet {
            statusHandler?(status)
        }
    }
    
    var statusHandler: ((Status) -> Void)?
    var messageHandler: (([String: Any]) -> Void)?
    
    init(url: URL) {
        self.url = url
        self.session = URLSession(configuration: .default)
    }
    
    func connect() {
        guard webSocketTask == nil else { return }
        
        status = .connecting
        let task = session.webSocketTask(with: url)
        webSocketTask = task
        task.resume()
        status = .open
        
        receiveLoop()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        status = .closed
    }
    
    private func receiveLoop() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                self.status = .error(error)
                self.webSocketTask = nil
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.messageHandler?(jsonObject)
                    }
                case .data(let data):
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.messageHandler?(jsonObject)
                    }
                @unknown default:
                    break
                }
                // Continue listening
                self.receiveLoop()
            }
        }
    }
    
    func send(json: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let task = webSocketTask else {
            completion(false)
            return
        }
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            completion(false)
            return
        }
        let message = URLSessionWebSocketTask.Message.data(data)
        task.send(message) { error in
            if let error {
                print("WS send error:", error)
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}
