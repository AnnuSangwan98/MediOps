import SwiftUI

struct AdminProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationState: AppNavigationState
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.teal)
                    .padding(.top, 20)
                
                Text("Admin Profile")
                    .font(.title)
                    .fontWeight(.bold)
                
                Form {
                    Section(header: Text("Personal Information")) {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text("Hospital Admin")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text("admin@mediops.com")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Role")
                            Spacer()
                            Text("Hospital Administrator")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            showLogoutAlert = true
                        }) {
                            HStack {
                                Spacer()
                                Text("Logout")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Yes, Logout", role: .destructive) {
                    // First sign out in navigation state
                    navigationState.signOut()
                    
                    // Dismiss the profile sheet
                    dismiss()
                    
                    // Get the scene delegate window
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first else { return }
                    
                    // Reset to RoleSelectionView
                    let contentView = NavigationStack {
                        RoleSelectionView()
                    }
                    .environmentObject(navigationState)
                    
                    window.rootViewController = UIHostingController(rootView: contentView)
                    window.makeKeyAndVisible()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

#Preview {
    AdminProfileView()
        .environmentObject(AppNavigationState())
} 