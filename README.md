# RTCI

## 📌 Real-Time Chat Interface (Assignment Submission)

This project is a single-screen mobile chat application that supports real-time communication and offline message queuing, developed based on the provided assignment requirements.

---
## Demo Video
https://drive.google.com/file/d/1FPu7V9Phwf1bq-9ZEVxmRiCYqPFyCR2a/view?usp=sharing

## 🚀 Features

- Single-screen chat interface  
- List of chatbot conversations with latest message preview  
- Real-time messaging using WebSockets (Pie socket host)  
- Messages appear instantly without manual screen refresh  

**Offline handling:**

- Messages that fail to send are queued  
- Automatic retry when the device is back online  

**Error handling & states:**

- Error handling & alerts for network / socket failures  
- “No chats available” empty state  
- “No internet connection” state  

Other:

- Unread message indicator for each chat  
- Chat history cleared on app close (no persistence)

---

## 🛠 Tech Stack

| Component           | Technology                       |
|--------------------|----------------------------------|
| UI                 | SwiftUI                          |
| State              | ObservableObject + `@Published`  |
| WebSocket          | `URLSessionWebSocketTask`        |
| Network monitoring | `NWPathMonitor`                  |
| Offline queue      | In-memory queue (no persistence) |

---

## 🔧 WebSocket Configuration

Update this constant in `ChatScreen.init()` (or wherever you initialize your `ChatViewModel`):

```swift
let url = URL(string: "wss://YOUR_PIESOCKET_URL")!

