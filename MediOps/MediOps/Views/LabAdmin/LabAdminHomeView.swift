import SwiftUI

struct LabAdminHomeView: View {
    @State private var selectedTab = 0
    @State private var labAdminName: String = "Lab Admin"
    @State private var labAdminId: String = ""
    @State private var showLogoutConfirmation = false
    @EnvironmentObject private var navigationState: AppNavigationState
    @State private var labAdmin: LabAdmin?
    
    var body: some View {
        Group {
            if let labAdmin = labAdmin {
                TabView(selection: $selectedTab) {
                    // Dashboard Tab - Using the existing LabDashboardView from the Lab directory
                    LabDashboardView(labAdmin: labAdmin)
                        .tabItem {
                            Image(systemName: "chart.bar")
                            Text("Dashboard")
                        }
                        .tag(0)
                    
                    // Tests Tab - Using placeholder view for now
                    Text("Tests List")
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tabItem {
                            Image(systemName: "flask")
                            Text("Tests")
                        }
                        .tag(1)
                    
                    // Patients Tab - Using placeholder view for now
                    Text("Patients List")
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tabItem {
                            Image(systemName: "person.2")
                            Text("Patients")
                        }
                        .tag(2)
                    
                    // Reports Tab - Using our new PatientReportsView
                    PatientReportsView()
                        .tabItem {
                            Image(systemName: "doc.text")
                            Text("Reports")
                        }
                        .tag(3)
                    
                    // Profile Tab - Using placeholder view for now
                    Text("Lab Profile")
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tabItem {
                            Image(systemName: "person.circle")
                            Text("Profile")
                        }
                        .tag(4)
                }
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        VStack(alignment: .leading) {
                            Text("Welcome,")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(labAdmin.name)
                                .font(.headline)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showLogoutConfirmation = true
                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                    }
                }
            } else {
                // Show loading view while fetching lab admin details
                ProgressView("Loading profile...")
                    .onAppear {
                        fetchLabAdminDetails()
                    }
            }
        }
        .alert("Logout", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .onAppear {
            fetchLabAdminDetails()
        }
    }
    
    private func fetchLabAdminDetails() {
        // Get lab admin ID from UserDefaults
        if let id = UserDefaults.standard.string(forKey: "lab_admin_id") {
            labAdminId = id
            
            // Fetch lab admin details from Supabase
            Task {
                do {
                    let labAdmins = try await SupabaseController.shared.select(
                        from: "lab_admins",
                        where: "id",
                        equals: id
                    )
                    
                    if let labAdminData = labAdmins.first {
                        await MainActor.run {
                            // Create a LabAdmin object from the data
                            if let name = labAdminData["name"] as? String,
                               let hospitalId = labAdminData["hospital_id"] as? String,
                               let email = labAdminData["email"] as? String,
                               let department = labAdminData["department"] as? String {
                                
                                let contactNumber = labAdminData["contact_number"] as? String ?? ""
                                let address = labAdminData["Address"] as? String ?? ""
                                
                                self.labAdmin = LabAdmin(
                                    id: id,
                                    hospitalId: hospitalId,
                                    name: name,
                                    email: email,
                                    contactNumber: contactNumber,
                                    department: department,
                                    address: address,
                                    createdAt: Date(),  // Using current date as fallback
                                    updatedAt: Date()   // Using current date as fallback
                                )
                                
                                self.labAdminName = name
                            }
                        }
                    }
                } catch {
                    print("Failed to fetch lab admin details: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func logout() {
        // Clear stored IDs
        UserDefaults.standard.removeObject(forKey: "lab_admin_id")
        UserDefaults.standard.removeObject(forKey: "hospital_id")
        
        // Update navigation state to signed out
        navigationState.signOut()
    }
}

#Preview {
    NavigationStack {
        LabAdminHomeView()
            .environmentObject(AppNavigationState())
    }
} 