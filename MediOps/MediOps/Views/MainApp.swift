import SwiftUI

// Utility for integrating theming into the main app
struct ThemingHelper {
    // Get shared instance of theme manager
    static var themeManager: ThemeManager {
        return ThemeManager.shared
    }
    
    // Apply theming to any view
    static func applyTheming<T: View>(to view: T) -> some View {
        return view
            .environmentObject(themeManager)
    }
}

// Renamed to ThemedRootView for clarity
struct ThemedRootView: View {
    @EnvironmentObject var navigationState: AppNavigationState
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            if navigationState.isLoggedIn {
                switch navigationState.userRole {
                case .patient:
                    HomeTabView()
                        .transition(.opacity)
                case .doctor:
                    DoctorLoginView()
                case .superAdmin:
                    SuperAdminLoginView()
                case .hospitalAdmin:
                    AdminLoginView()
                case .labAdmin:
                    LabAdminLoginView()
                default:
                    RoleSelectionView()
                        .environmentObject(navigationState)
                }
            } else {
                RoleSelectionView()
                    .environmentObject(navigationState)
            }
        }
        .animation(.easeInOut, value: navigationState.isLoggedIn)
        .animation(.easeInOut, value: navigationState.userRole)
    }
} 