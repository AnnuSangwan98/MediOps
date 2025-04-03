//
//  MediOpsApp.swift
//  MediOps
//
//  Created by Abcom on 13/03/25.
//

import SwiftUI

@main
struct MediOpsApp: App {
    // State object for theme management
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            SplashScreenAlt()
                // Add theme support
                .environmentObject(themeManager)
        }
    }
}
