import SwiftUI

// Utility for integrating localization into the main app
struct LocalizationHelper {
    // Get shared instance of translation manager
    static var translationManager: TranslationManager {
        return TranslationManager.shared
    }
    
    // Apply localization to any view
    static func applyLocalization<T: View>(to view: T) -> some View {
        return view
            .environmentObject(translationManager)
            .modifier(LocalizedViewModifier())
    }
}

// Renamed to LocalizedRootView for clarity
struct LocalizedRootView: View {
    @EnvironmentObject var navigationState: AppNavigationState
    @EnvironmentObject var translationManager: TranslationManager
    
    var body: some View {
        ZStack {
            if navigationState.isLoggedIn {
                switch navigationState.userRole {
                case .patient:
                    HomeTabView()
                        .transition(.opacity)
                        .localizedLayout()
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