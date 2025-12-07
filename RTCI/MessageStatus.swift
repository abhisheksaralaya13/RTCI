//
//  MessageStatus.swift
//  RTCI
//
//  Created by Abhishek Saralaya on 06/12/25.
//


import Foundation

enum MessageStatus {
    case sending
    case sent
    case queued
    case failed
}

struct ChatMessage: Identifiable, Hashable {
    let id: String
    let text: String
    let from: Sender
    let createdAt: Date
    var status: MessageStatus
    let conversationId: String
    var isRead: Bool
    
    enum Sender {
        case user
        case bot
    }
}

struct Conversation: Identifiable, Hashable {
    let id: String
    var title: String
    var lastMessage: ChatMessage?
    var unreadCount: Int
}
