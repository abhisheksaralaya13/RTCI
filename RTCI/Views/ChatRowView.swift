//
//  ChatRowView.swift
//  RTCI
//
//  Created by Abhishek Saralaya on 06/12/25.
//


import SwiftUI

struct ChatRowView: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .frame(width: 40, height: 40)
                .overlay(Text("🤖"))

            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(conversation.lastMessage?.text ?? "No messages yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let date = conversation.lastMessage?.createdAt {
                Text(Self.timeFormatter.string(from: date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.caption2)
                    .padding(6)
                    .background(Color.accentColor.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}
