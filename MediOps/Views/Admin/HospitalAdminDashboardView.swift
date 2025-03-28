import SwiftUI

struct HospitalAdminDashboardView: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    @Environment(\.dismiss) private var dismiss
    
    // State variables
    @State private var showLogoutConfirmation = false
    @State private var navigateToRoleSelection = false
    
    private let userController = UserController.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hospital Admin Dashboard")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Welcome back!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        // Logout Button
                        Button(action: { showLogoutConfirmation = true }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    
                    // Main content will go here
                    // Add your dashboard content
                    
                    Spacer()
                    
                    NavigationLink(destination: RoleSelectionView(), isActive: $navigateToRoleSelection) {
                        EmptyView()
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Logout Confirmation", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func performLogout() {
        // Clear authentication data
        userController.logout()
        
        // Update navigation state
        navigationState.signOut()
        
        // Navigate to role selection
        navigateToRoleSelection = true
    }
}

#Preview {
    HospitalAdminDashboardView()
        .environmentObject(AppNavigationState())
} 