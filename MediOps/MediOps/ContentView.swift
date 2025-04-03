import SwiftUI

struct ContentView: View {
    @StateObject private var navigationState = AppNavigationState()
    
    var body: some View {
        NavigationStack {
            RoleSelectionView()
        }
        .environmentObject(navigationState)
        .environmentObject(ThemeManager.shared)
    }
}

#Preview {
    ContentView()
}
