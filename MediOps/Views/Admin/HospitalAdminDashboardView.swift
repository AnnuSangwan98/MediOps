import SwiftUI

// ViewModel to manage lab admin data
class LabAdminDashboardViewModel: ObservableObject {
    @Published var labAdmins: [LabAdmin] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private let adminController = AdminController.shared
    private let userController = UserController.shared
    
    func fetchLabAdmins() async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            // Try to get the current hospital admin ID
            var hospitalAdminId: String? = nil
            
            if let currentUser = try? await userController.getCurrentUser() {
                print("Current user role: \(currentUser.role.rawValue)")
                
                // If user is a hospital admin, use their ID directly
                if currentUser.role == .hospitalAdmin {
                    hospitalAdminId = currentUser.id
                    print("Using hospital admin ID: \(hospitalAdminId ?? "unknown")")
                } else {
                    // For other roles, try to get their associated hospital admin
                    do {
                        let hospitalAdmin = try await adminController.getHospitalAdminByUserId(userId: currentUser.id)
                        hospitalAdminId = hospitalAdmin.id
                        print("Retrieved hospital admin ID: \(hospitalAdminId ?? "unknown")")
                    } catch {
                        print("Warning: \(error.localizedDescription)")
                    }
                }
            }
            
            // Use a fallback ID if needed
            if hospitalAdminId == nil {
                hospitalAdminId = "HOS001"
                print("Using fallback hospital admin ID")
            }
            
            // Fetch lab admins
            print("Fetching lab admins for hospital ID: \(hospitalAdminId!)")
            let fetchedLabAdmins = try await adminController.getLabAdmins(hospitalAdminId: hospitalAdminId!)
            
            await MainActor.run {
                self.labAdmins = fetchedLabAdmins
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch lab admins: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("Error fetching lab admins: \(error)")
        }
    }
}

struct HospitalAdminDashboardView: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var labAdminViewModel = LabAdminDashboardViewModel()
    
    // State variables
    @State private var showLogoutConfirmation = false
    @State private var navigateToRoleSelection = false
    @State private var selectedTab = 0
    
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
                    
                    // Tab selector
                    TabView(selection: $selectedTab) {
                        // Doctors Tab
                        DoctorsTabView()
                            .tabItem {
                                Label("Doctors", systemImage: "stethoscope")
                            }
                            .tag(0)
                        
                        // Lab Admins Tab
                        LabAdminsTabView(viewModel: labAdminViewModel)
                            .tabItem {
                                Label("Lab Admins", systemImage: "testtube.2")
                            }
                            .tag(1)
                        
                        // Settings Tab (if needed)
                        Text("Settings")
                            .tabItem {
                                Label("Settings", systemImage: "gear")
                            }
                            .tag(2)
                    }
                    
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
        .task {
            await labAdminViewModel.fetchLabAdmins()
        }
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

// DoctorsTabView: View to display doctors
struct DoctorsTabView: View {
    var body: some View {
        VStack {
            Text("Doctors Management")
                .font(.headline)
                .padding()
            
            // Link to DoctorsListView
            NavigationLink(destination: DoctorsListView(doctors: .constant([]))) {
                HStack {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.teal)
                    Text("Manage Doctors")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.1), radius: 5)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

// LabAdminsTabView: View to display lab admins
struct LabAdminsTabView: View {
    @ObservedObject var viewModel: LabAdminDashboardViewModel
    
    var body: some View {
        VStack {
            Text("Lab Admins Management")
                .font(.headline)
                .padding()
            
            if viewModel.isLoading {
                ProgressView("Loading lab admins...")
                    .padding()
            } else if !viewModel.errorMessage.isEmpty {
                VStack {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Try Again") {
                        Task {
                            await viewModel.fetchLabAdmins()
                        }
                    }
                    .padding()
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            } else if viewModel.labAdmins.isEmpty {
                VStack {
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("No lab admins found")
                        .foregroundColor(.gray)
                }
                .padding()
            } else {
                // Display lab admins list
                List {
                    ForEach(viewModel.labAdmins, id: \.id) { labAdmin in
                        VStack(alignment: .leading) {
                            Text(labAdmin.name)
                                .font(.headline)
                            Text(labAdmin.department)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(labAdmin.email)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .refreshable {
                    await viewModel.fetchLabAdmins()
                }
            }
            
            // Link to LabAdminsListView (if you have one)
            NavigationLink(destination: Text("Lab Admins List View")) {
                HStack {
                    Image(systemName: "testtube.2")
                        .foregroundColor(.teal)
                    Text("Manage Lab Admins")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.1), radius: 5)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

#Preview {
    HospitalAdminDashboardView()
        .environmentObject(AppNavigationState())
} 
