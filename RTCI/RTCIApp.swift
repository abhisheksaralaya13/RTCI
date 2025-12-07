//
//  RTCIApp.swift
//  RTCI
//
//  Created by Abhishek Saralaya on 06/12/25.
//

import SwiftUI
import SwiftData

@main
struct RTCIApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ChatScreen()
        }
        .modelContainer(sharedModelContainer)
    }
}
