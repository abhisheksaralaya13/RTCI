//
//  MessageBubbleView.swift
//  RTCI
//
//  Created by Abhishek Saralaya on 06/12/25.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.from == .bot {
                bubble
                Spacer()
            } else {
                Spacer()
                bubble
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.text)

            HStack(spacing: 4) {
                Text(Self.timeFormatter.string(from: message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if message.from == .user {
                    Text(statusText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(bubbleBackground)
        .foregroundColor(bubbleForeground)
        .cornerRadius(12)
    }

    private var bubbleBackground: Color {
        message.from == .user
            ? Color.accentColor                      // adapts to theme
            : Color(.secondarySystemBackground)      // light: light grey, dark: dark grey
    }

    private var bubbleForeground: Color {
        message.from == .user ? .white : .primary   // primary adapts automatically
    }

    private var statusText: String {
        switch message.status {
        case .sending: return "Sending..."
        case .sent:    return "Sent"
        case .queued:  return "Queued"
        case .failed:  return "Failed"
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}
