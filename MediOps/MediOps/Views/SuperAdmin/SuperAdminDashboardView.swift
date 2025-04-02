import SwiftUI

struct SuperAdminDashboardView: View {
    @StateObject private var viewModel = SuperAdminDashboardViewModel()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var navigationState: AppNavigationState
    @Environment(\.dismiss) var dismiss
    
    // Form States
    @State private var showHospitalForm = false
    @State private var hospitalName = ""
    @State private var adminName = ""
    @State private var hospitalID = ""
    @State private var licenseNumber = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = "Delhi"
    @State private var zipCode = ""
    @State private var emergencyContact = ""
    
    // Alert States
    @State private var showSuccessAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showLogoutConfirmation = false
    @State private var navigateToRoleSelection = false
    @State private var showProfileSheet = false
    
    // Selected Hospital States
    @State private var hospitalToDelete: Hospital?
    @State private var showEditForm = false
    @State private var selectedHospital: Hospital?
    
    // Loading States
    @State private var isLoadingAction = false
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        return phone.count == 10 && phone.allSatisfy { $0.isNumber }
    }
    
    private func isValidPinCode(_ pinCode: String) -> Bool {
        return pinCode.count == 6 && pinCode.allSatisfy { $0.isNumber }
    }
    
    // MARK: - View Components
    @ViewBuilder
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Super Admin")
                    .font(.title)
                    .fontWeight(.bold)
               
            }
            Spacer()
            
            HStack(spacing: 20) {
                NavigationLink(destination: SuperAdminProfileView()) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.teal)
                        .background(Circle().fill(Color.white))
                        .shadow(color: .gray.opacity(0.2), radius: 3)
                }
                .padding(.trailing)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    @ViewBuilder
    private var searchAndFilterView: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search hospitals...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .gray.opacity(0.1), radius: 5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    FilterChip(title: "All States", 
                             isSelected: viewModel.selectedState == nil) {
                        viewModel.selectedState = nil
                    }
                    
                    ForEach(viewModel.uniqueStates, id: \.self) { state in
                        FilterChip(title: state,
                                 isSelected: viewModel.selectedState == state) {
                            viewModel.selectedState = state
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    headerView
                    searchAndFilterView
                    
                    // Hospitals section with title outside scroll view
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 5){
                            Text("\(viewModel.filteredHospitals.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.teal)
                            Text(viewModel.filteredHospitals.count == 1 ? " Hospital Found" : " Hospitals Found")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal)
                        // Only the hospital list is scrollable
                        ScrollView {
                            VStack(spacing: 15) {
                                if viewModel.isLoading {
                                    ProgressView("Loading hospitals...")
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .padding()
                                } else if !viewModel.errorMessage.isEmpty {
                                    VStack(spacing: 15) {
                                        Text("Error")
                                            .font(.headline)
                                            .foregroundColor(.red)
                                        
                                        Text(viewModel.errorMessage)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                        
                                        Button(action: { viewModel.fetchHospitals() }) {
                                            Text("Try Again")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 24)
                                                .padding(.vertical, 12)
                                                .background(Color.teal)
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: .gray.opacity(0.1), radius: 5)
                                    .padding()
                                } else if viewModel.filteredHospitals.isEmpty {
                                    Text("No hospitals found")
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(color: .gray.opacity(0.1), radius: 5)
                                } else {
                                    ForEach(viewModel.filteredHospitals) { hospital in
                                        HospitalListItem(
                                            hospital: hospital,
                                            onEdit: {
                                                selectedHospital = hospital
                                                showEditForm = true
                                            },
                                            onDelete: {
                                                hospitalToDelete = hospital
                                                showDeleteConfirmation = true
                                            }
                                        )
                                    }
                                }
                            }
                            .padding()
                        }
                        .refreshable {
                            await refreshData()
                        }
                    }
                    .padding(.top)
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showHospitalForm = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.teal)
                                .clipShape(Circle())
                                .shadow(color: .gray.opacity(0.3), radius: 5)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showHospitalForm) {
                NavigationView {
                    AddHospitalForm(
                        hospitalName: $hospitalName,
                        hospitalID: $hospitalID,
                        licenseNumber: $licenseNumber,
                        emergencyContact: $emergencyContact,
                        street: $street,
                        city: $city,
                        state: $state,
                        zipCode: $zipCode,
                        adminName: $adminName,
                        phone: $phone,
                        email: $email,
                        onSubmit: addHospital
                    )
                    .navigationTitle("Add Hospital")
                }
            }
            .sheet(isPresented: $showEditForm) {
                if let hospital = selectedHospital {
                    NavigationView {
                        EditHospitalForm(hospital: hospital, onSave: updateHospital)
                            .navigationTitle("Edit Hospital")
                            .navigationBarItems(trailing: Button("Cancel") {
                                showEditForm = false
                            })
                    }
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { clearForm() }
            } message: {
                Text("Hospital added successfully!")
            }
            .alert("Delete Hospital", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let hospital = hospitalToDelete {
                        deleteHospital(hospital)
                    }
                }
                .disabled(isLoadingAction)
            } message: {
                VStack {
                    Text("Are you sure you want to delete this hospital? This action cannot be undone.")
                    if isLoadingAction {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding(.top, 8)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Logout Confirmation", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .fullScreenCover(isPresented: $navigateToRoleSelection) {
                RoleSelectionView()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Actions
    private func addHospital() {
        // The actual adding of the hospital to Supabase is already handled in the AddHospitalForm
        // This method is just called after submission from the form
        // We'll refresh the hospitals list to reflect the new addition
        Task {
            await refreshData()
        }
        showSuccessAlert = true
        showHospitalForm = false
        clearForm()
    }
    
    private func updateHospital(_ hospital: Hospital) {
        // Set loading indicator
        isLoadingAction = true
        
        Task {
            do {
                // Update hospital in Supabase through the viewModel
                try await viewModel.updateHospital(hospital)
                
                await MainActor.run {
                    // Update UI state on success
                    showEditForm = false
                    isLoadingAction = false
                    errorMessage = "Hospital updated successfully"
                    showError = true
                }
            } catch {
                await MainActor.run {
                    // Handle error
                    isLoadingAction = false
                    errorMessage = "Failed to update hospital: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func deleteHospital(_ hospital: Hospital) {
        // Set loading and disable the button
        isLoadingAction = true
        
        Task {
            do {
                // Delete from Supabase using the viewModel
                try await viewModel.deleteHospital(hospital)
                
                await MainActor.run {
                    // Update UI state
                    hospitalToDelete = nil
                    isLoadingAction = false
                    errorMessage = "Hospital deleted successfully"
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isLoadingAction = false
                    errorMessage = "Failed to delete hospital: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func refreshData() async {
        viewModel.fetchHospitals()
    }
    
    private func clearForm() {
        hospitalName = ""
        adminName = ""
        hospitalID = ""
        licenseNumber = ""
        phone = ""
        email = ""
        street = ""
        city = ""
        state = "Delhi"
        zipCode = ""
        emergencyContact = ""
    }
    
    private func performLogout() {
        // Clear user data
        UserDefaults.standard.removeObject(forKey: "userRole")
        UserDefaults.standard.removeObject(forKey: "userToken")
        
        // Navigate to role selection using fullScreenCover
        navigateToRoleSelection = true
    }
}

struct HospitalListItem: View {
    let hospital: Hospital
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 15) {
                // Hospital Image
                if let imageData = hospital.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Hospital Name and Status
                    HStack {
                        Text(hospital.name)
                            .font(.headline)
                            .foregroundColor(.black)
                        Spacer()
                        
                        Text(hospital.status.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(statusColor)
                                    .opacity(0.2)
                            )
                            .foregroundColor(statusColor)
                        
                        // Three-dot menu
                        Menu {
                            Button(action: onEdit) {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(action: onDelete) {
                                Label("Delete", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    
                    // IDs
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hospital ID")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(hospital.id)
                                .font(.caption)
                                .foregroundColor(.teal)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("License")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(hospital.licenseNumber)
                                .font(.caption)
                                .foregroundColor(.teal)
                        }
                    }
                    
                    // Address
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Address")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("\(hospital.street), \(hospital.city), \(hospital.state) - \(hospital.zipCode)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Contact Information (Hospital Emergency Contact)
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                            .foregroundColor(.teal)
                        Text(hospital.hospitalPhone)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
        .contentShape(Rectangle())
    }
    
    private var statusColor: Color {
        switch hospital.status {
        case .active:
            return .green
        case .pending:
            return .orange
        case .inactive:
            return .red
        }
    }
}


struct DashboardCards: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(title: String, icon: String, color: Color, action: @escaping () -> Void = {}) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.1), radius: 5)
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// New FilterChip View
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.teal : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(20)
        }
    }
}

// New SuperAdminProfileView
struct SuperAdminProfileView: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    @State private var showLogoutConfirmation = false
    @State private var navigateToRoleSelection = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Profile Image
                Circle()
                    .fill(Color.teal.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.teal)
                    )
                    .padding(.top, 40)
                
                // Profile Info
                VStack(spacing: 12) {
                    Text("Super Admin")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("SUPER1")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Profile Stats
                VStack(spacing: 15) {
                    ProfileRowView(icon: "building.2.fill", title: "Role", value: "Manage Hospitals")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.1), radius: 5)
                .padding(.horizontal)
                
                Spacer()
                
                // Logout Button
                Button(action: { showLogoutConfirmation = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Logout")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Logout Confirmation", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .fullScreenCover(isPresented: $navigateToRoleSelection) {
            RoleSelectionView()
        }
    }
    
    private func performLogout() {
        // Clear user data
        UserDefaults.standard.removeObject(forKey: "userRole")
        UserDefaults.standard.removeObject(forKey: "userToken")
        
        // Navigate to role selection using fullScreenCover
        navigateToRoleSelection = true
    }
}

struct ProfileRowView: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.teal)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SuperAdminDashboardView()
}
