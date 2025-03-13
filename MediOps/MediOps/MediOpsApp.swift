//
//  MediOpsApp.swift
//  MediOps
//
//  Created by Abcom on 13/03/25.
//

import SwiftUI

@main
struct MediOpsApp: App {
    init() {
        // Configure development assets
        #if DEBUG
        if let developmentAssetsPath = Bundle.main.path(forResource: "Development Assets", ofType: "xcassets") {
            print("Development Assets path: \(developmentAssetsPath)")
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RoleSelectionView()
            }
        }
    }
}
