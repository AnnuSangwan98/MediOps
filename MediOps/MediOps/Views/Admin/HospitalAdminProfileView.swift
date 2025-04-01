import SwiftUI
import Foundation

// Model to represent a HospitalAdmin based on the provided schema
struct HospitalAdminProfile: Identifiable {
    var id: String
    var hospitalId: String
    var adminName: String
    var email: String
    var contactNumber: String?
    var street: String?
    var city: String?
    var state: String?
    var pincode: String?
    var role: String
    var status: String
    var createdAt: Date
    var updatedAt: Date
}

class HospitalAdminProfileViewModel: ObservableObject {
    @Published var admin: HospitalAdminProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseController.shared
    private let adminController = AdminController.shared
    
    init() {
        fetchAdminProfile()
    }
    
    func fetchAdminProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Get admin ID from UserDefaults (saved during admin login)
                guard let adminId = UserDefaults.standard.string(forKey: "hospital_id") else {
                    await MainActor.run {
                        self.errorMessage = "No admin ID found. Please login again."
                        self.isLoading = false
                    }
                    return
                }
                
                print("Fetching admin profile for ID: \(adminId)")
                
                // Query the hospital_admins table for the admin
                let admins = try await supabase.select(
                    from: "hospital_admins",
                    where: "id",
                    equals: adminId
                )
                
                print("Query returned \(admins.count) results")
                
