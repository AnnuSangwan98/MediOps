//
//  MediOpsApp.swift
//  MediOps
//
//  Created by Abcom on 13/03/25.
//

import SwiftUI

@main
struct MediOpsApp: App {
    // Add translation manager
    @StateObject private var translationManager = TranslationManager.shared
    
    var body: some Scene {
        WindowGroup {
            SplashScreenAlt()
                // Add translation support
                .environmentObject(translationManager)
                .localizedLayout()
        }
    }
}
