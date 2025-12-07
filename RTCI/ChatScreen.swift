//
//  ChatScreen.swift
//  RTCI
//
//  Created by Abhishek Saralaya on 06/12/25.
//


import SwiftUI

/// Root screen that shows the chatbot conversations and messages on a single screen.
struct ChatScreen: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var currentInput: String = ""

    init() {
        if let url = URL(string: "wss://demo.piesocket.com/v3/channel_123?api_key=VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV&notify_self") {
            _viewModel = StateObject(wrappedValue: ChatViewModel(socketURL: url))
        } else {
            _viewModel = StateObject(wrappedValue: ChatViewModel(socketURL: URL(string: "ws://localhost:8080/")!))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Status / error banner
            if viewModel.showErrorBanner {
                HStack {
                    Image(systemName: "wifi.slash")
                    Text(viewModel.connectionStatusText)
                    Spacer()
                }
                .foregroundColor(.primary)
                .padding(8)
                .background(Color.red)
            } else {
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.isOnline ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(viewModel.connectionStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }

            // Content
            if viewModel.conversations.isEmpty {
                // Empty: No chats
                Spacer()
                Text("No chats yet")
                    .font(.headline)
                Text("Start a conversation with the chatbot using the input below.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            } else {
                // Single-screen layout: left conversations, right messages
                HStack(spacing: 0) {
                    // Conversations list
                    List(viewModel.conversations) { conv in
                        Button {
                            viewModel.selectConversation(conv.id)
                        } label: {
                            ChatRowView(conversation: conv)
                        }
                    }
                    .listStyle(.plain)
                    .frame(width: 260)

                    Divider()

                    // Messages for selected conversation
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(viewModel.messagesForSelectedConversation()) { msg in
                                    MessageBubbleView(message: msg)
                                        .id(msg.id)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .onChange(of: viewModel.messagesForSelectedConversation().count) {
                            if let lastId = viewModel.messagesForSelectedConversation().last?.id {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }

            Divider()

            // Input bar – always visible (needed to start first chat)
            HStack(spacing: 10) {
                TextField("Type a message...", text: $currentInput, axis: .vertical)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    let trimmed = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    viewModel.sendMessage(text: trimmed)
                    currentInput = ""
                } label: {
                    Text("Send")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundColor(.primary)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}