                if let adminData = admins.first {
                    // Parse the admin data
                    let dateFormatter = ISO8601DateFormatter()
                    
                    let createdAtString = adminData["created_at"] as? String
                    let createdAt = createdAtString != nil ? dateFormatter.date(from: createdAtString!) ?? Date() : Date()
                    
                    let updatedAtString = adminData["updated_at"] as? String
                    let updatedAt = updatedAtString != nil ? dateFormatter.date(from: updatedAtString!) ?? Date() : Date()
                    
                    // Create admin profile object
                    let profile = HospitalAdminProfile(
                        id: adminData["id"] as? String ?? "",
                        hospitalId: adminData["hospital_id"] as? String ?? "",
                        adminName: adminData["admin_name"] as? String ?? "",
                        email: adminData["email"] as? String ?? "",
                        contactNumber: adminData["contact_number"] as? String,
                        street: adminData["street"] as? String,
                        city: adminData["city"] as? String,
                        state: adminData["state"] as? String,
                        pincode: adminData["pincode"] as? String,
                        role: adminData["role"] as? String ?? "HOSPITAL_ADMIN",
                        status: adminData["status"] as? String ?? "active",
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    )
                    
                    await MainActor.run {
                        self.admin = profile
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Admin profile not found."
                        self.isLoading = false
                    }
                }
            } catch {
                print("Error fetching admin profile: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func updateAdminProfile(email: String, contactNumber: String) {
        guard let admin = admin else { return }
        
        isLoading = true
        
        Task {
            do {
                // Prepare update data
                let updateData: [String: Any] = [
                    "email": email,
                    "contact_number": contactNumber,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ]
                
                // Update the admin in Supabase
                try await supabase.update(
                    table: "hospital_admins",
                    id: admin.id,
                    data: updateData
                )
                
                // Refresh the admin profile
                await MainActor.run {
                    // Update local model first for instant UI update
                    var updatedAdmin = self.admin
                    updatedAdmin?.email = email
                    updatedAdmin?.contactNumber = contactNumber
                    updatedAdmin?.updatedAt = Date()
                    self.admin = updatedAdmin
                    
                    // Then refetch from server to ensure everything is in sync
                    self.fetchAdminProfile()
                }
            } catch {
                print("Error updating admin profile: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func resetPassword(currentPassword: String, newPassword: String, useForceReset: Bool = false) async -> Result<Void, Error> {
        guard let admin = admin else { 
            return .failure(NSError(domain: "AdminProfile", code: 1, userInfo: [NSLocalizedDescriptionKey: "Admin profile not loaded"]))
        }
        
        do {
            print("PROFILE: Attempting to reset password for admin ID: \(admin.id)")
            print("PROFILE: Using force reset: \(useForceReset)")
            
            if useForceReset {
                // Use the emergency override reset (doesn't require current password)
                try await adminController.forceResetHospitalAdminPassword(
                    adminId: admin.id, 
                    newPassword: newPassword
                )
                print("PROFILE: Force password reset successful")
            } else {
                // Use the standard reset (requires current password)
                try await adminController.resetHospitalAdminPassword(
                    adminId: admin.id,
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                print("PROFILE: Standard password reset successful")
            }
            
            print("PROFILE: Password successfully reset for admin ID: \(admin.id)")
            return .success(())
        } catch {
            print("PROFILE ERROR: Password reset failed: \(error.localizedDescription)")
            
            // Extract more specific error messages from AdminError if available
            if let adminError = error as? AdminError {
                let errorMessage: String
                switch adminError {
                case .invalidPassword(let message):
                    errorMessage = message
                case .adminNotFound:
                    errorMessage = "Admin account not found"
                default:
                    errorMessage = adminError.errorDescription ?? error.localizedDescription
                }
                
                return .failure(NSError(domain: "AdminProfile", code: 4, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            }
            
            return .failure(error)
        }
    }
}

struct HospitalAdminProfileView: View {
    @StateObject private var viewModel = HospitalAdminProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationState: AppNavigationState
    
    // Edit state
    @State private var isEditing = false
    @State private var editingEmail = ""
    @State private var editingContact = ""
    
    // Password reset
    @State private var showResetPasswordSheet = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    // Alert states
    @State private var showLogoutConfirmation = false
    @State private var showSaveSuccess = false
    @State private var showResetSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var successMessage = "Your password has been successfully reset."
    @State private var useForceReset = true // Temporarily set to true for emergency use
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading profile...")
                        .padding()
                } else if let admin = viewModel.admin {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Profile Image
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                                .foregroundColor(.teal)
                                .padding(.top, 20)
                            
                            Text("Hospital Admin Profile")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .padding(.bottom, 20)
                            
                            // Personal Information
                            GroupBox(label: 
                                Text("PERSONAL INFORMATION")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            ) {
                                VStack(spacing: 0) {
                                    // Read-only name field
                                    ProfileInfoRow(title: "Name", value: admin.adminName)
                                    Divider()
                                    
                                    // Editable Email field
                                    if isEditing {
                                        HStack {
                                            Text("Email")
                                                .foregroundColor(.primary)
                                            Spacer()
                                            TextField("Email", text: $editingEmail)
                                                .multilineTextAlignment(.trailing)
                                                .keyboardType(.emailAddress)
                                                .autocapitalization(.none)
                                                .disableAutocorrection(true)
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 5)
                                    } else {
                                        ProfileInfoRow(title: "Email", value: admin.email)
                                    }
                                    Divider()
                                    
                                    // Editable Contact field
                                    if isEditing {
                                        HStack {
                                            Text("Contact")
                                                .foregroundColor(.primary)
                                            Spacer()
                                            TextField("Contact", text: $editingContact)
                                                .multilineTextAlignment(.trailing)
                                                .keyboardType(.phonePad)
                                                .foregroundColor(.blue)
                                                .onChange(of: editingContact) { newValue in
                                                    // Filter non-digit characters
                                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                                    
                                                    // Limit to 10 digits
                                                    if filtered.count > 10 {
                                                        editingContact = String(filtered.prefix(10))
                                                    } else if filtered != newValue {
                                                        editingContact = filtered
                                                    }
                                                }
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 5)
                                    } else {
                                        ProfileInfoRow(title: "Contact", value: admin.contactNumber ?? "Not provided")
                                    }
                                    Divider()
                                    
                                    // Read-only role field
                                    ProfileInfoRow(title: "Role", value: "Hospital Administrator")
                                    Divider()
                                    
                                    // Status
                                    ProfileInfoRow(title: "Status", value: admin.status.capitalized)
                                }
                                .padding(.vertical, 5)
                            }
                            .padding(.horizontal)
                            
                            // Hospital Information
                            GroupBox(label: 
                                Text("HOSPITAL INFORMATION")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            ) {
                                VStack(spacing: 0) {
                                    ProfileInfoRow(title: "Admin ID", value: admin.id)
                                    Divider()
                                    ProfileInfoRow(title: "Hospital ID", value: admin.hospitalId)
                                    
                                    // Address section (if available)
                                    if let street = admin.street, !street.isEmpty {
                                        Divider()
                                        ProfileInfoRow(title: "Street", value: street)
                                    }
                                    
                                    if let city = admin.city, !city.isEmpty {
                                        Divider()
                                        ProfileInfoRow(title: "City", value: city)
                                    }
                                    
                                    if let state = admin.state, !state.isEmpty {
                                        Divider()
                                        ProfileInfoRow(title: "State", value: state)
                                    }
                                    
                                    if let pincode = admin.pincode, !pincode.isEmpty {
                                        Divider()
                                        ProfileInfoRow(title: "PIN Code", value: pincode)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                            .padding(.horizontal)
                            
                            // Security Section
                            GroupBox(label: 
                                Text("SECURITY")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            ) {
                                Button(action: {
                                    showResetPasswordSheet = true
                                }) {
                                    HStack {
                                        Text("Reset Password")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 17))
                                        Spacer()
                                        Image(systemName: "key.fill")
                                            .foregroundColor(.blue)
                                    }
                                    .contentShape(Rectangle())
                                    .padding(.vertical, 10)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Logout Button
                            Button(action: {
                                showLogoutConfirmation = true
                            }) {
                                Text("Logout")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.red, lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                            
                            Spacer()
                        }
                    }
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                        
                        Button("Try Again") {
                            viewModel.fetchAdminProfile()
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.teal)
                        .cornerRadius(10)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                    } else {
                        Button("Edit") {
                            // Initialize editing fields with current values
                            if let admin = viewModel.admin {
                                editingEmail = admin.email
                                editingContact = admin.contactNumber ?? ""
                            }
                            isEditing = true
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                        }
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Logout", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    // Clear stored ID
                    UserDefaults.standard.removeObject(forKey: "hospital_id")
                    
                    // Update navigation state
                    navigationState.signOut()
                    
                    // Dismiss the sheet
                    dismiss()
                    
                    // Get the scene delegate window and reset to RoleSelectionView immediately
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
                Text("Are you sure you want to logout?")
            }
            .sheet(isPresented: $showResetPasswordSheet) {
                ResetPasswordView(
                    currentPassword: $currentPassword,
                    newPassword: $newPassword,
                    confirmPassword: $confirmPassword,
                    onSubmit: handlePasswordReset,
                    onCancel: { showResetPasswordSheet = false }
                )
            }
            .alert("Success", isPresented: $showResetSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your password has been successfully reset.")
            }
            .alert("Profile Updated", isPresented: $showSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your profile information has been updated successfully.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveChanges() {
        Task {
            do {
                // Email validation
                let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
                let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
                
                if !emailPredicate.evaluate(with: editingEmail) {
                    await MainActor.run {
                        showError = true
                        errorMessage = "Please enter a valid email address."
                    }
                    return
                }
                
                // Phone number validation (only if provided)
                if !editingContact.isEmpty {
                    let phoneRegex = "^[0-9]{10}$"
                    let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
                    
                    if !phonePredicate.evaluate(with: editingContact) {
                        await MainActor.run {
                            showError = true
                            errorMessage = "Please enter a valid 10-digit phone number."
                        }
                        return
                    }
                }
                
                // Update profile through ViewModel
                viewModel.updateAdminProfile(email: editingEmail, contactNumber: editingContact)
                
                // Show success message and exit edit mode
                await MainActor.run {
                    isEditing = false
                    showSaveSuccess = true
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = "Failed to update profile: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func handlePasswordReset() {
        Task {
            // Validate new password
            // Password must be at least 8 characters
            if newPassword.count < 8 {
                await MainActor.run {
                    showResetPasswordSheet = false
                    showError = true
                    errorMessage = "Password must be at least 8 characters long."
                }
                return
            }
            
            // Password must contain at least one uppercase, one lowercase, one digit and one special character
            let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]+$"
            let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
            
            if !passwordPredicate.evaluate(with: newPassword) {
                await MainActor.run {
                    showResetPasswordSheet = false
                    showError = true
                    errorMessage = "Password must contain at least one uppercase letter, one lowercase letter, one digit, and one special character (@$!%*?&)."
                }
                return
            }
            
            // Check if passwords match
            if newPassword != confirmPassword {
                await MainActor.run {
                    showResetPasswordSheet = false
                    showError = true
                    errorMessage = "New password and confirmation do not match."
                }
                return
            }
            
            // Reset password
            let result = await viewModel.resetPassword(
                currentPassword: currentPassword, 
                newPassword: newPassword,
                useForceReset: useForceReset // Use the force reset option
            )
            
            await MainActor.run {
                showResetPasswordSheet = false
                
                switch result {
                case .success:
                    // Reset form fields
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    successMessage = "Your password has been successfully reset and updated in all systems."
                    showResetSuccess = true
                    
                case .failure(let error):
                    showError = true
                    // Check for common error messages and provide more user-friendly feedback
                    let errorString = error.localizedDescription
                    if errorString.contains("Current password is incorrect") {
                        errorMessage = "The current password you entered is incorrect. Please try again."
                    } else if errorString.contains("already in use") {
                        errorMessage = "This password is already in use. Please choose a different password."
                    } else if errorString.contains("meet the required format") || 
                              errorString.contains("meet security requirements") {
                        errorMessage = "Your password does not meet the required format. It must contain at least 8 characters, one uppercase letter, one lowercase letter, one digit, and one special character (@$!%*?&)."
                    } else {
                        errorMessage = "Failed to reset password: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

// Reusable row component
struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
    }
}

#Preview {
    NavigationStack {
        HospitalAdminProfileView()
            .environmentObject(AppNavigationState())
    }
}
