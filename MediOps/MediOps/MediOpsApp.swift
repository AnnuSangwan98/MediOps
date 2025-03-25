//
//  MediOpsApp.swift
//  MediOps
//
//  Created by Abcom on 13/03/25.
//

import SwiftUI
import AppIntents

@main
struct MediOpsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Implement app shortcuts at the module level
struct MediOpsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [emergencyShortcut]
    }
}
