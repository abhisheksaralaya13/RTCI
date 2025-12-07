# RTCI
📌 Real-Time Chat Interface (Assignment Submission)

This project is a single-screen mobile chat application that supports real-time communication and offline message queuing, developed based on the provided assignment requirements.

🚀 Features

Single-screen chat interface

List of chatbot conversations with latest message preview

Real-time messaging using WebSockets (Pie socket host)

Messages appear instantly without manual screen refresh

Offline handling:

Messages that fail to send are queued

Automatic retry when the device is back online

Error handling & alerts for network / socket failures

Empty UI states:

No chats available

No internet connection

Unread message indicator for each chat

Chat history cleared on app close (no persistence)

🛠 Tech Stack
Component	Technology
UI	SwiftUI
State	ObservableObject + @Published
WebSocket	URLSessionWebSocketTask
Network monitoring	NWPathMonitor
Offline queue	In-memory queue
📡 WebSocket Configuration

Update this constant in ChatScreen.init() (or where you initialize your ChatViewModel):

let url = URL(string: "wss://YOUR_PIESOCKET_URL")!


You can test with PieHost dashboard or any echo bot.

▶️ Running the App

Clone repository

Open .xcworkspace or .xcodeproj in Xcode

Set minimum iOS version to 15+

Build and run on real device or simulator

No backend setup required besides WebSocket URL.
