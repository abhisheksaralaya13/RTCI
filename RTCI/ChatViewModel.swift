//
//  ChatViewModel.swift
//  RTCI
//
//  Created by Abhishek Saralaya on 06/12/25.
//


import Foundation
import Combine

/// View model managing messages, conversations, offline queue and WebSocket state.
final class ChatViewModel: ObservableObject {
    // MARK: - Published state
    
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var conversations: [Conversation] = []
    
    @Published var selectedConversationId: String? = nil
    
    @Published var connectionStatusText: String = "Connecting..."
    @Published var showErrorBanner: Bool = false
    @Published var errorMessage: String = ""
    
    @Published var isOnline: Bool = true
    
    // simulate failure flag (for assignment requirement)
    @Published var simulateFailure: Bool = false
    
    // MARK: - Private
    
    private let socketClient: ChatWebSocketClient
    private var cancellables = Set<AnyCancellable>()
    
    /// Queue for messages that failed to send while offline
    private var queue: [ChatMessage] = []
    
    init(socketURL: URL, networkMonitor: NetworkMonitor = .shared) {
        self.socketClient = ChatWebSocketClient(url: socketURL)
        
        // Network state
        networkMonitor.$isOnline
            .receive(on: DispatchQueue.main)
            .sink { [weak self] online in
                self?.isOnline = online
                self?.updateConnectionBanner()
                if online {
                    self?.retryQueuedMessages()
                }
            }
            .store(in: &cancellables)
        
        // Socket callbacks
        socketClient.statusHandler = { [weak self] status in
            DispatchQueue.main.async {
                self?.handleSocketStatus(status)
            }
        }
        
        socketClient.messageHandler = { [weak self] json in
            DispatchQueue.main.async {
                self?.handleIncoming(json: json)
            }
        }
        
        socketClient.connect()
    }
    
    // MARK: - Public API
    
    func sendMessage(text: String) {
        let conversationId = selectedConversationId ?? "default"
        let id = UUID().uuidString
        
        var newMessage = ChatMessage(
            id: id,
            text: text,
            from: .user,
            createdAt: Date(),
            status: .sending,
            conversationId: conversationId,
            isRead: true
        )
        
        messages.append(newMessage)
        rebuildConversations()
        
        let payload: [String: Any] = [
            "id": id,
            "text": text,
            "conversationId": conversationId,
            "from": "user"
        ]
        
        let canSendNow = isOnline && (isSocketOpen || !simulateFailure)
        
        if canSendNow && !simulateFailure {
            socketClient.send(json: payload) { [weak self] success in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if success {
                        self.updateMessage(id: id) { msg in
                            var m = msg
                            m.status = .sent
                            return m
                        }
                    } else {
                        self.queueMessage(newMessage)
                    }
                }
            }
        } else {
            queueMessage(newMessage)
        }
    }
    
    func messagesForSelectedConversation() -> [ChatMessage] {
        guard let id = selectedConversationId else { return [] }
        return messages
            .filter { $0.conversationId == id }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    func selectConversation(_ id: String) {
        selectedConversationId = id
        // mark bot messages as read
        messages = messages.map { msg in
            guard msg.conversationId == id, msg.from == .bot else { return msg }
            var copy = msg
            copy.isRead = true
            return copy
        }
        rebuildConversations()
    }
    
    // MARK: - Private
    
    private var isSocketOpen: Bool {
        if case .open = socketClient.status {
            return true
        }
        return false
    }
    
    private func handleSocketStatus(_ status: ChatWebSocketClient.Status) {
        switch status {
        case .connecting:
            connectionStatusText = "Connecting..."
            showErrorBanner = false
        case .open:
            connectionStatusText = "Connected"
            showErrorBanner = false
            retryQueuedMessages()
        case .closed:
            connectionStatusText = "Disconnected"
        case .error(let error):
            connectionStatusText = "Error"
            errorMessage = error?.localizedDescription ?? "Unknown error"
            showErrorBanner = true
        }
    }
    
    private func handleIncoming(json: [String: Any]) {
        // Expecting { id, text, conversationId, from }
        guard let id = json["id"] as? String,
              let text = json["text"] as? String else { return }
        
        let conversationId = (json["conversationId"] as? String) ?? "default"
        
        let message = ChatMessage(
            id: id,
            text: text,
            from: .bot,
            createdAt: Date(),
            status: .sent,
            conversationId: conversationId,
            isRead: false // unread until user opens
        )
        
        messages.append(message)
        rebuildConversations()
    }
    
    private func updateMessage(id: String, transform: (ChatMessage) -> ChatMessage) {
        messages = messages.map { msg in
            guard msg.id == id else { return msg }
            return transform(msg)
        }
        rebuildConversations()
    }
    
    private func rebuildConversations() {
        var map: [String: Conversation] = [:]
        
        for msg in messages {
            var conv = map[msg.conversationId] ?? Conversation(
                id: msg.conversationId,
                title: "Chatbot \(msg.conversationId)",
                lastMessage: nil,
                unreadCount: 0
            )
            
            // last message
            if let last = conv.lastMessage {
                if msg.createdAt > last.createdAt {
                    conv.lastMessage = msg
                }
            } else {
                conv.lastMessage = msg
            }
            
            if msg.from == .bot && !msg.isRead {
                conv.unreadCount += 1
            }
            
            map[msg.conversationId] = conv
        }
        
        conversations = Array(map.values)
            .sorted { (a, b) in
                (a.lastMessage?.createdAt ?? .distantPast) >
                (b.lastMessage?.createdAt ?? .distantPast)
            }
        
        if selectedConversationId == nil, let first = conversations.first {
            selectedConversationId = first.id
        }
    }
    
    private func queueMessage(_ msg: ChatMessage) {
        var queued = msg
        queued.status = .queued
        
        // Update in main message list
        updateMessage(id: msg.id) { _ in queued }
        
        queue.append(queued)
        rebuildConversations()
    }
    
    // Retry queued messages when network + socket are available again
    private func retryQueuedMessages() {
        guard isOnline, isSocketOpen, !queue.isEmpty else { return }
        
        let toRetry = queue
        queue.removeAll()
        
        for msg in toRetry {
            let payload: [String: Any] = [
                "id": msg.id,
                "text": msg.text,
                "conversationId": msg.conversationId,
                "from": "user"
            ]
            
            socketClient.send(json: payload) { [weak self] success in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if success {
                        self.updateMessage(id: msg.id) { original in
                            var copy = original
                            copy.status = .sent
                            return copy
                        }
                    } else {
                        self.queueMessage(msg) // still queued
                    }
                }
            }
        }
    }
    
    private func updateConnectionBanner() {
        if !isOnline {
            connectionStatusText = "Offline – messages will be queued"
            showErrorBanner = true
            errorMessage = "No internet connection"
        } else if isSocketOpen {
            connectionStatusText = "Connected"
            showErrorBanner = false
        } else {
            connectionStatusText = "Reconnecting..."
        }
    }
}
